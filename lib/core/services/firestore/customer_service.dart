import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/constant/categories.dart';
import 'package:palseapp/core/models/comment_model.dart';
import 'package:palseapp/core/models/customer.dart';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateCustomerSubscription(String uuid, bool isPremium) async {
    try {
      await _firestore.collection("customers").doc(uuid).update({'isPremium': isPremium});
    } catch (e) {
      debugPrint('Kullanıcı abonelik güncellenirken hata: $e');
    }
  }

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

  Future<void> updateCustomerCategories(String uuid, List<Categories> categories) async {
    try {
      await _firestore.collection("customers").doc(uuid).update({'favoriteCategories': categories.map((category) => category.name).toList()});
    } catch (e) {
      debugPrint('Kullanıcı kategorileri güncellenirken hata: $e');
      throw Exception('Kullanıcı kategorileri güncellenemedi: $e');
    }
  }

  Future<void> updateCustomerVerifiedAndPhone(String uuid, bool verified, String phone) async {
    try {
      await _firestore.collection("customers").doc(uuid).update({'verification': verified, 'phoneNumber': phone});
    } catch (e) {
      debugPrint('Kullanıcı doğrulama güncellenirken hata: $e');
      throw Exception('Kullanıcı doğrulama güncellenemedi: $e');
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

  // Kullanıcı bilgilerini getirir - getCustomer metodu
  Future<Customer?> getCustomer(String userId) async {
    try {
      final userDocument = await _firestore.collection("customers").doc(userId).get();
      if (userDocument.exists) {
        return Customer.fromJson(userDocument.data()!, userId);
      }
      debugPrint('Kullanıcı bulunamadı: $userId');
      return null;
    } catch (e) {
      debugPrint('Kullanıcı bilgileri getirme hatası: $e');
      return null;
    }
  }

  Future<void> likeAdvert(String advertId, String userId) async {
    try {
      await _firestore.collection('customers').doc(userId).update({
        'favoriteAdverts': FieldValue.arrayUnion([advertId])
      });
    } catch (e) {
      debugPrint('İlan beğenme hatası: $e');
    }
  }

  Future<void> unlikeAdvert(String advertId, String userId) async {
    try {
      await _firestore.collection('customers').doc(userId).update({
        'favoriteAdverts': FieldValue.arrayRemove([advertId])
      });
    } catch (e) {
      debugPrint('İlan beğenme hatası: $e');
    }
  }

  Future<void> deleteAdvertFromCustomer(String advertId, String userId) async {
    try {
      await _firestore.collection('customers').doc(userId).update({
        'adverts': FieldValue.arrayRemove([advertId])
      });
      debugPrint('İlan başarıyla silindi');
    } catch (e) {
      debugPrint('İlan silme hatası: $e');
    }
  }

  // Silinen ilanlara ait referansları kullanıcılardan temizle
  Future<void> cleanupDeletedAdvertReferences() async {
    try {
      // Mevcut tüm ilan ID'lerini al
      final advertsSnapshot = await _firestore.collection('events').get();
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

  // Firestore verilerini stream olarak dinleme
  Stream<DocumentSnapshot<Object?>> streamFirestore(String userId) {
    return _firestore.collection('customers').doc(userId).snapshots();
  }

  Future<void> updateUserLastSeen(String userId) async {
    try {
      await _firestore.collection('customers').doc(userId).update({'lastSeen': Timestamp.now()});
    } catch (e) {
      debugPrint('Kullanıcı görünümü güncellenirken hata: $e');
    }
  }

  Future<void> resetFcmToken(String userId) async {
    try {
      await _firestore.collection('customers').doc(userId).update({'fcmToken': null});
    } catch (e) {
      debugPrint('Kullanıcı görünümü güncellenirken hata: $e');
    }
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

  /// Kullanıcı bilgilerini günceller
  Future<void> updateUser(String uuid, Customer user) async {
    await _firestore.collection('customers').doc(uuid).update(user.toJson());
  }

  Future<void> deleteAccount(String uuid) async {
    try {
      await _firestore.collection('customers').doc(uuid).delete();
    } catch (e) {
      debugPrint('Kullanıcı silinirken hata oluştu: $e');
      throw Exception('Kullanıcı silinemedi: $e');
    }
  }

  // Kullanıcının sohbetini siler
  Future<void> deleteChat(String userId, String otherUserId) async {
    try {
      // Kullanıcı belgesini al
      final userDoc = await _firestore.collection('customers').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('Kullanıcı bulunamadı');
      }

      // chatMap'i al
      final userData = userDoc.data();
      if (userData == null || userData['chatMap'] == null) {
        throw Exception('Sohbet bilgisi bulunamadı');
      }

      // chatMap'ten ilgili sohbeti çıkar
      final Map<String, dynamic> chatMap = Map<String, dynamic>.from(userData['chatMap']);

      // Doğrudan key (otherUserId) kullanarak sohbeti sil
      if (chatMap.containsKey(otherUserId)) {
        chatMap.remove(otherUserId);

        // Firestore'u güncelle
        await _firestore.collection('customers').doc(userId).update({'chatMap': chatMap});

        debugPrint('Sohbet başarıyla silindi: $otherUserId');
      } else {
        debugPrint('Silinecek sohbet bulunamadı: $otherUserId');
      }
    } catch (e) {
      debugPrint('Sohbet silinirken hata oluştu: $e');
      throw Exception('Sohbet silinemedi: $e');
    }
  }

  Future<void> addProfileViewers(String userId, String currentUserId) async {
    try {
      await _firestore.collection('customers').doc(userId).set({
        'profileViewers': FieldValue.arrayUnion([currentUserId])
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Kullanıcı görünümü güncellenirken hata: $e');
    }
  }
}
