-- ============================================================
-- Firebase'den Supabase'e Manuel Veri Taşıma Rehberi
-- ============================================================
-- Bu dosyayı okuyarak adımları takip et.
--
-- ADIM 1: Firebase Console'dan veriyi dışa aktar
--   - Firebase Console → Firestore Database
--   - Sağ üst menü → "Export" (JSON formatında)
--   - Ya da Firebase Admin SDK ile dışa aktarabilirsin
--
-- ADIM 2: Aşağıdaki SQL şablonunu doldurarak çalıştır
--   - Her kullanıcı için user_id değerini Supabase'deki ID ile değiştir
--   - Supabase Dashboard → Authentication → Users → kullanıcının UUID'si

-- ============================================================
-- KATEGORİ EKLEME (Firebase'den taşı)
-- ============================================================
-- Örnek: Her satırı kendi Firebase verine göre doldur

INSERT INTO public.categories (id, user_id, name, icon, color_value, category_type, rating_type, created_at)
VALUES
  -- (gen_random_uuid(), 'SUPABASE_USER_UUID_BURAYA', 'Filmler', '🎬', 0, 'movie', 'stars5', NOW()),
  -- (gen_random_uuid(), 'SUPABASE_USER_UUID_BURAYA', 'Diziler', '📺', 0, 'tvShow', 'stars5', NOW()),
  -- (gen_random_uuid(), 'SUPABASE_USER_UUID_BURAYA', 'Kitaplar', '📚', 0, 'book', 'stars5', NOW()),
  -- Daha fazla kategori eklemek için yukarıdaki satırları kopyala
  (gen_random_uuid(), 'SUPABASE_USER_UUID_BURAYA', 'Örnek Kategori', '⭐', 0, 'custom', 'stars5', NOW());

-- ============================================================
-- ÖGE EKLEME (Film, Kitap vb. - Firebase'den taşı)
-- ============================================================
-- NOT: category_id değeri yukarıda oluşturduğun kategorinin ID'si olmalı
-- Kategori ID'lerini şöyle bulabilirsin:
--   SELECT id, name FROM public.categories WHERE user_id = 'SUPABASE_USER_UUID';

INSERT INTO public.items (id, category_id, user_id, title, rating, created_at, watch_status, is_favorite)
VALUES
  -- (gen_random_uuid(), 'KATEGORİ_UUID', 'KULLANICI_UUID', 'Film Adı', 4.5, NOW(), 'watched', false),
  (gen_random_uuid(), (SELECT id FROM public.categories WHERE name = 'Örnek Kategori' LIMIT 1), 'SUPABASE_USER_UUID_BURAYA', 'Test Öge', 3.5, NOW(), 'watched', false);

-- ============================================================
-- KULLANICI UUID'NİZİ BULMAK İÇİN:
-- ============================================================
SELECT id, email FROM auth.users;
