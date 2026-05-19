import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category_model.dart';
import '../models/item_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Şu anki kullanıcının 'categories' koleksiyonuna erişim
  CollectionReference get _categoriesRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("Kullanıcı oturum açmamış.");
    return _firestore.collection('users').doc(uid).collection('categories');
  }

  // Kategori Listesini Canlı Dinle (Stream)
  Stream<List<CategoryModel>> getCategoriesStream() {
    try {
      return _categoriesRef
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CategoryModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
      }).handleError((error) {
        // ignore: avoid_print
        print('[DatabaseService] getCategoriesStream HATA: $error');
      });
    } catch (e) {
      // ignore: avoid_print
      print('[DatabaseService] getCategoriesStream exception: $e');
      return const Stream.empty();
    }
  }

  // Kategori Ekle
  Future<String?> addCategory(CategoryModel category) async {
    try {
      await _categoriesRef.add(category.toMap());
      return null; // başarılı
    } catch (e) {
      // ignore: avoid_print
      print('[DatabaseService] addCategory HATA: $e');
      return e.toString();
    }
  }

  // Kategori Sil
  Future<String?> deleteCategory(String categoryId) async {
    try {
      await _categoriesRef.doc(categoryId).delete();
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('[DatabaseService] deleteCategory HATA: $e');
      return e.toString();
    }
  }

  // Kategoriyi Düzenle (İsim ve Emoji)
  Future<String?> updateCategory(String categoryId, String newName, String newIcon) async {
    try {
      await _categoriesRef.doc(categoryId).update({
        'name': newName,
        'icon': newIcon,
      });
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('[DatabaseService] updateCategory HATA: $e');
      return e.toString();
    }
  }

  CollectionReference _getItemsRef(String categoryId) {
    return _categoriesRef.doc(categoryId).collection('items');
  }

  // Item Listesini Getir
  Stream<List<ItemModel>> getItemsStream(String categoryId) {
    try {
      return _getItemsRef(categoryId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return ItemModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
      }).handleError((error) {
        // ignore: avoid_print
        print('[DatabaseService] getItemsStream HATA: $error');
      });
    } catch (e) {
      // ignore: avoid_print
      print('[DatabaseService] getItemsStream exception: $e');
      return const Stream.empty();
    }
  }

  // Item içeriğini Düzenle
  Future<String?> updateItem(String categoryId, String itemId, String newTitle, String newDescription) async {
    try {
      await _getItemsRef(categoryId).doc(itemId).update({
        'title': newTitle,
        'description': newDescription,
      });
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('[DatabaseService] updateItem HATA: $e');
      return e.toString();
    }
  }

  // Item Ekle
  Future<String?> addItem(String categoryId, ItemModel item) async {
    try {
      await _getItemsRef(categoryId).add(item.toMap());
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('[DatabaseService] addItem HATA: $e');
      return e.toString();
    }
  }

  // Item Puanını Güncelle
  Future<String?> updateItemRating(String categoryId, String itemId, double newRating) async {
    try {
      await _getItemsRef(categoryId).doc(itemId).update({
        'rating': newRating,
      });
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('[DatabaseService] updateItemRating HATA: $e');
      return e.toString();
    }
  }

  // Item Sil
  Future<String?> deleteItem(String categoryId, String itemId) async {
    try {
      await _getItemsRef(categoryId).doc(itemId).delete();
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('[DatabaseService] deleteItem HATA: $e');
      return e.toString();
    }
  }

  // Item Favori Durumunu Güncelle
  Future<String?> toggleFavorite(String categoryId, String itemId, bool currentStatus) async {
    try {
      await _getItemsRef(categoryId).doc(itemId).update({
        'isFavorite': !currentStatus,
      });
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('[DatabaseService] toggleFavorite HATA: $e');
      return e.toString();
    }
  }
  // Item �zleme Durumunu G�ncelle (watched / watching / watchlist)
  Future<String?> updateItemStatus(String categoryId, String itemId, String newStatus) async {
    try {
      await _getItemsRef(categoryId).doc(itemId).update({
        'watchStatus': newStatus,
      });
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('[DatabaseService] updateItemStatus HATA: $e');
      return e.toString();
    }
  }
}