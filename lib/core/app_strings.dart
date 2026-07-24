class AppStrings {
  AppStrings._();

  // App
  static const String appName    = 'Ratix';
  static const String appTagline = 'Her şeyin listesi. Puanla, takip et!';

  // Auth
  static const String login          = 'Giriş Yap';
  static const String register       = 'Kayıt Ol';
  static const String logout         = 'Çıkış Yap';
  static const String logoutConfirm  = 'Hesabından çıkmak istediğine emin misin?';
  static const String email          = 'E-posta';
  static const String password       = 'Şifre';
  static const String fullName       = 'Ad Soyad';
  static const String nameSurname    = 'İsim Soyisim';
  static const String forgotPassword = 'Şifreni mi unuttun?';
  static const String noAccount      = 'Hesabın yok mu? Kayıt ol';
  static const String hasAccount     = 'Zaten hesabın var mı? Giriş yap';
  static const String resetPassword  = 'Şifreyi Sıfırla';
  static const String resetSent      = 'Şifre sıfırlama e-postası gönderildi.';
  static const String guestUser      = 'Misafir';

  // Home
  static const String homeTitle         = 'Listelerim';
  static const String myCategories      = 'Listelerim';
  static const String addCategory       = 'Yeni Liste';
  static const String newCategory       = 'Yeni Liste';
  static const String createCategory    = 'Liste Oluştur';
  static const String editCategory      = 'Listeyi Düzenle';
  static const String categoryName      = 'Liste Adı';
  static const String categoryIcon      = 'İkon Seç';
  static const String categoryType      = 'Tür';
  static const String updateCategory    = 'Güncelle';
  static const String deleteCategory    = 'Listeyi Sil';
  static const String deleteCatMsg      = 'Bu liste ve içindeki tüm öğeler silinecek. Emin misin?';
  static const String deleteCategoryMsg = 'Bu liste ve içindeki tüm öğeler silinecek. Emin misin?';
  static const String emptyHome         = 'Henüz liste yok.\n+ butonuyla ekleyebilirsin!';
  static const String emptyCategories   = 'Henüz liste yok.\n+ butonuyla ilk listeni oluştur!';
  static const String searchCategory    = 'Liste ara...';
  static const String noSearchResult    = 'Sonuç bulunamadı.';
  static const String edit              = 'Düzenle';

  // Sort (Home - Kategori sıralaması)
  static const String sort         = 'Sırala';
  static const String sortDefault  = 'Varsayılan';
  static const String sortNameDesc = 'Z → A';

  // Sort (Detail - Öge sıralaması)
  static const String sortLabel      = 'Sırala';
  static const String sortNewest     = 'En Yeni';
  static const String sortRatingHigh = 'Puan (Yüksek → Düşük)';
  static const String sortRatingLow  = 'Puan (Düşük → Yüksek)';
  static const String sortNameAsc    = 'A → Z';

  // Detail
  static const String addItem       = 'Ekle';
  static const String itemTitle     = 'Başlık';
  static const String saveItem      = 'Kaydet';
  static const String editItem      = 'Düzenle';
  static const String updateItem    = 'Güncelle';
  static const String emptyList     = 'Bu liste boş. + ile ekle!';
  static const String noResult      = 'Sonuç bulunamadı.';
  static const String favoritesOnly = 'Sadece Favoriler';

  // Rating Types
  static const String stars5  = '5 Yıldız';
  static const String score10 = '1-10 Puan';

  // Status
  static const String statusWatched   = 'İzlendi';
  static const String statusWatching  = 'İzleniyor';
  static const String statusWatchlist = 'İzlenecek';
  static const String statusAll       = 'Tümü';
  static const String changeStatus    = 'Durum';

  // Search & API
  static const String searchHint       = 'Ara...';
  static const String searchResults    = 'Sonuçlar';
  static const String searching        = 'Aranıyor...';
  static const String noApiResult      = 'Sonuç bulunamadı. Manuel eklemek ister misin?';
  static const String addManually      = 'Manuel Ekle';
  static const String tapToAdd         = 'Eklemek için seç';
  static const String apiNotConfigured = 'API key tanımlı değil. Arama için key gerekiyor.';

  // Delete / Common
  static const String deleteConfirm = 'Sil?';
  static const String deleteItemMsg = 'Bu öğe kalıcı olarak silinecek.';
  static const String delete        = 'Sil';
  static const String cancel        = 'İptal';

  // Profile
  static const String profileTitle = 'Profil';
  static const String uid          = 'Kullanıcı ID';
  static const String about        = 'Hakkımda (Opsiyonel)';
  static const String save         = 'Kaydet';
  static const String profileMotto = 'Ratix — Her şeyin listesi.';
  static const String aboutApp     = 'Ratix v4.0.1\nFilmlerini, dizilerini, kitaplarını,\noyunlarını ve çok daha fazlasını takip edip puanla.';
  static const String aboutSection = 'Hakkında';

  // Settings
  static const String settingsTitle     = 'Ayarlar';
  static const String themeLabel        = 'Tema';
  static const String darkMode          = 'Karanlık Mod';
  static const String defaultRatingType = 'Varsayılan Puanlama';
  static const String profileInfo       = 'Profil Bilgileri';
  static const String general           = 'Genel';
  static const String profileSaved      = 'Profil kaydedildi ✓';

  // Category Type Label
  static const String categoryTypeLabel = 'Kategori Türü';
  static const String categoryTypeHint  = 'Ne tür bir liste?';

  // Errors / Success
  static const String errorUpload   = 'Yükleme başarısız';
  static const String errorGeneric  = 'Bir hata oluştu';
  static const String photoUpdated  = 'Profil fotoğrafı güncellendi ✓';
  static const String ratingSuccess = 'Puanlandı ✓';

  // Image Picker
  static const String pickSource = 'Kaynak Seç';
  static const String gallery    = 'Galeri';
  static const String camera     = 'Kamera';
}
