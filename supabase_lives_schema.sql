CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Table lives
CREATE TABLE public.lives (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  facebook_url TEXT NOT NULL,
  seller_id UUID REFERENCES public.profiles(id) NOT NULL,
  shop_name TEXT,
  is_active BOOLEAN DEFAULT false,
  started_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.lives
ADD COLUMN IF NOT EXISTS description TEXT DEFAULT '';

-- RLS
ALTER TABLE public.lives ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Vendeurs peuvent gérer leurs lives" ON public.lives
  FOR ALL USING (auth.uid() = seller_id);
CREATE POLICY "Clients peuvent lire les lives" ON public.lives
  FOR SELECT USING (true);
