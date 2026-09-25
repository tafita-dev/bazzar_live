-- Mise à jour de la fonction create_cod_reservation pour accepter p_seller_id
CREATE OR REPLACE FUNCTION public.create_cod_reservation(
  p_items JSONB,
  p_client_name TEXT,
  p_client_phone TEXT,
  p_delivery_address TEXT,
  p_payment_method_id UUID,
  p_delivery_remark TEXT DEFAULT NULL,
  p_group_info JSONB DEFAULT NULL,
  p_seller_id UUID DEFAULT NULL -- NOUVEAU PARAMÈTRE
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
  v_seller_id UUID := p_seller_id; -- Utilise le paramètre passé
  v_reservation_id UUID;
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
    -- Si pas de vendeur passé, on prend celui du premier produit
    IF v_seller_id IS NULL THEN
        v_seller_id := v_product.seller_id;
    END IF;
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
    order_group_id,
    seller_id -- Enregistrement du vendeur
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
          'prix_unitaire', p.price,
          'seller_id', p.seller_id -- Important pour le filtrage côté Dart
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
    v_order_group_id,
    v_seller_id
  )
  RETURNING id INTO v_reservation_id;

  RETURN jsonb_build_object(
    'reservation_id', v_reservation_id,
    'id', v_reservation_id,
    'order_group_id', v_order_group_id,
    'qr_token', v_qr_token
  );
END;
$$;
