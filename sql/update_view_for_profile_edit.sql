-- Edit Profile ve diğer ekranlarda eksik kalan tüm alanların (badge_emoji vb.) 
-- Supabase view üzerinden çekilebilmesi için görünümü güncelliyoruz.

DROP VIEW IF EXISTS user_social_profiles_view;

CREATE OR REPLACE VIEW user_social_profiles_view WITH (security_invoker = true) AS
SELECT 
    u.id,
    u.username,
    u.display_name,
    u.avatar_url,
    u.bio,
    u.badge_emoji,
    u.diary_visibility,
    u.is_admin,
    u.is_verified,
    u.is_banned,
    u.muted_until,
    u.mute_reason,
    u.is_shadowbanned,
    (SELECT COUNT(*) FROM public.follows f WHERE f.following_id = u.id) as followers_count,
    (SELECT COUNT(*) FROM public.follows f WHERE f.follower_id = u.id) as following_count,
    (SELECT COUNT(*) FROM public.posts p WHERE p.user_id = u.id) as posts_count
FROM public.users u;
