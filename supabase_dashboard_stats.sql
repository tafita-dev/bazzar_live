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

-- 4. Fonction pour agréger les statistiques du dashboard vendeur
CREATE OR REPLACE FUNCTION public.get_seller_dashboard_stats(p_seller_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_stats JSONB;
BEGIN
  -- Calcul des métriques agrégées
  SELECT jsonb_build_object(
    'total_orders', COUNT(DISTINCT r.id),
    'pending_orders', COUNT(DISTINCT r.id) FILTER (WHERE r.status = 'pending'),
    'validated_orders', COUNT(DISTINCT r.id) FILTER (WHERE r.status = 'validated'),
    'in_delivery_orders', COUNT(DISTINCT r.id) FILTER (WHERE r.status = 'in_delivery'),
    'delivered_orders', COUNT(DISTINCT r.id) FILTER (WHERE r.status = 'delivered'),
    'category_count', (SELECT COUNT(DISTINCT c.id) FROM public.categories c WHERE c.seller_id = p_seller_id),
    'total_revenue', COALESCE(SUM(r.total_amount) FILTER (WHERE r.status = 'delivered'), 0),
    'deliverer_count', (SELECT COUNT(*) FROM public.profiles WHERE added_by = p_seller_id AND role = 'livreur'),
    'total_views', (SELECT COALESCE(SUM(pv.view_count), 0) 
                    FROM public.product_views pv 
                    JOIN public.products p ON p.id = pv.product_id 
                    WHERE p.seller_id = p_seller_id),
    'daily_sales', (
      SELECT jsonb_agg(daily_data)
      FROM (
        SELECT 
          d.day::text as date,
          COALESCE(SUM(r_sub.total_amount) FILTER (WHERE r_sub.status = 'delivered'), 0) as revenue
        FROM generate_series(CURRENT_DATE - INTERVAL '6 days', CURRENT_DATE, '1 day'::interval) d(day)
        LEFT JOIN public.reservations r_sub ON r_sub.created_at::DATE = d.day AND r_sub.seller_id = p_seller_id
        GROUP BY d.day
        ORDER BY d.day ASC
      ) daily_data
    )
  ) INTO v_stats
  FROM public.reservations r
  WHERE r.seller_id = p_seller_id;

  RETURN v_stats;
END;
$$;
