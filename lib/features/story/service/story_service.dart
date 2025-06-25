import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/features/story/model/story_model.dart';
import 'package:uuid/uuid.dart';

// Hikayelerle ilgili tüm Firestore ve Firebase Storage işlemlerini yöneten servis.
class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collectionPath = 'stories';

  // Yeni bir hikaye oluşturur ve veritabanına kaydeder.
  Future<void> createStory({
    required File imageFile,
    required String userId,
    required String username,
    required String profilePictureUrl,
    required bool isPublic,
  }) async {
    try {
      // 1. Resmi Firebase Storage'a yükle
      final storyId = const Uuid().v4();
      final imagePath = 'stories/$userId/$storyId.jpg';
      final uploadTask = _storage.ref(imagePath).putFile(imageFile);
      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      // 2. StoryModel oluştur
      final newStory = StoryModel(
        id: storyId,
        userId: userId,
        username: username,
        profilePictureUrl: profilePictureUrl,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        viewedBy: [],
        isPublic: isPublic,
      );

      // 3. Modeli Firestore'a kaydet
      await _firestore
          .collection(_collectionPath)
          .doc(storyId)
          .set(newStory.toJson()); // Modelde toJson() methodu olmalı
    } catch (e) {
      // Hata yönetimi
      debugPrint('Hikaye oluşturulurken hata: $e');
      throw Exception('Hikaye oluşturulamadı.');
    }
  }

  // Kullanıcının ve takip ettiklerinin hikayelerini çeker.
  Future<List<StoryModel>> fetchStories({
    required String currentUserId,
    required List<String> followingIds,
  }) async {
    try {
      final twentyFourHoursAgo =
          DateTime.now().subtract(const Duration(hours: 24));
      final timestampFilter = Timestamp.fromDate(twentyFourHoursAgo);

      // Görülebilir kullanıcı ID'lerini hazırla (kendim + takip ettiklerim)
      final visibleUserIds = [currentUserId, ...followingIds];

      // Tek sorgu ile tüm hikayeleri çek
      final querySnapshot = await _firestore
          .collection(_collectionPath)
          .where('createdAt', isGreaterThan: timestampFilter)
          .orderBy('createdAt', descending: true)
          .get();

      final List<StoryModel> stories = [];

      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          final story = StoryModel.fromJson(data);

          // Filtreleme mantığı:
          // 1. Kendi hikayelerim -> hep görünür
          // 2. Herkese açık hikayeler -> hep görünür
          // 3. Özel hikayeler -> sadece takip ettiklerimden
          final isMyStory = story.userId == currentUserId;
          final isPublicStory = story.isPublic;
          final isFromFollowedUser = followingIds.contains(story.userId);

          if (isMyStory ||
              isPublicStory ||
              (isFromFollowedUser && !isPublicStory)) {
            stories.add(story);
          }
        } catch (e) {
          debugPrint('Hikaye parse hatası: $e');
          // Hatalı hikayeyi atla, devam et
          continue;
        }
      }

      return stories;
    } catch (e) {
      debugPrint('Hikayeler çekilirken hata: $e');
      return [];
    }
  }

  // Bir hikayenin 'viewedBy' listesine yeni bir kullanıcı ID'si ekler.
  Future<void> addViewToStory(String storyId, String viewerId) async {
    try {
      await _firestore.collection(_collectionPath).doc(storyId).update({
        'viewedBy': FieldValue.arrayUnion([viewerId])
      });
    } catch (e) {
      // Bu hatayı loglamak önemli olabilir, ama kullanıcıya göstermek şart değil.
      debugPrint('Hikaye görüntülemesi güncellenirken hata: $e');
    }
  }

  // Hikayeyi siler (hem Firestore'dan hem Storage'dan)
  Future<void> deleteStory({
    required String storyId,
    required String userId,
  }) async {
    try {
      // 1. Önce hikaye verisini Firestore'dan çek
      final storyDoc =
          await _firestore.collection(_collectionPath).doc(storyId).get();

      if (!storyDoc.exists) {
        throw Exception('Hikaye bulunamadı');
      }

      final storyData = storyDoc.data()!;

      // 2. Hikaye sahibi kontrolü
      if (storyData['userId'] != userId) {
        throw Exception('Bu hikayeyi silme yetkiniz yok');
      }

      // 3. Storage'dan resmi sil
      final imagePath = 'stories/$userId/$storyId.jpg';
      try {
        await _storage.ref(imagePath).delete();
        debugPrint('Hikaye resmi Storage\'dan silindi: $imagePath');
      } catch (e) {
        // Storage'da dosya bulunamazsa devam et
        debugPrint('Storage\'dan silme hatası (dosya bulunamayabilir): $e');
      }

      // 4. Firestore'dan hikayeyi sil
      await _firestore.collection(_collectionPath).doc(storyId).delete();

      debugPrint('Hikaye başarıyla silindi: $storyId');
    } catch (e) {
      debugPrint('Hikaye silinirken hata: $e');
      throw Exception('Hikaye silinemedi: $e');
    }
  }

  // Kullanıcının tüm hikayelerini siler
  Future<void> deleteAllUserStories(String userId) async {
    try {
      // Kullanıcının tüm hikayelerini çek
      final userStoriesQuery = await _firestore
          .collection(_collectionPath)
          .where('userId', isEqualTo: userId)
          .get();

      // Batch işlemi için
      final batch = _firestore.batch();

      for (var doc in userStoriesQuery.docs) {
        final storyId = doc.id;

        // Storage'dan resmi sil
        final imagePath = 'stories/$userId/$storyId.jpg';
        try {
          await _storage.ref(imagePath).delete();
        } catch (e) {
          debugPrint('Storage silme hatası: $e');
        }

        // Batch'e silme işlemini ekle
        batch.delete(doc.reference);
      }

      // Batch işlemini çalıştır
      await batch.commit();

      debugPrint('Kullanıcının tüm hikayeleri silindi: $userId');
    } catch (e) {
      debugPrint('Kullanıcı hikayeleri silinirken hata: $e');
      throw Exception('Kullanıcı hikayeleri silinemedi: $e');
    }
  }
}
