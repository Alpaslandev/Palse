import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/constant/categories.dart';
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

      final upperCity = city;
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
    List<Categories>? interests, {
    DocumentSnapshot? lastDocument,
    int limit = 25,
  }) async {
    try {
      // İlgi alanı yoksa boş liste döndür
      if (interests == null || interests.isEmpty) {
        return [];
      }

      // Eski format değerler (enum.text)
      final oldFormatValues = interests.map((interest) => interest.text).toList();
      debugPrint('Eski format değerler: $oldFormatValues');

      // Yeni format değerler (enum.name)
      final newFormatValues = interests.map((interest) => interest.name).toList();
      debugPrint('Yeni format değerler: $newFormatValues');

      // Events koleksiyonuna referans
      final eventsRef = FirebaseFirestore.instance.collection('events');

      // Sorgular listesi
      List<Future<QuerySnapshot>> queries = [];

      // Eski format için sorgular (advertType alanı için)
      for (var value in oldFormatValues) {
        queries.add(eventsRef.where('advertType', isEqualTo: value).limit(limit).get());
      }

      // Yeni format için sorgular (advertType alanı için)
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

      // Tarihe göre sırala (yeniden eskiye)
      if (adverts.isNotEmpty) {
        adverts.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
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
      'likers': FieldValue.arrayUnion([userId])
    });
  }

  Future<void> unlikeAdvert(String advertId, String userId) async {
    await _firestore.collection('events').doc(advertId).update({
      'likers': FieldValue.arrayRemove([userId])
    });
  }
}
