import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcının mevcut ayarlarını güncelleme fonksiyonu
  Future<void> updateRatingPreference(String preference) async {
    User? user = _auth.currentUser;
    if (user != null) {
      // 'preferences' map'inin tamamını değil, SADECE 'defaultRatingType' alanını günceller
      await _firestore.collection('users').doc(user.uid).update({
        'preferences.defaultRatingType': preference, 
      });
    }
  }

  // Tema tercihini güncelle 
  Future<void> updateThemePreference(bool preference) async {
      User? user = _auth.currentUser;
       if (user != null) {

         await _firestore.collection('users').doc(user.uid).update({
            'preferences.defaultTheme': preference,
         });
       }
  }

  // Profil bilgilerini güncelleme
  Future<void> updateProfileInfo(String displayName, String bio) async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Auth profilini güncelle
      await user.updateDisplayName(displayName);
      
      // Firestore'a detaylı bilgi yaz
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': displayName,
        'bio': bio,
      }, SetOptions(merge: true));
    }
  }
    // Kullanıcı verilerini veritabanından oku
  Future<Map<String, dynamic>?> getUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
    }
    return null;
  }
}