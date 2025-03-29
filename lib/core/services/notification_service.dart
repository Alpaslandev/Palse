import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/routes/app_router.dart';
import 'package:palseapp/core/services/shared_pref_service.dart';
import 'package:palseapp/core/widgets/scaffold_mess.dart';

// NotificationService sınıfı - bildirim yönetimi için genel sınıf
class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Bildirim türleri
  static const String typeMessage = 'message';
  static const String typeLikeAdvert = 'likeAdvert';
  static const String typeProfileViewed = 'profileViewed';

  // Servisi başlatma metodu
  Future<void> initialize() async {
    await _requestPermissions();
    _configureFCM();
  }

  // İzinleri isteme metodu
  Future<void> _requestPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // FCM token güncelleme metodu
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

  // FCM yapılandırma metodu
  void _configureFCM() {
    // Ön planda bildirim işleme
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Arka planda bildirim tıklama işleme
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundNotificationClick);
  }

  // Ön plandaki bildirimleri işleme metodu
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Ön planda bildirim alındı: ${message.notification?.title}');
    debugPrint('Ön planda bildirim alındı: ${message.notification?.body}');
    debugPrint('Bildirim data: ${message.data}');

    final String notificationType = message.data['type'] ?? '';

    // Mesaj dışındaki bildirimler için SharedPrefs'e kaydet
    if (notificationType != typeMessage) {
      _saveNotificationToLocal(message);
      return;
    }

    // Mesaj ise bildirim göster
    _showMessageNotification(message);
  }

  // Yerel bildirimleri kaydetme metodu
  void _saveNotificationToLocal(RemoteMessage message) {
    SharedPrefService.saveNotificationWithEnum(
      type: message.data['type'],
      body: message.notification?.body ?? '',
      title: message.notification?.title ?? '',
    );
    debugPrint('Bildirim kaydedildi');
  }

  // Mesaj bildirimi gösterme metodu
  void _showMessageNotification(RemoteMessage message) {
    final data = message.data;
    final chatId = data['chatId'];
    final senderId = data['senderId'];
    final receiverId = data['receiverId'];

    // Kullanıcı zaten ilgili sohbet sayfasındaysa bildirim gösterme
    if (chatId != null && AppRouter.router.routeInformationProvider.value.uri.path.contains('chats/$chatId')) {
      return;
    }

    // ScaffoldMess sınıfının showMessageBanner metodunu kullanarak üstte bildirim göster
    ScaffoldMess.showMessageBanner(
      title: message.notification?.title ?? 'Yeni Mesaj',
      message: message.notification?.body ?? '',
      backgroundColor: Colors.blue.shade800,
      duration: const Duration(seconds: 5),
      onViewPressed: () {
        _navigateToChat(chatId, senderId, receiverId);
      },
    );
  }

  // Sohbete yönlendirme metodu
  void _navigateToChat(String? chatId, String? senderId, String? receiverId) {
    if (chatId != null && senderId != null && receiverId != null) {
      AppRouter.router.push('/chats/$chatId?otherId=$senderId&currentId=$receiverId');
    }
  }

  // Arka plan bildirimi tıklama işleme metodu
  void _handleBackgroundNotificationClick(RemoteMessage message) {
    debugPrint('Arka planda bildirim tıklandı');

    final String notificationType = message.data['type'] ?? '';
    final data = message.data;

    // Bildirim türüne göre yönlendirme yap
    _navigateBasedOnNotificationType(notificationType, data);
  }

  // Bildirim türüne göre yönlendirme metodu
  void _navigateBasedOnNotificationType(String notificationType, Map<String, dynamic> data) {
    final chatId = data['chatId'];
    final senderId = data['senderId'];
    final receiverId = data['receiverId'];

    switch (notificationType) {
      case typeMessage:
        _navigateToChat(chatId, senderId, receiverId);
        break;

      case typeLikeAdvert:
        AppRouter.router.push('/myAdverts');
        break;

      case typeProfileViewed:
        if (senderId != null) {
          AppRouter.router.push('/profile/$senderId');
        }
        break;

      default:
        debugPrint('Bilinmeyen bildirim türü: $notificationType');
        break;
    }
  }

  // Bildirim gönderme metodu
  Future<void> sendNotification({
    required String receiverId,
    required String notificationType,
    String? chatId,
  }) async {
    try {
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

  /// Firestore koleksiyon kopyalama yardımcı metodu
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
