-- Add fcm_token column to users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS fcm_token text;
