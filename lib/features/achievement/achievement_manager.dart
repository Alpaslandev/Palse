import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:palseapp/core/services/notification_service.dart';
import 'package:palseapp/core/services/shared_pref_service.dart';
import 'package:palseapp/core/constant/notifications_enum.dart';
import 'package:palseapp/core/widgets/scaffold_mess.dart';
import 'package:palseapp/features/achievement/user_rank.dart';
import 'package:palseapp/features/achievement/xp_events.dart';
import 'package:palseapp/features/achievement/premium_rewards.dart';
import 'package:palseapp/core/localization/locale_manager.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Tüm başarı sistemi işlemlerini merkezi olarak yöneten sınıf
class AchievementManager {
  // Singleton yapısı
  static final AchievementManager _instance = AchievementManager._internal();
  factory AchievementManager() => _instance;
  AchievementManager._internal();

  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SharedPreferences anahtarları
  static const String _dailyTaskResetTimeKey = 'dailyTaskResetTime';
  static const String _completedTasksKey = 'completedTasks';
  static const String _totalXpKey = 'totalXp';
  static const String _lastDailyTaskDateKey = 'lastDailyTaskDate';

  // Görev sıfırlama süresi (24 saat)
  static const Duration _dailyTaskResetDuration = Duration(hours: 24);

  //
  // TEMEL XP İŞLEMLERİ
  //

  /// Kullanıcının toplam XP değerini Firestore'dan getirir
  Future<int> getUserXp(String userId) async {
    try {
      // Önce local'den kontrol et
      final prefs = await SharedPreferences.getInstance();
      final localXp = prefs.getInt('${userId}_$_totalXpKey');

      if (localXp != null) {
        return localXp;
      }

      // Local'de yoksa Firestore'dan getir
      final userDoc = await _firestore.collection('customers').doc(userId).get();
      if (userDoc.exists && userDoc.data()!.containsKey('xp')) {
        final xp = userDoc.data()!['xp'] as int;

        // Local'e kaydet
        await prefs.setInt('${userId}_$_totalXpKey', xp);

        return xp;
      }

      return 0;
    } catch (e) {
      debugPrint('XP getirme hatası: $e');
      return 0;
    }
  }

  /// Kullanıcıya XP ekler ve Firestore'a kaydeder
  Future<int> addXp(String userId, int amount) async {
    if (userId.isEmpty || amount <= 0) {
      return 0;
    }

    try {
      // Mevcut XP'yi getir
      final currentXp = await getUserXp(userId);
      final newXp = currentXp + amount;

      // Firestore'a kaydet
      await _firestore.collection('customers').doc(userId).update({
        'xp': newXp,
      });

      // Local'e kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${userId}_$_totalXpKey', newXp);

      // Seviye atlama kontrolü
      final oldRank = UserRank.fromXp(currentXp);
      final newRank = UserRank.fromXp(newXp);

      if (oldRank != newRank) {
        await _sendRankUpNotification(newRank, userId);
      }

      return newXp;
    } catch (e) {
      debugPrint('XP ekleme hatası: $e');
      return await getUserXp(userId);
    }
  }

  /// Belirli bir XP olayı için XP kazandırır
  Future<int> earnXpForEvent(String userId, XpEvent event) async {
    if (userId.isEmpty) {
      return 0;
    }

    // Görevin tamamlanabilir olup olmadığını kontrol et
    if (!await canCompleteTask(userId, event)) {
      debugPrint('${event.name} görevi şu anda tamamlanamaz');
      return await getUserXp(userId);
    }

    // Görev tamamlama sayısını güncelle
    await _updateTaskCompletionCount(userId, event);

    // XP ekle
    final newXp = await addXp(userId, event.xpAmount);

    // Görev tamamlama bildirimi gönder
    await _sendTaskCompletionNotification(event, userId);

    return newXp;
  }

  //
  // GÖREV YÖNETİMİ
  //

  /// Bir görevin tamamlanabilir olup olmadığını kontrol eder
  Future<bool> canCompleteTask(String userId, XpEvent event) async {
    // Günlük görevler için kontrol
    if (event.isDaily) {
      return await _canCompleteDailyTask(userId, event);
    }

    // Tekrarlanabilir görevler her zaman tamamlanabilir
    if (event.isRepeatable) {
      return true;
    }

    // Tek seferlik görevler için kontrol
    final completionCount = await _getTaskCompletionCount(userId, event);
    return completionCount == 0;
  }

  /// Günlük görevlerin tamamlanabilir olup olmadığını kontrol eder
  Future<bool> _canCompleteDailyTask(String userId, XpEvent event) async {
    if (!event.isDaily) return true;

    final prefs = await SharedPreferences.getInstance();
    final lastResetTimeStr = prefs.getString('${userId}_$_dailyTaskResetTimeKey');

    if (lastResetTimeStr == null) {
      // Hiç sıfırlanmamış, tamamlanabilir
      return true;
    }

    final lastResetTime = DateTime.parse(lastResetTimeStr);
    final now = DateTime.now();

    // 24 saat geçmiş mi kontrol et
    if (now.isAfter(lastResetTime)) {
      // Sıfırlama zamanı geçmiş, görev tamamlanabilir
      return true;
    }

    // Görev tamamlama sayısını kontrol et
    final completionCount = await _getTaskCompletionCount(userId, event);
    return completionCount == 0;
  }

  /// Günlük görevleri sıfırlar
  Future<void> resetDailyTasks(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    // Tüm tamamlanmış görevleri getir
    final completedTasksJson = prefs.getString('${userId}_$_completedTasksKey') ?? '{}';
    final completedTasks = Map<String, int>.from(json.decode(completedTasksJson));

    // Günlük görevleri sıfırla
    for (final event in XpEvent.values) {
      if (event.isDaily) {
        completedTasks[event.name] = 0;
      }
    }

    // Güncellenmiş görevleri kaydet
    await prefs.setString('${userId}_$_completedTasksKey', json.encode(completedTasks));

    // Yeni sıfırlama zamanını ayarla
    final now = DateTime.now();
    final nextResetTime = now.add(_dailyTaskResetDuration);
    await prefs.setString('${userId}_$_dailyTaskResetTimeKey', nextResetTime.toIso8601String());

    debugPrint('Günlük görevler sıfırlandı! Yeni sıfırlama zamanı: ${nextResetTime.toIso8601String()}');
  }

  /// Görev tamamlama sayısını günceller
  Future<void> _updateTaskCompletionCount(String userId, XpEvent event) async {
    final prefs = await SharedPreferences.getInstance();

    // Tamamlanmış görevleri getir
    final completedTasksJson = prefs.getString('${userId}_$_completedTasksKey') ?? '{}';
    final completedTasks = Map<String, int>.from(json.decode(completedTasksJson));

    // Görev sayısını artır
    completedTasks[event.name] = (completedTasks[event.name] ?? 0) + 1;

    // Güncellenmiş görevleri kaydet
    await prefs.setString('${userId}_$_completedTasksKey', json.encode(completedTasks));

    // Günlük görev ise, son tamamlama tarihini güncelle
    if (event.isDaily) {
      final now = DateTime.now();
      await prefs.setString('${userId}_$_lastDailyTaskDateKey', now.toIso8601String());

      // Sıfırlama zamanını ayarla
      final resetTime = now.add(_dailyTaskResetDuration);
      await prefs.setString('${userId}_$_dailyTaskResetTimeKey', resetTime.toIso8601String());
    }

    debugPrint('Görev tamamlama sayısı güncellendi: ${event.name} -> ${completedTasks[event.name]}');
  }

  /// Görev tamamlama sayısını getirir
  Future<int> _getTaskCompletionCount(String userId, XpEvent event) async {
    final prefs = await SharedPreferences.getInstance();

    // Tamamlanmış görevleri getir
    final completedTasksJson = prefs.getString('${userId}_$_completedTasksKey') ?? '{}';
    final completedTasks = Map<String, int>.from(json.decode(completedTasksJson));

    return completedTasks[event.name] ?? 0;
  }

  //
  // RANK VE PROGRESS HESAPLAMA
  //

  /// Kullanıcının mevcut rütbesini getirir
  UserRank getUserRank(int xp) {
    return UserRank.fromXp(xp);
  }

  /// Rütbe ilerleme yüzdesini hesaplar
  double getRankProgressPercentage(int xp) {
    final rank = UserRank.fromXp(xp);

    if (rank == UserRank.master) {
      return 1.0; // En üst seviye için %100
    }

    final totalRangeXp = rank.maxXp - rank.minXp;
    final userProgressInRange = xp - rank.minXp;

    return (userProgressInRange / totalRangeXp).clamp(0.0, 1.0);
  }

  /// Bir sonraki rütbeye geçmek için gereken XP miktarını hesaplar
  int getXpToNextRank(int xp) {
    final rank = UserRank.fromXp(xp);

    if (rank == UserRank.master) {
      return 0; // En üst seviyede olduğu için 0
    }

    return (rank.maxXp - xp + 1).toInt();
  }

  //
  // BİLDİRİM İŞLEMLERİ
  //

  /// Görev tamamlama bildirimi gönderir
  Future<void> _sendTaskCompletionNotification(XpEvent event, String userId) async {
    final title = 'Görev Tamamlandı!';
    final body = '${event.xpAmount} XP kazandın: ${LocaleManager.translate(event.descriptionKey)}';

    // Bildirim servisi yerine sadece debug log yazıyoruz
    // ScaffoldMessenger kullanımı için gerekli bilgiyi saklıyoruz
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString('${userId}_recentCompletedTasks') ?? '[]';
    final tasks = List<Map<String, dynamic>>.from(
      (json.decode(tasksJson) as List).cast<Map<String, dynamic>>(),
    );

    // Son tamamlanan görevi ekleyelim
    tasks.add({
      'event_name': event.name,
      'xp_amount': event.xpAmount,
      'description_key': event.descriptionKey,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Son 5 görevi tutalım
    if (tasks.length > 5) {
      tasks.removeAt(0);
    }

    // Güncellenmiş görevleri kaydedelim
    await prefs.setString('${userId}_recentCompletedTasks', json.encode(tasks));

    debugPrint('🎉 Görev tamamlama bildirimi: $title - $body');
  }

  /// Seviye atlama bildirimi gönderir
  Future<void> _sendRankUpNotification(UserRank newRank, String userId) async {
    final title = 'Yeni Seviye!';
    final body = 'Tebrikler! ${LocaleManager.translate(newRank.titleKey)} seviyesine ulaştın!';

    // Bildirim servisi yerine SharedPreferences'a kaydediyoruz
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${userId}_lastRankUp', newRank.name);
    await prefs.setString('${userId}_lastRankUpDate', DateTime.now().toIso8601String());

    // ScaffoldMessenger için global bir key kullanılamadığından, bu bilgi sonradan
    // ilgili sayfada gösterilmek üzere kaydedilir.
    debugPrint('🏆 Yeni seviye bildirimi: $title - $body');
  }

  //
  // YERELLEŞTIRME METODLARI
  //

  /// Görev açıklamasını yerelleştirilmiş olarak döndürür
  String getLocalizedTaskDescription(XpEvent event, [BuildContext? context]) {
    if (context != null) {
      return context.tr(event.descriptionKey);
    }
    return LocaleManager.translate(event.descriptionKey);
  }

  /// Unvan başlığını yerelleştirilmiş olarak döndürür
  String getLocalizedRankTitle(UserRank rank, [BuildContext? context]) {
    if (context != null) {
      return context.tr(rank.titleKey);
    }
    return LocaleManager.translate(rank.titleKey);
  }

  /// Grup başlığını yerelleştirilmiş olarak döndürür
  String getLocalizedGroupTitle(XpEventGroup group, [BuildContext? context]) {
    if (context != null) {
      return context.tr(group.titleKey);
    }
    return LocaleManager.translate(group.titleKey);
  }

  //
  // TEST VE LOGLAMA METODLARI
  //

  /// Kullanıcının tamamladığı görevleri getirir
  Future<Map<String, int>> getCompletedTasks(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    // Tamamlanmış görevleri getir
    final completedTasksJson = prefs.getString('${userId}_$_completedTasksKey') ?? '{}';
    final completedTasks = Map<String, int>.from(json.decode(completedTasksJson));

    return completedTasks;
  }

  /// Günlük görevlerin durumunu kontrol eder ve debug bilgisi döndürür
  Future<Map<String, dynamic>> checkDailyTasksStatus(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    // Son sıfırlama zamanını getir
    final lastResetTimeStr = prefs.getString('${userId}_$_dailyTaskResetTimeKey');
    final DateTime? lastResetTime = lastResetTimeStr != null ? DateTime.parse(lastResetTimeStr) : null;

    // Son günlük görev tarihini getir
    final lastDailyTaskDateStr = prefs.getString('${userId}_$_lastDailyTaskDateKey');
    final DateTime? lastDailyTaskDate = lastDailyTaskDateStr != null ? DateTime.parse(lastDailyTaskDateStr) : null;

    // Tamamlanmış görevleri getir
    final completedTasks = await getCompletedTasks(userId);

    // Günlük görevlerin durumlarını kontrol et
    final isDailyLoginCompletable = await canCompleteTask(userId, XpEvent.dailyLogin);
    final isDailyCreateListingCompletable = await canCompleteTask(userId, XpEvent.dailyCreateListing);
    final isDailySendMessageCompletable = await canCompleteTask(userId, XpEvent.dailySendMessage);

    // Görevlerin tamamlanma sayılarını getir
    final dailyLoginCount = completedTasks[XpEvent.dailyLogin.name] ?? 0;
    final dailyCreateListingCount = completedTasks[XpEvent.dailyCreateListing.name] ?? 0;
    final dailySendMessageCount = completedTasks[XpEvent.dailySendMessage.name] ?? 0;

    // Şu anki zaman
    final now = DateTime.now();

    // Bir sonraki sıfırlamaya kalan süre
    final Duration? timeUntilReset = lastResetTime != null ? lastResetTime.difference(now) : null;

    return {
      'last_reset_time': lastResetTime?.toIso8601String() ?? 'Hiç sıfırlanmamış',
      'last_daily_task_date': lastDailyTaskDate?.toIso8601String() ?? 'Hiç tamamlanmamış',
      'time_until_reset': timeUntilReset != null ? '${timeUntilReset.inHours} saat ${timeUntilReset.inMinutes % 60} dakika' : 'Bilinmiyor',
      'completed_tasks': completedTasks,
      'daily_login': {'completable': isDailyLoginCompletable, 'completion_count': dailyLoginCount},
      'daily_create_listing': {'completable': isDailyCreateListingCompletable, 'completion_count': dailyCreateListingCount},
      'daily_send_message': {'completable': isDailySendMessageCompletable, 'completion_count': dailySendMessageCount}
    };
  }

  /// Test amaçlı olarak belirli bir görevi tamamlandı olarak işaretler
  Future<void> completeTaskForTesting(String userId, XpEvent event) async {
    await _updateTaskCompletionCount(userId, event);

    // Bilgi mesajı
    debugPrint('🔄 Test için görev tamamlandı: ${event.name}');
  }

  /// Test amaçlı olarak belirli bir günlük görevin sıfırlama zamanını geçmiş olarak ayarlar
  Future<void> setDailyTaskAsExpired(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    // Sıfırlama zamanını dün olarak ayarla
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await prefs.setString('${userId}_$_dailyTaskResetTimeKey', yesterday.toIso8601String());

    // Bilgi mesajı
    debugPrint('🔄 Günlük görev sıfırlama zamanı dün olarak ayarlandı');
  }
}
