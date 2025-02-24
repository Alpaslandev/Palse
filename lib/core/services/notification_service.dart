import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/routes/app_router.dart';
import 'package:palseapp/features/messages/view/messages_view.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  BuildContext? _context;

  void setContext(BuildContext context) {
    _context = context;
  }

  Future<void> initialize() async {
    await _requestPermissions();
    _configureFCM();
  }

  Future<void> _requestPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
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
      debugPrint('Bildirim data: ${message.data}');

      if (_context == null) return;

      final data = message.data;
      final chatId = data['chatId'];
      final senderId = data['senderId'];
      final receiverId = data['receiverId'];

      ScaffoldMessenger.of(_context!).showMaterialBanner(
        MaterialBanner(
          backgroundColor: Colors.white,
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
                if (chatId != null && senderId != null && receiverId != null) {
                  AppRouter.router.push('/chats/$chatId?otherId=$senderId&currentId=$receiverId');
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

    // Arka plan bildirimi için
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Arka planda bildirim tıklandı');
      final data = message.data;
      final chatId = data['chatId'];
      final senderId = data['senderId'];
      final receiverId = data['receiverId'];

      if (chatId != null && senderId != null && receiverId != null) {
        AppRouter.router.push('/chats/$chatId?otherId=$senderId&currentId=$receiverId');
      }
    });
  }

  // Bildirim gönder
  Future<void> sendNotification({
    required String receiverId,
    required String senderName,
    required String message,
    required String chatId,
    required String senderId,
  }) async {
    try {
      final userDoc = await _db.collection('customers').doc(receiverId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        debugPrint('Alıcının FCM token\'ı bulunamadı');
        return;
      }

      // Bildirim verilerini düzenleyelim
      await _db.collection('notifications').add({
        'token': fcmToken,
        'title': senderName,
        'body': message,
        'timestamp': FieldValue.serverTimestamp(),
        'receiverId': receiverId,
        'type': 'message',
        'chatId': chatId,
        'senderId': senderId,
      });

      debugPrint('Bildirim gönderildi: ChatId: $chatId, SenderId: $senderId');
    } catch (e) {
      debugPrint('Bildirim gönderme hatası: $e');
    }
  }
}
