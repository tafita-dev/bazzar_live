DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'profiles'
      AND policyname = 'Clients peuvent lire les profils vendeurs'
  ) THEN
    CREATE POLICY "Clients peuvent lire les profils vendeurs" ON public.profiles
      FOR SELECT USING (role = 'vendeur');
  END IF;
END $$;
