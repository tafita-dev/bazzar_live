-- Ajout d'une politique RLS pour permettre aux vendeurs de lire les réservations contenant leurs produits.
-- Cette commande doit être exécutée dans l'éditeur SQL de votre Dashboard Supabase.

CREATE POLICY "Vendeurs peuvent voir les réservations de leurs produits" ON public.reservations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.products
      WHERE products.seller_id = auth.uid()
      AND products.id IN (
        SELECT (product->>'id')::uuid
        FROM jsonb_array_elements(reservations.products) AS product
      )
    )
  );
