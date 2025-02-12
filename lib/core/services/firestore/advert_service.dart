import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:intl/intl.dart';

class AdvertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firestore'dan 10 ilan çeker
  Future<List<Advert>?> fetchAdvertsFromFirestore() async {
    try {
      final querySnapshot = await _firestore.collection('adverts').orderBy('createdAt', descending: true).limit(10).get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Advert.fromJson(data, doc.id);
      }).toList();
    } catch (e) {
      debugPrint('İlanlar çekilirken hata: $e');
      return null;
    }
  }

// İlanı hem events hem de adverts koleksiyonlarında arar
  Future<Advert?> fetchAdvertById(String advertID) async {
    try {
      // Önce events koleksiyonunda ara
      DocumentSnapshot eventSnapshot = await _firestore.collection('adverts').doc(advertID).get();
      if (eventSnapshot.exists) {
        return Advert.fromJson(eventSnapshot.data() as Map<String, dynamic>, advertID);
      }

      // Events'de bulunamazsa adverts koleksiyonunda ara
      DocumentSnapshot advertSnapshot = await _firestore.collection('events').doc(advertID).get();
      if (advertSnapshot.exists) {
        return Advert.fromJson(advertSnapshot.data() as Map<String, dynamic>, advertID);
      }

      return null;
    } catch (e) {
      debugPrint('İlan arama hatası: $e');
      return null;
    }
  }

  Future<void> likeAdvert(String advertId, String userId) async {
    await _firestore.collection('adverts').doc(advertId).update({
      'countUUIDs': FieldValue.arrayUnion([userId])
    });
  }

  Future<void> unlikeAdvert(String advertId, String userId) async {
    await _firestore.collection('adverts').doc(advertId).update({
      'countUUIDs': FieldValue.arrayRemove([userId])
    });
  }

  // Süresi geçmiş ilanları sil
  Future<void> deleteExpiredAdverts() async {
    try {
      // Bugünün tarihini al ve string'e çevir
      final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

      // Tüm ilanları çek
      final querySnapshot = await _firestore.collection('adverts').get();

      // Batch işlemi başlat
      final batch = _firestore.batch();
      var deletedCount = 0;

      for (var doc in querySnapshot.docs) {
        final advertLastUsage = doc.data()['advertLastUsage'] as String?;

        if (advertLastUsage != null) {
          // Tarihleri DateTime'a çevir
          final lastUsageDate = DateFormat('dd/MM/yyyy').parse(advertLastUsage);
          final todayDate = DateFormat('dd/MM/yyyy').parse(today);

          // Eğer son kullanma tarihi bugünden önceyse sil
          if (lastUsageDate.isBefore(todayDate)) {
            batch.delete(doc.reference);
            deletedCount++;
          }
        }
      }

      // Batch işlemini uygula
      await batch.commit();
      debugPrint('$deletedCount adet süresi geçmiş ilan silindi');
    } catch (e) {
      debugPrint('Süresi geçmiş ilanlar silinirken hata: $e');
    }
  }
}
