import '../core/app_strings.dart';

/// Kategori türleri — hangi API'nin kullanılacağını ve
/// status etiketlerini belirler.
enum CategoryType {
  movie,   // 🎬 Film     → TMDB
  tvShow,  // 📺 Dizi     → TMDB
  book,    // 📚 Kitap    → Open Library
  game,    // 🎮 Oyun     → RAWG
  music,   // 🎵 Müzik    → iTunes Search
  food,    // 🍽️ Yemek    → Manuel
  drink,   // 🍺 İçecek   → Manuel
  place,   // ✈️ Yer      → Manuel
  custom,  // 📁 Özel     → Manuel
}

extension CategoryTypeX on CategoryType {
  /// Kullanıcıya gösterilen isim
  String get displayName {
    if (AppStrings.isEn) {
      switch (this) {
        case CategoryType.movie:  return 'Movie';
        case CategoryType.tvShow: return 'TV Show';
        case CategoryType.book:   return 'Book';
        case CategoryType.game:   return 'Game';
        case CategoryType.music:  return 'Music';
        case CategoryType.food:   return 'Food';
        case CategoryType.drink:  return 'Drink';
        case CategoryType.place:  return 'Place';
        case CategoryType.custom: return 'Custom';
      }
    } else {
      switch (this) {
        case CategoryType.movie:  return 'Film';
        case CategoryType.tvShow: return 'Dizi';
        case CategoryType.book:   return 'Kitap';
        case CategoryType.game:   return 'Oyun';
        case CategoryType.music:  return 'Müzik';
        case CategoryType.food:   return 'Yemek';
        case CategoryType.drink:  return 'İçecek';
        case CategoryType.place:  return 'Yer';
        case CategoryType.custom: return 'Özel';
      }
    }
  }

  /// Varsayılan emoji
  String get defaultEmoji {
    switch (this) {
      case CategoryType.movie:  return '🎬';
      case CategoryType.tvShow: return '📺';
      case CategoryType.book:   return '📚';
      case CategoryType.game:   return '🎮';
      case CategoryType.music:  return '🎵';
      case CategoryType.food:   return '🍽️';
      case CategoryType.drink:  return '🍺';
      case CategoryType.place:  return '✈️';
      case CategoryType.custom: return '📁';
    }
  }

  /// Bu kategori tipi için API araması destekleniyor mu?
  bool get hasApiSearch {
    switch (this) {
      case CategoryType.movie:
      case CategoryType.tvShow:
      case CategoryType.book:
      case CategoryType.game:
      case CategoryType.music:
        return true;
      default:
        return false;
    }
  }

  /// Status 1 etiketi (tamamlandı)
  String get status1Label {
    if (AppStrings.isEn) {
      switch (this) {
        case CategoryType.movie:
        case CategoryType.tvShow: return 'Watched';
        case CategoryType.book:   return 'Read';
        case CategoryType.game:   return 'Played';
        case CategoryType.music:  return 'Listened';
        case CategoryType.food:
        case CategoryType.drink:  return 'Tried';
        case CategoryType.place:  return 'Visited';
        case CategoryType.custom: return 'Completed';
      }
    } else {
      switch (this) {
        case CategoryType.movie:
        case CategoryType.tvShow: return 'İzlendi';
        case CategoryType.book:   return 'Okundu';
        case CategoryType.game:   return 'Oynandı';
        case CategoryType.music:  return 'Dinlendi';
        case CategoryType.food:
        case CategoryType.drink:  return 'Denendi';
        case CategoryType.place:  return 'Gidildi';
        case CategoryType.custom: return 'Tamamlandı';
      }
    }
  }

  /// Status 2 etiketi (devam ediyor) — null ise bu tip 2. durumu desteklemiyor
  String? get status2Label {
    if (AppStrings.isEn) {
      switch (this) {
        case CategoryType.movie:
        case CategoryType.tvShow: return 'Watching';
        case CategoryType.book:   return 'Reading';
        case CategoryType.game:   return 'Playing';
        case CategoryType.music:  return 'Listening';
        case CategoryType.custom: return 'In Progress';
        default:                  return null;
      }
    } else {
      switch (this) {
        case CategoryType.movie:
        case CategoryType.tvShow: return 'İzleniyor';
        case CategoryType.book:   return 'Okunuyor';
        case CategoryType.game:   return 'Oynanıyor';
        case CategoryType.music:  return 'Dinleniyor';
        case CategoryType.custom: return 'Devam Ediyor';
        default:                  return null;
      }
    }
  }

  /// Status 3 etiketi (yapılacak)
  String get status3Label {
    if (AppStrings.isEn) {
      switch (this) {
        case CategoryType.movie:
        case CategoryType.tvShow: return 'To Watch';
        case CategoryType.book:   return 'To Read';
        case CategoryType.game:   return 'To Play';
        case CategoryType.music:  return 'To Listen';
        case CategoryType.food:
        case CategoryType.drink:  return 'To Try';
        case CategoryType.place:  return 'To Visit';
        case CategoryType.custom: return 'To Do';
      }
    } else {
      switch (this) {
        case CategoryType.movie:
        case CategoryType.tvShow: return 'İzlenecek';
        case CategoryType.book:   return 'Okunacak';
        case CategoryType.game:   return 'Oynanacak';
        case CategoryType.music:  return 'Dinlenecek';
        case CategoryType.food:
        case CategoryType.drink:  return 'Denenecek';
        case CategoryType.place:  return 'Gidilecek';
        case CategoryType.custom: return 'Yapılacak';
      }
    }
  }

  /// Status 1 emoji
  String get status1Emoji => '✅';

  /// Status 2 emoji
  String get status2Emoji => '▶️';

  /// Status 3 emoji => '🔖'
  String get status3Emoji => '🔖';

  /// Bu tipin tüm geçerli status değerleri
  List<String> get allStatuses {
    final list = [status1Label, status3Label];
    if (status2Label != null) list.insert(1, status2Label!);
    return list;
  }
}
