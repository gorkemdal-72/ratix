-- Ratix Social Media Features SQL Schema

-- 1. Users Tablosunun Güncellenmesi
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS username TEXT UNIQUE;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS bio TEXT;

-- Username aramalarını hızlandırmak için index
CREATE INDEX IF NOT EXISTS users_username_idx ON public.users (username);

-- Profil görüntüleme sosyal medya app'i olduğu için herkes açık olmalı
DROP POLICY IF EXISTS "Kullanıcılar kendi profilini görebilir" ON public.users;
CREATE POLICY "Kullanıcı profilleri herkes tarafından görülebilir" ON public.users FOR SELECT USING (true);


-- 2. Items (Öğeler) Tablosunun Güncellenmesi (Sosyal paylaşımlarda başkalarının görebilmesi için)
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT true;

DROP POLICY IF EXISTS "Ögeleri sahibi görebilir" ON public.items;
CREATE POLICY "Herkes herkese açık öğeleri görebilir" ON public.items FOR SELECT USING (is_public = true OR auth.uid() = user_id);


-- 3. Follows (Takip) Tablosu
CREATE TABLE IF NOT EXISTS public.follows (
    follower_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    following_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    PRIMARY KEY (follower_id, following_id)
);
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Herkes takipleri görebilir" ON public.follows FOR SELECT USING (true);
CREATE POLICY "Kullanıcılar kendileri takip edebilir" ON public.follows FOR INSERT WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "Kullanıcılar takibi bırakabilir" ON public.follows FOR DELETE USING (auth.uid() = follower_id);


-- 4. Blocks (Engelleme) Tablosu
CREATE TABLE IF NOT EXISTS public.blocks (
    blocker_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    blocked_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    PRIMARY KEY (blocker_id, blocked_id)
);
ALTER TABLE public.blocks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Kullanıcı kendi engellediklerini görebilir" ON public.blocks FOR SELECT USING (auth.uid() = blocker_id);
CREATE POLICY "Kullanıcı birini engelleyebilir" ON public.blocks FOR INSERT WITH CHECK (auth.uid() = blocker_id);
CREATE POLICY "Kullanıcı engeli kaldırabilir" ON public.blocks FOR DELETE USING (auth.uid() = blocker_id);


-- 5. Posts (Paylaşımlar) Tablosu
CREATE TABLE IF NOT EXISTS public.posts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    item_id UUID REFERENCES public.items(id) ON DELETE SET NULL, -- Eğer post bir listeleme/puanlama içeriyorsa
    content TEXT,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Herkes (engellenmeyen) gönderileri görebilir" ON public.posts FOR SELECT USING (
    NOT EXISTS (
        SELECT 1 FROM public.blocks 
        WHERE (blocker_id = public.posts.user_id AND blocked_id = auth.uid())
           OR (blocker_id = auth.uid() AND blocked_id = public.posts.user_id)
    )
);
CREATE POLICY "Kullanıcılar kendi gönderilerini oluşturabilir" ON public.posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Kullanıcılar kendi gönderilerini silebilir" ON public.posts FOR DELETE USING (auth.uid() = user_id);


-- 6. Post Likes (Gönderi Beğenileri) Tablosu
CREATE TABLE IF NOT EXISTS public.post_likes (
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    PRIMARY KEY (user_id, post_id)
);
ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Herkes gönderi beğenilerini görebilir" ON public.post_likes FOR SELECT USING (true);
CREATE POLICY "Kullanıcı kendi beğenisini oluşturabilir" ON public.post_likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Kullanıcı kendi beğenisini kaldırabilir" ON public.post_likes FOR DELETE USING (auth.uid() = user_id);


-- 7. Comments (Yorumlar) Tablosu
CREATE TABLE IF NOT EXISTS public.comments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    parent_id UUID REFERENCES public.comments(id) ON DELETE CASCADE, -- Null değilse alt yorum (reply)
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Herkes yorumları görebilir" ON public.comments FOR SELECT USING (true);
CREATE POLICY "Kullanıcı yorum ekleyebilir" ON public.comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Kullanıcı kendi yorumunu silebilir" ON public.comments FOR DELETE USING (auth.uid() = user_id);


-- 8. Comment Likes (Yorum Beğenileri) Tablosu
CREATE TABLE IF NOT EXISTS public.comment_likes (
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    PRIMARY KEY (user_id, comment_id)
);
ALTER TABLE public.comment_likes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Herkes yorum beğenilerini görebilir" ON public.comment_likes FOR SELECT USING (true);
CREATE POLICY "Kullanıcı kendi beğenisini oluşturabilir" ON public.comment_likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Kullanıcı kendi beğenisini kaldırabilir" ON public.comment_likes FOR DELETE USING (auth.uid() = user_id);


-- 9. Notifications Tablosu ve Enum Type
CREATE TYPE notification_type AS ENUM ('follow', 'post_like', 'comment_like', 'comment', 'reply');

CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    recipient_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    sender_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    type notification_type NOT NULL,
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Kullanıcılar sadece kendi bildirimlerini görebilir" ON public.notifications FOR SELECT USING (auth.uid() = recipient_id);
CREATE POLICY "Kullanıcılar bildirim gönderebilir" ON public.notifications FOR INSERT WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "Kullanıcı bildirimleri güncelleyebilir" ON public.notifications FOR UPDATE USING (auth.uid() = recipient_id);
CREATE POLICY "Kullanıcı bildirim silebilir" ON public.notifications FOR DELETE USING (auth.uid() = recipient_id);

-- 10. İstatistikleri Hızlı Çekmek İçin View (Güvenlik Uyarısını Önlemek İçin security_invoker = true eklendi)
CREATE OR REPLACE VIEW user_social_profiles_view WITH (security_invoker = true) AS
SELECT 
    u.id,
    u.username,
    u.display_name,
    u.avatar_url,
    u.bio,
    (SELECT COUNT(*) FROM public.follows f WHERE f.following_id = u.id) as followers_count,
    (SELECT COUNT(*) FROM public.follows f WHERE f.follower_id = u.id) as following_count,
    (SELECT COUNT(*) FROM public.posts p WHERE p.user_id = u.id) as posts_count
FROM public.users u;
