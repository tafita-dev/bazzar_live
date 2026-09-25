-- Ajout de la colonne seller_id pour optimiser le filtrage
ALTER TABLE public.reservations ADD COLUMN seller_id UUID REFERENCES public.profiles(id);

-- Création d'un index pour accélérer les requêtes basées sur le vendeur
CREATE INDEX idx_reservations_seller_id ON public.reservations(seller_id);
