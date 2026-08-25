class AppStrings {
  AppStrings._();

  static String currentLanguage = 'tr';
  static bool get isEn => currentLanguage == 'en';

  // App
  static String get appName => 'Ratix';
  static String get appTagline => isEn
      ? 'List of everything. Rate & follow!'
      : 'Her şeyin listesi. Puanla, takip et!';

  // Auth
  static String get login => isEn ? 'Log In' : 'Giriş Yap';
  static String get register => isEn ? 'Register' : 'Kayıt Ol';
  static String get logout => isEn ? 'Log Out' : 'Çıkış Yap';
  static String get logoutConfirm => isEn
      ? 'Are you sure you want to log out?'
      : 'Hesabından çıkmak istediğine emin misin?';
  static String get email => isEn ? 'Email' : 'E-posta';
  static String get password => isEn ? 'Password' : 'Şifre';
  static String get fullName => isEn ? 'Full Name' : 'Ad Soyad';
  static String get nameSurname => isEn ? 'Full Name' : 'İsim Soyisim';
  static String get forgotPassword => isEn ? 'Forgot password?' : 'Şifreni mi unuttun?';
  static String get noAccount => isEn ? 'Don\'t have an account? Register' : 'Hesabın yok mu? Kayıt ol';
  static String get hasAccount => isEn ? 'Already have an account? Log in' : 'Zaten hesabın var mı? Giriş yap';
  static String get resetPassword => isEn ? 'Reset Password' : 'Şifreyi Sıfırla';
  static String get resetSent => isEn ? 'Password reset email sent.' : 'Şifre sıfırlama e-postası gönderildi.';
  static String get guestUser => isEn ? 'Guest' : 'Misafir';

  // Navigation & Tabs
  static String get homeTitle => isEn ? 'My Lists' : 'Listelerim';
  static String get diaryTitle => isEn ? 'Diary' : 'Günlük';
  static String get socialTitle => isEn ? 'Social' : 'Sosyal';
  static String get explore => isEn ? 'Explore' : 'Keşfet';
  static String get notifications => isEn ? 'Notifications' : 'Bildirimler';

  // Home
  static String get myCategories => isEn ? 'My Lists' : 'Listelerim';
  static String get addCategory => isEn ? 'New List' : 'Yeni Liste';
  static String get newCategory => isEn ? 'New List' : 'Yeni Liste';
  static String get createCategory => isEn ? 'Create List' : 'Liste Oluştur';
  static String get editCategory => isEn ? 'Edit List' : 'Listeyi Düzenle';
  static String get categoryName => isEn ? 'List Name' : 'Liste Adı';
  static String get categoryIcon => isEn ? 'Select Icon' : 'İkon Seç';
  static String get categoryType => isEn ? 'Type' : 'Tür';
  static String get updateCategory => isEn ? 'Update' : 'Güncelle';
  static String get deleteCategory => isEn ? 'Delete List' : 'Listeyi Sil';
  static String get deleteCatMsg => isEn
      ? 'This list and all items inside will be deleted. Are you sure?'
      : 'Bu liste ve içindeki tüm öğeler silinecek. Emin misin?';
  static String get deleteCategoryMsg => isEn
      ? 'This list and all items inside will be deleted. Are you sure?'
      : 'Bu liste ve içindeki tüm öğeler silinecek. Emin misin?';
  static String get emptyHome => isEn
      ? 'No lists yet.\nAdd one with the + button!'
      : 'Henüz liste yok.\n+ butonuyla ekleyebilirsin!';
  static String get emptyCategories => isEn
      ? 'No lists yet.\nCreate your first list with the + button!'
      : 'Henüz liste yok.\n+ butonuyla ilk listeni oluştur!';
  static String get searchCategory => isEn ? 'Search lists...' : 'Liste ara...';
  static String get noSearchResult => isEn ? 'No results found.' : 'Sonuç bulunamadı.';
  static String get edit => isEn ? 'Edit' : 'Düzenle';

  // Category Options & Custom Statuses (Screenshot 1)
  static String get statusOptionsCustomRequired => isEn
      ? 'Status Options (Required for Custom *)'
      : 'Durum Seçenekleri (Özel Tür İçin Zorunlu *)';
  static String get statusOptionsOptional => isEn
      ? 'Customize Status Options (Optional)'
      : 'Durum Seçeneklerini Özelleştir (Opsiyonel)';
  static String get statusOptionsEdit => isEn
      ? 'Edit Status Options (Optional)'
      : 'Durum Seçeneklerini Düzenle (Opsiyonel)';
  static String get statusOptionsRequired => isEn
      ? 'Status Options (Required *)'
      : 'Durum Seçenekleri (Zorunlu *)';
  static String get status1 => isEn ? '1st Status' : '1. Durum';
  static String get status2 => isEn ? '2nd Status (If any)' : '2. Durum (Varsa)';
  static String get status3 => isEn ? '3rd Status' : '3. Durum';
  static String get privateCategory => isEn
      ? 'Private (Password-Protected) Category'
      : 'Özel (Şifreli) Kategori';
  static String get privateCategorySub => isEn
      ? 'Password required to enter this category'
      : 'Bu kategoriye girmek için şifre istenir';
  static String get categoryPassword => isEn ? 'Category Password' : 'Kategori Şifresi';
  static String get rating => isEn ? 'Rating' : 'Puan';

  // Social Feed & Posts (Screenshot 2 & 3)
  static String get socialFeedTitle => isEn ? 'Social Feed' : 'Sosyal Akış';
  static String get following => isEn ? 'Following' : 'Takip Ettiklerin';
  static String get newPost => isEn ? 'New Post' : 'Yeni Gönderi';
  static String get share => isEn ? 'Share' : 'Paylaş';
  static String get postPlaceholder => isEn
      ? 'What do you want to talk about?'
      : 'Ne hakkında konuşmak istersin?';
  static String get whoCanSee => isEn ? 'Who Can See:' : 'Kimler Görebilir:';
  static String get publicVisibility => isEn ? '🌍 Public' : '🌍 Herkese Açık';
  static String get followersOnlyVisibility => isEn ? '👥 Followers Only' : '👥 Sadece Takipçilerim';
  static String get attachMedia => isEn ? 'Add a Movie / TV Show / Book' : 'Bir Film / Dizi / Kitap Ekle';
  static String get changeMedia => isEn ? 'Change Selected Item' : 'Seçili Ögeyi Değiştir';
  static String get selectItem => isEn ? 'Select an Item' : 'Bir Öge Seç';
  static String get searchItems => isEn ? 'Search items...' : 'Öğelerde ara...';
  static String get noCategory => isEn ? 'No Category' : 'Kategori Yok';
  static String get deletePost => isEn ? 'Delete Post' : 'Gönderiyi Sil';
  static String get deletePostConfirm => isEn
      ? 'Are you sure you want to delete this post? This action cannot be undone.'
      : 'Bu gönderiyi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.';
  static String get reportPost => isEn ? 'Report Post' : 'Gönderiyi Raporla';
  static String get report => isEn ? 'Report' : 'Raporla';
  static String get reason => isEn ? 'Reason' : 'Sebep';
  static String get descriptionOptional => isEn ? 'Description (optional)' : 'Açıklama (opsiyonel)';
  static String get reportSent => isEn ? 'Report submitted. Thank you! 🛡️' : 'Rapor gönderildi. Teşekkürler! 🛡️';
  static String get editorsChoice => isEn ? 'Editor\'s Choice' : 'Editörün Seçimi';
  static String get anonymousUser => isEn ? 'Anonymous' : 'İsimsiz';
  static String get searchUsers => isEn ? 'Search users...' : 'Kullanıcı ara...';
  static String get followers => isEn ? 'Followers' : 'Takipçi';
  static String get follow => isEn ? 'Follow' : 'Takip Et';
  static String get unfollow => isEn ? 'Unfollow' : 'Takipten Çık';
  static String get editProfile => isEn ? 'Edit Profile' : 'Profili Düzenle';
  static String get noPostsYet => isEn ? 'No posts yet.' : 'Henüz gönderi yok.';
  static String get followingPostsSub => isEn
      ? 'Posts from people you follow will appear here.'
      : 'Takip ettiğiniz kişilerin gönderileri burada görünür.';

  // Sort (Home)
  static String get sort => isEn ? 'Sort' : 'Sırala';
  static String get sortDefault => isEn ? 'Default' : 'Varsayılan';
  static String get sortNameDesc => 'Z → A';

  // Sort (Detail)
  static String get sortLabel => isEn ? 'Sort' : 'Sırala';
  static String get sortNewest => isEn ? 'Newest' : 'En Yeni';
  static String get sortRatingHigh => isEn ? 'Rating (High → Low)' : 'Puan (Yüksek → Düşük)';
  static String get sortRatingLow => isEn ? 'Rating (Low → High)' : 'Puan (Düşük → Yüksek)';
  static String get sortNameAsc => 'A → Z';

  // Detail
  static String get addItem => isEn ? 'Add' : 'Ekle';
  static String get itemTitle => isEn ? 'Title' : 'Başlık';
  static String get saveItem => isEn ? 'Save' : 'Kaydet';
  static String get editItem => isEn ? 'Edit' : 'Düzenle';
  static String get updateItem => isEn ? 'Update' : 'Güncelle';
  static String get emptyList => isEn ? 'This list is empty. Add with +!' : 'Bu liste boş. + ile ekle!';
  static String get noResult => isEn ? 'No results found.' : 'Sonuç bulunamadı.';
  static String get favoritesOnly => isEn ? 'Favorites Only' : 'Sadece Favoriler';

  // Rating Types
  static String get stars5 => isEn ? '5 Stars' : '5 Yıldız';
  static String get score10 => isEn ? '1-10 Score' : '1-10 Puan';

  // Status
  static String get statusWatched => isEn ? 'Watched' : 'İzlendi';
  static String get statusWatching => isEn ? 'Watching' : 'İzleniyor';
  static String get statusWatchlist => isEn ? 'To Watch' : 'İzlenecek';
  static String get statusAll => isEn ? 'All' : 'Tümü';
  static String get changeStatus => isEn ? 'Status' : 'Durum';

  // Search & API
  static String get searchHint => isEn ? 'Search...' : 'Ara...';
  static String get searchResults => isEn ? 'Results' : 'Sonuçlar';
  static String get searching => isEn ? 'Searching...' : 'Aranıyor...';
  static String get noApiResult => isEn
      ? 'No results found. Want to add manually?'
      : 'Sonuç bulunamadı. Manuel eklemek ister misin?';
  static String get addManually => isEn ? 'Add Manually' : 'Manuel Ekle';
  static String get tapToAdd => isEn ? 'Tap to select' : 'Eklemek için seç';
  static String get apiNotConfigured => isEn
      ? 'API key not configured. Key needed for search.'
      : 'API key tanımlı değil. Arama için key gerekiyor.';

  // Delete / Common
  static String get deleteConfirm => isEn ? 'Delete?' : 'Sil?';
  static String get deleteItemMsg => isEn
      ? 'This item will be permanently deleted.'
      : 'Bu öğe kalıcı olarak silinecek.';
  static String get delete => isEn ? 'Delete' : 'Sil';
  static String get cancel => isEn ? 'Cancel' : 'İptal';

  // Profile
  static String get profileTitle => isEn ? 'Profile' : 'Profil';
  static String get uid => isEn ? 'User ID' : 'Kullanıcı ID';
  static String get about => isEn ? 'About Me (Optional)' : 'Hakkımda (Opsiyonel)';
  static String get save => isEn ? 'Save' : 'Kaydet';
  static String get profileMotto => isEn ? 'Ratix — List of everything.' : 'Ratix — Her şeyin listesi.';
  static String get aboutApp => isEn
      ? 'Ratix v4.2.2\nTrack and rate your movies, TV shows, books, games and more.'
      : 'Ratix v4.2.2\nFilmlerini, dizilerini, kitaplarını,\noyunlarını ve çok daha fazlasını takip edip puanla.';
  static String get aboutSection => isEn ? 'About' : 'Hakkında';

  // Settings
  static String get settingsTitle => isEn ? 'Settings' : 'Ayarlar';
  static String get themeLabel => isEn ? 'Theme' : 'Tema';
  static String get darkMode => isEn ? 'Dark Mode' : 'Karanlık Mod';
  static String get defaultRatingType => isEn ? 'Default Rating' : 'Varsayılan Puanlama';
  static String get profileInfo => isEn ? 'Profile Information' : 'Profil Bilgileri';
  static String get general => isEn ? 'General' : 'Genel';
  static String get profileSaved => isEn ? 'Profile saved ✓' : 'Profil kaydedildi ✓';
  static String get languageOption => isEn ? 'Language' : 'Dil Seçeneği';
  static String get selectLanguage => isEn ? 'Select Language' : 'Dil Seçimi';
  static String get turkish => 'Türkçe';
  static String get english => 'English';
  static String get currentLanguageName => isEn ? 'English' : 'Türkçe';
  static String get currentLanguageSubtitle => isEn ? 'Current language: English' : 'Şu anki dil: Türkçe';
  static String get pushNotifications => isEn ? 'Push Notifications' : 'Anlık Bildirimler';
  static String get notificationsOn => isEn ? 'Notifications enabled' : 'Bildirimler açık';
  static String get notificationsOff => isEn ? 'Notifications disabled' : 'Bildirimler kapalı';
  static String get privateAccount => isEn ? 'Private Account' : 'Gizli Hesap';
  static String get privateAccountSubOn => isEn ? 'Only followers can view your profile' : 'Profilini sadece takipçilerin görebilir';
  static String get privateAccountSubOff => isEn ? 'Your profile is public' : 'Profilin herkese açık';
  static String get showSharePrompt => isEn ? 'Show Share Dialog on Item Add' : 'Öğe Eklendiğinde Paylaşım Penceresini Göster';
  static String get blockedUsers => isEn ? 'Blocked Users' : 'Engellenen Kullanıcılar';
  static String get blockedUsersSub => isEn ? 'Manage blocked users' : 'Engellediğin kullanıcıları yönet';
  static String get privacyPolicy => isEn ? 'Privacy Policy' : 'Gizlilik Politikası';
  static String get termsOfService => isEn ? 'Terms of Service' : 'Kullanım Koşulları';
  static String get supportContact => isEn ? 'Support & Contact' : 'Destek ve İletişim';
  static String get copyright => isEn ? '© 2026 Ratix. All Rights Reserved.' : '© 2026 Ratix. Tüm Hakları Saklıdır.';

  // Category Type Label
  static String get categoryTypeLabel => isEn ? 'Category Type' : 'Kategori Türü';
  static String get categoryTypeHint => isEn ? 'What kind of list?' : 'Ne tür bir liste?';

  // Errors / Success
  static String get errorUpload => isEn ? 'Upload failed' : 'Yükleme başarısız';
  static String get errorGeneric => isEn ? 'An error occurred' : 'Bir hata oluştu';
  static String get photoUpdated => isEn ? 'Profile photo updated ✓' : 'Profil fotoğrafı güncellendi ✓';
  static String get ratingSuccess => isEn ? 'Rated ✓' : 'Puanlandı ✓';

  // Image Picker
  static String get pickSource => isEn ? 'Select Source' : 'Kaynak Seç';
  static String get gallery => isEn ? 'Gallery' : 'Galeri';
  static String get camera => isEn ? 'Camera' : 'Kamera';
}
