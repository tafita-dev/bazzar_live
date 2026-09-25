-- Migration: add order_group_id to reservations
-- Date: 2026-08-14
-- IMPORTANT: Back up the database before running this migration.
-- Run in a transaction. If you have a migration system, adapt the filename/metadata to it.

BEGIN;

-- 1) Add the column as nullable so existing rows are not blocked
ALTER TABLE reservations
  ADD COLUMN order_group_id UUID;

-- 2) Add an index for queries that will filter/join on this column
CREATE INDEX IF NOT EXISTS idx_reservations_order_group_id ON reservations(order_group_id);

-- 3) (Optional) Add a foreign key constraint referencing order_groups.id
-- Uncomment the following line if an order_groups table exists and you want referential integrity.
-- ALTER TABLE reservations
--   ADD CONSTRAINT fk_reservations_order_group_id FOREIGN KEY (order_group_id)
--     REFERENCES order_groups(id) ON DELETE SET NULL;

COMMIT;

-- Backfill example (run only if you have a deterministic way to map existing reservations to order_groups):
-- UPDATE reservations r
-- SET order_group_id = og.id
-- FROM order_groups og
-- WHERE <your join condition here>;

-- If you want the column to be NOT NULL after backfilling, do:
-- ALTER TABLE reservations ALTER COLUMN order_group_id SET NOT NULL;

-- Notes:
-- - Do not set NOT NULL until all existing rows have been backfilled or a safe default is provided.
-- - If your application (or PostgREST) expects a different column name (camelCase vs snake_case), ensure requests use snake_case: order_group_id.
-- - After applying this migration, re-run the failing operation to confirm the PostgREST error is resolved.
