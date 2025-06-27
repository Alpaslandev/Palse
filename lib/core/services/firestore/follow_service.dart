// Kullanıcı takip işlemlerini yöneten servis
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/models/customer.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcının profil gizliliğini kontrol et ve uygun takip işlemini yap
  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      // Hedef kullanıcının profil bilgilerini al
      final targetUserDoc =
          await _firestore.collection('customers').doc(targetUserId).get();
      if (!targetUserDoc.exists) {
        throw Exception('Kullanıcı bulunamadı');
      }

      final targetUserData = targetUserDoc.data()!;
      final isPrivateProfile = targetUserData['isPrivate'] ?? false;

      if (isPrivateProfile) {
        // Profil gizli ise takip isteği gönder
        await sendFollowRequest(currentUserId, targetUserId);
      } else {
        // Profil açık ise direkt takip et
        await followUserDirectly(currentUserId, targetUserId);
      }
    } catch (e) {
      debugPrint('Takip etme hatası: $e');
      throw Exception('Kullanıcı takip edilemedi: $e');
    }
  }

  // Direkt takip etme (profil açık kullanıcılar için)
  Future<void> followUserDirectly(
      String currentUserId, String targetUserId) async {
    try {
      final batch = _firestore.batch();

      // Current user'ın followings listesine ekle
      batch.update(_firestore.collection('customers').doc(currentUserId), {
        'followings': FieldValue.arrayUnion([targetUserId]),
      });

      // Target user'ın followers listesine ekle
      batch.update(_firestore.collection('customers').doc(targetUserId), {
        'followers': FieldValue.arrayUnion([currentUserId]),
      });

      await batch.commit();
      debugPrint('Kullanıcı direkt takip edildi: $targetUserId');
    } catch (e) {
      debugPrint('Direkt takip etme hatası: $e');
      throw Exception('Kullanıcı takip edilemedi: $e');
    }
  }

  // Takip isteği gönder (profil gizli kullanıcılar için)
  Future<void> sendFollowRequest(
      String currentUserId, String targetUserId) async {
    try {
      // Target user'ın followingRequests listesine ekle
      await _firestore.collection('customers').doc(targetUserId).update({
        'followingRequests': FieldValue.arrayUnion([currentUserId]),
      });

      debugPrint('Takip isteği gönderildi: $targetUserId');
    } catch (e) {
      debugPrint('Takip isteği gönderme hatası: $e');
      throw Exception('Takip isteği gönderilemedi: $e');
    }
  }

  // Takip isteğini onayla
  Future<void> acceptFollowRequest(
      String currentUserId, String requesterUserId) async {
    try {
      final batch = _firestore.batch();

      // Current user'ın followingRequests listesinden çıkar ve followers listesine ekle
      batch.update(_firestore.collection('customers').doc(currentUserId), {
        'followingRequests': FieldValue.arrayRemove([requesterUserId]),
        'followers': FieldValue.arrayUnion([requesterUserId]),
      });

      // Requester user'ın followings listesine ekle
      batch.update(_firestore.collection('customers').doc(requesterUserId), {
        'followings': FieldValue.arrayUnion([currentUserId]),
      });

      await batch.commit();
      debugPrint('Takip isteği onaylandı: $requesterUserId');
    } catch (e) {
      debugPrint('Takip isteği onaylama hatası: $e');
      throw Exception('Takip isteği onaylanamadı: $e');
    }
  }

  // Takip isteğini reddet
  Future<void> rejectFollowRequest(
      String currentUserId, String requesterUserId) async {
    try {
      // Current user'ın followingRequests listesinden çıkar
      await _firestore.collection('customers').doc(currentUserId).update({
        'followingRequests': FieldValue.arrayRemove([requesterUserId]),
      });

      debugPrint('Takip isteği reddedildi: $requesterUserId');
    } catch (e) {
      debugPrint('Takip isteği reddetme hatası: $e');
      throw Exception('Takip isteği reddedilemedi: $e');
    }
  }

  // Kullanıcıyı takipten çıkar
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      final batch = _firestore.batch();

      // Current user'ın followings listesinden çıkar
      batch.update(_firestore.collection('customers').doc(currentUserId), {
        'followings': FieldValue.arrayRemove([targetUserId]),
      });

      // Target user'ın followers listesinden çıkar
      batch.update(_firestore.collection('customers').doc(targetUserId), {
        'followers': FieldValue.arrayRemove([currentUserId]),
      });

      await batch.commit();
      debugPrint('Kullanıcı takipten çıkarıldı: $targetUserId');
    } catch (e) {
      debugPrint('Takipten çıkarma hatası: $e');
      throw Exception('Kullanıcı takipten çıkarılamadı: $e');
    }
  }

  // UI'da kullanım için statik yardımcı metodlar
  static bool isFollowing(Customer currentUser, String targetUserId) {
    return currentUser.followings?.contains(targetUserId) ?? false;
  }

  static bool isFollowRequestSent(Customer targetUser, String currentUserId) {
    return targetUser.followingRequests?.contains(currentUserId) ?? false;
  }
}
