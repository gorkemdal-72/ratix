class ItemModel {
  final String id;
  final String title;
  final String description;
  final double rating;
  final bool isFavorite;
  final DateTime createdAt;

  // ─── YENİ API/Veritabanı Alanları (nullable — eski veriler bozulmaz) ───
  final String? posterUrl;   // Kapak/poster resmi URL'i
  final int? year;           // Çıkış yılı
  final String? externalId;  // TMDB/RAWG/OpenLibrary ID'si
  final String? mediaType;   // "movie", "tv", "book", "game", "music" vb.
  final List<String> genres; // Türler: ["Drama", "Aksiyon"]
  final String watchStatus;  // "watched" | "watching" | "watchlist"
  final String? author;      // Kitaplar için yazar, müzik için sanatçı
  final String? overview;    // Kısa açıklama

  final String? review;      // Kullanıcının detaylı yorumu
  final String? categoryIcon; // Diary için kategori emojisi
  final String? categoryName; // Diary için kategori adı
  final String? categoryId;   // Kategori ID'si
  final int? runtime;         // Toplam izleme süresi (dakika)
  final Map<String, dynamic>? seasonsData; // Dizi sezon ve bölüm seçim verileri
  final int rewatchCount;     // Tekrar izleme sayısı
  final bool isSpoiler;       // YENİ: Spoiler Kalkanı

  ItemModel({
    required this.id,
    required this.title,
    this.description = '',
    this.rating = 0.0,
    this.isFavorite = false,
    required this.createdAt,
    this.review,
    this.categoryIcon,
    this.categoryName,
    this.categoryId,
    // Yeni alanlar
    this.posterUrl,
    this.year,
    this.externalId,
    this.mediaType,
    this.genres = const [],
    this.watchStatus = 'watched',
    this.author,
    this.overview,
    this.runtime,
    this.seasonsData,
    this.rewatchCount = 0,
    this.isSpoiler = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'rating': rating,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      // Yeni alanlar
      'posterUrl': posterUrl,
      'year': year,
      'externalId': externalId,
      'mediaType': mediaType,
      'genres': genres,
      'watchStatus': watchStatus,
      'author': author,
      'overview': overview,
      'review': review,
      'is_spoiler': isSpoiler,
      'category_id': categoryId,
      'runtime': runtime,
      'seasons_data': seasonsData,
      'rewatch_count': rewatchCount,
    };
  }

  factory ItemModel.fromMap(Map<String, dynamic> map, String docId) {
    // 1. RATING GÜVENLİĞİ: Hem int hem double kabul et
    double parsedRating = 0.0;
    if (map['rating'] is num) {
      parsedRating = (map['rating'] as num).toDouble();
    } else if (map['rating'] is String) {
      parsedRating = double.tryParse(map['rating']) ?? 0.0;
    }

    // 2. TARİH GÜVENLİĞİ: Hem ISO String hem DateTime kabul et
    DateTime parsedDate = DateTime.now();
    try {
      final createdVal = map['createdAt'] ?? map['created_at'];
      if (createdVal is String) {
        parsedDate = DateTime.parse(createdVal).toLocal();
      } else if (createdVal is DateTime) {
        parsedDate = createdVal.toLocal();
      }
    } catch (e) {
      parsedDate = DateTime.now();
    }

    // 3. GENRES GÜVENLİĞİ
    List<String> parsedGenres = [];
    try {
      final genresVal = map['genres'];
      if (genresVal is List) {
        parsedGenres = genresVal.map((e) => e.toString()).toList();
      }
    } catch (_) {}

    Map<String, dynamic>? parsedSeasonsData;
    try {
      final sData = map['seasons_data'] ?? map['seasonsData'];
      if (sData is Map) {
        parsedSeasonsData = Map<String, dynamic>.from(sData);
      }
    } catch (_) {}

    return ItemModel(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      rating: parsedRating,
      isFavorite: map['isFavorite'] ?? map['is_favorite'] ?? false,
      createdAt: parsedDate,
      // Yeni alanlar — null-safe
      posterUrl: (map['posterUrl'] ?? map['poster_url']) as String?,
      year: (map['year'] as num?)?.toInt(),
      externalId: (map['externalId'] ?? map['external_id'])?.toString(),
      mediaType: (map['mediaType'] ?? map['media_type']) as String?,
      genres: parsedGenres,
      watchStatus: (map['watchStatus'] ?? map['watch_status']) as String? ?? 'watched',
      author: map['author'] as String?,
      overview: map['overview'] as String?,
      review: map['review'] as String?,
      isSpoiler: map['is_spoiler'] == true,
      categoryIcon: map['categories']?['icon'] as String?,
      categoryName: map['categories']?['name'] as String?,
      categoryId: map['category_id'] as String?,
      runtime: (map['runtime'] as num?)?.toInt(),
      seasonsData: parsedSeasonsData,
      rewatchCount: (map['rewatch_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Kopyala + güncelle (immutable güncelleme için)
  ItemModel copyWith({
    String? id,
    String? title,
    String? description,
    double? rating,
    bool? isFavorite,
    DateTime? createdAt,
    String? posterUrl,
    int? year,
    String? externalId,
    String? mediaType,
    List<String>? genres,
    String? watchStatus,
    String? author,
    String? overview,
    String? review,
    String? categoryIcon,
    String? categoryName,
    String? categoryId,
    int? runtime,
    Map<String, dynamic>? seasonsData,
    int? rewatchCount,
    bool? isSpoiler,
  }) {
    return ItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      posterUrl: posterUrl ?? this.posterUrl,
      year: year ?? this.year,
      externalId: externalId ?? this.externalId,
      mediaType: mediaType ?? this.mediaType,
      genres: genres ?? this.genres,
      watchStatus: watchStatus ?? this.watchStatus,
      author: author ?? this.author,
      overview: overview ?? this.overview,
      review: review ?? this.review,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryName: categoryName ?? this.categoryName,
      categoryId: categoryId ?? this.categoryId,
      runtime: runtime ?? this.runtime,
      seasonsData: seasonsData ?? this.seasonsData,
      rewatchCount: rewatchCount ?? this.rewatchCount,
      isSpoiler: isSpoiler ?? this.isSpoiler,
    );
  }

  /// Sezon ve bölüm yardımcı getter'ları
  int get selectedEpisodesCount => seasonsData?['selected_episodes_count'] as int? ?? 0;
  int get totalEpisodesCount => seasonsData?['total_episodes'] as int? ?? 0;
  bool get isAllSeasonsSelected => seasonsData?['all_selected'] == true;

  String? get seasonsSummary {
    if (mediaType != 'tv' || seasonsData == null) return null;
    if (isAllSeasonsSelected) {
      final total = totalEpisodesCount;
      return total > 0 ? 'Tüm Dizi ($total Bölüm)' : 'Tüm Dizi';
    }
    final selCount = selectedEpisodesCount;
    final total = totalEpisodesCount;
    if (selCount > 0 && total > 0) {
      return '$selCount / $total Bölüm';
    } else if (selCount > 0) {
      return '$selCount Bölüm';
    }
    return null;
  }
}