-- 1. users tablosuna diary_visibility alanı ekleme
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS diary_visibility TEXT DEFAULT 'followers_only';

-- 2. Görünümü (View) güncelleyerek yeni alanı dahil etme
DROP VIEW IF EXISTS user_social_profiles_view;

CREATE OR REPLACE VIEW user_social_profiles_view WITH (security_invoker = true) AS
SELECT 
    u.id,
    u.username,
    u.display_name,
    u.avatar_url,
    u.bio,
    u.diary_visibility,
    (SELECT COUNT(*) FROM public.follows f WHERE f.following_id = u.id) as followers_count,
    (SELECT COUNT(*) FROM public.follows f WHERE f.follower_id = u.id) as following_count,
    (SELECT COUNT(*) FROM public.posts p WHERE p.user_id = u.id) as posts_count
FROM public.users u;
