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

      // Yeni veri yapısına göre sorgu güncellendi
      // Artık city doğrudan belgede değil, location.city içinde
      var query = _firestore.collection('events').where('location.city', isEqualTo: upperCity).limit(limit);

      // Eğer son döküman varsa, ondan sonrasını getir
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();
      final adverts = querySnapshot.docs.map((doc) => Advert.fromJson(doc.data(), doc.id)).toList();

      // Şehre göre ilanları karıştır
      if (adverts.isNotEmpty) {
        adverts.shuffle();
        debugPrint('Şehre göre ilanlar karıştırıldı.');
      }

      debugPrint('Bulunan ilan sayısı: ${adverts.length}');
      return adverts;
    } catch (e) {
      debugPrint('Şehre göre ilanlar çekilirken hata: $e');
      return [];
    }
  }

  // İlgi alanlarına göre ilanları getir
  Future<List<Advert>> fetchAdvertsByInterests(
    List<Categories>? interests, {
    DocumentSnapshot? lastDocument,
    int limit = 25,
    LocationModel? userLocation,
  }) async {
    try {
      // İlgi alanı yoksa boş liste döndür
      if (interests == null || interests.isEmpty) {
        return [];
      }

      // Eski format değerler (Türkçe metin karşılıkları)
      final oldFormatValues = interests.map((interest) => legacyTurkishTextMapReverse[interest] ?? interest.name).toList();
      debugPrint('Eski format değerler (Türkçe): $oldFormatValues');

      // Yeni format değerler (enum.name)
      final newFormatValues = interests.map((interest) => interest.name).toList();
      debugPrint('Yeni format değerler (enum.name): $newFormatValues');

      // Events koleksiyonuna referans
      final eventsRef = FirebaseFirestore.instance.collection('events');

      // Sorgular listesi
      List<Future<QuerySnapshot>> queries = [];

      // Eski format için sorgular (Türkçe metinler için)
      for (var value in oldFormatValues) {
        queries.add(eventsRef.where('advertType', isEqualTo: value).limit(limit).get());
      }

      // Yeni format için sorgular (enum.name değerleri için)
      for (var value in newFormatValues) {
        queries.add(eventsRef.where('advertType', isEqualTo: value).limit(limit).get());
      }

      // Tüm sorguları paralel çalıştır
      final queryResults = await Future.wait(queries);

      // Sonuçları birleştir (tekrarları önlemek için Map kullan)
      final Map<String, Advert> uniqueAdverts = {};

      for (var querySnapshot in queryResults) {
        for (var doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;

          final advert = Advert.fromJson(data, doc.id);
          uniqueAdverts[doc.id] = advert;
        }
      }

      // Map'ten liste oluştur
      final adverts = uniqueAdverts.values.toList();
      debugPrint('Bulunan ilan sayısı: ${adverts.length}');

      // İlgi alanlarına göre ilanları karıştır
      if (adverts.isNotEmpty) {
        adverts.shuffle();
        debugPrint('İlgi alanlarına göre ilanlar karıştırıldı.');
      }

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
        bool isNotInUserCity = userCity == null || userCity.isEmpty || advert.location?.city != userCity;
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
      if (a.location == null) return 1;
      if (b.location == null) return -1;

      // Mesafeleri hesapla
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
