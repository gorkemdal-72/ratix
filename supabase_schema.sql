-- Supabase SQL Editor'da bu kodları kopyalayıp çalıştır. (Run)

-- 1. Kullanıcılar (Users) Tablosu (Opsiyonel ama auth.users ile eşleşmek için iyidir)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT,
  display_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  preferences JSONB
);

-- 2. Kategoriler (Categories) Tablosu
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  name TEXT NOT NULL,
  icon TEXT NOT NULL,
  color_value INTEGER NOT NULL,
  category_type TEXT NOT NULL,
  rating_type TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  parent_id UUID REFERENCES public.categories(id) ON DELETE CASCADE,
  custom_status_1 TEXT,
  custom_status_2 TEXT,
  custom_status_3 TEXT
);

-- Alt kategoriler ve Özel durum etiketleri için ALTER komutları:
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS parent_id UUID REFERENCES public.categories(id) ON DELETE CASCADE;
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS custom_status_1 TEXT;
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS custom_status_2 TEXT;
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS custom_status_3 TEXT;

-- 3. Ögeler (Items - Filmler, Kitaplar vb.) Tablosu
CREATE TABLE IF NOT EXISTS public.items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  category_id UUID REFERENCES public.categories(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  title TEXT NOT NULL,
  rating DOUBLE PRECISION NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  poster_url TEXT,
  year INTEGER,
  watch_status TEXT,
  external_id TEXT,
  media_type TEXT,
  genres TEXT,
  author TEXT,
  overview TEXT,
  is_favorite BOOLEAN DEFAULT false,
  seasons_data JSONB
);

-- 4. Güvenlik Politikaları (RLS - Row Level Security) - Sadece herkes kendi verisini görsün
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kullanıcılar kendi profilini görebilir" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Kullanıcılar kendi profilini düzenleyebilir" ON public.users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Kullanıcılar kendi profilini oluşturabilir" ON public.users FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Kategorileri sahibi görebilir" ON public.categories FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Kategorileri sahibi ekleyebilir" ON public.categories FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Kategorileri sahibi düzenleyebilir" ON public.categories FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Kategorileri sahibi silebilir" ON public.categories FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Ögeleri sahibi görebilir" ON public.items FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Ögeleri sahibi ekleyebilir" ON public.items FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Ögeleri sahibi düzenleyebilir" ON public.items FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Ögeleri sahibi silebilir" ON public.items FOR DELETE USING (auth.uid() = user_id);
