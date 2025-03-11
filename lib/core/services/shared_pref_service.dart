import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class SharedPrefService {
  static SharedPreferences? _prefs;

  // Bildirim sayısı için stream controller
  static final StreamController<int> _notificationCountController = StreamController<int>.broadcast();

  // Bildirim sayısı stream'i
  static Stream<int> get notificationCountStream => _notificationCountController.stream;

  // SharedPreferences'ı başlat
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // İlk değeri stream'e gönder
    _updateNotificationCount();
  }
  // ----- BİLDİRİM İŞLEMLERİ İÇİN ÖZEL METODLAR -----

  static const String _notificationsKey = 'local_notifications';

  // Bildirimi NotificationsEnum ile kaydet
  static Future<bool> saveNotificationWithEnum({
    required String type,
    required String body,
    required String title,
  }) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();

      // Mevcut bildirimleri al
      List<String> savedNotifications = _prefs!.getStringList(_notificationsKey) ?? [];

      // Bildirim içeriğini oluştur
      final notification = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'body': body,
        'title': title,
        'type': type,
        'receivedAt': DateTime.now().toIso8601String(),
        'read': false
      };

      // Bildirimi ekle
      savedNotifications.add(jsonEncode(notification));

      // Kaydet
      final result = await _prefs!.setStringList(_notificationsKey, savedNotifications);

      // Bildirim sayısını güncelle ve stream'e gönder
      _updateNotificationCount();

      return result;
    } catch (e) {
      debugPrint("Bildirim kaydedilirken hata: $e");
      return false;
    }
  }

  static Future<bool> removeNotification(int index) async {
    _prefs ??= await SharedPreferences.getInstance();
    List<String> savedNotifications = _prefs!.getStringList(_notificationsKey) ?? [];
    savedNotifications.removeAt(index);
    final result = await _prefs!.setStringList(_notificationsKey, savedNotifications);

    // Bildirim sayısını güncelle ve stream'e gönder
    _updateNotificationCount();

    return result;
  }

  // Tüm bildirimleri getir
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      List<String> savedNotifications = _prefs!.getStringList(_notificationsKey) ?? [];

      // String'den Map'e dönüştür
      List<Map<String, dynamic>> notifications =
          savedNotifications.map((notificationStr) => jsonDecode(notificationStr) as Map<String, dynamic>).toList();

      return notifications;
    } catch (e) {
      debugPrint("Yerel bildirimler alınırken hata: $e");
      return [];
    }
  }

  // Bildirimi okundu olarak işaretle
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      List<String> savedNotifications = _prefs!.getStringList(_notificationsKey) ?? [];

      if (savedNotifications.isEmpty) return false;

      // String'den Map'e dönüştür
      List<Map<String, dynamic>> notifications =
          savedNotifications.map((notificationStr) => jsonDecode(notificationStr) as Map<String, dynamic>).toList();

      bool updated = false;

      // Bildirimi bul ve güncelle
      for (int i = 0; i < notifications.length; i++) {
        if (notifications[i]['id'] == notificationId) {
          notifications[i]['read'] = true;
          savedNotifications[i] = jsonEncode(notifications[i]);
          updated = true;
          break;
        }
      }

      if (!updated) return false;

      // Güncellenen listeyi kaydet
      final result = await _prefs!.setStringList(_notificationsKey, savedNotifications);

      // Bildirim sayısını güncelle ve stream'e gönder
      _updateNotificationCount();

      return result;
    } catch (e) {
      debugPrint("Bildirim okundu işaretlenirken hata: $e");
      return false;
    }
  }

  // Tüm bildirimleri okundu olarak işaretle
  static Future<bool> markAllNotificationsAsRead() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      List<String> savedNotifications = _prefs!.getStringList(_notificationsKey) ?? [];

      if (savedNotifications.isEmpty) return false;

      // String'den Map'e dönüştür
      List<Map<String, dynamic>> notifications =
          savedNotifications.map((notificationStr) => jsonDecode(notificationStr) as Map<String, dynamic>).toList();

      // Tüm bildirimleri güncelle
      for (int i = 0; i < notifications.length; i++) {
        notifications[i]['read'] = true;
        savedNotifications[i] = jsonEncode(notifications[i]);
      }

      // Güncellenen listeyi kaydet
      final result = await _prefs!.setStringList(_notificationsKey, savedNotifications);

      // Bildirim sayısını güncelle ve stream'e gönder
      _updateNotificationCount();

      return result;
    } catch (e) {
      debugPrint("Tüm bildirimler okundu işaretlenirken hata: $e");
      return false;
    }
  }

  // Okunmamış bildirim sayısını getir
  static Future<int> getUnreadNotificationsCount() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      List<String> savedNotifications = _prefs!.getStringList(_notificationsKey) ?? [];

      if (savedNotifications.isEmpty) return 0;

      // String'den Map'e dönüştür
      List<Map<String, dynamic>> notifications =
          savedNotifications.map((notificationStr) => jsonDecode(notificationStr) as Map<String, dynamic>).toList();

      // Okunmamış bildirimleri say
      return notifications.where((notification) => notification['read'] == false).length;
    } catch (e) {
      debugPrint("Okunmamış bildirim sayısı alınırken hata: $e");
      return 0;
    }
  }

  // Bildirim sayısını güncelle ve stream'e gönder
  static Future<void> _updateNotificationCount() async {
    final count = await getUnreadNotificationsCount();
    _notificationCountController.add(count);
  }

  static Future<void> clearNotifications() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_notificationsKey);

    // Bildirim sayısını güncelle ve stream'e gönder
    _updateNotificationCount();

    debugPrint('Bildirimler temizlendi');
  }

  // Uygulama kapanırken stream'i kapat
  static void dispose() {
    _notificationCountController.close();
  }
}
