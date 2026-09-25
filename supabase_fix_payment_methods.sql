-- ==========================================
-- SCRIPT DE CORRECTION SUPABASE : TABLES, COLONNES & PAIEMENT
-- A executer dans l'editeur SQL de Supabase
-- ==========================================

-- 1. S'assurer de l'existence de la table payment_methods
CREATE TABLE IF NOT EXISTS public.payment_methods (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  code TEXT UNIQUE NOT NULL,
  label TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Insérer le moyen de paiement 'cod' (Paiement à la livraison) si manquant
INSERT INTO public.payment_methods (code, label)
VALUES ('cod', 'Paiement à la livraison')
ON CONFLICT (code) DO UPDATE
SET label = EXCLUDED.label,
    is_active = true;

-- 3. Configurer la politique RLS en lecture publique (SELECT) pour la table payment_methods
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read access to payment_methods" ON public.payment_methods;
CREATE POLICY "Allow public read access to payment_methods" ON public.payment_methods
  FOR SELECT USING (true);

-- 4. Alerter et mettre à jour la table reservations pour ajouter les colonnes manquantes
ALTER TABLE public.reservations 
  ADD COLUMN IF NOT EXISTS order_group_id UUID DEFAULT gen_random_uuid(),
  ADD COLUMN IF NOT EXISTS validated_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL;

-- 5. Rendre la colonne payment_method_id optionnelle (DROP NOT NULL) pour éviter tout échec si non fournie
ALTER TABLE public.reservations 
  ALTER COLUMN payment_method_id DROP NOT NULL;

-- 6. Mettre à jour la contrainte CHECK sur le statut pour accepter 'in_delivery' et 'expired'
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
  CHECK (status IN ('pending', 'validated', 'in_delivery', 'delivered', 'cancelled', 'expired'));

-- 7. Recréer la fonction create_cod_reservation avec gestion robuste du payment_method_id et sans colonne qr_token
CREATE OR REPLACE FUNCTION public.create_cod_reservation(
  p_items JSONB,
  p_client_name TEXT,
  p_client_phone TEXT,
  p_delivery_address TEXT,
  p_payment_method_id UUID DEFAULT NULL, -- Rendu optionnel avec valeur par défaut NULL
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
  v_item JSONB;
  v_product RECORD;
  v_quantity INT;
  v_total DECIMAL(10, 2) := 0;
  v_seller_id UUID;
  v_shop_name TEXT;
  v_payment_method_id UUID := p_payment_method_id;
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

  -- Résolution robuste du payment_method_id s'il n'est pas fourni par le client
  IF v_payment_method_id IS NULL THEN
    SELECT id INTO v_payment_method_id 
    FROM public.payment_methods 
    WHERE code = 'cod';
    
    -- Si la ligne n'existe pas en table, on la crée à la volée
    IF v_payment_method_id IS NULL THEN
      INSERT INTO public.payment_methods (code, label, is_active)
      VALUES ('cod', 'Paiement à la livraison', true)
      RETURNING id INTO v_payment_method_id;
    END IF;
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

  -- Insertion sans utiliser de colonne qr_token (on utilise directement order_group_id comme identifiant de QR code)
  INSERT INTO public.reservations (
    user_id,
    client_info,
    payment_method_id,
    total_amount,
    products,
    group_name,
    status,
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
    v_payment_method_id::text, -- Cast en TEXT pour correspondre à la colonne de la table
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
    jsonb_build_object('shop_name', v_shop_name),
    'pending',
    v_order_group_id
  );

  RETURN jsonb_build_object('reservation_id', v_order_group_id);
END;
$$;

-- 8. Recréer mark_reservation_delivered_by_qr pour comparer avec order_group_id au lieu de la colonne qr_token
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
  v_order_group_id UUID;
BEGIN
  -- Tenter de parser le token reçu en UUID
  BEGIN
    v_order_group_id := p_qr_token::UUID;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Format de QR Code invalide (UUID attendu)';
  END;

  UPDATE public.reservations
  SET status = 'delivered',
      delivered_at = timezone('utc'::text, now()),
      updated_at = timezone('utc'::text, now())
  WHERE order_group_id = v_order_group_id
    AND status = 'in_delivery';

  GET DIAGNOSTICS v_count = ROW_COUNT;

  IF v_count = 0 THEN
    RAISE EXCEPTION 'ID de commande invalide ou commande pas encore en livraison';
  END IF;

  RETURN jsonb_build_object('delivered_lines', v_count, 'status', 'delivered');
END;
$$;
