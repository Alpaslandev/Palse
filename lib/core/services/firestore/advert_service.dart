import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/constant/categories.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/models/location_model.dart';
import 'package:palseapp/core/services/notification_service.dart';

class AdvertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService notificationService = NotificationService();

  // Şehre göre ilanları getir (index gerekmeden)
  Future<List<Advert>> fetchAdvertsByCity(
    String? city, {
    DocumentSnapshot? lastDocument,
    int limit = 25,
    LocationModel? userLocation,
  }) async {
    try {
      if (city == null || city.isEmpty) {
        return await fetchAdverts(lastDocument: lastDocument, limit: limit, userLocation: userLocation);
      }

      final upperCity = city;
      debugPrint('Aranan şehir: $upperCity, limit: $limit');

      // Temel sorgu
      var query = _firestore.collection('events').where('location.city', isEqualTo: upperCity).orderBy('createdAt', descending: true).limit(limit);
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
  Future<List<Advert>> fetchAdvertsByInterests(List<Categories>? interests,
      {DocumentSnapshot? lastDocument, int limit = 25, LocationModel? userLocation}) async {
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
      var query = _firestore.collection('events').where('advertType', whereIn: categoriesToQuery).orderBy('createdAt', descending: true).limit(limit);

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

  // Tüm ilanları getir
  Future<List<Advert>> fetchAdverts({
    DocumentSnapshot? lastDocument,
    int limit = 25,
    LocationModel? userLocation,
  }) async {
    try {
      var query = _firestore.collection('events').limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();
      final adverts = querySnapshot.docs.map((doc) => Advert.fromJson(doc.data(), doc.id)).toList();

      // Konuma göre sıralama - SADECE fetchAdverts için
      if (userLocation != null) {
        _sortAdvertsByDistance(adverts, userLocation);
        debugPrint('Tüm ilanlar konuma göre sıralandı.');
      }

      debugPrint('Toplam ilan sayısı: ${adverts.length}');
      return adverts;
    } catch (e) {
      debugPrint('İlanlar çekilirken hata: $e');
      return [];
    }
  }

  // Other sekmesi için ilanları getir - Kullanıcının şehrinde ve ilgi alanlarında olmayan ilanlar
  Future<List<Advert>> fetchOtherAdverts({
    required String? userCity,
    required List<Categories>? userInterests,
    DocumentSnapshot? lastDocument,
    int limit = 25,
    LocationModel? userLocation,
  }) async {
    try {
      debugPrint('Other sekmesi için ilanlar getiriliyor...');
      debugPrint('Kullanıcı şehri: $userCity');
      debugPrint('Kullanıcı ilgi alanları: ${userInterests?.map((e) => e.name).toList()}');

      // Tüm ilanları çek
      var query = _firestore.collection('events').limit(limit * 3); // Daha fazla ilan çekelim, filtreleme yapacağız

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();
      final allAdverts = querySnapshot.docs.map((doc) => Advert.fromJson(doc.data(), doc.id)).toList();

      debugPrint('Toplam çekilen ilan sayısı: ${allAdverts.length}');

      // Kullanıcının şehrinde ve ilgi alanlarında olmayan ilanları filtrele
      List<Advert> otherAdverts = allAdverts.where((advert) {
        // Kullanıcının şehrinde değilse ve ilgi alanlarında değilse göster
        bool isNotInUserCity = userCity == null || userCity.isEmpty || advert.location.city != userCity;
        bool isNotInUserInterests = userInterests == null || userInterests.isEmpty || !userInterests.contains(advert.advertType);

        return isNotInUserCity && isNotInUserInterests;
      }).toList();

      // Limit uygula
      if (otherAdverts.length > limit) {
        otherAdverts = otherAdverts.sublist(0, limit);
      }

      debugPrint('Filtreleme sonrası kalan ilan sayısı: ${otherAdverts.length}');

      // Konuma göre sıralama
      if (userLocation != null) {
        _sortAdvertsByDistance(otherAdverts, userLocation);
        debugPrint('Other ilanlar konuma göre sıralandı.');
      }

      return otherAdverts;
    } catch (e) {
      debugPrint('Other ilanlar çekilirken hata: $e');
      return [];
    }
  }

  // İlanları mesafeye göre sıralayan yardımcı metod
  void _sortAdvertsByDistance(List<Advert> adverts, LocationModel userLocation) {
    adverts.sort((a, b) {
      // Eğer konum bilgisi yoksa en sona koy
      int distanceA = userLocation.distanceTo(a.location);
      int distanceB = userLocation.distanceTo(b.location);

      // Yakından uzağa sırala
      return distanceA.compareTo(distanceB);
    });

    debugPrint('İlanlar konuma göre sıralandı.');
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
