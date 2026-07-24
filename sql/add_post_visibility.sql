-- Paylaşım hedef kitlesi için visibility sütunu ekleme
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS visibility TEXT DEFAULT 'public';
