-- Flux commande utilisateur:
-- live -> panier -> informations client/livraison -> paiement à la livraison
-- -> commande en attente avec stock réservé -> vendeur valide en livraison
-- -> livreur scanne le QR code -> livré.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Moyens de paiement. Pour le moment: paiement à la livraison.
CREATE TABLE IF NOT EXISTS public.payment_methods (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  code TEXT UNIQUE NOT NULL,
  label TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.payment_methods
  ALTER COLUMN id SET DEFAULT gen_random_uuid();

INSERT INTO public.payment_methods (code, label)
VALUES ('cod', 'Paiement à la livraison')
ON CONFLICT (code) DO UPDATE
SET label = EXCLUDED.label,
    is_active = true;

-- Extension non destructive de la table reservations existante.
ALTER TABLE public.reservations
  ADD COLUMN IF NOT EXISTS order_group_id UUID DEFAULT gen_random_uuid(),
  ADD COLUMN IF NOT EXISTS quantity INT DEFAULT 1 NOT NULL,
  ADD COLUMN IF NOT EXISTS unit_price DECIMAL(10, 2),
  ADD COLUMN IF NOT EXISTS total_amount DECIMAL(10, 2),
  ADD COLUMN IF NOT EXISTS client_name TEXT,
  ADD COLUMN IF NOT EXISTS client_phone TEXT,
  ADD COLUMN IF NOT EXISTS delivery_address TEXT,
  ADD COLUMN IF NOT EXISTS delivery_remark TEXT,
  ADD COLUMN IF NOT EXISTS payment_method_id UUID REFERENCES public.payment_methods(id),
  ADD COLUMN IF NOT EXISTS qr_token TEXT,
  ADD COLUMN IF NOT EXISTS stock_reserved BOOLEAN DEFAULT false NOT NULL,
  ADD COLUMN IF NOT EXISTS validated_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL;

ALTER TABLE public.reservations
  ALTER COLUMN id SET DEFAULT gen_random_uuid(),
  ALTER COLUMN order_group_id SET DEFAULT gen_random_uuid();

-- Si l'ancien CHECK limite les statuts à pending/validated/delivered,
-- il faut le remplacer. Le nom par défaut est souvent reservations_status_check.
DO $$
DECLARE
  constraint_name TEXT;
BEGIN
  SELECT conname INTO constraint_name
  FROM pg_constraint
  WHERE conrelid = 'public.reservations'::regclass
    AND contype = 'c'
    AND pg_get_constraintdef(oid) LIKE '%status%';

  IF constraint_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.reservations DROP CONSTRAINT %I', constraint_name);
  END IF;
END $$;

ALTER TABLE public.reservations
  ADD CONSTRAINT reservations_status_check
  CHECK (status IN ('pending', 'in_delivery', 'delivered', 'cancelled', 'expired'));

CREATE INDEX IF NOT EXISTS reservations_order_group_id_idx
  ON public.reservations(order_group_id);
CREATE INDEX IF NOT EXISTS reservations_qr_token_idx
  ON public.reservations(qr_token);
CREATE INDEX IF NOT EXISTS reservations_status_idx
  ON public.reservations(status);

-- Policies utiles pour le nouveau flux.
DROP POLICY IF EXISTS "Vendeurs peuvent voir leurs commandes" ON public.reservations;
CREATE POLICY "Vendeurs peuvent voir leurs commandes" ON public.reservations
  FOR SELECT USING (
    EXISTS (
      SELECT 1
      FROM public.products p
      WHERE p.id = reservations.product_id
        AND p.seller_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Vendeurs peuvent valider leurs commandes" ON public.reservations;
CREATE POLICY "Vendeurs peuvent valider leurs commandes" ON public.reservations
  FOR UPDATE USING (
    EXISTS (
      SELECT 1
      FROM public.products p
      WHERE p.id = reservations.product_id
        AND p.seller_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.products p
      WHERE p.id = reservations.product_id
        AND p.seller_id = auth.uid()
    )
  );

-- Création transactionnelle d'une commande COD.
-- Le stock est réservé dès la validation client (status pending):
-- on décrémente products.stock pour éviter la survente pendant un live.
CREATE OR REPLACE FUNCTION public.create_cod_reservation(
  p_items JSONB,
  p_client_name TEXT,
  p_client_phone TEXT,
  p_delivery_address TEXT,
  p_payment_method_id UUID,
  p_delivery_remark TEXT DEFAULT NULL,
  p_group_info JSONB DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_order_group_id UUID := gen_random_uuid();
  v_qr_token TEXT := md5(concat_ws(':', clock_timestamp()::text, random()::text, v_user_id::text));
  v_item JSONB;
  v_product RECORD;
  v_quantity INT;
  v_total DECIMAL(10, 2) := 0;
  v_seller_id UUID;
  v_shop_name TEXT;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non connecté';
  END IF;

  IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'Panier vide';
  END IF;

  IF NULLIF(trim(p_client_name), '') IS NULL
    OR NULLIF(trim(p_client_phone), '') IS NULL
    OR NULLIF(trim(p_delivery_address), '') IS NULL THEN
    RAISE EXCEPTION 'Nom, contact et adresse sont obligatoires';
  END IF;

  UPDATE public.profiles
  SET full_name = COALESCE(NULLIF(full_name, ''), trim(p_client_name)),
      phone = COALESCE(NULLIF(phone, ''), trim(p_client_phone)),
      address = COALESCE(NULLIF(address, ''), trim(p_delivery_address))
  WHERE id = v_user_id;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    v_quantity := COALESCE((v_item->>'quantity')::INT, 1);
    
    SELECT id, name, price, stock, seller_id
    INTO v_product
    FROM public.products
    WHERE id = (v_item->>'product_id')::UUID
    FOR UPDATE;

    IF v_product.stock < v_quantity THEN
      RAISE EXCEPTION 'Stock insuffisant pour %', v_product.name;
    END IF;

    UPDATE public.products SET stock = stock - v_quantity WHERE id = v_product.id;
    
    v_total := v_total + (v_product.price * v_quantity);
    v_seller_id := v_product.seller_id;
  END LOOP;

  -- Résolution du nom de boutique (group_name)
  v_shop_name := COALESCE(p_group_info->>'name', (SELECT shop_name FROM public.profiles WHERE id = v_seller_id));

  INSERT INTO public.reservations (
    user_id,
    client_info,
    payment_method_id,
    total_amount,
    products,
    group_name,
    status,
    qr_token,
    order_group_id
  )
  VALUES (
    v_user_id,
    jsonb_build_object(
      'nom', p_client_name,
      'contact', p_client_phone,
      'adresse', p_delivery_address,
      'remarque', p_delivery_remark
    ),
    p_payment_method_id::UUID,
    v_total,
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'nom', p.name,
          'image', p.image_url,
          'quantité', (item->>'quantity')::INT,
          'prix_unitaire', p.price
        )
      )
      FROM jsonb_array_elements(p_items) AS item
      JOIN public.products p ON p.id = (item->>'product_id')::UUID
    ),
    jsonb_build_object(
      'shop_name', v_shop_name,
      'seller_id', v_seller_id
    ),
    'pending',
    v_qr_token,
    v_order_group_id
  );

  RETURN jsonb_build_object('reservation_id', v_order_group_id);
END;
$$;

-- Scan QR livreur: le QR token marque toutes les lignes de la commande comme livrées.
-- À connecter plus tard à un écran scanner QR.
CREATE OR REPLACE FUNCTION public.mark_reservation_delivered_by_qr(
  p_qr_token TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INT;
BEGIN
  UPDATE public.reservations
  SET status = 'delivered',
      delivered_at = timezone('utc'::text, now()),
      updated_at = timezone('utc'::text, now())
  WHERE qr_token = p_qr_token
    AND status = 'in_delivery';

  GET DIAGNOSTICS v_count = ROW_COUNT;

  IF v_count = 0 THEN
    RAISE EXCEPTION 'QR code invalide ou commande pas encore en livraison';
  END IF;

  RETURN jsonb_build_object('delivered_lines', v_count, 'status', 'delivered');
END;
$$;

-- Annulation/expiration: restaure le stock si la commande avait réservé le stock.
CREATE OR REPLACE FUNCTION public.cancel_reserved_order(
  p_order_group_id UUID,
  p_status TEXT DEFAULT 'cancelled'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_line RECORD;
  v_count INT := 0;
BEGIN
  IF p_status NOT IN ('cancelled', 'expired') THEN
    RAISE EXCEPTION 'Statut d''annulation invalide';
  END IF;

  FOR v_line IN
    SELECT id, product_id, quantity
    FROM public.reservations
    WHERE order_group_id = p_order_group_id
      AND status = 'pending'
      AND stock_reserved = true
    FOR UPDATE
  LOOP
    UPDATE public.products
    SET stock = stock + v_line.quantity
    WHERE id = v_line.product_id;

    UPDATE public.reservations
    SET status = p_status,
        stock_reserved = false,
        updated_at = timezone('utc'::text, now())
    WHERE id = v_line.id;

    v_count := v_count + 1;
  END LOOP;

  RETURN jsonb_build_object('cancelled_lines', v_count, 'status', p_status);
END;
$$;
