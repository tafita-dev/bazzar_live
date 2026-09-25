-- 1. Table pour les vues des produits
CREATE TABLE IF NOT EXISTS public.product_views (
  product_id UUID REFERENCES public.products(id) ON DELETE CASCADE PRIMARY KEY,
  view_count BIGINT DEFAULT 0
);

-- 2. Fonction pour créer une vue initiale (initialisation)
CREATE OR REPLACE FUNCTION public.create_product_view(p_product_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.product_views (product_id, view_count)
  VALUES (p_product_id, 0)
  ON CONFLICT (product_id) DO NOTHING;
END;
$$;

-- 3. Fonction pour incrémenter les vues
CREATE OR REPLACE FUNCTION public.increment_product_view(p_product_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.product_views (product_id, view_count)
  VALUES (p_product_id, 1)
  ON CONFLICT (product_id) 
  DO UPDATE SET view_count = public.product_views.view_count + 1;
END;
$$;
