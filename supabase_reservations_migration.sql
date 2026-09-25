-- Migration pour la table public.reservations

-- 1. Ajout des colonnes manquantes (si elles n'existent pas déjà)
ALTER TABLE public.reservations
  ADD COLUMN IF NOT EXISTS order_group_id UUID DEFAULT gen_random_uuid(),
  ADD COLUMN IF NOT EXISTS quantity INT DEFAULT 1 NOT NULL,
  ADD COLUMN IF NOT EXISTS unit_price DECIMAL(10, 2),
  ADD COLUMN IF NOT EXISTS total_amount DECIMAL(10, 2),
  ADD COLUMN IF NOT EXISTS client_name TEXT,
  ADD COLUMN IF NOT EXISTS client_phone TEXT,
  ADD COLUMN IF NOT EXISTS delivery_address TEXT,
  ADD COLUMN IF NOT EXISTS delivery_remark TEXT,
  ADD COLUMN IF NOT EXISTS payment_method_id UUID REFERENCES public.payment_methods(id),
  ADD COLUMN IF NOT EXISTS qr_token TEXT,
  ADD COLUMN IF NOT EXISTS stock_reserved BOOLEAN DEFAULT false NOT NULL,
  ADD COLUMN IF NOT EXISTS validated_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL;

-- 2. Mise à jour des valeurs par défaut
ALTER TABLE public.reservations
  ALTER COLUMN order_group_id SET DEFAULT gen_random_uuid();

-- 3. Mise à jour de la contrainte CHECK pour les statuts
DO $$
DECLARE
  constraint_name TEXT;
BEGIN
  SELECT conname INTO constraint_name
  FROM pg_constraint
  WHERE conrelid = 'public.reservations'::regclass
    AND contype = 'c'
    AND pg_get_constraintdef(oid) LIKE '%status%';

  IF constraint_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.reservations DROP CONSTRAINT %I', constraint_name);
  END IF;
END $$;

ALTER TABLE public.reservations
  ADD CONSTRAINT reservations_status_check
  CHECK (status IN ('pending', 'in_delivery', 'delivered', 'cancelled', 'expired'));

-- 4. Création des index pour la performance
CREATE INDEX IF NOT EXISTS reservations_order_group_id_idx ON public.reservations(order_group_id);
CREATE INDEX IF NOT EXISTS reservations_qr_token_idx ON public.reservations(qr_token);
CREATE INDEX IF NOT EXISTS reservations_status_idx ON public.reservations(status);
