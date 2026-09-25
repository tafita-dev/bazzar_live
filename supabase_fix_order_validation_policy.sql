-- ==============================================================
-- CORRECTION DES POLITIQUES RLS ET STATUT DES RÉSERVATIONS
-- A exécuter dans l'éditeur SQL de votre Dashboard Supabase
-- ==============================================================

-- 1. Mise à jour de la contrainte CHECK sur le statut pour s'assurer que 'validated' est bien accepté
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

-- 2. Suppression des anciennes politiques RLS obsolètes ou incorrectes
DROP POLICY IF EXISTS "Vendeurs peuvent voir leurs commandes" ON public.reservations;
DROP POLICY IF EXISTS "Vendeurs peuvent voir les réservations de leurs produits" ON public.reservations;
DROP POLICY IF EXISTS "Vendeurs peuvent valider leurs commandes" ON public.reservations;

-- 3. Création d'une nouvelle politique SELECT pour les vendeurs (basée sur seller_id ou le tableau products)
CREATE POLICY "Vendeurs peuvent voir leurs commandes" ON public.reservations
  FOR SELECT USING (
    seller_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM jsonb_array_elements(products) AS product
      WHERE (product->>'seller_id')::uuid = auth.uid()
    )
  );

-- 4. Création d'une nouvelle politique UPDATE pour les vendeurs (validation et mise à jour de statut)
CREATE POLICY "Vendeurs peuvent valider leurs commandes" ON public.reservations
  FOR UPDATE USING (
    seller_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM jsonb_array_elements(products) AS product
      WHERE (product->>'seller_id')::uuid = auth.uid()
    )
  )
  WITH CHECK (
    seller_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM jsonb_array_elements(products) AS product
      WHERE (product->>'seller_id')::uuid = auth.uid()
    )
  );
