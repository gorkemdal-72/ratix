import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/push_notification_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Kullanıcı oturum durumunu dinlemek için stream (Login mi değil mi?)
  Stream<User?> get authStateChanges => _supabase.auth.onAuthStateChange.map((event) => event.session?.user);

  // Mevcut kullanıcıyı getir
  User? get currentUser => _supabase.auth.currentUser;

  // Çıkış yap
  Future<void> signOut() async {
    try {
      await PushNotificationService().deleteToken();
    } catch (_) {}
    await _supabase.auth.signOut();
  }

  // Kayıt Olma (Sign Up)
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    try {
      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': name, 'username': username},
        emailRedirectTo: 'io.supabase.ratix://login-callback',
      );
      
      if (res.user != null) {
        try {
          // upsert kullanarak profil oluştur/güncelle (trigger yoksa bile çalışır)
          await _supabase.from('users').upsert({
            'id': res.user!.id,
            'email': email,
            'display_name': name,
            'username': username,
          }, onConflict: 'id');
        } catch (e) {
          // Eğer e-posta doğrulaması açıksa, kullanıcı henüz oturum açmamış sayılır 
          // ve RLS (Row Level Security) nedeniyle tabloya yazma işlemi hata verir.
          // Bu hatayı yutuyoruz; çünkü ilk girişte ensureUserProfile() metodu profil tablosunu güncelleyecek.
          debugPrint('Kayıt sırasında profil oluşturulamadı (RLS veya Auth nedeniyle). Giriş yapıldığında denenecek: $e');
        }
      }
      return null; // Success
    } on AuthException catch (e) {
      if (e.message.contains('confirmation email') || e.message.contains('unexpected_failure')) {
        return 'Kayıt başarılı! Ancak doğrulama e-postası gönderilemedi. Lütfen tekrar deneyin veya yöneticiye başvurun.';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// Giriş sonrası kullanıcı profilinin users tablosunda mevcut olduğundan emin ol.
  /// Auth metadata'dan display_name ve username alıp upsert yapar.
  Future<void> ensureUserProfile() async {
    final user = currentUser;
    if (user == null) return;

    try {
      // Önce profil var mı kontrol et
      final existing = await _supabase
          .from('users')
          .select('id, username')
          .eq('id', user.id)
          .maybeSingle();

      // Profil yoksa veya username boşsa, auth metadata'dan oluştur/güncelle
      if (existing == null || existing['username'] == null || (existing['username'] as String).isEmpty) {
        final meta = user.userMetadata ?? {};
        final displayName = meta['display_name'] as String? ?? meta['full_name'] as String? ?? user.email?.split('@').first ?? '';
        final username = meta['username'] as String? ?? '';

        if (username.isNotEmpty) {
          await _supabase.from('users').upsert({
            'id': user.id,
            'email': user.email,
            'display_name': displayName,
            'username': username,
          }, onConflict: 'id');
        }
      }
    } catch (_) {
      // Sessizce hata yut; profil sync kritik değil
    }
  }

  // Giriş Yapma (Sign In)
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      await ensureUserProfile();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // Şifre Sıfırlama (Reset Password)
  Future<String?> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // 6 Haneli Şifre Sıfırlama Kodunu Doğrula (OTP)
  Future<String?> verifyRecoveryOTP(String email, String token) async {
    try {
      await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // Doğrulama E-postası Yeniden Gönder
  Future<String?> resendVerificationEmail(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // Kullanıcı Adı Benzersizlik Kontrolü
  Future<bool> checkUsernameAvailable(String username) async {
    final res = await _supabase.from('user_social_profiles_view').select('id').eq('username', username).maybeSingle();
    return res == null;
  }
}