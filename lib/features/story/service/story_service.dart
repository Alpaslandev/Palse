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
        imageUrl: imageUrl,
        createdAt: DateTime.now().toIso8601String(),
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
      final timestamp = twentyFourHoursAgo.toIso8601String();

      // Sorgu 1: Herkese açık tüm hikayeler
      final publicStoriesQuery = _firestore
          .collection(_collectionPath)
          .where('isPublic', isEqualTo: true)
          .where('createdAt', isGreaterThan: timestamp)
          .get();

      // Sorgu 2: Takip edilenlerin özel hikayeleri
      final privateStoriesQuery = followingIds.isEmpty
          ? Future.value(null)
          : _firestore
              .collection(_collectionPath)
              .where('isPublic', isEqualTo: false)
              .where('userId', whereIn: followingIds)
              .where('createdAt', isGreaterThan: timestamp)
              .get();

      // Sorgu 3: Kullanıcının kendi hikayeleri (özel veya herkese açık)
      final myStoriesQuery = _firestore
          .collection(_collectionPath)
          .where('userId', isEqualTo: currentUserId)
          .where('createdAt', isGreaterThan: timestamp)
          .get();

      // Üç sorguyu paralel olarak çalıştır
      final results = await Future.wait(
          [publicStoriesQuery, privateStoriesQuery, myStoriesQuery]);

      // Sonuçları bir Map kullanarak birleştirerek mükerrer kayıtları engelle
      final Map<String, StoryModel> storyMap = {};

      // Herkese açık hikayeler
      for (var doc in (results[0] as QuerySnapshot).docs) {
        final story = StoryModel.fromJson(doc.data() as Map<String, dynamic>);
        storyMap[story.id] = story;
      }

      // Takip edilenlerin özel hikayeleri
      if (results[1] != null) {
        for (var doc in (results[1] as QuerySnapshot).docs) {
          final story = StoryModel.fromJson(doc.data() as Map<String, dynamic>);
          storyMap[story.id] = story;
        }
      }

      // Kullanıcının kendi hikayeleri
      for (var doc in (results[2] as QuerySnapshot).docs) {
        final story = StoryModel.fromJson(doc.data() as Map<String, dynamic>);
        storyMap[story.id] = story;
      }

      // Map'teki değerleri bir listeye çevir ve tarihe göre sırala
      final allStories = storyMap.values.toList();
      allStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return allStories;
    } catch (e) {
      print('Hikayeler çekilirken hata: $e');
      return [];
    }
  }
}
