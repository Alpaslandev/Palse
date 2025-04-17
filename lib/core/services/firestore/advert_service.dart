import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/constant/categories.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/notification_service.dart';

class AdvertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService notificationService = NotificationService();

  // Şehre göre ilanları getir (index gerekmeden)
  Future<List<Advert>> fetchAdvertsByCity(
    String? city, {
    DocumentSnapshot? lastDocument,
    int limit = 25,
  }) async {
    try {
      final upperCity = city;
      debugPrint('Aranan şehir: $upperCity, limit: $limit');

      // Temel sorgu - isCreatorPremium alanına göre önce sırala sonra createdAt
      var query = _firestore
          .collection('events')
          .where('location.city', isEqualTo: upperCity)
          .orderBy('isCreatorPremium', descending: true) // Premium ilanlar önce
          .orderBy('createdAt', descending: true) // Aynı premium durumunda yeni ilanlar önce
          .limit(limit);

      // Eğer son döküman varsa, ondan sonrasını getir
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();
      final adverts = querySnapshot.docs.map((doc) => Advert.fromJson(doc.data(), doc.id)).toList();

      debugPrint('Bulunan ilan sayısı: ${adverts.length}');
      return adverts;
    } catch (e) {
      debugPrint('Şehre göre ilanlar çekilirken hata: $e');
      return [];
    }
  }

  // İlgi alanlarına göre ilanları getir
  Future<List<Advert>> fetchAdvertsByInterests(List<Categories>? interests, {DocumentSnapshot? lastDocument, int limit = 25}) async {
    try {
      // İlgi alanı yoksa boş liste döndür
      if (interests == null || interests.isEmpty) {
        return [];
      }

      // Kategorileri string olarak al
      final categoryValues = interests.map((interest) => interest.name).toList();
      debugPrint('Aranan kategoriler: $categoryValues');

      // GERÇEK ÇÖZÜM: Firestore'un kısıtlamalarından dolayı tek sorguda tüm kategorileri alamayız
      // En fazla whereIn ile 10 kategori alabiliriz
      List<String> categoriesToQuery = categoryValues.length > 10 ? categoryValues.sublist(0, 10) : categoryValues;

      // Tek sorgu oluştur - 10'dan fazla kategori varsa ilk 10'unu al
      var query = _firestore
          .collection('events')
          .where('advertType', whereIn: categoriesToQuery)
          .orderBy('isCreatorPremium', descending: true) // Premium ilanlar önce
          .orderBy('createdAt', descending: true) // Aynı premium durumunda yeni ilanlar önce
          .limit(limit);

      // Pagination için
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      // Sorguyu çalıştır
      final querySnapshot = await query.get();
      final adverts = querySnapshot.docs.map((doc) => Advert.fromJson(doc.data(), doc.id)).toList();

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
      query = query.orderBy('isCreatorPremium', descending: true).orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      // Sorguyu çalıştır
      final querySnapshot = await query.get();
      final adverts = querySnapshot.docs.map((doc) => Advert.fromJson(doc.data(), doc.id)).toList();

      debugPrint('Filtrelenmiş ilan sayısı: ${adverts.length}');
      return adverts;
    } catch (e) {
      debugPrint('Filtrelenmiş ilanlar çekilirken hata: $e');
      return [];
    }
  }

  // Other sekmesi için ilanları getir - Kullanıcının şehrinde ve ilgi alanlarında olmayan ilanlar
  Future<List<Advert>> fetchOtherAdverts({
    DocumentSnapshot? lastDocument,
    int limit = 25,
    Customer? user,
  }) async {
    try {
      // Kullanıcı null ise veya favoriteCategories null/boş ise doğrudan tüm ilanları getir
      if (user == null || user.favoriteCategories == null || user.favoriteCategories!.isEmpty) {
        // Temel sorgu: Tüm ilanları getir
        var query = _firestore.collection('events').orderBy('isCreatorPremium', descending: true).orderBy('createdAt', descending: true).limit(limit);

        // Pagination için
        if (lastDocument != null) {
          query = query.startAfterDocument(lastDocument);
        }

        final querySnapshot = await query.get();
        final adverts = querySnapshot.docs.map((doc) => Advert.fromJson(doc.data(), doc.id)).toList();
        debugPrint('Kategori olmadan çekilen ilan sayısı: ${adverts.length}');
        return adverts;
      }

      // İlgi alanları dışındaki ilanları filtrele
      // Firestore whereNotIn sorgusu en fazla 10 değer alabilir
      var categoryValues = user.favoriteCategories!.map((interest) => interest.name).take(10).toList();

      // Temel sorgu: İlgi alanları dışındaki ilanları çek
      var query = _firestore
          .collection('events')
          .where('advertType', whereNotIn: categoryValues)
          // ÖNEMLİ: whereNotIn kullanıldığında, aynı alan için orderBy gereklidir
          .orderBy('advertType')
          // Önce premium kullanıcıları getir
          .orderBy('isCreatorPremium', descending: true)
          // Sonra oluşturma tarihine göre sırala
          .orderBy('createdAt', descending: true)
          .limit(limit);
      // Pagination için
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      // Sorguyu çalıştır
      final querySnapshot = await query.get();
      final adverts = querySnapshot.docs.map((doc) => Advert.fromJson(doc.data(), doc.id)).toList();

      debugPrint('whereNotIn ile çekilen ilan sayısı: ${adverts.length}');
      return adverts;
    } catch (e) {
      debugPrint('Other ilanlar çekilirken hata: $e');
      // Hata durumunda hatanın tam detayını logla
      debugPrint('Hata detayı: $e');

      // Hata durumunda boş liste döndür
      return [];
    }
  }

// İlan adverts koleksiyonlarında arar
  Future<Advert?> fetchAdvertById(String advertID) async {
    try {
      // Önce events koleksiyonunda ara
      DocumentSnapshot eventSnapshot = await _firestore.collection('events').doc(advertID).get();
      if (eventSnapshot.exists) {
        return Advert.fromJson(eventSnapshot.data() as Map<String, dynamic>, advertID);
      }

      return null;
    } catch (e) {
      debugPrint('İlan arama hatası: $e');
      return null;
    }
  }

  Future<void> likeAdvert(String advertId, String userId, String creatorUserID) async {
    try {
      final docSnapshot = await _firestore.collection('events').doc(advertId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data.containsKey('likers')) {
          await _firestore.collection('events').doc(advertId).update({
            'likers': FieldValue.arrayUnion([userId])
          });
        } else {
          await _firestore.collection('events').doc(advertId).update({
            'likers': [userId]
          });
        }
      }
    } catch (e) {
      debugPrint('İlan beğenme hatası: $e');
    }
  }

  Future<void> unlikeAdvert(String advertId, String userId) async {
    try {
      await _firestore.collection('events').doc(advertId).update({
        'likers': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      debugPrint('İlan beğenme hatası: $e');
    }
  }

  Future<void> deleteAdvert(String advertId) async {
    try {
      await _firestore.collection('events').doc(advertId).delete();
      debugPrint('İlan başarıyla silindi');
    } catch (e) {
      debugPrint('İlan silme hatası: $e');
    }
  }
}
