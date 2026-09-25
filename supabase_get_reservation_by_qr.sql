-- Fonction pour récupérer les détails d'une réservation via son QR code
CREATE OR REPLACE FUNCTION public.get_reservation_by_qr(
  p_qr_token TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_reservation RECORD;
BEGIN
  SELECT * INTO v_reservation
  FROM public.reservations
  WHERE qr_token = p_qr_token;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'QR code invalide ou réservation non trouvée';
  END IF;

  RETURN to_jsonb(v_reservation);
END;
$$;
