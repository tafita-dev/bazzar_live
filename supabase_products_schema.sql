-- Séquence pour les codes JP
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SEQUENCE product_code_seq START 1001;

-- Table products
CREATE TABLE public.products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  code_jp TEXT UNIQUE DEFAULT 'JP-' || nextval('product_code_seq')::text,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10, 2) NOT NULL,
  stock INT DEFAULT 0,
  seller_id UUID REFERENCES public.profiles(id) NOT NULL,
  category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS (Row Level Security) - basique pour démarrer
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Vendeurs peuvent tout faire sur leurs produits" ON public.products
  FOR ALL USING (auth.uid() = seller_id);
CREATE POLICY "Clients peuvent lire les produits" ON public.products
  FOR SELECT USING (true);
