import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import '../models/item_model.dart';
import 'search_service.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String get _uid {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw Exception("User not authenticated.");
    return uid;
  }

  // --- Categories Stream (Realtime + Offline Cache) ---
  Stream<List<CategoryModel>> getCategoriesStream() async* {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'categories_cache_$_uid';

    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      try {
        final List decoded = jsonDecode(cachedData);
        yield decoded.map((data) => CategoryModel.fromMap(data, data['id'])).toList();
      } catch (_) {}
    }

    yield* _supabase
        .from('categories')
        .stream(primaryKey: ['id'])
        .eq('user_id', _uid)
        .order('updated_at', ascending: false)
        .handleError((e) {
          debugPrint('[DatabaseService] getCategoriesStream ERROR: $e');
        })
        .map((rows) {
          prefs.setString(cacheKey, jsonEncode(rows));
          return rows.map((data) => CategoryModel.fromMap(data, data['id'])).toList();
        });
  }

  // --- Items Stream (Realtime + Offline Cache) ---
  Stream<List<ItemModel>> getItemsStream(String categoryId) async* {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'items_cache_${_uid}_$categoryId';

    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      try {
        final List decoded = jsonDecode(cachedData);
        yield decoded.map((data) => ItemModel.fromMap(data, data['id'])).toList();
      } catch (_) {}
    }

    yield* _supabase
        .from('items')
        .stream(primaryKey: ['id'])
        .eq('category_id', categoryId)
        .order('created_at', ascending: false)
        .handleError((e) {
          debugPrint('[DatabaseService] getItemsStream ERROR: $e');
        })
        .map((rows) {
          prefs.setString(cacheKey, jsonEncode(rows));
          return rows.map((data) => ItemModel.fromMap(data, data['id'])).toList();
        });
  }

  // --- Main Category Items Stream (Includes Main Category + All Subcategories) ---
  Stream<List<ItemModel>> getMainCategoryItemsStream(String mainCategoryId) async* {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'main_items_cache_${_uid}_$mainCategoryId';

    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      try {
        final List decoded = jsonDecode(cachedData);
        yield decoded.map((data) => ItemModel.fromMap(data, data['id'])).toList();
      } catch (_) {}
    }

    final subCatRes = await _supabase
        .from('categories')
        .select('id')
        .eq('parent_id', mainCategoryId);
    
    final Set<String> targetCategoryIds = {mainCategoryId};
    for (final row in (subCatRes as List? ?? [])) {
      if (row['id'] != null) {
        targetCategoryIds.add(row['id'].toString());
      }
    }

    yield* _supabase
        .from('items')
        .stream(primaryKey: ['id'])
        .eq('user_id', _uid)
        .order('created_at', ascending: false)
        .handleError((e) {
          debugPrint('[DatabaseService] getMainCategoryItemsStream ERROR: $e');
        })
        .map((rows) {
          final filteredRows = rows.where((data) => targetCategoryIds.contains(data['category_id'].toString())).toList();
          prefs.setString(cacheKey, jsonEncode(filteredRows));
          return filteredRows.map((data) => ItemModel.fromMap(data, data['id'])).toList();
        });
  }

  // --- Fetch categories once (for back-navigation reliability) ---
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final data = await _supabase
          .from('categories')
          .select()
          .eq('user_id', _uid)
          .order('updated_at', ascending: false);
      return data.map((row) => CategoryModel.fromMap(row, row['id'])).toList();
    } catch (e) {
      debugPrint('[DatabaseService] fetchCategories ERROR: $e');
      return [];
    }
  }

  // --- Add Category ---
  Future<String?> addCategory(CategoryModel category) async {
    try {
      await _supabase.from('categories').insert({
        'user_id': _uid,
        'name': category.name,
        'icon': category.icon,
        'color_value': 0,
        'category_type': category.categoryType.toString().split('.').last,
        'rating_type': category.ratingType.toString().split('.').last,
        'is_private': category.isPrivate,
        if (category.passwordHash != null) 'password_hash': category.passwordHash,
        if (category.parentId != null) 'parent_id': category.parentId,
        if (category.customStatus1 != null) 'custom_status_1': category.customStatus1,
        if (category.customStatus2 != null) 'custom_status_2': category.customStatus2,
        if (category.customStatus3 != null) 'custom_status_3': category.customStatus3,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      return null;
    } catch (e) {
      debugPrint('[DatabaseService] addCategory ERROR: $e');
      return e.toString();
    }
  }

  // --- SubCategories Stream ---
  Stream<List<CategoryModel>> getSubCategoriesStream(String parentId) async* {
    yield* _supabase
        .from('categories')
        .stream(primaryKey: ['id'])
        .eq('parent_id', parentId)
        .order('updated_at', ascending: false)
        .handleError((e) {
          debugPrint('[DatabaseService] getSubCategoriesStream ERROR: $e');
        })
        .map((rows) => rows.map((data) => CategoryModel.fromMap(data, data['id'])).toList());
  }

  // --- Update Category ---
  Future<String?> updateCategory(
    String id,
    String name,
    String icon, {
    String? customStatus1,
    String? customStatus2,
    String? customStatus3,
  }) async {
    try {
      await _supabase.from('categories').update({
        'name': name,
        'icon': icon,
        'custom_status_1': customStatus1,
        'custom_status_2': customStatus2,
        'custom_status_3': customStatus3,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
      return null;
    } catch (e) {
      debugPrint('[DatabaseService] updateCategory ERROR: $e');
      return e.toString();
    }
  }

  // --- Delete Category ---
  Future<String?> deleteCategory(String categoryId) async {
    try {
      await _supabase.from('categories').delete().eq('id', categoryId);
      return null;
    } catch (e) {
      debugPrint('[DatabaseService] deleteCategory ERROR: $e');
      return e.toString();
    }
  }

  // --- Duplicate Category ---
  Future<String?> duplicateCategory(String categoryId) async {
    try {
      // 1. Fetch category
      final catRes = await _supabase.from('categories').select().eq('id', categoryId).single();
      
      // 2. Create new category
      final newCatRes = await _supabase.from('categories').insert({
        'user_id': _uid,
        'name': '${catRes['name']} (Kopya)',
        'rating_type': catRes['rating_type'],
        'icon': catRes['icon'],
        'category_type': catRes['category_type'],
        'is_private': catRes['is_private'] ?? false,
      }).select('id').single();
      
      final newCatId = newCatRes['id'] as String;

      // 3. Fetch items
      final itemsRes = await _supabase.from('items').select().eq('category_id', categoryId);
      final List<dynamic> items = itemsRes;

      // 4. Insert items to new category
      if (items.isNotEmpty) {
        final newItems = items.map((item) {
          final newItem = Map<String, dynamic>.from(item as Map<String, dynamic>);
          newItem.remove('id'); 
          newItem['category_id'] = newCatId;
          newItem['user_id'] = _uid;
          newItem['created_at'] = DateTime.now().toUtc().toIso8601String();
          return newItem;
        }).toList();
        
        await _supabase.from('items').insert(newItems);
      }
      return null;
    } catch (e) {
      debugPrint('[DatabaseService] duplicateCategory ERROR: $e');
      return e.toString();
    }
  }

  // --- Paste Items from another category ---
  Future<String?> pasteCategoryItems(String fromCategoryId, String toCategoryId) async {
    try {
      final itemsRes = await _supabase.from('items').select().eq('category_id', fromCategoryId);
      final List<dynamic> items = itemsRes;

      if (items.isNotEmpty) {
        final newItems = items.map((item) {
          final newItem = Map<String, dynamic>.from(item as Map<String, dynamic>);
          newItem.remove('id'); 
          newItem['category_id'] = toCategoryId;
          newItem['user_id'] = _uid;
          newItem['created_at'] = DateTime.now().toUtc().toIso8601String();
          return newItem;
        }).toList();
        
        await _supabase.from('items').insert(newItems);
      }
      return null;
    } catch (e) {
      debugPrint('[DatabaseService] pasteCategoryItems ERROR: $e');
      return e.toString();
    }
  }

  // --- Add Item ---
  Future<String> addItem(String categoryId, ItemModel item) async {
    final res = await _supabase.from('items').insert({
      'category_id': categoryId,
      'user_id': _uid,
      'title': item.title,
      'rating': item.rating,
      'created_at': item.createdAt.toUtc().toIso8601String(),
      'poster_url': item.posterUrl,
      'year': item.year,
      'watch_status': item.watchStatus,
      'external_id': item.externalId,
      'media_type': item.mediaType,
      'genres': item.genres.join(','),
      'author': item.author,
      'overview': item.overview,
      'is_favorite': item.isFavorite,
      'review': item.review,
      'runtime': item.runtime,
      if (item.seasonsData != null) 'seasons_data': item.seasonsData,
    }).select('id').single();
    return res['id'] as String;
  }

  // --- Update Item Seasons Data ---
  Future<void> updateItemSeasons(String itemId, Map<String, dynamic> seasonsData, int calculatedRuntime) async {
    try {
      final bool isAllSelected = seasonsData['all_selected'] == true;
      final String watchStatus = isAllSelected ? 'watched' : 'watching';

      await _supabase.from('items').update({
        'seasons_data': seasonsData,
        'runtime': calculatedRuntime,
        'watch_status': watchStatus,
      }).eq('id', itemId);
    } catch (e) {
      debugPrint('[DatabaseService] updateItemSeasons ERROR: $e');
    }
  }

  // --- Update Item Runtime ---
  Future<void> updateItemRuntime(String itemId, int runtime) async {
    try {
      await _supabase.from('items').update({'runtime': runtime}).eq('id', itemId);
    } catch (e) {
      debugPrint('[DatabaseService] updateItemRuntime ERROR: $e');
    }
  }
  // YENİ: Tekrar İzleme (Rewatch) Sayısını Güncelleme (Artırma/Azaltma)
  Future<void> updateRewatchCount(String itemId, int newCount) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    await _supabase.from('items').update({
      'rewatch_count': newCount < 0 ? 0 : newCount,
    }).eq('id', itemId).eq('user_id', userId);
  }

  final Set<String> _backfillingItemIds = {};

  /// Check items without runtime and fetch from TMDB, updating DB automatically
  Future<void> checkAndBackfillRuntimes(List<ItemModel> items) async {
    final missingItems = items.where((i) =>
      i.id.isNotEmpty &&
      i.runtime == null &&
      i.externalId != null &&
      i.externalId!.isNotEmpty &&
      i.mediaType != null &&
      (i.mediaType == 'movie' || i.mediaType == 'tv') &&
      !_backfillingItemIds.contains(i.id)
    ).toList();

    if (missingItems.isEmpty) return;

    for (final item in missingItems) {
      _backfillingItemIds.add(item.id);
      try {
        final runtime = await SearchService.instance.getTmdbRuntime(item.mediaType!, item.externalId!);
        if (runtime != null && runtime > 0) {
          await updateItemRuntime(item.id, runtime);
        }
      } catch (e) {
        debugPrint('[DatabaseService] backfill error for ${item.title}: $e');
      }
    }
  }

  // --- Get Item with Category ---
  Future<Map<String, dynamic>?> getItemWithCategory(String itemId) async {
    try {
      final res = await _supabase.from('items')
        .select('*, categories(id, name, icon, category_type)')
        .eq('id', itemId)
        .maybeSingle();
      return res;
    } catch (e) {
      debugPrint('[DatabaseService] getItemWithCategory ERROR: $e');
      return null;
    }
  }

  // --- Delete Item ---
  Future<String?> deleteItem(String categoryId, String itemId) async {
    try {
      await _supabase.from('items').delete().eq('id', itemId);
      return null;
    } catch (e) {
      debugPrint('[DatabaseService] deleteItem ERROR: $e');
      return e.toString();
    }
  }

  // --- Update Item Rating & Review ---
  Future<void> updateItemRatingAndReview(String categoryId, String itemId, double rating, String? review) async {
    await _supabase.from('items').update({'rating': rating, 'review': review}).eq('id', itemId);
  }

  // --- Update Item Status ---
  Future<void> updateItemStatus(String categoryId, String itemId, String watchStatus) async {
    await _supabase.from('items').update({'watch_status': watchStatus}).eq('id', itemId);
  }

  // --- Toggle Favorite ---
  Future<void> toggleFavorite(String categoryId, String itemId, bool currentVal) async {
    await _supabase.from('items').update({'is_favorite': !currentVal}).eq('id', itemId);
  }
}
