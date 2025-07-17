import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/constant/categories.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/models/customer.dart';

class AdvertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final CollectionReference _eventsCollection =
      FirebaseFirestore.instance.collection('events');

  final CollectionReference _customersCollection =
      FirebaseFirestore.instance.collection('customers');

  // Şehre göre tüm ilanları getir
  Future<List<Advert>> fetchAdvertsByCity(String? city) async {
    try {
      final upperCity = city;
      debugPrint('Aranan şehir: $upperCity');

      // Temel sorgu - isCreatorPremium alanına göre önce sırala sonra createdAt
      final query = _firestore
          .collection('events')
          .where('location.city', isEqualTo: upperCity)
          .orderBy('isCreatorPremium', descending: true) // Premium ilanlar önce
          .orderBy('createdAt',
              descending: true); // Aynı premium durumunda yeni ilanlar önce

      final querySnapshot = await query.get();
      final adverts = querySnapshot.docs
          .map((doc) => Advert.fromJson(doc.data(), doc.id))
          .toList();

      debugPrint('Bulunan ilan sayısı: ${adverts.length}');
      return adverts;
    } catch (e) {
      debugPrint('Şehre göre ilanlar çekilirken hata: $e');
      return [];
    }
  }

  // İlgi alanlarına göre tüm ilanları getir
  Future<List<Advert>> fetchAdvertsByInterests(
      List<Categories>? interests) async {
    try {
      // İlgi alanı yoksa boş liste döndür
      if (interests == null || interests.isEmpty) {
        return [];
      }

      // Kategorileri string olarak al
      final categoryValues =
          interests.map((interest) => interest.name).toList();
      debugPrint('Aranan kategoriler: $categoryValues');

      // GERÇEK ÇÖZÜM: Firestore'un kısıtlamalarından dolayı tek sorguda tüm kategorileri alamayız
      // En fazla whereIn ile 10 kategori alabiliriz
      List<String> categoriesToQuery = categoryValues.length > 10
          ? categoryValues.sublist(0, 10)
          : categoryValues;

      // Tek sorgu oluştur - 10'dan fazla kategori varsa ilk 10'unu al
      final query = _firestore
          .collection('events')
          .where('advertType', whereIn: categoriesToQuery)
          .orderBy('isCreatorPremium', descending: true) // Premium ilanlar önce
          .orderBy('createdAt',
              descending: true); // Aynı premium durumunda yeni ilanlar önce

      // Sorguyu çalıştır
      final querySnapshot = await query.get();
      final adverts = querySnapshot.docs
          .map((doc) => Advert.fromJson(doc.data(), doc.id))
          .toList();

      debugPrint('Bulunan ilan sayısı: ${adverts.length}');
      return adverts;
    } catch (e) {
      debugPrint('İlgi alanlarına göre ilanlar çekilirken hata: $e');
      debugPrint('Hata detayı: $e');
      return [];
    }
  }

  // Cinsiyet ve kategoriye göre esnek filtreleme ile ilanları getir
  Future<List<Advert>> fetchAdvertsByFiltering({
    DocumentSnapshot? lastDocument,
    int limit = 25,
    String? gender,
    String? category,
  }) async {
    try {
      // Temel sorgu
      var query = _firestore.collection('events').limit(1000);

      // Cinsiyet filtresi ekle (eğer belirtilmişse)
      if (gender != null && gender.isNotEmpty) {
        query = query.where('creatorGender', isEqualTo: gender);
      }

      // Kategori filtresi ekle (eğer belirtilmişse)
      if (category != null && category.isNotEmpty) {
        query = query.where('advertType', isEqualTo: category);
      }

      // Sıralama ve pagination - Premium ilanlar önce
      query = query
          .orderBy('isCreatorPremium', descending: true)
          .orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      // Sorguyu çalıştır
      final querySnapshot = await query.get();
      final adverts = querySnapshot.docs
          .map((doc) => Advert.fromJson(doc.data(), doc.id))
          .toList();

      debugPrint('Filtrelenmiş ilan sayısı: ${adverts.length}');
      return adverts;
    } catch (e) {
      debugPrint('Filtrelenmiş ilanlar çekilirken hata: $e');
      return [];
    }
  }

  Future<List<Advert>> fetchOtherAdverts({
    Customer? user,
  }) async {
    try {
      // Tüm ilanları sırala: Önce premium olanlar, sonra en yeniler
      final querySnapshot = await _firestore
          .collection('events')
          .orderBy('isCreatorPremium', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      final allAdverts = querySnapshot.docs
          .map((doc) => Advert.fromJson(doc.data(), doc.id))
          .toList();

      debugPrint('Toplam çekilen ilan sayısı: ${allAdverts.length}');

      // Kullanıcı yoksa veya filtre verisi boşsa tüm ilanları döndür
      if (user == null ||
          user.favoriteCategories == null ||
          user.favoriteCategories!.isEmpty) {
        return allAdverts;
      }

      final filtered = allAdverts.where((advert) {
        final isDifferentCity = advert.location.city != user.location?.city;
        final isNotInInterest = !user.favoriteCategories!
            .any((cat) => cat.name == advert.advertType.name);
        return isDifferentCity && isNotInInterest;
      }).toList();

      debugPrint('Filtrelenmiş other ilan sayısı: ${filtered.length}');
      return filtered;
    } catch (e) {
      debugPrint('Other ilanlar çekilirken hata: $e');
      return [];
    }
  }

  // Takip edilen kişilerin ilanlarını getir
  Future<List<Advert>> fetchFollowingUserAdverts(
      List<String>? followingIds) async {
    try {
      // Takip edilen kişi yoksa boş liste döndür
      if (followingIds == null || followingIds.isEmpty) {
        return [];
      }

      debugPrint('Takip edilen kullanıcı sayısı: ${followingIds.length}');

      // Firestore'da whereIn sorgusu en fazla 10 öğe ile çalışır
      // Bu yüzden takip edilen kişileri 10'arlı gruplar halinde sorgulamalıyız
      List<Advert> allAdverts = [];

      // Takip edilen kişileri 10'arlı gruplara böl
      for (int i = 0; i < followingIds.length; i += 10) {
        final endIndex =
            (i + 10 < followingIds.length) ? i + 10 : followingIds.length;
        final batch = followingIds.sublist(i, endIndex);

        // Bu gruptaki kullanıcıların ilanlarını sorgula
        final query = _firestore
            .collection('events')
            .where('creatorUserID', whereIn: batch)
            .orderBy('isCreatorPremium',
                descending: true) // Premium ilanlar önce
            .orderBy('createdAt',
                descending: true); // Aynı premium durumunda yeni ilanlar önce

        final querySnapshot = await query.get();
        final batchAdverts = querySnapshot.docs
            .map((doc) => Advert.fromJson(doc.data(), doc.id))
            .toList();

        allAdverts.addAll(batchAdverts);
      }

      debugPrint(
          'Takip edilen kişilerin toplam ilan sayısı: ${allAdverts.length}');
      return allAdverts;
    } catch (e) {
      debugPrint('Takip edilen kişilerin ilanları çekilirken hata: $e');
      return [];
    }
  }

// İlan adverts koleksiyonlarında arar
  Future<Advert?> fetchAdvertById(String advertID) async {
    try {
      // Önce events koleksiyonunda ara
      DocumentSnapshot eventSnapshot =
          await _eventsCollection.doc(advertID).get();
      if (eventSnapshot.exists) {
        return Advert.fromJson(
            eventSnapshot.data() as Map<String, dynamic>, advertID);
      }

      return null;
    } catch (e) {
      debugPrint('İlan arama hatası: $e');
      return null;
    }
  }

  /// İlan beğen
  Future<void> likeAdvert({
    required String advertId,
    required String userId,
  }) async {
    final eventRef = _eventsCollection.doc(advertId);
    final userRef = _customersCollection.doc(userId);

    try {
      await _firestore.runTransaction((tx) async {
        tx.update(eventRef, {
          'likers': FieldValue.arrayUnion([userId]),
        });
        tx.update(userRef, {
          'favoriteAdverts': FieldValue.arrayUnion([advertId]),
        });
      });
    } catch (e) {
      debugPrint('İlan beğenme hatası: $e');
      rethrow; // UI'da snackbar göstermek için
    }
  }

  /// İlan beğeniyi kaldır
  Future<void> unlikeAdvert({
    required String advertId,
    required String userId,
  }) async {
    final eventRef = _eventsCollection.doc(advertId);
    final userRef = _customersCollection.doc(userId);

    try {
      await _firestore.runTransaction((tx) async {
        tx.update(eventRef, {
          'likers': FieldValue.arrayRemove([userId]),
        });
        tx.update(userRef, {
          'favoriteAdverts': FieldValue.arrayRemove([advertId]),
        });
      });
    } catch (e) {
      debugPrint('İlan beğeni kaldırma hatası: $e');
      rethrow;
    }
  }

  Future<void> deleteAdvert(String advertId, String userId) async {
    try {
      final batch = _firestore.batch();
      batch.delete(_eventsCollection.doc(advertId));
      batch.update(_customersCollection.doc(userId), {
        'adverts': FieldValue.arrayRemove([advertId])
      });

      await batch.commit();
      debugPrint('İlan başarıyla silindi');
    } catch (e) {
      debugPrint('İlan silme hatası: $e');
      rethrow;
    }
  }

  Future<void> sendJoinRequest(String advertId, String userId) async {
    try {
      final eventRef = _eventsCollection.doc(advertId);
      final userRef = _customersCollection.doc(userId);

      await _firestore.runTransaction((tx) async {
        tx.update(eventRef, {
          'joinRequestIds': FieldValue.arrayUnion([userId]),
          'joinRequestAcceptedIds': FieldValue.arrayRemove([userId]),
        });
        tx.update(userRef, {
          'joinRequestAdverts': FieldValue.arrayUnion([advertId]),
          'joinedAdvertIds': FieldValue.arrayRemove([advertId]),
        });
      });
    } catch (e) {
      debugPrint('Katılım isteği gönderme hatası: $e');
      rethrow;
    }
  }

  Future<void> acceptJoinRequest(String advertId, String userId) async {
    final WriteBatch batch = _firestore.batch();
    final eventRef = _eventsCollection.doc(advertId);
    final userRef = _customersCollection.doc(userId);

    batch.update(eventRef, {
      'joinRequestIds': FieldValue.arrayRemove([userId]),
      'joinRequestAcceptedIds': FieldValue.arrayUnion([userId]),
    });

    batch.update(userRef, {
      'joinedAdvertIds': FieldValue.arrayUnion([advertId]),
    });

    await batch.commit();
  }

  Future<void> rejectJoinRequest(String advertId, String userId) async {
    final WriteBatch batch = _firestore.batch();
    final eventRef = _eventsCollection.doc(advertId);
    final userRef = _customersCollection.doc(userId);

    batch.update(eventRef, {
      'joinRequestIds': FieldValue.arrayRemove([userId]),
      'joinRequestAcceptedIds': FieldValue.arrayRemove([userId]),
    });

    batch.update(userRef, {
      'joinedAdvertIds': FieldValue.arrayRemove([advertId]),
    });

    await batch.commit();
  }

  Future<void> leaveJoinedAdvert(String advertId, String userId) async {
    final WriteBatch batch = _firestore.batch();
    final eventRef = _eventsCollection.doc(advertId);
    final userRef = _customersCollection.doc(userId);

    batch.update(eventRef, {
      'joinRequestAcceptedIds': FieldValue.arrayRemove([userId]),
    });

    batch.update(userRef, {
      'joinedAdvertIds': FieldValue.arrayRemove([advertId]),
    });

    await batch.commit();
  }
}
