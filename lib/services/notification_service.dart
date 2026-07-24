import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  String? get currentUserId => _supabase.auth.currentUser?.id;

  Future<List<NotificationModel>> getNotifications({int limit = 20, int offset = 0}) async {
    if (currentUserId == null) return [];
    
    // users tablosuna sender_id üzerinden join yapıyoruz.
    final res = await _supabase.from('notifications')
        .select('*, users:users!notifications_sender_id_fkey(*), posts:posts!notifications_post_id_fkey(*, items(*)), comments:comments!notifications_comment_id_fkey(content)')
        .eq('recipient_id', currentUserId!)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
        
    return res.map((json) {
      return NotificationModel.fromJson(json);
    }).toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    if (currentUserId == null) return;
    await _supabase.from('notifications').update({'is_read': true}).eq('recipient_id', currentUserId!);
  }

  Future<int> getUnreadCount() async {
    if (currentUserId == null) return 0;
    try {
      final res = await _supabase.from('notifications')
          .select('id')
          .eq('recipient_id', currentUserId!)
          .eq('is_read', false);
      return res.length;
    } catch (_) {
      return 0; // Hata olursa uygulamanın çökmesini (ve VS Code'a atmasını) engeller
    }
  }
}
