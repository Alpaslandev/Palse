// Kullanıcı takip işlemlerini yöneten servis
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/models/customer.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcıyı takip et
  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      final batch = _firestore.batch();

      // Current user'ın following listesine ekle
      batch.update(_firestore.collection('customers').doc(currentUserId), {
        'following': FieldValue.arrayUnion([targetUserId]),
      });

      // Target user'ın followers listesine ekle
      batch.update(_firestore.collection('customers').doc(targetUserId), {
        'followers': FieldValue.arrayUnion([currentUserId]),
      });

      await batch.commit();
      debugPrint('Kullanıcı takip edildi: $targetUserId');
    } catch (e) {
      debugPrint('Takip etme hatası: $e');
      throw Exception('Kullanıcı takip edilemedi: $e');
    }
  }

  // Kullanıcıyı takipten çıkar
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      final batch = _firestore.batch();

      // Current user'ın following listesinden çıkar
      batch.update(_firestore.collection('customers').doc(currentUserId), {
        'following': FieldValue.arrayRemove([targetUserId]),
        'followingCount': FieldValue.increment(-1),
      });

      // Target user'ın followers listesinden çıkar
      batch.update(_firestore.collection('customers').doc(targetUserId), {
        'followers': FieldValue.arrayRemove([currentUserId]),
        'followerCount': FieldValue.increment(-1),
      });

      await batch.commit();
      debugPrint('Kullanıcı takipten çıkarıldı: $targetUserId');
    } catch (e) {
      debugPrint('Takipten çıkarma hatası: $e');
      throw Exception('Kullanıcı takipten çıkarılamadı: $e');
    }
  }

  // Takip durumunu kontrol et
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      final userDoc =
          await _firestore.collection('customers').doc(currentUserId).get();

      if (userDoc.exists) {
        final following = List<String>.from(userDoc.data()?['following'] ?? []);
        return following.contains(targetUserId);
      }
      return false;
    } catch (e) {
      debugPrint('Takip durumu kontrolü hatası: $e');
      return false;
    }
  }

  // Takipçileri getir
  Future<List<Customer>> getFollowers(String userId) async {
    try {
      final userDoc =
          await _firestore.collection('customers').doc(userId).get();

      if (userDoc.exists) {
        final followers = List<String>.from(userDoc.data()?['followers'] ?? []);
        final List<Customer> followerUsers = [];

        for (String followerId in followers) {
          final followerDoc =
              await _firestore.collection('customers').doc(followerId).get();

          if (followerDoc.exists) {
            followerUsers
                .add(Customer.fromJson(followerDoc.data()!, followerId));
          }
        }

        return followerUsers;
      }
      return [];
    } catch (e) {
      debugPrint('Takipçi listesi getirme hatası: $e');
      return [];
    }
  }

  // Takip edilenleri getir
  Future<List<Customer>> getFollowing(String userId) async {
    try {
      final userDoc =
          await _firestore.collection('customers').doc(userId).get();

      if (userDoc.exists) {
        final following = List<String>.from(userDoc.data()?['following'] ?? []);
        final List<Customer> followingUsers = [];

        for (String followingId in following) {
          final followingDoc =
              await _firestore.collection('customers').doc(followingId).get();

          if (followingDoc.exists) {
            followingUsers
                .add(Customer.fromJson(followingDoc.data()!, followingId));
          }
        }

        return followingUsers;
      }
      return [];
    } catch (e) {
      debugPrint('Takip edilen listesi getirme hatası: $e');
      return [];
    }
  }
}
