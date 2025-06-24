import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:palseapp/core/models/notification_model.dart';
import 'package:palseapp/core/routes/app_router.dart';
import 'package:palseapp/core/routes/routes.dart' as Routes;
import 'package:palseapp/core/services/shared_pref_service.dart';
import 'package:flutter/foundation.dart';

// NotificationService sınıfı - bildirim yönetimi için genel sınıf
class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Flutter Local Notifications için plugin tanımla
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Bildirim kanalı ID'si
  static const String _channelId = 'high_importance_channel';
  static const String _channelName = 'Yüksek Öncelikli Bildirimler';
  static const String _channelDescription =
      'Bu kanal önemli bildirimler için kullanılır.';

  // Servisi başlatma metodu
  Future<void> initialize() async {
    debugPrint('📢 NotificationService başlatılıyor...');

    // Önce Android için yüksek öncelikli bildirim kanalı oluştur
    await _createHighPriorityChannel();

    // Önce izinleri isteyelim
    await _requestPermissions();

    // FCM yapılandırmasını ayarlayalım
    _configureFCM();

    // Token kontrolü yapalım
    _checkFcmToken();

    debugPrint('📢 NotificationService başlatma tamamlandı!');
  }

  // Android için yüksek öncelikli bildirim kanalı oluştur
  Future<void> _createHighPriorityChannel() async {
    if (Platform.isAndroid) {
      try {
        debugPrint(
            '📢 Android için yüksek öncelikli bildirim kanalı oluşturuluyor...');

        // Android bildirim kanalını tanımla
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          _channelId, // id
          _channelName, // title
          description: _channelDescription, // description
          importance:
              Importance.max, // Yüksek öncelikli kanal (heads-up notification)
        );

        // Kanalı oluştur (eğer varsa günceller)
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);

        debugPrint(
            '📢 Android için yüksek öncelikli bildirim kanalı oluşturuldu!');

        // Not: AndroidManifest.xml dosyasına da aşağıdaki meta-data'yı eklemen gerekiyor:
        // <meta-data
        //   android:name="com.google.firebase.messaging.default_notification_channel_id"
        //   android:value="high_importance_channel" />

        // Flutter Local Notifications'ı başlat
        await _initializeLocalNotifications();
      } catch (e) {
        debugPrint('📢 Bildirim kanalı oluşturma hatası: $e');
      }
    }
  }

  // Flutter Local Notifications'ı başlat
  Future<void> _initializeLocalNotifications() async {
    // Bildirim ikon ayarları
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Android icon

    // iOS bildirim ayarları
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false, // İzinleri FCM ile alacağız
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // Tüm platformlar için başlatma ayarları
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Plugin'i başlat
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      // Bildirime tıklama olayını yakalama (opsiyonel)
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('📢 Yerel bildirime tıklandı: ${response.payload}');
        // Payload varsa, işle ve yönlendir
        if (response.payload != null && response.payload!.isNotEmpty) {
          // Bildirime tıklayınca navigate işlemi yap
          _handleLocalNotificationClick(response.payload!);
        }
      },
    );

    debugPrint('📢 Yerel bildirim ayarları yapılandırıldı.');
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
      debugPrint(
          '📢 FCM Token: ${token?.substring(0, 20)}... (ilk 20 karakter)');
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
    // FCM izin kontrolü
    _firebaseMessaging.getNotificationSettings().then((settings) {
      debugPrint('📢 FCM bildirim ayarları: ${settings.authorizationStatus}');
    });

    // Ön planda bildirim işleme
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('📢 FCM onMessage tetiklendi!');
      debugPrint(
          '📢 Mesaj bilgileri: messageId=${message.messageId}, senderId=${message.senderId}');
      debugPrint(
          '📢 Bildirim: ${message.notification?.title ?? "başlık yok"} - ${message.notification?.body ?? "içerik yok"}');
      debugPrint('📢 Data: ${message.data}');

      // Ön plandayken bildirim geldiği an kaydet
      _saveNotification(message);

      // Android için ön plandayken heads-up notification göster
      _showHeadsUpNotification(message);
    });

    // Arka planda bildirim tıklama işleme
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('📢 onMessageOpenedApp tetiklendi! Bildirim tıklandı!');

      // Arka plandayken tıklanınca önce kaydet sonra yönlendir
      _saveNotification(message);
      _navigateForNotification(message);
    });

    // Bildirim iznini kontrol et ve yenile
    _refreshNotificationPermission();

    _getInitialMessage();
  }

  // Bildirim izinlerini kontrol et ve yenile
  Future<void> _refreshNotificationPermission() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      debugPrint('📢 Mevcut bildirim izni: ${settings.authorizationStatus}');

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint(
            '📢 Bildirim izni eksik veya kısıtlı, yeniden izin isteniyor...');
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
      RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('📢 Uygulama bildirimden açıldı!');

        // Tamamen kapalıyken bildirime tıklayınca önce kaydet sonra yönlendir
        _saveNotification(initialMessage);
        _navigateForNotification(initialMessage);
      } else {
        debugPrint('📢 Uygulama normal şekilde açıldı');
      }
    } catch (e) {
      debugPrint('📢 İlk mesaj kontrolü hatası: $e');
    }
  }

  // Bildirimi yerel depolamaya kaydet
  void _saveNotification(RemoteMessage message) {
    try {
      final NotificationType notificationType = message.data['type'] != null
          ? NotificationType.values.byName(message.data['type'])
          : NotificationType.message;

      // Mesaj tipinde bildirimleri kaydetme, diğerlerini kaydet
      if (notificationType != NotificationType.message) {
        debugPrint('📢 Bildirim yerel depolamaya kaydediliyor...');

        SharedPrefService.saveNotificationWithEnum(
          type: notificationType.name,
          body: message.notification?.body ?? '',
          title: message.notification?.title ?? '',
        );

        debugPrint('📢 Bildirim kaydedildi: $notificationType');
      }
    } catch (e) {
      debugPrint('📢 Bildirim kaydetme hatası: $e');
    }
  }

  // Bildirim için yönlendirme yap
  void _navigateForNotification(RemoteMessage message) {
    try {
      final NotificationType notificationType = message.data['type'] != null
          ? NotificationType.values.byName(message.data['type'])
          : NotificationType.message;
      debugPrint(
          '📢 Bildirime tıklandı, yönlendirme yapılıyor: $notificationType');
      _navigateBasedOnNotificationType(notificationType, message.data);
    } catch (e) {
      debugPrint('📢 Bildirim yönlendirme hatası: $e');
    }
  }

  // Bildirim türüne göre yönlendirme metodu
  void _navigateBasedOnNotificationType(
      NotificationType notificationType, Map<String, dynamic> data) {
    final chatId = data['chatId'];
    final senderId = data['senderId'];
    final receiverId = data['receiverId'];

    switch (notificationType) {
      case NotificationType.message:
        AppRouter.router
            .push('/chats/$chatId?otherId=$senderId&currentId=$receiverId');
        break;

      case NotificationType.likeAdvert:
        AppRouter.router.pushNamed(Routes.myAdverts);
        break;

      case NotificationType.profileViewed:
        AppRouter.router.pushNamed(Routes.recentlyViewers);
        break;

      case NotificationType.newAdvertInInterestArea:
        AppRouter.router.pushNamed(Routes.byInterest);
        break;

      case NotificationType.comment:
        AppRouter.router.pushNamed(Routes.comment);
        break;

      case NotificationType.joinRequest:
        AppRouter.router.pushNamed(Routes.myAdverts);
        break;

      default:
        debugPrint('Bilinmeyen bildirim türü: $notificationType');

        break;
    }
  }

  // Android için ön plandayken heads-up notification gösterme
  void _showHeadsUpNotification(RemoteMessage message) {
    if (Platform.isAndroid && message.notification != null) {
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null) {
        // Bildirim payloadını oluştur - JSON formatında bilgileri saklayalım
        final Map<String, dynamic> notificationData = {
          'messageId': message.messageId,
          ...message.data, // tüm data'yı ekle
        };
        final String payload = notificationData.toString();

        _flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              importance: Importance.max,
              priority: Priority.high,
              icon: android?.smallIcon ?? '@mipmap/ic_stat_ic_launcher',
            ),
          ),
          // JSON formatında mesaj verilerini payloada ekle
          payload: payload,
        );
        debugPrint('📢 Android için heads-up notification gösterildi');
      }
    }
  }

  // Yerel bildirime tıklanınca çağrılan metot
  void _handleLocalNotificationClick(String payload) {
    try {
      debugPrint('📢 Yerel bildirime tıklandı, navigate yapılıyor...');

      // String payload'ı Map'e çevirme işlemi
      // Basit bir yaklaşım - regex kullanarak string map'i parse etmek
      final Map<String, dynamic> data = {};

      // {key: value, key2: value2} formatında gelen string'i parse et
      final pattern = RegExp(r'([^:,{\s]+)(?:\s*:\s*)([^,}]+)');
      final matches = pattern.allMatches(payload);

      for (var match in matches) {
        if (match.groupCount >= 2) {
          final key = match.group(1)?.trim().replaceAll("'", "") ?? "";
          final value = match.group(2)?.trim().replaceAll("'", "") ?? "";
          data[key] = value;
        }
      }

      // Bildirim tipini belirle
      final notificationType = data['type'] != null
          ? NotificationType.values.byName(data['type'])
          : NotificationType.message;

      // Kullanıcıyı bildirim tipine göre yönlendir
      _navigateBasedOnNotificationType(notificationType, data);
    } catch (e) {
      debugPrint('📢 Yerel bildirim tıklama işleme hatası: $e');
    }
  }
}
