-- ==============================================================================
-- FLUX LIVREUR SUPABASE (RLS + RPC FUNCTIONS)
-- ==============================================================================

-- 1. Politiques RLS pour les livreurs sur la table reservations
DROP POLICY IF EXISTS "Livreurs peuvent voir leurs réservations assignées" ON public.reservations;
CREATE POLICY "Livreurs peuvent voir leurs réservations assignées" ON public.reservations
  FOR SELECT USING (
    deliverer_id = auth.uid()
  );

DROP POLICY IF EXISTS "Livreurs peuvent mettre à jour leurs réservations assignées" ON public.reservations;
CREATE POLICY "Livreurs peuvent mettre à jour leurs réservations assignées" ON public.reservations
  FOR UPDATE USING (
    deliverer_id = auth.uid()
  )
  WITH CHECK (
    deliverer_id = auth.uid()
  );

-- 2. Fonction RPC pour récupérer les détails d'une réservation via QR code ou ID pour un livreur
CREATE OR REPLACE FUNCTION public.get_reservation_for_deliverer(
  p_qr_value TEXT,
  p_deliverer_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_reservation RECORD;
  v_clean_val TEXT := trim(replace(p_qr_value, '#', ''));
BEGIN
  IF v_clean_val IS NULL OR v_clean_val = '' THEN
    RAISE EXCEPTION 'QR Code ou identifiant invalide';
  END IF;

  -- Recherche par ID exact ou qr_token ou order_group_id ou préfixe (8 caractères min)
  SELECT * INTO v_reservation
  FROM public.reservations
  WHERE LOWER(id::TEXT) = LOWER(v_clean_val)
     OR qr_token = v_clean_val
     OR LOWER(order_group_id::TEXT) = LOWER(v_clean_val)
     OR (length(v_clean_val) >= 8 AND LOWER(id::TEXT) LIKE LOWER(v_clean_val) || '%')
     OR (length(v_clean_val) >= 8 AND LOWER(order_group_id::TEXT) LIKE LOWER(v_clean_val) || '%')
  ORDER BY created_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Aucune commande trouvée pour ce QR code / identifiant';
  END IF;

  -- Vérifier si la commande est assignée à un autre livreur
  IF v_reservation.deliverer_id IS NOT NULL 
     AND p_deliverer_id IS NOT NULL 
     AND v_reservation.deliverer_id != p_deliverer_id THEN
    RAISE EXCEPTION 'Cette commande est assignée à un autre livreur';
  END IF;

  RETURN to_jsonb(v_reservation);
END;
$$;

-- 3. Fonction RPC pour marquer une réservation comme livrée
CREATE OR REPLACE FUNCTION public.mark_reservation_delivered_by_deliverer(
  p_reservation_id UUID,
  p_deliverer_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_res RECORD;
BEGIN
  SELECT * INTO v_res
  FROM public.reservations
  WHERE id = p_reservation_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Réservation introuvable';
  END IF;

  IF v_res.deliverer_id IS NOT NULL AND v_res.deliverer_id != p_deliverer_id THEN
    RAISE EXCEPTION 'Cette commande est assignée à un autre livreur';
  END IF;

  IF v_res.status = 'delivered' THEN
    RAISE EXCEPTION 'Cette commande a déjà été marquée comme livrée';
  END IF;

  UPDATE public.reservations
  SET status = 'delivered',
      deliverer_id = p_deliverer_id,
      delivered_at = timezone('utc'::text, now()),
      updated_at = timezone('utc'::text, now())
  WHERE id = p_reservation_id;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Commande livrée avec succès',
    'id', p_reservation_id,
    'status', 'delivered',
    'delivered_at', timezone('utc'::text, now())
  );
END;
$$;
