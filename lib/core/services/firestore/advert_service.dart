import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/models/advert.dart';

class AdvertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Şehre göre ilanları getir (index gerekmeden)
  Future<List<Advert>> fetchAdvertsByCity(
    String? city, {
    DocumentSnapshot? lastDocument,
    int limit = 25,
  }) async {
    try {
      if (city == null || city.isEmpty) {
        return await fetchAdverts(lastDocument: lastDocument, limit: limit);
      }

      final upperCity = city.toUpperCase().trim();
      debugPrint('Aranan şehir: $upperCity, limit: $limit');

      var query = _firestore.collection('events').where('city', isEqualTo: upperCity).limit(limit);

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
  Future<List<Advert>> fetchAdvertsByInterests(
    List<String>? interests, {
    DocumentSnapshot? lastDocument,
    int limit = 25,
  }) async {
    try {
      if (interests == null || interests.isEmpty) {
        debugPrint('İlgi alanları boş, tüm ilanlar getiriliyor');
        return await fetchAdverts(lastDocument: lastDocument, limit: limit);
      }

      // İlgi alanlarını doğru formata çevir (ilk harf büyük, diğerleri küçük)
      final formattedInterests = interests.map((e) {
        return e.split(' ').map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' ');
      }).toList();

      debugPrint('Aranan ilgi alanları: $formattedInterests');

      var query = _firestore.collection('events').where('advertType', whereIn: formattedInterests).limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();

      // Ham verileri kontrol et
      debugPrint('Sorgu sonuçları:');
      for (var doc in querySnapshot.docs) {
        debugPrint('ID: ${doc.id}, advertType: ${doc.data()['advertType']}');
      }

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
  }) async {
    try {
      var query = _firestore.collection('events').limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();
      final adverts = querySnapshot.docs.map((doc) => Advert.fromJson(doc.data(), doc.id)).toList();

      debugPrint('Toplam ilan sayısı: ${adverts.length}');
      return adverts;
    } catch (e) {
      debugPrint('İlanlar çekilirken hata: $e');
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

  Future<void> likeAdvert(String advertId, String userId) async {
    await _firestore.collection('events').doc(advertId).update({
      'countUUIDs': FieldValue.arrayUnion([userId])
    });
  }

  Future<void> unlikeAdvert(String advertId, String userId) async {
    await _firestore.collection('events').doc(advertId).update({
      'countUUIDs': FieldValue.arrayRemove([userId])
    });
  }
}
