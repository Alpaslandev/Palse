import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/routes/app_router.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/services/shared_pref_service.dart';

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
      debugPrint('Ön planda bildirim alındı: ${message.notification?.body}');

      debugPrint('Bildirim data: ${message.data}');
      //  final notificationDate = (message.data['timestamp'] as Timestamp).toDate();
      final bool isMessage = message.data['type'] == 'message';
      if (!isMessage) {
        SharedPrefService.saveNotificationWithEnum(
          type: message.data['type'],
          body: message.notification?.body ?? '',
          title: message.notification?.title ?? '',
        );
        debugPrint('Bildirim kaydedildi');
      }

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
            if (isMessage)
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
      Future.delayed(const Duration(seconds: 400), () {
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

      if (chatId != null && senderId != null) {
        AppRouter.router.push('/chats/$chatId?otherId=$senderId&currentId=$receiverId');
      } else {
        AppRouter.router.push(notification);
      }
    });
  }

  // Bildirim gönder
  Future<void> sendNotification({
    required String receiverId,
    required String notificationType,
    String? chatId,
  }) async {
    try {
      // Bildirim verilerini düzenleyelim
      debugPrint('Bildirim gönderiliyor: $receiverId, $notificationType, $chatId');
      await _db.collection('notifications').add({
        'timestamp': FieldValue.serverTimestamp(),
        'receiverId': receiverId,
        'type': notificationType,
        'chatId': chatId,
      });

      debugPrint('Bildirim gönderildi');
    } catch (e) {
      debugPrint('Bildirim gönderme hatası: $e');
    }
  }

  /// Bir Firestore koleksiyonunu başka bir koleksiyona kopyalar
  Future<void> copyFirestoreCollection({
    required String sourceCollection,
    required String targetCollection,
    Function(String)? onProgress,
  }) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // İlerleme bildirimi
      onProgress?.call('Belgeler alınıyor...');

      // Kaynak koleksiyondan tüm belgeleri al
      final QuerySnapshot snapshot = await firestore.collection(sourceCollection).get();
      final int totalDocs = snapshot.docs.length;

      onProgress?.call('$totalDocs belge kopyalanacak');

      // Belgeleri gruplar halinde işle (Firestore batch sınırı 500)
      int processedDocs = 0;
      List<List<QueryDocumentSnapshot>> batches = [];

      for (int i = 0; i < totalDocs; i += 500) {
        final end = (i + 500 < totalDocs) ? i + 500 : totalDocs;
        batches.add(snapshot.docs.sublist(i, end));
      }

      // Her batch için işlem yap
      for (var batchDocs in batches) {
        final WriteBatch batch = firestore.batch();

        for (var doc in batchDocs) {
          // Belgeyi hedef koleksiyona aynı ID ile ekle
          final targetDocRef = firestore.collection(targetCollection).doc(doc.id);
          batch.set(targetDocRef, doc.data() as Map<String, dynamic>);
        }

        // Batch'i commit et
        await batch.commit();

        processedDocs += batchDocs.length;
        onProgress?.call('$processedDocs / $totalDocs belge kopyalandı');
      }

      onProgress?.call('Kopyalama tamamlandı: $sourceCollection -> $targetCollection');
    } catch (e) {
      onProgress?.call('Hata: $e');
      rethrow;
    }
  }
}
