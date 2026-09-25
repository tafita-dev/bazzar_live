-- Mise à jour de la table reservations pour une structure par commande
DROP TABLE IF EXISTS public.reservations;

CREATE TABLE public.reservations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) NOT NULL,
  
  -- Informations client (JSON)
  client_info JSONB NOT NULL, -- {nom, contact, adresse, remarque}
  
  -- Paiement
  payment_method_id TEXT NOT NULL,
  total_amount NUMERIC(10, 2) NOT NULL,
  
  -- Produits (Array de JSON)
  -- Structure: [{nom, image, quantité, prix_unitaire}]
  products JSONB NOT NULL,
  group_name JSONB,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'validated', 'delivered', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
  );

-- RLS
ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Clients peuvent voir leurs réservations" ON public.reservations
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Clients peuvent créer des réservations" ON public.reservations
  FOR INSERT WITH CHECK (auth.uid() = user_id);
