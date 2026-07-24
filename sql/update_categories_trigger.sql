-- Categories tablosuna gerekli kolonları ekleyelim
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS item_count INTEGER DEFAULT 0;
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW());
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS is_private BOOLEAN DEFAULT false;
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- Trigger için fonksiyon
CREATE OR REPLACE FUNCTION update_category_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE public.categories 
        SET item_count = item_count + 1, updated_at = NOW()
        WHERE id = NEW.category_id;
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE public.categories 
        SET item_count = GREATEST(item_count - 1, 0), updated_at = NOW()
        WHERE id = OLD.category_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Varsa eski trigger'ı silelim
DROP TRIGGER IF EXISTS trigger_update_category_stats ON public.items;

-- Yeni trigger'ı oluşturalım
CREATE TRIGGER trigger_update_category_stats
AFTER INSERT OR DELETE ON public.items
FOR EACH ROW EXECUTE FUNCTION update_category_stats();

-- Mevcut item'lar için item_count ve updated_at değerlerini güncelleyelim
UPDATE public.categories c
SET 
  item_count = (SELECT COUNT(*) FROM public.items i WHERE i.category_id = c.id),
  updated_at = COALESCE((SELECT MAX(created_at) FROM public.items i WHERE i.category_id = c.id), c.created_at);
