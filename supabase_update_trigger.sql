-- Mettre a jour le trigger pour creer le profil depuis les metadata d'inscription.
-- Le role et le nom viennent de auth.signUp(data: ...).
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

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Utilisateurs peuvent creer leur profil" ON public.profiles;
CREATE POLICY "Utilisateurs peuvent creer leur profil" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Utilisateurs peuvent lire leur profil" ON public.profiles;
CREATE POLICY "Utilisateurs peuvent lire leur profil" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Utilisateurs peuvent modifier leur profil" ON public.profiles;
CREATE POLICY "Utilisateurs peuvent modifier leur profil" ON public.profiles
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);
