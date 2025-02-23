import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  BuildContext? _context;

  void setContext(BuildContext context) {
    _context = context;
  }

  Future<void> initialize() async {
    await _requestPermissions();
    //  await _saveToken();
    _configureFCM();
  }

  Future<void> _requestPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // FCM token'ı kaydet
  Future<void> _saveToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
      }
    } catch (e) {
      debugPrint('FCM token alma hatası: $e');
    }
  }

  // Kullanıcının token'ını güncelle
  Future<void> saveUserToken(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _db.collection('customers').doc(userId).update({
          'fcmToken': token,
        });
      }
    } catch (e) {
      debugPrint('FCM token kaydetme hatası: $e');
    }
  }

  void _configureFCM() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Ön planda bildirim alındı: ${message.notification?.title}');

      if (_context == null) return;

      final data = message.data;
      final chatId = data['chatId'];
      final senderId = data['senderId'];

      // ScaffoldMessenger ile bildirim göster
      ScaffoldMessenger.of(_context!).showMaterialBanner(
        MaterialBanner(
          padding: const EdgeInsets.all(16),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.notification?.title ?? 'Yeni Mesaj',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(message.notification?.body ?? ''),
            ],
          ),
          leading: const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.message, color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(_context!).hideCurrentMaterialBanner();
                if (chatId != null && senderId != null) {
                  GoRouter.of(_context!).push('/chats/$chatId?otherId=$senderId');
                }
              },
              child: const Text('Görüntüle'),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(_context!).hideCurrentMaterialBanner();
              },
              child: const Text('Kapat'),
            ),
          ],
        ),
      );

      // 4 saniye sonra otomatik kapat
      Future.delayed(const Duration(seconds: 4), () {
        if (_context != null) {
          ScaffoldMessenger.of(_context!).hideCurrentMaterialBanner();
        }
      });
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);
  }

  void _handleNotificationClick(RemoteMessage message) {
    if (_context == null) return;

    final data = message.data;
    final chatId = data['chatId'];
    final senderId = data['senderId'];

    if (chatId != null) {
      GoRouter.of(_context!).push('/chats/$chatId?otherId=$senderId');
    }
  }

  // Bildirim gönder
  Future<void> sendNotification({
    required String receiverId,
    required String senderName,
    required String message,
    required String chatId, // Yeni eklenen
    required String senderId, // Yeni eklenen
  }) async {
    try {
      // Alıcının FCM token'ını al
      final userDoc = await _db.collection('customers').doc(receiverId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        debugPrint('Alıcının FCM token\'ı bulunamadı');
        return;
      }

      // Cloud Function'a bildirim gönderme isteği yap
      await _db.collection('notifications').add({
        'token': fcmToken,
        'title': senderName,
        'body': message,
        'timestamp': FieldValue.serverTimestamp(),
        'receiverId': receiverId,
        'type': 'message',
        'chatId': chatId, // Yeni eklenen
        'senderId': senderId, // Yeni eklenen
      });
    } catch (e) {
      debugPrint('Bildirim gönderme hatası: $e');
    }
  }
}
