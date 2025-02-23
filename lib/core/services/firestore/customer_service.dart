import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/models/customer.dart';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// Kullanıcıyı günceller veya yeni bir kullanıcı oluşturur
  Future<void> updateCustomer(String uuid, Customer customer) async {
    try {
      final docRef = _firestore.collection("customers").doc(uuid);

      // Belgeyi güncelle veya oluştur
      await docRef.set(customer.toJson(), SetOptions(merge: true));

      debugPrint('Kullanıcı başarıyla güncellendi: $uuid');
    } on FirebaseException catch (e) {
      debugPrint('Firestore hatası: ${e.message}');
      throw Exception('Kullanıcı güncelleme başarısız: ${e.message}');
    } catch (e) {
      debugPrint('Beklenmeyen hata: $e');
      throw Exception('Kullanıcı güncelleme başarısız: $e');
    }
  }

  // Firestore'dan kullanıcı verisini çeker
  Future<Customer?> fetchUserFromFirestore(String uid) async {
    try {
      final userDocument = await _firestore.collection("customers").doc(uid).get();
      return userDocument.exists ? Customer.fromJson(userDocument.data()!, uid) : null; // Kullanıcı verisi varsa Customer nesnesi döner
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<void> likeAdvert(String advertId, String userId) async {
    await _firestore.collection('customers').doc(userId).update({
      'favoriteAdverts': FieldValue.arrayUnion([advertId])
    });
  }

  Future<void> unlikeAdvert(String advertId, String userId) async {
    await _firestore.collection('customers').doc(userId).update({
      'favoriteAdverts': FieldValue.arrayRemove([advertId])
    });
  }

  // Silinen ilanlara ait referansları kullanıcılardan temizle
  Future<void> cleanupDeletedAdvertReferences() async {
    try {
      // Mevcut tüm ilan ID'lerini al
      final advertsSnapshot = await _firestore.collection('adverts').get();
      final existingAdvertIds = advertsSnapshot.docs.map((doc) => doc.id).toSet();

      // Tüm kullanıcıları çek
      final customersSnapshot = await _firestore.collection('customers').get();

      // Batch işlemi başlat
      final batch = _firestore.batch();
      var updatedCount = 0;

      for (var customerDoc in customersSnapshot.docs) {
        final data = customerDoc.data();

        // Kullanıcının ilan listelerini al
        List<String> adverts = List<String>.from(data['adverts'] ?? []);
        List<String> favoriteAdverts = List<String>.from(data['favoriteAdverts'] ?? []);

        // Silinmiş ilanları filtrele
        final newAdverts = adverts.where((id) => existingAdvertIds.contains(id)).toList();
        final newFavorites = favoriteAdverts.where((id) => existingAdvertIds.contains(id)).toList();

        // Eğer herhangi bir değişiklik varsa güncelle
        if (adverts.length != newAdverts.length || favoriteAdverts.length != newFavorites.length) {
          batch.update(customerDoc.reference, {
            'adverts': newAdverts,
            'favoriteAdverts': newFavorites,
          });

          updatedCount++;
        }
      }

      // Batch işlemini uygula
      await batch.commit();
      debugPrint('$updatedCount kullanıcının ilan referansları temizlendi');
    } catch (e) {
      debugPrint('Kullanıcı ilan referansları temizlenirken hata: $e');
    }
  }

  // Kullanıcı bilgilerini stream olarak al
  Stream<Customer?> getUserStream(String userId) {
    return _firestore
        .collection('customers')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.data() != null ? Customer.fromJson(snapshot.data()!, userId) : null);
  }

  Future<void> addComment(String userId, Comment comment) async {
    try {
      await _firestore.collection('customers').doc(userId).update({
        'comments': FieldValue.arrayUnion([comment.toJson()])
      });
      debugPrint('Yorum başarıyla eklendi');
    } catch (e) {
      debugPrint('Yorum eklenirken hata oluştu: $e');
      throw Exception('Yorum eklenemedi: $e');
    }
  }

  Future<void> deleteComment(String userId, Comment comment) async {
    try {
      await _firestore.collection('customers').doc(userId).update({
        'comments': FieldValue.arrayRemove([comment.toJson()])
      });
      debugPrint('Yorum başarıyla silindi');
    } catch (e) {
      debugPrint('Yorum silinirken hata oluştu: $e');
      throw Exception('Yorum silinemedi: $e');
    }
  }

  Future<void> reportComment(String userId, Comment comment) async {
    try {
      await _firestore.collection('reports').doc(userId).update({
        'reportedComments': FieldValue.arrayUnion([comment.toJson()])
      });

      debugPrint('Yorum başarıyla şikayet edildi');
    } catch (e) {
      debugPrint('Yorum şikayet edilirken hata oluştu: $e');
      throw Exception('Yorum şikayet edilemedi: $e');
    }
  }
}
