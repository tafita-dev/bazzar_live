-- 1. Suppression des anciens éléments product_views
DROP TABLE IF EXISTS public.product_views;
DROP FUNCTION IF EXISTS public.create_product_view(UUID);
DROP FUNCTION IF EXISTS public.increment_product_view(UUID);

-- 2. Table pour les vues des lives (unique par utilisateur et par live)
CREATE TABLE IF NOT EXISTS public.live_views (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  live_id UUID REFERENCES public.lives(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  viewed_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  UNIQUE(live_id, user_id)
);

-- 3. Fonction pour enregistrer une vue unique par utilisateur
CREATE OR REPLACE FUNCTION public.record_live_view(p_live_id UUID, p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.live_views (live_id, user_id)
  VALUES (p_live_id, p_user_id)
  ON CONFLICT (live_id, user_id) DO NOTHING;
END;
$$;

-- 3. Fonction pour agréger les statistiques du dashboard vendeur
CREATE OR REPLACE FUNCTION public.get_seller_dashboard_stats(p_seller_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_stats JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_orders', COUNT(DISTINCT r.id),
    'pending_orders', COUNT(DISTINCT r.id) FILTER (WHERE r.status = 'pending'),
    'validated_orders', COUNT(DISTINCT r.id) FILTER (WHERE r.status = 'validated'),
    'in_delivery_orders', COUNT(DISTINCT r.id) FILTER (WHERE r.status = 'in_delivery'),
    'delivered_orders', COUNT(DISTINCT r.id) FILTER (WHERE r.status = 'delivered'),
    'category_count', (SELECT COUNT(DISTINCT c.id) FROM public.categories c WHERE c.seller_id = p_seller_id),
    'total_revenue', COALESCE(SUM(r.total_amount) FILTER (WHERE r.status = 'delivered'), 0),
    'deliverer_count', (SELECT COUNT(*) FROM public.profiles WHERE added_by = p_seller_id AND role = 'livreur'),
    'total_views', (
        SELECT 
          (SELECT COUNT(lv.id) FROM public.live_views lv JOIN public.lives l ON l.id = lv.live_id WHERE l.seller_id = p_seller_id) +
          (SELECT COALESCE(SUM(pv.view_count), 0) FROM public.product_views pv JOIN public.products p ON p.id = pv.product_id WHERE p.seller_id = p_seller_id)
    ),
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
$$;
