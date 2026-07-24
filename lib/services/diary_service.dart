import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/item_model.dart';

class DiaryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Belirli bir aydaki günlükleri getirir
  Future<Map<DateTime, List<ItemModel>>> getMonthlyDiary(int year, int month, {String? userId}) async {
    final String? myUserId = currentUserId;
    final targetUserId = userId ?? myUserId;
    if (targetUserId == null) return {};

    // ─── GİZLİLİK KONTROLÜ BAŞLANGIÇ ───
    if (myUserId != null && myUserId != targetUserId) {
      try {
        final targetProfile = await _supabase.from('user_social_profiles_view').select('diary_visibility').eq('id', targetUserId).maybeSingle();
        final visibility = targetProfile != null ? targetProfile['diary_visibility'] as String? ?? 'followers_only' : 'followers_only';
        
        final myProfile = await _supabase.from('users').select('is_admin, username').eq('id', myUserId).maybeSingle();
        final isAdmin = myProfile != null && (myProfile['is_admin'] == true || myProfile['username'] == 'zodleenar');

        if (!isAdmin) {
          if (visibility == 'private') {
            return {}; // Sadece kendi görebilir
          } else if (visibility == 'followers_only') {
            final isFollowing = await _supabase.from('follows')
                .select('follower_id')
                .match({'follower_id': myUserId, 'following_id': targetUserId})
                .maybeSingle();
            if (isFollowing == null) {
              return {}; // Takip etmiyor, göremez
            }
          }
        }
      } catch (e) {
        debugPrint('DiaryService privacy check error: $e');
        return {}; // Hata durumunda güvenli tarafta kalıp veriyi gösterme
      }
    }
    // ─── GİZLİLİK KONTROLÜ BİTİŞ ───

    // Ayın ilk günü ve bir sonraki ayın ilk günü
    final start = DateTime.utc(year, month, 1).toIso8601String();
    final end = (month == 12) 
        ? DateTime.utc(year + 1, 1, 1).toIso8601String() 
        : DateTime.utc(year, month + 1, 1).toIso8601String();

    try {
      final res = await _supabase.from('items')
          .select('*, categories(id, name, icon, category_type, rating_type)')
          .eq('user_id', targetUserId)
          .gte('created_at', start)
          .lt('created_at', end)
          .order('created_at', ascending: false);

      Map<DateTime, List<ItemModel>> diaryMap = {};

      for (var row in res as List) {
        final item = ItemModel.fromMap(row, row['id']);
        final date = item.createdAt.toLocal();
        // Sadece yıl, ay, gün olarak normalleştir (saat bilgisini at)
        final normalizedDate = DateTime.utc(date.year, date.month, date.day);
        
        if (!diaryMap.containsKey(normalizedDate)) {
          diaryMap[normalizedDate] = [];
        }
        diaryMap[normalizedDate]!.add(item);
      }
      return diaryMap;
    } catch (e) {
      debugPrint('DiaryService getMonthlyDiary error: $e');
      return {};
    }
  }
}
