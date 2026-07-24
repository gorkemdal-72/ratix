-- ═══════════════════════════════════════════════════════════════
-- RATIX ADMIN & MODERASYON SİSTEMİ — Phase 1 SQL
-- Bu SQL'i Supabase Dashboard → SQL Editor'a yapıştırıp çalıştır.
-- ═══════════════════════════════════════════════════════════════

-- ─── 1. USERS TABLOSU GÜNCELLEMELERİ ───
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT false;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_banned BOOLEAN DEFAULT false;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS ban_reason TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS muted_until TIMESTAMPTZ;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS mute_reason TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_shadowbanned BOOLEAN DEFAULT false;


-- ─── 2. WARNINGS (UYARILAR) TABLOSU ───
CREATE TABLE IF NOT EXISTS public.warnings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    admin_id UUID REFERENCES public.users(id) ON DELETE SET NULL NOT NULL,
    reason TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW())
);

ALTER TABLE public.warnings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "warnings_select" ON public.warnings;
CREATE POLICY "warnings_select" ON public.warnings FOR SELECT USING (
  user_id = auth.uid()
  OR EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = true)
  OR (SELECT username FROM public.users WHERE id = auth.uid()) = 'zodleenar'
);
DROP POLICY IF EXISTS "warnings_insert" ON public.warnings;
CREATE POLICY "warnings_insert" ON public.warnings FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = true)
  OR (SELECT username FROM public.users WHERE id = auth.uid()) = 'zodleenar'
);


-- ─── 3. REPORTS (ŞİKAYETLER) TABLOSU ───
CREATE TABLE IF NOT EXISTS public.reports (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    reporter_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    reported_user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    details TEXT,
    status TEXT DEFAULT 'pending',
    resolved_by UUID REFERENCES public.users(id),
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW())
);

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "reports_select" ON public.reports;
CREATE POLICY "reports_select" ON public.reports FOR SELECT USING (
  reporter_id = auth.uid()
  OR EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = true)
  OR (SELECT username FROM public.users WHERE id = auth.uid()) = 'zodleenar'
);

DROP POLICY IF EXISTS "reports_insert" ON public.reports;
CREATE POLICY "reports_insert" ON public.reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);

DROP POLICY IF EXISTS "reports_update" ON public.reports;
CREATE POLICY "reports_update" ON public.reports FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = true)
  OR (SELECT username FROM public.users WHERE id = auth.uid()) = 'zodleenar'
);


-- ─── 4. NOTIFICATION TYPE GÜNCELLEMESİ ───
-- Mevcut enum'a yeni değerler eklenir
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'warning';
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'admin_grant';
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'admin_revoke';
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'system';
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'mute';
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'ban';
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'report_resolved';
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'report_dismissed';


-- ─── 5. YORUM SİLME POLİTİKASI GÜNCELLEMESİ ───
DROP POLICY IF EXISTS "Kullanıcı kendi yorumunu silebilir" ON public.comments;
DROP POLICY IF EXISTS "Kullanıcı veya admin yorum silebilir" ON public.comments;
CREATE POLICY "Kullanıcı veya admin yorum silebilir" ON public.comments FOR DELETE USING (
  auth.uid() = user_id
  OR EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = true)
  OR (SELECT username FROM public.users WHERE id = auth.uid()) = 'zodleenar'
);


-- ─── 6. GÖNDERİ SİLME POLİTİKASI GÜNCELLEMESİ ───
DROP POLICY IF EXISTS "Kullanıcılar kendi gönderilerini silebilir" ON public.posts;
DROP POLICY IF EXISTS "Kullanıcı veya admin gönderi silebilir" ON public.posts;
CREATE POLICY "Kullanıcı veya admin gönderi silebilir" ON public.posts FOR DELETE USING (
  auth.uid() = user_id
  OR EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = true)
  OR (SELECT username FROM public.users WHERE id = auth.uid()) = 'zodleenar'
);


-- ─── 7. USERS UPDATE POLİTİKASI ───
DROP POLICY IF EXISTS "Kullanıcılar kendi profilini düzenleyebilir" ON public.users;
DROP POLICY IF EXISTS "Kullanıcı veya admin güncelleme" ON public.users;
CREATE POLICY "Kullanıcı veya admin güncelleme" ON public.users FOR UPDATE USING (
  auth.uid() = id
  OR EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = true)
  OR (SELECT username FROM public.users WHERE id = auth.uid()) = 'zodleenar'
);


-- ─── 8. VIEW GÜNCELLEMESİ ───
-- View yapısı (kolon sırası) değiştiği için önce eskisini siliyoruz.
DROP VIEW IF EXISTS public.user_social_profiles_view;

CREATE VIEW public.user_social_profiles_view WITH (security_invoker = true) AS
SELECT
    u.id,
    u.username,
    u.display_name,
    u.avatar_url,
    u.bio,
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


-- ═══════════════════════════════════════════════════════════════
-- BİTTİ! Şimdi zodleenar'ı super admin yap:
-- (zodleenar'ın username'i zaten 'zodleenar' olmalı)
-- ═══════════════════════════════════════════════════════════════
UPDATE public.users SET is_admin = true WHERE username = 'zodleenar';
