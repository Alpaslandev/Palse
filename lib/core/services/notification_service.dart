import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/routes/app_router.dart';
import 'package:palseapp/core/routes/routes.dart' as Routes;
import 'package:palseapp/core/services/shared_pref_service.dart';

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
    debugPrint('📢 NotificationService başlatılıyor...');

    // Önce izinleri isteyelim
    await _requestPermissions();

    // FCM yapılandırmasını ayarlayalım
    _configureFCM();

    // Token kontrolü yapalım
    _checkFcmToken();

    debugPrint('📢 NotificationService başlatma tamamlandı!');
  }

  // İzinleri isteme metodu
  Future<void> _requestPermissions() async {
    debugPrint('📢 Bildirim izinleri isteniyor...');

    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('📢 Bildirim izin durumu: ${settings.authorizationStatus}');

      // Ön planda bildirimleri göstermek için ayarlar
      // Bu, uygulamanın ön planda olması durumunda bile bildirim alanında görünmesini sağlar
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true, // iOS/macOS için sistem uyarısı gösterme seçeneği
        badge: true, // iOS/macOS için uygulama simgesi rozeti
        sound: true, // Bildirim sesi
      );

      debugPrint('📢 Ön plan bildirim görüntüleme ayarları yapılandırıldı.');
    } catch (e) {
      debugPrint('📢 Bildirim izni hatası: $e');
    }
  }

  // Token kontrolü
  Future<void> _checkFcmToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      debugPrint('📢 FCM Token: ${token?.substring(0, 20)}... (ilk 20 karakter)');
    } catch (e) {
      debugPrint('📢 Token kontrol hatası: $e');
    }
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
    debugPrint('📢 FCM yapılandırması başlatılıyor...');

    // FCM izin kontrolü
    _firebaseMessaging.getNotificationSettings().then((settings) {
      debugPrint('📢 FCM bildirim ayarları: ${settings.authorizationStatus}');
    });

    // Ön planda bildirim işleme
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('📢 FCM onMessage tetiklendi!');
      debugPrint('📢 Mesaj bilgileri: messageId=${message.messageId}, senderId=${message.senderId}');
      debugPrint('📢 Bildirim: ${message.notification?.title ?? "başlık yok"} - ${message.notification?.body ?? "içerik yok"}');
      debugPrint('📢 Data: ${message.data}');

      // Ön plandayken gelen notificationlar için data bilgisini işle
      _handleForegroundMessageData(message);
    });

    // Arka planda bildirim tıklama işleme
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('📢 onMessageOpenedApp tetiklendi! Bildirim tıklandı!');
      _handleBackgroundNotificationClick(message);
    });

    // Bildirim iznini kontrol et ve yenile
    _refreshNotificationPermission();

    debugPrint('📢 FCM yapılandırması tamamlandı!');
    _getInitialMessage();
  }

  // Bildirim izinlerini kontrol et ve yenile
  Future<void> _refreshNotificationPermission() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      debugPrint('📢 Mevcut bildirim izni: ${settings.authorizationStatus}');

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint('📢 Bildirim izni eksik veya kısıtlı, yeniden izin isteniyor...');
        final newSettings = await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
          criticalAlert: true,
          announcement: true,
        );
        debugPrint('📢 Yeni bildirim izni: ${newSettings.authorizationStatus}');
      }
    } catch (e) {
      debugPrint('📢 Bildirim izni kontrolü hatası: $e');
    }
  }

  // İlk açılıştaki bildirimi kontrol et
  Future<void> _getInitialMessage() async {
    try {
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('📢 Uygulama bildirimden açıldı!');
        _handleBackgroundNotificationClick(initialMessage);
      } else {
        debugPrint('📢 Uygulama normal şekilde açıldı');
      }
    } catch (e) {
      debugPrint('📢 İlk mesaj kontrolü hatası: $e');
    }
  }

  // Ön plandayken gelen bildirimlerin data bilgisini işle
  void _handleForegroundMessageData(RemoteMessage message) {
    try {
      final String notificationType = message.data['type'] ?? '';

      // Mesaj dışındaki bildirimler için SharedPrefs'e kaydet
      if (notificationType != typeMessage) {
        debugPrint('📢 Ön planda mesaj DIŞI bildirim alındı, locale kaydediliyor...');
        _saveNotificationToLocal(message);
      }
    } catch (e) {
      debugPrint('📢 Ön plan bildirim data işleme hatası: $e');
    }
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
        AppRouter.router.push('/chats/$chatId?otherId=$senderId&currentId=$receiverId');
        break;

      case typeLikeAdvert:
        AppRouter.router.pushNamed(Routes.myAdverts);
        break;

      case typeProfileViewed:
        if (senderId != null) {
          AppRouter.router.pushNamed(Routes.profile);
        }
        break;

      default:
        debugPrint('Bilinmeyen bildirim türü: $notificationType');
        break;
    }
  }
}
