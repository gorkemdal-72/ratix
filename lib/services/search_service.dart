import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category_type.dart';
import '../core/api_keys.dart';

/// Tüm harici API aramalarını yöneten servis.
/// Her kategori tipi için doğru API'yi seçer.
class SearchService {
  SearchService._();
  static final SearchService instance = SearchService._();

  // ─── ANA ARAMA METHODu ───
  /// CategoryType'a göre doğru API'yi çağırır.
  Future<List<SearchResult>> search(CategoryType type, String query) async {
    if (query.trim().isEmpty) return [];
    final q = Uri.encodeQueryComponent(query.trim());
    switch (type) {
      case CategoryType.movie:
        return _searchTmdb(q, 'movie');
      case CategoryType.tvShow:
        return _searchTmdb(q, 'tv');
      case CategoryType.book:
        return _searchBooks(q);
      case CategoryType.game:
        return _searchGames(q);
      case CategoryType.music:
        return _searchMusic(q);
      default:
        return []; // Manuel kategoriler API aramaz
    }
  }

  // ─── TMDB: Film & Dizi ───
  Future<List<SearchResult>> _searchTmdb(String query, String mediaType) async {
    try {
      final key = ApiKeys.tmdb;
      if (key == 'BURAYA_TMDB_KEY_YAZAR') return [];

      final url = Uri.parse(
        'https://api.themoviedb.org/3/search/$mediaType'
        '?api_key=$key&query=$query&language=tr-TR&page=1',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];

      final data = json.decode(res.body) as Map<String, dynamic>;
      final results = (data['results'] as List?) ?? [];

      return results.take(10).map((item) {
        final title = (item['title'] ?? item['name'] ?? '') as String;
        final date = (item['release_date'] ?? item['first_air_date'] ?? '') as String;
        final year = date.length >= 4 ? int.tryParse(date.substring(0, 4)) : null;
        final poster = item['poster_path'] != null
            ? 'https://image.tmdb.org/t/p/w200${item['poster_path']}'
            : null;
        final genreIds = (item['genre_ids'] as List?)?.map((e) => e.toString()).toList() ?? [];

        return SearchResult(
          externalId: item['id'].toString(),
          title: title,
          subtitle: year?.toString(),
          posterUrl: poster,
          year: year,
          mediaType: mediaType,
          genres: genreIds,
          overview: item['overview'] as String?,
        );
      }).where((r) => r.title.isNotEmpty).toList();
    } catch (e) {
      // ignore: avoid_print
      print('[SearchService] TMDB HATA: $e');
      return [];
    }
  }

  // ─── Open Library: Kitap (Key gerektirmez!) ───
  Future<List<SearchResult>> _searchBooks(String query) async {
    try {
      final url = Uri.parse(
        'https://openlibrary.org/search.json?q=$query&limit=10&fields=key,title,author_name,first_publish_year,cover_i',
      );
      final res = await http.get(url, headers: {
        'User-Agent': 'Ratix/1.0 (flutter app)',
      }).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];

      final data = json.decode(res.body) as Map<String, dynamic>;
      final results = (data['docs'] as List?) ?? [];

      return results.take(10).map((item) {
        final coverId = item['cover_i'];
        final poster = coverId != null
            ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
            : null;
        final authors = (item['author_name'] as List?)?.join(', ');

        return SearchResult(
          externalId: (item['key'] ?? '').toString().replaceAll('/works/', ''),
          title: item['title'] ?? '',
          subtitle: authors,
          posterUrl: poster,
          year: item['first_publish_year'] as int?,
          mediaType: 'book',
          genres: const [],
          author: authors,
          overview: null,
        );
      }).where((r) => r.title.isNotEmpty).toList();
    } catch (e) {
      // ignore: avoid_print
      print('[SearchService] Open Library HATA: $e');
      return [];
    }
  }

  // ─── RAWG: Oyun ───
  Future<List<SearchResult>> _searchGames(String query) async {
    try {
      final key = ApiKeys.rawg;
      if (key == 'BURAYA_RAWG_KEY_YAZAR') return [];

      final url = Uri.parse(
        'https://api.rawg.io/api/games?key=$key&search=$query&page_size=10',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];

      final data = json.decode(res.body) as Map<String, dynamic>;
      final results = (data['results'] as List?) ?? [];

      return results.take(10).map((item) {
        final releaseDate = item['released'] as String?;
        final year = releaseDate != null && releaseDate.length >= 4
            ? int.tryParse(releaseDate.substring(0, 4))
            : null;
        final genres = ((item['genres'] as List?) ?? [])
            .map((g) => (g['name'] ?? '') as String)
            .where((g) => g.isNotEmpty)
            .toList();

        return SearchResult(
          externalId: item['id'].toString(),
          title: item['name'] ?? '',
          subtitle: year?.toString(),
          posterUrl: item['background_image'] as String?,
          year: year,
          mediaType: 'game',
          genres: genres,
          overview: null,
        );
      }).where((r) => r.title.isNotEmpty).toList();
    } catch (e) {
      // ignore: avoid_print
      print('[SearchService] RAWG HATA: $e');
      return [];
    }
  }

  // ─── iTunes Search: Müzik (Key gerektirmez!) ───
  Future<List<SearchResult>> _searchMusic(String query) async {
    try {
      final url = Uri.parse(
        'https://itunes.apple.com/search?term=$query&entity=album&limit=10&country=TR',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];

      final data = json.decode(res.body) as Map<String, dynamic>;
      final results = (data['results'] as List?) ?? [];

      return results.take(10).map((item) {
        final releaseDate = item['releaseDate'] as String?;
        final year = releaseDate != null && releaseDate.length >= 4
            ? int.tryParse(releaseDate.substring(0, 4))
            : null;
        final poster = (item['artworkUrl100'] as String?)?.replaceAll('100x100', '200x200');

        return SearchResult(
          externalId: item['collectionId']?.toString() ?? '',
          title: item['collectionName'] ?? item['trackName'] ?? '',
          subtitle: item['artistName'] as String?,
          posterUrl: poster,
          year: year,
          mediaType: 'music',
          genres: item['primaryGenreName'] != null ? [item['primaryGenreName']] : [],
          author: item['artistName'] as String?,
          overview: null,
        );
      }).where((r) => r.title.isNotEmpty).toList();
    } catch (e) {
      // ignore: avoid_print
      print('[SearchService] iTunes HATA: $e');
      return [];
    }
  }
}

// ─── Normalize edilmiş arama sonucu modeli ───
class SearchResult {
  final String externalId;
  final String title;
  final String? subtitle;    // Yazar, sanatçı, yıl vb.
  final String? posterUrl;
  final int? year;
  final String mediaType;
  final List<String> genres;
  final String? author;
  final String? overview;

  const SearchResult({
    required this.externalId,
    required this.title,
    this.subtitle,
    this.posterUrl,
    this.year,
    required this.mediaType,
    this.genres = const [],
    this.author,
    this.overview,
  });
}
