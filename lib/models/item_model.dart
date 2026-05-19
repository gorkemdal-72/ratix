import 'package:cloud_firestore/cloud_firestore.dart';

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

  ItemModel({
    required this.id,
    required this.title,
    this.description = '',
    this.rating = 0.0,
    this.isFavorite = false,
    required this.createdAt,
    // Yeni alanlar
    this.posterUrl,
    this.year,
    this.externalId,
    this.mediaType,
    this.genres = const [],
    this.watchStatus = 'watched',
    this.author,
    this.overview,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'rating': rating,
      'isFavorite': isFavorite,
      'createdAt': Timestamp.fromDate(createdAt),
      // Yeni alanlar
      'posterUrl': posterUrl,
      'year': year,
      'externalId': externalId,
      'mediaType': mediaType,
      'genres': genres,
      'watchStatus': watchStatus,
      'author': author,
      'overview': overview,
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

    // 2. TARİH GÜVENLİĞİ: Hem Timestamp hem String kabul et
    DateTime parsedDate = DateTime.now();
    try {
      final createdVal = map['createdAt'];
      if (createdVal is Timestamp) {
        parsedDate = createdVal.toDate();
      } else if (createdVal is String) {
        parsedDate = DateTime.parse(createdVal);
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

    return ItemModel(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      rating: parsedRating,
      isFavorite: map['isFavorite'] ?? false,
      createdAt: parsedDate,
      // Yeni alanlar — null-safe
      posterUrl: map['posterUrl'] as String?,
      year: map['year'] as int?,
      externalId: map['externalId'] as String?,
      mediaType: map['mediaType'] as String?,
      genres: parsedGenres,
      watchStatus: map['watchStatus'] as String? ?? 'watched',
      author: map['author'] as String?,
      overview: map['overview'] as String?,
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
    );
  }
}