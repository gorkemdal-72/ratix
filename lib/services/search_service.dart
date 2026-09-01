import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category_type.dart';
import '../core/api_keys.dart';

/// Kitap arama modu: Tümü, Kitap Adı, Yazar
enum BookSearchMode { all, title, author }

/// Tüm harici API aramalarını yöneten servis.
/// Her kategori tipi için doğru API'yi seçer.
class SearchService {
  SearchService._();
  static final SearchService instance = SearchService._();

  // ─── ANA ARAMA METHODu ───
  /// CategoryType'a göre doğru API'yi çağırır.
  /// Kitap aramaları için [bookMode] ile arama tipi seçilebilir.
  Future<List<SearchResult>> search(CategoryType type, String query, {BookSearchMode bookMode = BookSearchMode.all}) async {
    if (query.trim().isEmpty) return [];
    final q = query.trim();
    switch (type) {
      case CategoryType.movie:
        return _searchTmdb(q, 'movie');
      case CategoryType.tvShow:
        return _searchTmdb(q, 'tv');
      case CategoryType.book:
        return _searchBooks(q, bookMode);
      case CategoryType.game:
        return _searchGames(q);
      case CategoryType.music:
        return _searchMusic(q);
      default:
        return []; // Manuel kategoriler API aramaz
    }
  }

  // ─── TMDB: Film & Dizi (orijinal isimle arama) ───
  Future<List<SearchResult>> _searchTmdb(String query, String mediaType) async {
    try {
      final key = ApiKeys.tmdb;
      if (key == 'BURAYA_TMDB_KEY_YAZAR') return [];

      final url = Uri.https('api.themoviedb.org', '/3/search/$mediaType', {
        'api_key': key,
        'query': query,
        'page': '1',
      });
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];

      final data = json.decode(res.body) as Map<String, dynamic>;
      final results = (data['results'] as List?) ?? [];

      return results.take(10).map((item) {
        // Orijinal ismi göster (film: original_title, dizi: original_name)
        final title = mediaType == 'movie'
            ? (item['original_title'] ?? item['title'] ?? '') as String
            : (item['original_name'] ?? item['name'] ?? '') as String;
        final date = (item['release_date'] ?? item['first_air_date'] ?? '') as String;
        final year = date.length >= 4 ? int.tryParse(date.substring(0, 4)) : null;
        final poster = item['poster_path'] != null
            ? 'https://image.tmdb.org/t/p/w200${item['poster_path']}'
            : null;
        final genreIds = (item['genre_ids'] as List?)?.map((e) => e.toString()).toList() ?? [];

        return SearchResult(
          externalId: item['id'].toString(),
          title: title,
          subtitle: year != null ? '$year' : null,
          posterUrl: poster,
          year: year,
          mediaType: mediaType,
          genres: genreIds,
          overview: item['overview'] as String?,
        );
      }).where((r) => r.title.isNotEmpty).toList();
    } catch (e) {
      // ignore: avoid_print
      debugPrint('[SearchService] TMDB HATA: $e');
      return [];
    }
  }

  // ─── TMDB: Runtime Getir (Film & Dizi) ───
  Future<int?> getTmdbRuntime(String mediaType, String id) async {
    if (mediaType != 'movie' && mediaType != 'tv') return null;
    try {
      final key = ApiKeys.tmdb;
      if (key == 'BURAYA_TMDB_KEY_YAZAR') return null;

      final url = Uri.https('api.themoviedb.org', '/3/$mediaType/$id', {
        'api_key': key,
        'language': 'tr-TR',
      });
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;

      final data = json.decode(res.body) as Map<String, dynamic>;

      if (mediaType == 'movie') {
        return (data['runtime'] as num?)?.toInt(); // Dakika cinsinden
      } else if (mediaType == 'tv') {
        int avgRuntime = 0;
        final runtimes = data['episode_run_time'] as List?;
        if (runtimes != null && runtimes.isNotEmpty && runtimes[0] is num) {
          avgRuntime = (runtimes[0] as num).toInt();
        } else if (data['last_episode_to_air'] != null && data['last_episode_to_air']['runtime'] != null) {
          if (data['last_episode_to_air']['runtime'] is num) {
            avgRuntime = (data['last_episode_to_air']['runtime'] as num).toInt();
          }
        }

        final numEpisodes = (data['number_of_episodes'] as num?)?.toInt();
        if (avgRuntime > 0 && numEpisodes != null && numEpisodes > 0) {
          return avgRuntime * numEpisodes;
        } else if (numEpisodes != null && numEpisodes > 0) {
          return 45 * numEpisodes; // Ortalama 45dk varsay
        }
      }
      return null;
    } catch (e) {
      debugPrint('[SearchService] getTmdbRuntime HATA: $e');
      return null;
    }
  }

  // ─── TMDB: Watch Providers (Nereden İzlenir) ───
  Future<List<Map<String, dynamic>>> getWatchProviders(String mediaType, String id, {String region = 'TR'}) async {
    if (mediaType != 'movie' && mediaType != 'tv' && mediaType != 'tvShow') return [];
    final type = mediaType == 'tvShow' ? 'tv' : mediaType;
    try {
      final key = ApiKeys.tmdb;
      if (key.isEmpty || key.contains('BURAYA')) return [];

      final url = Uri.https('api.themoviedb.org', '/3/$type/$id/watch/providers', {
        'api_key': key,
      });
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];

      final data = json.decode(res.body) as Map<String, dynamic>;
      final results = data['results'] as Map<String, dynamic>?;
      if (results == null || !results.containsKey(region)) return [];

      final regionData = results[region] as Map<String, dynamic>;
      // flatrate: Netflix, Prime vb. abonelikler
      // buy / rent: Satın alma / Kiralama
      final flatrate = (regionData['flatrate'] as List?) ?? [];
      
      return flatrate.map((e) => {
        'name': e['provider_name'],
        'logo_path': 'https://image.tmdb.org/t/p/w92${e['logo_path']}',
      }).toList();
    } catch (e) {
      debugPrint('[SearchService] WatchProviders HATA: $e');
      return [];
    }
  }

  // ─── TMDB: Keşfet (Trending) ───
  Future<List<SearchResult>> getTrending({String mediaType = 'all', String timeWindow = 'day'}) async {
    try {
      final key = ApiKeys.tmdb;
      if (key.isEmpty || key.contains('BURAYA')) return [];

      final url = Uri.https('api.themoviedb.org', '/3/trending/$mediaType/$timeWindow', {
        'api_key': key,
        'language': 'tr-TR',
      });
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];

      final data = json.decode(res.body) as Map<String, dynamic>;
      final results = (data['results'] as List?) ?? [];

      return results.take(15).map((item) {
        final mType = item['media_type'] ?? mediaType;
        final title = mType == 'movie'
            ? (item['original_title'] ?? item['title'] ?? '') as String
            : (item['original_name'] ?? item['name'] ?? '') as String;
        final date = (item['release_date'] ?? item['first_air_date'] ?? '') as String;
        final year = date.length >= 4 ? int.tryParse(date.substring(0, 4)) : null;
        final poster = item['poster_path'] != null
            ? 'https://image.tmdb.org/t/p/w200${item['poster_path']}'
            : null;
        final genreIds = (item['genre_ids'] as List?)?.map((e) => e.toString()).toList() ?? [];

        return SearchResult(
          externalId: item['id'].toString(),
          title: title,
          subtitle: year != null ? '$year' : null,
          posterUrl: poster,
          year: year,
          mediaType: mType,
          genres: genreIds,
          overview: item['overview'] as String?,
        );
      }).where((r) => r.title.isNotEmpty).toList();
    } catch (e) {
      debugPrint('[SearchService] Trending HATA: $e');
      return [];
    }
  }

  // ─── TMDB: TV Dizi Sezon Detaylarını Getir ───
  Future<TvShowDetails?> getTvDetails(String tvId) async {
    try {
      final key = ApiKeys.tmdb;
      if (key == 'BURAYA_TMDB_KEY_YAZAR') return null;

      final url = Uri.https('api.themoviedb.org', '/3/tv/$tvId', {
        'api_key': key,
        'language': 'tr-TR',
      });
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;

      final data = json.decode(res.body) as Map<String, dynamic>;

      int avgRuntime = 45;
      final runtimes = data['episode_run_time'] as List?;
      if (runtimes != null && runtimes.isNotEmpty && runtimes[0] is num) {
        avgRuntime = (runtimes[0] as num).toInt();
      } else if (data['last_episode_to_air'] != null && data['last_episode_to_air']['runtime'] != null) {
        if (data['last_episode_to_air']['runtime'] is num) {
          avgRuntime = (data['last_episode_to_air']['runtime'] as num).toInt();
        }
      }

      final seasonsRaw = (data['seasons'] as List?) ?? [];
      final List<TvSeasonInfo> seasons = [];
      for (final s in seasonsRaw) {
        final seasonNum = (s['season_number'] as num?)?.toInt() ?? 0;
        // Season 0 (Specials) genelde harici bırakılır ama seasonNum >= 1 alalım
        if (seasonNum > 0) {
          seasons.add(TvSeasonInfo(
            seasonNumber: seasonNum,
            name: (s['name'] as String?) ?? '$seasonNum. Sezon',
            episodeCount: (s['episode_count'] as num?)?.toInt() ?? 0,
            posterPath: s['poster_path'] as String?,
            overview: s['overview'] as String?,
          ));
        }
      }

      return TvShowDetails(
        tvId: tvId,
        name: (data['name'] as String?) ?? '',
        numberOfSeasons: (data['number_of_seasons'] as num?)?.toInt() ?? seasons.length,
        numberOfEpisodes: (data['number_of_episodes'] as num?)?.toInt() ?? 0,
        avgEpisodeRuntime: avgRuntime,
        seasons: seasons,
      );
    } catch (e) {
      debugPrint('[SearchService] getTvDetails HATA: $e');
      return null;
    }
  }

  // ─── TMDB: Belirli Bir Sezonun Bölümlerini Getir ───
  Future<List<TvEpisodeInfo>> getTvSeasonEpisodes(String tvId, int seasonNumber) async {
    try {
      final key = ApiKeys.tmdb;
      if (key == 'BURAYA_TMDB_KEY_YAZAR') return [];

      final url = Uri.https('api.themoviedb.org', '/3/tv/$tvId/season/$seasonNumber', {
        'api_key': key,
        'language': 'tr-TR',
      });
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];

      final data = json.decode(res.body) as Map<String, dynamic>;
      final episodesRaw = (data['episodes'] as List?) ?? [];

      return episodesRaw.map((ep) {
        return TvEpisodeInfo(
          episodeNumber: (ep['episode_number'] as num?)?.toInt() ?? 0,
          seasonNumber: (ep['season_number'] as num?)?.toInt() ?? seasonNumber,
          name: (ep['name'] as String?) ?? '${ep['episode_number']}. Bölüm',
          runtime: (ep['runtime'] as num?)?.toInt(),
          overview: ep['overview'] as String?,
        );
      }).toList();
    } catch (e) {
      debugPrint('[SearchService] getTvSeasonEpisodes HATA: $e');
      return [];
    }
  }

  // ─── Kitap Arama (Google Books → Fallback: OpenLibrary) ───
  // TR sonuçlar önce gösterilir, EN sonuçlar alta düşer.
  Future<List<SearchResult>> _searchBooks(String query, BookSearchMode mode) async {
    try {
      final googleResults = await _searchGoogleBooks(query, mode);
      if (googleResults.isNotEmpty) return googleResults;
    } catch (e) {
      debugPrint('[SearchService] Google Books Failed, falling back to OpenLibrary. Error: $e');
    }

    try {
      return await _searchOpenLibrary(query);
    } catch (e) {
      debugPrint('[SearchService] OpenLibrary Failed: $e');
      return [];
    }
  }

  Future<List<SearchResult>> _searchGoogleBooks(String query, BookSearchMode mode) async {
    // Arama moduna göre sorguları oluştur
    List<Future<List<dynamic>>> futures;
    switch (mode) {
      case BookSearchMode.title:
        // Sadece kitap adında ara (boşlukları hesaba katarak tırnak içine al)
        futures = [_fetchGoogleBooksItems('intitle:"$query"', 20).catchError((_) => <dynamic>[])];
        break;
      case BookSearchMode.author:
        // Sadece yazar adında ara (tırnak içine al ki İskender Pala gibi isimler bölünmesin)
        futures = [_fetchGoogleBooksItems('inauthor:"$query"', 20).catchError((_) => <dynamic>[])];
        break;
      case BookSearchMode.all:
        // Normal arama + yazar araması paralel
        futures = [
          _fetchGoogleBooksItems(query, 15).catchError((_) => <dynamic>[]),
          _fetchGoogleBooksItems('inauthor:"$query"', 15).catchError((_) => <dynamic>[]),
        ];
        break;
    }

    final responses = await Future.wait(futures);
    final allItems = responses.expand((items) => items).toList();

    // Parse ederken dil bilgisine göre TR/diğer olarak ayır, duplicate kaldır
    final trResults = <SearchResult>[];
    final otherResults = <SearchResult>[];
    final seenIds = <String>{};

    for (final item in allItems) {
      final volInfo = (item['volumeInfo'] ?? {}) as Map<String, dynamic>;
      final title = (volInfo['title'] ?? '') as String;
      if (title.isEmpty) continue;

      final id = item['id']?.toString() ?? '';
      if (!seenIds.add(id)) continue; // Duplicate atla

      final authors = (volInfo['authors'] as List?)?.join(', ');
      final publishedDate = volInfo['publishedDate'] as String?;
      final year = publishedDate != null && publishedDate.length >= 4
          ? int.tryParse(publishedDate.substring(0, 4))
          : null;
      final lang = (volInfo['language'] as String?) ?? '';

      String? poster = volInfo['imageLinks']?['smallThumbnail'] as String?;
      poster ??= volInfo['imageLinks']?['thumbnail'] as String?;

      final result = SearchResult(
        externalId: id,
        title: title,
        subtitle: authors,
        posterUrl: poster?.replaceAll('http:', 'https:'),
        year: year,
        mediaType: 'book',
        genres: (volInfo['categories'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        author: authors,
        overview: volInfo['description'] as String?,
      );

      // TR sonuçlar önce, diğerleri sonra
      if (lang == 'tr') {
        trResults.add(result);
      } else {
        otherResults.add(result);
      }
    }

    // TR sonuçlar üstte, EN/diğer sonuçlar altta
    return [...trResults, ...otherResults].take(20).toList();
  }

  /// Google Books API'den ham item listesini getirir.
  Future<List<dynamic>> _fetchGoogleBooksItems(String query, int maxResults) async {
    final params = <String, String>{
      'q': query,
      'maxResults': maxResults.toString(),
      'printType': 'all',
      'orderBy': 'relevance',
    };
    if (ApiKeys.googleBooksApiKey.isNotEmpty) {
      params['key'] = ApiKeys.googleBooksApiKey;
    }

    final url = Uri.https('www.googleapis.com', '/books/v1/volumes', params);

    final res = await http.get(url, headers: {
      'Accept': 'application/json',
      'User-Agent': 'Ratix/4.0 (Flutter)',
    }).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }

    final data = json.decode(res.body) as Map<String, dynamic>;
    return (data['items'] as List?) ?? [];
  }

  Future<List<SearchResult>> _searchOpenLibrary(String query) async {
    final url = Uri.https('openlibrary.org', '/search.json', {
      'q': query,
      'limit': '10',
    });

    final res = await http.get(url, headers: {
      'Accept': 'application/json',
      'User-Agent': 'Ratix/4.0 (Flutter)',
    }).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');

    final data = json.decode(res.body) as Map<String, dynamic>;
    final docs = data['docs'] as List? ?? [];

    return docs.map((doc) {
      final title = doc['title'] as String? ?? '';
      final author = (doc['author_name'] as List?)?.join(', ');
      final year = doc['first_publish_year'] as int?;
      final coverId = doc['cover_i'];
      
      String? posterUrl;
      if (coverId != null) posterUrl = 'https://covers.openlibrary.org/b/id/$coverId-M.jpg';

      final externalId = (doc['key'] as String?)?.replaceAll('/works/', '') ?? title;

      return SearchResult(
        externalId: externalId,
        title: title,
        subtitle: author,
        posterUrl: posterUrl,
        year: year,
        mediaType: 'book',
        genres: (doc['subject'] as List?)?.take(3).map((e) => e.toString()).toList() ?? const [],
        author: author,
      );
    }).where((r) => r.title.isNotEmpty).toList();
  }

  // ─── RAWG: Oyun ───
  Future<List<SearchResult>> _searchGames(String query) async {
    try {
      final key = ApiKeys.rawg;
      if (key == 'BURAYA_RAWG_KEY_YAZAR') return [];

      final url = Uri.https('api.rawg.io', '/api/games', {
        'key': key,
        'search': query,
        'page_size': '10',
      });
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
          title: item['name_original'] ?? item['name'] ?? '',
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
      debugPrint('[SearchService] RAWG HATA: $e');
      return [];
    }
  }

  // ─── iTunes Search: Müzik (TR + US mağaza, orijinal isimle) ───
  Future<List<SearchResult>> _searchMusic(String query) async {
    try {
      // TR ve US mağazalardan paralel arama yap
      final results = await Future.wait([
        _searchItunes(query, 'TR').catchError((_) => <SearchResult>[]),
        _searchItunes(query, 'US').catchError((_) => <SearchResult>[]),
      ]);

      final trResults = results[0];
      final usResults = results[1];

      // Birleştir, duplicate kaldır (collectionId bazlı)
      final seenIds = <String>{};
      final merged = <SearchResult>[];
      for (final r in [...usResults, ...trResults]) {
        if (seenIds.add(r.externalId)) merged.add(r);
      }
      return merged.take(10).toList();
    } catch (e) {
      // ignore: avoid_print
      debugPrint('[SearchService] iTunes HATA: $e');
      return [];
    }
  }

  Future<List<SearchResult>> _searchItunes(String query, String country) async {
    final url = Uri.https('itunes.apple.com', '/search', {
      'term': query,
      'entity': 'album',
      'limit': '10',
      'country': country,
    });
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

// ─── TMDB TV Dizi Detay Modelleri ───
class TvShowDetails {
  final String tvId;
  final String name;
  final int numberOfSeasons;
  final int numberOfEpisodes;
  final int avgEpisodeRuntime;
  final List<TvSeasonInfo> seasons;

  TvShowDetails({
    required this.tvId,
    required this.name,
    required this.numberOfSeasons,
    required this.numberOfEpisodes,
    required this.avgEpisodeRuntime,
    required this.seasons,
  });
}

class TvSeasonInfo {
  final int seasonNumber;
  final String name;
  final int episodeCount;
  final String? posterPath;
  final String? overview;

  TvSeasonInfo({
    required this.seasonNumber,
    required this.name,
    required this.episodeCount,
    this.posterPath,
    this.overview,
  });
}

class TvEpisodeInfo {
  final int episodeNumber;
  final int seasonNumber;
  final String name;
  final int? runtime;
  final String? overview;

  TvEpisodeInfo({
    required this.episodeNumber,
    required this.seasonNumber,
    required this.name,
    this.runtime,
    this.overview,
  });
}
