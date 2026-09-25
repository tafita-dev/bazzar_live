-- Création de la table profiles
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL PRIMARY KEY,
  email TEXT,
  role TEXT DEFAULT 'client' CHECK (role IN ('admin', 'vendeur', 'client', 'livreur')),
  full_name TEXT,
  avatar_url TEXT,
  phone TEXT,
  address TEXT,
  shop_name TEXT,
  shop_description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Trigger pour créer automatiquement un profil à l'inscription
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name',
    COALESCE(NULLIF(new.raw_user_meta_data->>'role', ''), 'client')
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Utilisateurs peuvent creer leur profil" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Utilisateurs peuvent lire leur profil" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Clients peuvent lire les profils vendeurs" ON public.profiles
  FOR SELECT USING (role = 'vendeur');

CREATE POLICY "Utilisateurs peuvent modifier leur profil" ON public.profiles
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);
