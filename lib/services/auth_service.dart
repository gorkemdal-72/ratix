import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı oturum durumunu dinlemek için stream (Login mi değil mi?)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Mevcut kullanıcıyı getir
  User? get currentUser => _auth.currentUser;

  // Kayıt Olma (Sign Up)
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // 1. Auth oluştur
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = result.user;

      // 2. Firestore'a kullanıcı bilgilerini yaz
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'displayName': name,
          'createdAt': FieldValue.serverTimestamp(),
          'preferences': {
            'defaultRatingType': 'stars', // Varsayılan ayar
          }
        });
        
        // Auth profilindeki ismi de güncelle
        await user.updateDisplayName(name);
        
        // E-posta doğrulama maili gönder
        await user.sendEmailVerification();
      }
      
      return null; // Hata yok, başarıyla kayıt olundu
    } on FirebaseAuthException catch (e) {
      return e.message; // Hata mesajını döndür
    }
  }

  // Giriş Yapma (Sign In)
  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Başarılı
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // Çıkış Yapma (Sign Out)
  Future<void> signOut() async {
    await _auth.signOut();
  }
}