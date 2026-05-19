class AppStrings {
  AppStrings._();

  // Genel
  static const String appName = "Ratix";
  static const String appTagline = "Her şeyi puanla, takibini yap.";
  static const String ok = "Tamam";
  static const String cancel = "İptal";
  static const String error = "Hata";
  static const String success = "Başarılı";
  static const String loading = "Yükleniyor...";

  // Auth
  static const String login = "Giriş Yap";
  static const String register = "Hesap Oluştur";
  static const String email = "E-posta";
  static const String password = "Şifre";
  static const String noAccount = "Hesabın yok mu? Kayıt Ol";
  static const String hasAccount = "Zaten hesabın var mı? Giriş Yap";

  // Profil & Ayarlar
  static const String profileTitle = "Profilim";
  static const String settingsTitle = "Ayarlar";
  static const String profileInfo = "Profil Bilgileri";
  static const String nameSurname = "İsim Soyisim";
  static const String about = "Hakkımda (Opsiyonel)";
  static const String save = "Kaydet";
  static const String profileSaved = "Profil kaydedildi ✓";
  static const String photoUpdated = "Fotoğraf güncellendi ✓";
  static const String logout = "Çıkış Yap";
  static const String logoutConfirm = "Çıkış yapmak istediğine emin misin?";
  
  // Resim Seçimi
  static const String gallery = "Galeriden Seç";
  static const String camera = "Kamera ile Çek";
  static const String pickSource = "Fotoğraf Ekle";
  
  // Hatalar
  static const String errorGeneric = "Bir hata oluştu.";
  static const String errorPickImage = "Resim seçilemedi.";
  static const String errorUpload = "Yükleme sırasında hata oluştu.";
  static const String guestUser = "Misafir";
  static const String uid = "Kullanıcı ID";
  static const String general = "Genel";
  static const String darkMode = "Karanlık Mod";

  // Home
  static const String myCategories = "Listelerim";
  static const String searchCategory = "Liste ara...";
  static const String emptyCategories = "Henüz liste oluşturmadın.\nİlkini eklemek için + butonuna bas.";
  static const String noSearchResult = "Sonuç bulunamadı.";
  static const String newCategory = "Yeni Liste";
  static const String categoryName = "Liste Adı";
  static const String createCategory = "Oluştur";
  static const String editCategory = "Listeyi Düzenle";
  static const String updateCategory = "Güncelle";
  static const String deleteConfirm = "Emin misin?";
  static const String deleteCategoryMsg = "Bu listeyi ve içindeki tüm öğeleri silmek üzeresin.";
  static const String deleteItemMsg = "Bu öğeyi silmek istediğine emin misin?";
  static const String delete = "Sil";
  static const String edit = "Düzenle";

  // Sıralama
  static const String sort = "Sırala";
  static const String sortDefault = "Varsayılan (En Yeni)";
  static const String sortNameAsc = "İsim (A-Z)";
  static const String sortNameDesc = "İsim (Z-A)";
  static const String sortNewest = "En Yeni";
  static const String sortRatingHigh = "Puan (Yüksek → Düşük)";
  static const String sortRatingLow = "Puan (Düşük → Yüksek)";

  // Detail
  static const String addItem = "Ekle";
  static const String itemTitle = "Başlık";
  static const String saveItem = "Kaydet";
  static const String editItem = "Düzenle";
  static const String updateItem = "Güncelle";
  static const String emptyList = "Bu liste boş. + ile ekle!";
  static const String noResult = "Sonuç bulunamadı.";
  static const String favoritesOnly = "Sadece Favoriler";

  // Puanlama Tipi İsimleri
  static const String stars5 = "5 Yıldız";
  static const String score10 = "1-10 Puan";

  // Mesajlar
  static const String ratingSuccess = "Puanlandı ✓";
  static const String profileMotto = "Ratix — Her şeyin listesi.";
  static const String aboutApp = "Ratix v1.2.0\nFilm, kitap, dizi ve daha fazlasını puanla.";
  static const String aboutSection = "Hakkında";

  // Arama & API
  static const String searchHint = "Ara...";
  static const String searchResults = "Sonuçlar";
  static const String searching = "Aranıyor...";
  static const String noApiResult = "Sonuç bulunamadı. Manuel eklemek ister misin?";
  static const String addManually = "Manuel Ekle";
  static const String tapToAdd = "Eklemek için seç";
  static const String apiNotConfigured = "API key tanımlı değil. Arama için key gerekiyor.";

  // Status (İzleme Durumu)
  static const String statusWatched   = "İzlendi";
  static const String statusWatching  = "İzleniyor";
  static const String statusWatchlist = "İzlenecek";
  static const String statusAll       = "Tümü";
  static const String changeStatus    = "Durumu Değiştir";

  // Kategori Tipi
  static const String categoryTypeLabel = "Kategori Türü";
  static const String categoryTypeHint  = "Ne tür bir liste?";
}
