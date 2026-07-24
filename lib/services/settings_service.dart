import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String get _uid {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw Exception('Oturum açık değil');
    return id;
  }

  // Kullanıcının mevcut ayarlarını güncelleme fonksiyonu
  Future<void> updateRatingPreference(String preference) async {
    try {
      final user = await getUserData();
      final prefs = (user?['preferences'] as Map<String, dynamic>?) ?? {};
      prefs['defaultRatingType'] = preference;
      
      await _supabase.from('users').update({
        'preferences': prefs
      }).eq('id', _uid);
    } catch (e) {
      debugPrint('Ayarlar güncellenemedi: $e');
    }
  }

  // Tema tercihini güncelle 
  Future<void> updateThemePreference(bool preference) async {
    try {
      final user = await getUserData();
      final prefs = (user?['preferences'] as Map<String, dynamic>?) ?? {};
      prefs['defaultTheme'] = preference;
      
      await _supabase.from('users').update({
        'preferences': prefs
      }).eq('id', _uid);
    } catch (e) {
      debugPrint('Tema güncellenemedi: $e');
    }
  }

  // Günlük Gizliliğini güncelle
  Future<void> updateDiaryVisibility(String visibility) async {
    try {
      await _supabase.from('users').update({
        'diary_visibility': visibility
      }).eq('id', _uid);
    } catch (e) {
      debugPrint('Gizlilik güncellenemedi: $e');
    }
  }

  // Profil bilgilerini güncelleme
  Future<void> updateProfileInfo(String displayName, String bio) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'display_name': displayName,
          }
        ),
      );
      
      await _supabase.from('users').update({
        'display_name': displayName,
        'bio': bio,
      }).eq('id', _uid);
    } catch (e) {
      debugPrint('Profil güncellenemedi: $e');
    }
  }

  // Kullanıcı verilerini veritabanından oku
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final data = await _supabase.from('users').select().eq('id', _uid).maybeSingle();
      return data;
    } catch (e) {
      debugPrint('Kullanıcı verisi alınamadı: $e');
      return null;
    }
  }
}