-- 1. App Settings Table for Force Update and general settings
CREATE TABLE IF NOT EXISTS public.app_settings (
  id text PRIMARY KEY,
  latest_version text,
  force_update_version text,
  update_url_android text,
  update_url_ios text,
  update_message text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Insert default settings
INSERT INTO public.app_settings (id, latest_version, force_update_version, update_url_android, update_url_ios, update_message)
VALUES ('default', '1.0.0', '1.0.0', 'https://play.google.com/store/apps/details?id=com.zodleenar.ratix', 'https://apps.apple.com/app/id123456789', 'Uygulamanın yeni bir sürümü var. Lütfen güncelleyin.')
ON CONFLICT (id) DO NOTHING;

-- Policies for app_settings
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public Read Settings" ON public.app_settings FOR SELECT USING (true);
CREATE POLICY "Admin All Settings" ON public.app_settings FOR ALL USING (
  EXISTS (SELECT 1 FROM public.users WHERE users.id = auth.uid() AND users.is_admin = true)
);

-- 2. Custom Badge for Users
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS badge_emoji text;

-- Allow users to update their own badge_emoji
-- (Assuming the existing policy "Users can update their own profile" covers all columns. 
-- If it's restrictive, we might need a specific policy, but Supabase standard UPDATE policy usually applies to all columns).
