ALTER TABLE public.profiles ADD COLUMN seller_id UUID REFERENCES public.profiles(id);

-- Mise à jour de la politique RLS pour permettre aux vendeurs de voir leurs livreurs
CREATE POLICY "Vendeurs peuvent voir leurs livreurs" ON public.profiles
  FOR SELECT USING (seller_id = auth.uid());
