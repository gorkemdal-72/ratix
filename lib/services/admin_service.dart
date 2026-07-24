import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

/// Admin ve moderasyon işlemlerini yöneten servis.
/// zodleenar = süper admin (hardcoded).
class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ─── Cache: mevcut kullanıcının profili ───
  UserModel? _cachedProfile;
  DateTime? _cacheTime;

  /// Mevcut kullanıcının profilini çeker (admin bilgisi dahil).
  /// 60 saniyelik cache kullanır.
  Future<UserModel?> getCurrentUserProfile({bool forceRefresh = false}) async {
    if (currentUserId == null) return null;

    if (!forceRefresh &&
        _cachedProfile != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!).inSeconds < 60) {
      return _cachedProfile;
    }

    try {
      final res = await _supabase
          .from('user_social_profiles_view')
          .select()
          .eq('id', currentUserId!)
          .maybeSingle();

      if (res != null) {
        _cachedProfile = UserModel.fromJson(res);
        _cacheTime = DateTime.now();
        return _cachedProfile;
      }
    } catch (e) {
      debugPrint('[AdminService] getCurrentUserProfile HATA: $e');
    }
    return null;
  }

  /// Mevcut kullanıcı admin mi?
  Future<bool> isCurrentUserAdmin() async {
    final profile = await getCurrentUserProfile();
    return profile?.hasAdminPrivileges ?? false;
  }

  /// Mevcut kullanıcı süper admin mi? (zodleenar)
  Future<bool> isCurrentUserSuperAdmin() async {
    final profile = await getCurrentUserProfile();
    return profile?.isSuperAdmin ?? false;
  }

  /// Mevcut kullanıcı susturulmuş mu?
  Future<bool> isCurrentUserMuted() async {
    final profile = await getCurrentUserProfile(forceRefresh: true);
    return profile?.isMuted ?? false;
  }

  // ═══════════════════════════════════════════════
  // ADMIN ATAMA (Sadece Süper Admin)
  // ═══════════════════════════════════════════════

  /// Kullanıcıyı admin yapar. Sadece süper admin yapabilir.
  Future<bool> grantAdmin(String targetUserId) async {
    if (!await isCurrentUserSuperAdmin()) return false;
    try {
      await _supabase
          .from('users')
          .update({'is_admin': true})
          .eq('id', targetUserId);

      // Bildirim gönder
      await _sendAdminNotification(targetUserId, 'admin_grant');
      clearCache();
      return true;
    } catch (e) {
      debugPrint('[AdminService] grantAdmin HATA: $e');
      return false;
    }
  }

  /// Kullanıcının admin yetkisini kaldırır. Sadece süper admin yapabilir.
  Future<bool> revokeAdmin(String targetUserId) async {
    if (!await isCurrentUserSuperAdmin()) return false;
    try {
      await _supabase
          .from('users')
          .update({'is_admin': false})
          .eq('id', targetUserId);

      await _sendAdminNotification(targetUserId, 'admin_revoke');
      clearCache();
      return true;
    } catch (e) {
      debugPrint('[AdminService] revokeAdmin HATA: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════
  // UYARI SİSTEMİ
  // ═══════════════════════════════════════════════

  /// Kullanıcıya uyarı gönderir.
  Future<bool> sendWarning(String targetUserId, String reason) async {
    if (!await isCurrentUserAdmin()) return false;
    try {
      await _supabase.from('warnings').insert({
        'user_id': targetUserId,
        'admin_id': currentUserId,
        'reason': reason,
      });

      // Bildirim olarak da gönder
      await _sendAdminNotification(targetUserId, 'warning');
      return true;
    } catch (e) {
      debugPrint('[AdminService] sendWarning HATA: $e');
      return false;
    }
  }

  /// Kullanıcının aldığı uyarıları listeler.
  Future<List<Map<String, dynamic>>> getUserWarnings(String userId) async {
    try {
      final res = await _supabase.from('warnings').select().eq('user_id', userId).order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('[AdminService] getUserWarnings HATA: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllWarnings() async {
    if (!await isCurrentUserAdmin()) return [];
    try {
      final res = await _supabase.from('warnings').select().order('created_at', ascending: false).limit(50);
      
      // Fetch user details manually to avoid FK errors
      List<Map<String, dynamic>> warnings = List<Map<String, dynamic>>.from(res);
      for (var warning in warnings) {
        if (warning['user_id'] != null) {
          final uRes = await _supabase.from('users').select('username, display_name').eq('id', warning['user_id']).maybeSingle();
          if (uRes != null) warning['target_user'] = uRes;
        }
        if (warning['admin_id'] != null) {
          final aRes = await _supabase.from('users').select('username, display_name').eq('id', warning['admin_id']).maybeSingle();
          if (aRes != null) warning['admin_user'] = aRes;
        }
      }
      return warnings;
    } catch (e) {
      debugPrint('[AdminService] getAllWarnings HATA: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════
  // SUSTURMA (MUTE)
  // ═══════════════════════════════════════════════

  /// Kullanıcıyı belirli bir süre susturur.
  Future<bool> muteUser(String targetUserId, Duration duration, String reason) async {
    if (!await isCurrentUserAdmin()) return false;
    try {
      final muteUntil = DateTime.now().toUtc().add(duration);
      await _supabase.from('users').update({
        'muted_until': muteUntil.toIso8601String(),
        'mute_reason': reason,
      }).eq('id', targetUserId);

      await _sendAdminNotification(targetUserId, 'mute');
      return true;
    } catch (e) {
      debugPrint('[AdminService] muteUser HATA: $e');
      return false;
    }
  }

  /// Kullanıcının susturulmasını kaldırır.
  Future<bool> unmuteUser(String targetUserId) async {
    if (!await isCurrentUserAdmin()) return false;
    try {
      await _supabase.from('users').update({
        'muted_until': null,
        'mute_reason': null,
      }).eq('id', targetUserId);
      return true;
    } catch (e) {
      debugPrint('[AdminService] unmuteUser HATA: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════
  // BAN (Sadece Süper Admin)
  // ═══════════════════════════════════════════════

  /// Kullanıcıyı kalıcı olarak banlar. Sadece süper admin.
  Future<bool> banUser(String targetUserId, String reason) async {
    if (!await isCurrentUserSuperAdmin()) return false;
    try {
      await _supabase.from('users').update({
        'is_banned': true,
        'ban_reason': reason,
      }).eq('id', targetUserId);

      await _sendAdminNotification(targetUserId, 'ban');
      return true;
    } catch (e) {
      debugPrint('[AdminService] banUser HATA: $e');
      return false;
    }
  }

  /// Kullanıcının banını kaldırır. Sadece süper admin.
  Future<bool> unbanUser(String targetUserId) async {
    if (!await isCurrentUserSuperAdmin()) return false;
    try {
      await _supabase.from('users').update({
        'is_banned': false,
        'ban_reason': null,
      }).eq('id', targetUserId);
      return true;
    } catch (e) {
      debugPrint('[AdminService] unbanUser HATA: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════
  // VERIFIED BADGE (Sadece Süper Admin)
  // ═══════════════════════════════════════════════

  /// Kullanıcıya doğrulanmış rozeti verir.
  Future<bool> verifyUser(String targetUserId) async {
    if (!await isCurrentUserSuperAdmin()) return false;
    try {
      await _supabase
          .from('users')
          .update({'is_verified': true})
          .eq('id', targetUserId);
      return true;
    } catch (e) {
      debugPrint('[AdminService] verifyUser HATA: $e');
      return false;
    }
  }

  /// Doğrulanmış rozetini kaldırır.
  Future<bool> unverifyUser(String targetUserId) async {
    if (!await isCurrentUserSuperAdmin()) return false;
    try {
      await _supabase
          .from('users')
          .update({'is_verified': false})
          .eq('id', targetUserId);
      return true;
    } catch (e) {
      debugPrint('[AdminService] unverifyUser HATA: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════
  // ADMIN İÇERİK SİLME
  // ═══════════════════════════════════════════════

  /// Admin olarak yorumu siler (user_id filtresi olmadan).
  Future<bool> adminDeleteComment(String commentId) async {
    if (!await isCurrentUserAdmin()) return false;
    try {
      await _supabase.from('comments').delete().eq('id', commentId);
      return true;
    } catch (e) {
      debugPrint('[AdminService] adminDeleteComment HATA: $e');
      return false;
    }
  }

  /// Admin olarak gönderiyi siler (user_id filtresi olmadan).
  Future<bool> adminDeletePost(String postId) async {
    if (!await isCurrentUserAdmin()) return false;
    try {
      await _supabase.from('posts').delete().eq('id', postId);
      return true;
    } catch (e) {
      debugPrint('[AdminService] adminDeletePost HATA: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════
  // RAPORLAMA SİSTEMİ
  // ═══════════════════════════════════════════════

  /// Bir gönderi, yorum veya kullanıcıyı raporlar.
  Future<bool> submitReport({
    String? reportedUserId,
    String? postId,
    String? commentId,
    required String reason,
    String? details,
  }) async {
    final uid = currentUserId;
    if (uid == null) return false;
    try {
      await _supabase.from('reports').insert({
        'reporter_id': uid,
        'reported_user_id': reportedUserId,
        'post_id': postId,
        'comment_id': commentId,
        'reason': reason,
        'details': details,
      });

      // Bütün adminlere bildirim gönder
      try {
        final adminRes = await _supabase.from('users').select('id').eq('is_admin', true);
        final List<dynamic> admins = adminRes;
        
        final superAdminRes = await _supabase.from('users').select('id').eq('username', 'zodleenar').maybeSingle();
        Set<String> adminIds = {};
        for (var a in admins) {
          adminIds.add(a['id'].toString());
        }
        if (superAdminRes != null) adminIds.add(superAdminRes['id'].toString());
        
        final notifs = adminIds.map((adminId) => {
          'recipient_id': adminId,
          'sender_id': uid,
          'type': 'new_report',
          'post_id': postId,
          'comment_id': commentId,
        }).toList();

        if (notifs.isNotEmpty) {
          await _supabase.from('notifications').insert(notifs);
        }
      } catch (e) {
        debugPrint('[AdminService] submitReport Notif Error: $e');
      }

      return true;
    } catch (e) {
      debugPrint('[AdminService] submitReport HATA: $e');
      return false;
    }
  }

  /// Bekleyen raporları listeler. Sadece admin görebilir.
  Future<List<Map<String, dynamic>>> getPendingReports() async {
    if (!await isCurrentUserAdmin()) return [];
    try {
      final res = await _supabase
          .from('reports')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);
          
      List<Map<String, dynamic>> reports = List<Map<String, dynamic>>.from(res);
      
      for (var report in reports) {
        if (report['reporter_id'] != null) {
          final uRes = await _supabase.from('users').select('username, display_name').eq('id', report['reporter_id']).maybeSingle();
          if (uRes != null) report['reporter'] = uRes;
        }
        if (report['reported_user_id'] != null) {
          final uRes = await _supabase.from('users').select('username, display_name').eq('id', report['reported_user_id']).maybeSingle();
          if (uRes != null) report['reported'] = uRes;
        }
      }
      return reports;
    } catch (e) {
      debugPrint('[AdminService] getPendingReports HATA: $e');
      return [];
    }
  }

  /// Çözülmüş şikayetleri listeler. Sadece admin görebilir.
  Future<List<Map<String, dynamic>>> getResolvedReports() async {
    if (!await isCurrentUserAdmin()) return [];
    try {
      final res = await _supabase
          .from('reports')
          .select()
          .neq('status', 'pending')
          .order('resolved_at', ascending: false)
          .limit(50);
          
      List<Map<String, dynamic>> reports = List<Map<String, dynamic>>.from(res);
      
      for (var report in reports) {
        if (report['reporter_id'] != null) {
          final uRes = await _supabase.from('users').select('username, display_name').eq('id', report['reporter_id']).maybeSingle();
          if (uRes != null) report['reporter'] = uRes;
        }
        if (report['reported_user_id'] != null) {
          final uRes = await _supabase.from('users').select('username, display_name').eq('id', report['reported_user_id']).maybeSingle();
          if (uRes != null) report['reported'] = uRes;
        }
        if (report['resolved_by'] != null) {
          final aRes = await _supabase.from('users').select('username, display_name').eq('id', report['resolved_by']).maybeSingle();
          if (aRes != null) report['resolver'] = aRes;
        }
      }
      return reports;
    } catch (e) {
      debugPrint('[AdminService] getResolvedReports HATA: $e');
      return [];
    }
  }

  /// Raporu çözümlenmiş olarak işaretler ve raporlayana bildirim gönderir.
  Future<bool> resolveReport(String reportId, String reporterId) async {
    if (!await isCurrentUserAdmin()) return false;
    try {
      await _supabase.from('reports').update({
        'status': 'resolved',
        'resolved_by': currentUserId,
        'resolved_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', reportId);
      
      await _sendAdminNotification(reporterId, 'report_resolved');
      return true;
    } catch (e) {
      debugPrint('[AdminService] resolveReport HATA: $e');
      return false;
    }
  }

  /// Raporu reddeder ve raporlayana bildirim gönderir.
  Future<bool> dismissReport(String reportId, String reporterId) async {
    if (!await isCurrentUserAdmin()) return false;
    try {
      await _supabase.from('reports').update({
        'status': 'dismissed',
        'resolved_by': currentUserId,
        'resolved_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', reportId);
      
      await _sendAdminNotification(reporterId, 'report_dismissed');
      return true;
    } catch (e) {
      debugPrint('[AdminService] dismissReport HATA: $e');
      return false;
    }
  }

  /// Bekleyen rapor sayısını döndürür.
  Future<int> getPendingReportCount() async {
    if (!await isCurrentUserAdmin()) return 0;
    try {
      final res = await _supabase
          .from('reports')
          .select('id')
          .eq('status', 'pending');
      return res.length;
    } catch (_) {
      return 0;
    }
  }

  // ═══════════════════════════════════════════════
  // YARDIMCI METHODLAR
  // ═══════════════════════════════════════════════

  Future<void> _sendAdminNotification(String recipientId, String type) async {
    final senderId = _supabase.auth.currentUser?.id;
    if (senderId == null) return;
    
    try {
      await _supabase.from('notifications').insert({
        'recipient_id': recipientId,
        'sender_id': senderId,
        'type': type,
      });
    } catch (e) {
      debugPrint('[AdminService] _sendAdminNotification HATA: $e');
    }
  }

  // ═══════════════════════════════════════════════
  // SİSTEM DUYURULARI (Phase 2)
  // ═══════════════════════════════════════════════

  Future<bool> createAnnouncement(String message, {String type = 'info'}) async {
    if (!await isCurrentUserSuperAdmin()) return false;
    try {
      await _supabase.from('system_announcements').insert({
        'message': message,
        'type': type,
        'created_by': currentUserId,
      });
      return true;
    } catch (e) {
      debugPrint('[AdminService] createAnnouncement HATA: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getActiveAnnouncements() async {
    try {
      final res = await _supabase
          .from('system_announcements')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('[AdminService] getActiveAnnouncements HATA: $e');
      return [];
    }
  }

  Future<bool> deleteAnnouncement(String id) async {
    if (!await isCurrentUserSuperAdmin()) return false;
    try {
      await _supabase.from('system_announcements').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('[AdminService] deleteAnnouncement HATA: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════
  // SHADOWBAN (Phase 2)
  // ═══════════════════════════════════════════════

  Future<bool> shadowbanUser(String targetUserId) async {
    if (!await isCurrentUserSuperAdmin()) return false;
    try {
      await _supabase.from('users').update({
        'is_shadowbanned': true,
      }).eq('id', targetUserId);
      return true;
    } catch (e) {
      debugPrint('[AdminService] shadowbanUser HATA: $e');
      return false;
    }
  }

  Future<bool> unshadowbanUser(String targetUserId) async {
    if (!await isCurrentUserSuperAdmin()) return false;
    try {
      await _supabase.from('users').update({
        'is_shadowbanned': false,
      }).eq('id', targetUserId);
      return true;
    } catch (e) {
      debugPrint('[AdminService] unshadowbanUser HATA: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════
  // EDITOR'S CHOICE (Phase 2)
  // ═══════════════════════════════════════════════

  Future<bool> toggleEditorsChoice(String postId, bool isChoice) async {
    if (!await isCurrentUserAdmin()) return false;
    try {
      await _supabase.from('posts').update({
        'is_editors_choice': isChoice,
      }).eq('id', postId);
      return true;
    } catch (e) {
      debugPrint('[AdminService] toggleEditorsChoice HATA: $e');
      return false;
    }
  }

  /// Cache'i temizler (profil değişikliklerinden sonra).
  void clearCache() {
    _cachedProfile = null;
    _cacheTime = null;
  }
}
