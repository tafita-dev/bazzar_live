CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Table categories
CREATE TABLE public.categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  seller_id UUID REFERENCES public.profiles(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS (Row Level Security)
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Vendeurs peuvent tout faire sur leurs catégories" ON public.categories
  FOR ALL USING (auth.uid() = seller_id);
CREATE POLICY "Clients peuvent lire les catégories" ON public.categories
  FOR SELECT USING (true);
