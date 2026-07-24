-- items tablosuna review kolonu ekler
ALTER TABLE items ADD COLUMN IF NOT EXISTS review TEXT;
