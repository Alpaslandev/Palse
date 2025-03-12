import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

/// Achievement sistemi için tek merkezi sınıf
class AchievementService {
  // Singleton yapısı
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SharedPreferences anahtarları
  static const String _dailyTaskResetTimeKey = 'dailyTaskResetTime';
  static const String _completedTasksKey = 'completedTasks';
  static const String _totalXpKey = 'totalXp';
  static const String _lastDailyTaskDateKey = 'lastDailyTaskDate';
  static const String _recentRankUpKey = 'recentRankUp';

  // Ödüllendirilmiş sohbetleri tutacak anahtarlar
  static const String _firstMessageSentKey = 'firstMessageSent';
  static const String _firstMessageReceivedKey = 'firstMessageReceived';

  // Görev sıfırlama süresi (24 saat)
  static const Duration _dailyTaskResetDuration = Duration(hours: 24);

  //
  // TEMEL XP İŞLEMLERİ
  //

  /// Kullanıcının toplam XP değerini Firestore'dan getirir
  Future<int> getUserXp(String userId) async {
    if (userId.isEmpty) {
      return 0;
    }

    try {
      // Önce yerel veriyi kontrol et
      final prefs = await SharedPreferences.getInstance();
      final localXp = prefs.getInt('${_totalXpKey}_$userId');

      if (localXp != null) {
        return localXp;
      }

      // Yerel veri yoksa Firestore'dan getir
      final userDoc = await _firestore.collection('customers').doc(userId).get();

      if (userDoc.exists && userDoc.data()!.containsKey('totalXp')) {
        final totalXp = userDoc.data()!['totalXp'] as int;

        // Yerel olarak da kaydet
        await prefs.setInt('${_totalXpKey}_$userId', totalXp);

        return totalXp;
      }

      return 0;
    } catch (e) {
      debugPrint('XP getirme hatası: $e');
      return 0;
    }
  }

  /// Kullanıcıya XP ekler (hem Firestore hem de yerel)
  Future<int> addXp(String userId, int amount) async {
    if (userId.isEmpty || amount <= 0) {
      return await getUserXp(userId);
    }

    try {
      // Mevcut XP değerini al
      final currentXp = await getUserXp(userId);
      final newXp = currentXp + amount;

      // Firestore'a kaydet
      await _firestore.collection('customers').doc(userId).update({
        'totalXp': newXp,
      });

      // Yerel veritabanına da kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${_totalXpKey}_$userId', newXp);

      // Seviye atlama kontrol et
      await _checkAndSendRankNotifications(currentXp, newXp, userId);

      return newXp;
    } catch (e) {
      debugPrint('XP ekleme hatası: $e');
      return await getUserXp(userId);
    }
  }

  /// Hem görev tamamlama hem de XP ekleme işlemlerini yapar
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

    // Görev tamamlama bildirimini göster (ScaffoldMessenger)
    _showTaskCompletionMessage(event);

    return newXp;
  }

  /// Belirli bir miktarda XP ekler (özel ödüller için)
  Future<int> earnCustomXp({required String userId, required int amount}) async {
    if (userId.isEmpty || amount <= 0) {
      debugPrint('Kullanıcı ID bulunamadı veya geçersiz XP miktarı, XP eklenemedi');
      return 0;
    }

    return await addXp(userId, amount);
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
    final lastResetTimeStr = prefs.getString('${_dailyTaskResetTimeKey}_$userId');

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

  /// Görev tamamlama sayısını günceller
  Future<void> _updateTaskCompletionCount(String userId, XpEvent event) async {
    final prefs = await SharedPreferences.getInstance();

    // Tamamlanmış görevleri getir
    final completedTasksJson = prefs.getString('${_completedTasksKey}_$userId') ?? '{}';
    final completedTasks = Map<String, int>.from(json.decode(completedTasksJson));

    // Görev sayısını artır
    completedTasks[event.name] = (completedTasks[event.name] ?? 0) + 1;

    // Güncellenmiş görevleri kaydet
    await prefs.setString('${_completedTasksKey}_$userId', json.encode(completedTasks));

    // Günlük görev ise, son tamamlama tarihini güncelle
    if (event.isDaily) {
      final now = DateTime.now();
      await prefs.setString('${_lastDailyTaskDateKey}_$userId', now.toIso8601String());

      // Tüm günlük görevlerin tamamlanıp tamamlanmadığını kontrol et
      final allDailyTasksCompleted = await _areAllDailyTasksCompleted(userId);

      // Eğer tüm günlük görevler tamamlandıysa, sıfırlama zamanını ayarla
      if (allDailyTasksCompleted) {
        final resetTime = now.add(_dailyTaskResetDuration);
        await prefs.setString('${_dailyTaskResetTimeKey}_$userId', resetTime.toIso8601String());
        debugPrint('Tüm günlük görevler tamamlandı! Yeni sıfırlama zamanı: ${resetTime.toIso8601String()}');
      }
    }
  }

  /// Tüm günlük görevlerin tamamlanıp tamamlanmadığını kontrol eder
  Future<bool> _areAllDailyTasksCompleted(String userId) async {
    final dailyTasks = XpEvent.values.where((event) => event.isDaily).toList();

    for (final task in dailyTasks) {
      final count = await _getTaskCompletionCount(userId, task);
      if (count == 0) {
        return false;
      }
    }

    return true;
  }

  /// Görev tamamlama sayısını getirir (private)
  Future<int> _getTaskCompletionCount(String userId, XpEvent event) async {
    final prefs = await SharedPreferences.getInstance();

    // Tamamlanmış görevleri getir
    final completedTasksJson = prefs.getString('${_completedTasksKey}_$userId') ?? '{}';
    final completedTasks = Map<String, int>.from(json.decode(completedTasksJson));

    return completedTasks[event.name] ?? 0;
  }

  /// Görev tamamlama sayısını getirir (public)
  Future<int> getTaskCompletionCount(String userId, XpEvent event) async {
    return _getTaskCompletionCount(userId, event);
  }

  /// Günlük görevleri sıfırlar
  Future<void> resetDailyTasks(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    // Tüm tamamlanmış görevleri getir
    final completedTasksJson = prefs.getString('${_completedTasksKey}_$userId') ?? '{}';
    final completedTasks = Map<String, int>.from(json.decode(completedTasksJson));

    // Günlük görevleri sıfırla
    for (final event in XpEvent.values) {
      if (event.isDaily) {
        completedTasks[event.name] = 0;
      }
    }

    // Güncellenmiş görevleri kaydet
    await prefs.setString('${_completedTasksKey}_$userId', json.encode(completedTasks));

    // Yeni sıfırlama zamanını ayarla
    final now = DateTime.now();
    final nextResetTime = now.add(_dailyTaskResetDuration);
    await prefs.setString('${_dailyTaskResetTimeKey}_$userId', nextResetTime.toIso8601String());

    ScaffoldMess.showSnackBar(LocaleManager.translate('notification_daily_task_reset_body'));
    debugPrint('Günlük görevler sıfırlandı! Yeni sıfırlama zamanı: ${nextResetTime.toIso8601String()}');
  }

  /// Kullanıcının tamamladığı görevleri getirir
  Future<Map<String, int>> getCompletedTasks(String userId) async {
    if (userId.isEmpty) return {};

    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString('${_completedTasksKey}_$userId');
    return tasksJson != null ? Map<String, int>.from(json.decode(tasksJson)) : {};
  }

  //
  // RANK VE PROGRESS HESAPLAMA
  //

  /// Kullanıcının mevcut rütbesini getirir
  UserRank getUserRankFromXp(int xp) {
    return UserRank.fromXp(xp);
  }

  /// Kullanıcının mevcut rütbesini getirir (userId ile)
  Future<UserRank> getUserRank(String userId) async {
    final totalXp = await getUserXp(userId);
    return UserRank.fromXp(totalXp);
  }

  /// Rütbe ilerleme yüzdesini hesaplar
  double getRankProgressPercentage(UserRank rank, int currentXp) {
    if (rank == UserRank.master) {
      return 1.0; // En üst seviye için %100
    }

    final totalRangeXp = rank.maxXp - rank.minXp;
    final userProgressInRange = currentXp - rank.minXp;

    return (userProgressInRange / totalRangeXp).clamp(0.0, 1.0);
  }

  /// Bir sonraki unvana geçmek için gereken XP miktarını hesaplayan metod
  int calculateXpToNextRank(UserRank rank, int currentXp) {
    if (rank == UserRank.master) {
      return 0; // En üst seviyede olduğu için 0
    }

    return (rank.maxXp - currentXp + 1).toInt();
  }

  /// Bir sonraki seviyeye kalan XP yüzdesini hesaplar
  Future<double> getXpToNextRankPercentage(String userId) async {
    final totalXp = await getUserXp(userId);
    final userRank = UserRank.fromXp(totalXp);
    return getRankProgressPercentage(userRank, totalXp);
  }

  /// Bir sonraki seviyeye kalan XP miktarını hesaplar
  Future<int> getXpToNextRank(String userId) async {
    final totalXp = await getUserXp(userId);
    final userRank = UserRank.fromXp(totalXp);
    return calculateXpToNextRank(userRank, totalXp);
  }

  //
  // PREMIUM ÖDÜL İŞLEMLERİ
  //

  /// Premium ödül bilgilerini hesaplar
  Future<int> getEarnedPremiumRewardCount(String userId) async {
    final totalXp = await getUserXp(userId);
    return PremiumRewards.earnedPremiumRewards(totalXp);
  }

  /// Bir sonraki premium ödüle kalan XP miktarını hesaplar
  Future<int> getXpToNextPremium(String userId) async {
    final totalXp = await getUserXp(userId);
    return PremiumRewards.xpToNextPremium(totalXp);
  }

  //
  // BİLDİRİM İŞLEMLERİ
  //

  /// Görev tamamlama bildirimi gösterir (ScaffoldMessenger)
  void _showTaskCompletionMessage(XpEvent event) {
    final message = LocaleManager.translateWithParams(
        'notification_xp_earned_body', {'task': getLocalizedTaskDescription(event), 'xp': event.xpAmount.toString()});

    ScaffoldMess.showSuccessSnackBar(message);
  }

  /// Seviye atlama ve ödül bildirimlerini kontrol eder ve kaydeder
  Future<void> _checkAndSendRankNotifications(int oldTotalXp, int newTotalXp, String userId) async {
    // Eğer bu XP ile bir sonraki seviyeye geçildiyse
    final oldRank = UserRank.fromXp(oldTotalXp);
    final newRank = UserRank.fromXp(newTotalXp);

    if (oldRank != newRank) {
      // Rankup bildirimini SharedPreferences'a kaydet
      await SharedPrefService.saveNotificationWithEnum(
        type: NotificationsEnum.rankUp.name,
        title: LocaleManager.translate('notification_rank_up_title'),
        body: LocaleManager.translateWithParams(
            'notification_rank_up_body', {'xp': newTotalXp.toString(), 'rank': getLocalizedRankTitle(newRank), 'icon': newRank.icon}),
      );

      // Rankup bildirimini ekranda göster
      ScaffoldMess.showSuccessSnackBar(LocaleManager.translateWithParams(
          'notification_rank_up_body', {'xp': newTotalXp.toString(), 'rank': getLocalizedRankTitle(newRank), 'icon': newRank.icon}));

      // Son rankup'ı kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_recentRankUpKey}_$userId', newRank.name);
      await prefs.setString('${_recentRankUpKey}_${userId}_date', DateTime.now().toIso8601String());
    }

    // Bir sonraki premium ödüle kalan XP bildirimini kaydet
    final xpToNextPremium = PremiumRewards.xpToNextPremium(newTotalXp);
    await SharedPrefService.saveNotificationWithEnum(
      type: NotificationsEnum.premiumReward.name,
      title: LocaleManager.translate('notification_next_premium_title'),
      body: LocaleManager.translateWithParams('notification_next_premium_body', {'xp': xpToNextPremium.toString()}),
    );
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
  // YARDIMCI METODLAR
  //

  /// Tüm görev gruplarını başlıklarına göre Map olarak döndürür
  Map<String, List<XpEvent>> getAllTaskGroups() {
    final Map<String, List<XpEvent>> groups = {};
    for (final group in XpEventGroup.values) {
      groups[group.titleKey] = group.events;
    }
    return groups;
  }

  /// Belirli bir grup anahtarının emojisinin döndürülmesi
  String getGroupEmoji(String groupKey) {
    final group = XpEventGroup.values.firstWhere(
      (g) => g.titleKey == groupKey,
      orElse: () => XpEventGroup.welcomeRewards, // varsayılan değer
    );
    return group.emoji;
  }

  /// Belirli bir görevin XP değerini döndürür
  int getTaskXpValue(String taskName) {
    // taskName'i XpEvent'e çevirmeye çalış
    final xpEvent = mapTaskNameToXpEvent(taskName);
    if (xpEvent != null) {
      return xpEvent.xpAmount;
    }
    return 0; // Eşleşme bulunamazsa 0 döndür
  }

  /// Task adını XpEvent'e dönüştürür
  XpEvent? mapTaskNameToXpEvent(String taskName) {
    try {
      return XpEvent.values.firstWhere((event) => event.name == taskName || event.descriptionKey == taskName);
    } catch (e) {
      debugPrint('Bu taskName için tanımsız bir XpEvent var: $taskName');
      return null;
    }
  }

  //
  // TEST VE LOGLAMA METODLARI
  //

  /// Günlük görevlerin durumunu kontrol eder ve debug bilgisi döndürür
  Future<Map<String, dynamic>> checkDailyTasksStatus(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    // Son sıfırlama zamanını getir
    final lastResetTimeStr = prefs.getString('${_dailyTaskResetTimeKey}_$userId');
    final DateTime? lastResetTime = lastResetTimeStr != null ? DateTime.parse(lastResetTimeStr) : null;

    // Son günlük görev tarihini getir
    final lastDailyTaskDateStr = prefs.getString('${_lastDailyTaskDateKey}_$userId');
    final DateTime? lastDailyTaskDate = lastDailyTaskDateStr != null ? DateTime.parse(lastDailyTaskDateStr) : null;

    // Tamamlanmış görevleri getir
    final completedTasks = await getCompletedTasks(userId);

    // Tüm görevleri kontrol et (günlük, tek seferlik ve tekrarlanabilir)
    final Map<String, Map<String, dynamic>> taskStatuses = {};

    // Tüm görev tiplerinin durumlarını ekle
    for (final event in XpEvent.values) {
      final isCompletable = await canCompleteTask(userId, event);
      final completionCount = completedTasks[event.name] ?? 0;

      taskStatuses[event.name] = {
        'completable': isCompletable,
        'completion_count': completionCount,
        'is_repeatable': event.isRepeatable,
        'is_daily': event.isDaily,
        'xp_amount': event.xpAmount,
      };
    }

    // Şu anki zaman
    final now = DateTime.now();

    // Bir sonraki sıfırlamaya kalan süre
    final Duration? timeUntilReset = lastResetTime != null ? lastResetTime.difference(now) : null;

    final result = {
      'last_reset_time': lastResetTime?.toIso8601String() ?? 'Henüz ayarlanmadı',
      'last_daily_task_date': lastDailyTaskDate?.toIso8601String() ?? 'Henüz ayarlanmadı',
      'time_until_reset': timeUntilReset != null ? '${timeUntilReset.inHours} saat ${timeUntilReset.inMinutes % 60} dakika' : 'Sıfırlama zamanı yok',
      'all_daily_tasks_completed': await _areAllDailyTasksCompleted(userId),
      'completed_tasks': completedTasks,
    };

    // Tüm görev durumlarını ekle
    result.addAll(taskStatuses);

    return result;
  }

  /// Test için görev tamamlama (test sayfasından çağrılır)
  Future<void> completeTaskForTesting(String userId, XpEvent event) async {
    // Sadece görev tamamlama sayısını güncelle, XP ekleme
    await _updateTaskCompletionCount(userId, event);

    ScaffoldMess.showSnackBar('${event.name} görevi test için tamamlandı!');
  }

  /// Test için günlük görevleri geçmiş olarak ayarla
  Future<void> setDailyTaskAsExpired(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    // Dün olarak ayarla
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await prefs.setString('${_dailyTaskResetTimeKey}_$userId', yesterday.toIso8601String());

    ScaffoldMess.showSnackBar('Sıfırlama zamanı dün olarak ayarlandı!');
  }

  /// Test için TÜM görevleri sıfırla (Tüm görev tiplerini içerir)
  Future<void> resetAllTasks(String userId) async {
    if (userId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Tüm tamamlanmış görevleri sıfırla
      final emptyTasks = <String, int>{};

      // Her görev için 0 sayısını set et
      for (final event in XpEvent.values) {
        emptyTasks[event.name] = 0;
      }

      // Boş görev listesini kaydet
      await prefs.setString('${_completedTasksKey}_$userId', json.encode(emptyTasks));

      // Sıfırlama zamanını şimdiki zaman olarak ayarla
      final now = DateTime.now();
      final nextResetTime = now.add(_dailyTaskResetDuration);
      await prefs.setString('${_dailyTaskResetTimeKey}_$userId', nextResetTime.toIso8601String());

      // Mesaj sohbet ödüllerini de sıfırla (Çok karmaşık olabilir, seçimlik)
      // Bu kısım isteğe bağlı, her sohbet ID'si için kaydedilmiş ödülleri temizlemek için
      // tüm SharedPreferences'ı tarayıp ilgili anahtarları silmek gerekebilir

      ScaffoldMess.showSuccessSnackBar('Tüm görevler sıfırlandı! Yeniden başlayabilirsiniz.');
    } catch (e) {
      debugPrint('Tüm görevler sıfırlanırken hata: $e');
      ScaffoldMess.showSnackBar('Görevler sıfırlanırken bir hata oluştu: $e');
    }
  }

  /// Test için XP'yi sıfırla (hem yerel depolamada hem de Firestore'da)
  Future<void> resetAllXp(String userId) async {
    if (userId.isEmpty) return;

    try {
      // Yerel depolamada XP'yi sıfırla
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${_totalXpKey}_$userId', 0);

      // Firestore'da XP'yi sıfırla
      await _firestore.collection('customers').doc(userId).update({
        'totalXp': 0,
      });

      ScaffoldMess.showSuccessSnackBar('XP sıfırlandı! Yerel ve Firestore\'daki XP değerleri 0 olarak ayarlandı.');
    } catch (e) {
      debugPrint('XP sıfırlanırken hata: $e');
      ScaffoldMess.showSnackBar('XP sıfırlanırken bir hata oluştu: $e');
    }
  }

  /// Tam fabrika ayarlarına döndür (Tüm görevler ve XP sıfırlanır)
  Future<void> factoryReset(String userId) async {
    if (userId.isEmpty) return;

    try {
      // Önce tüm görevleri sıfırla
      await resetAllTasks(userId);

      // Sonra XP'yi sıfırla
      await resetAllXp(userId);

      ScaffoldMess.showSuccessSnackBar('Fabrika ayarlarına dönüldü! Tüm görevler ve XP sıfırlandı.');
    } catch (e) {
      debugPrint('Fabrika ayarlarına dönerken hata: $e');
      ScaffoldMess.showSnackBar('İşlem sırasında bir hata oluştu: $e');
    }
  }

  //
  // MESAJ ÖDÜLLERİ METODLARI
  //

  /// Belirli bir sohbet için ödül alınıp alınmadığını kontrol eder
  Future<bool> hasChatReward(String userId, String chatId, String rewardType) async {
    if (userId.isEmpty || chatId.isEmpty) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${rewardType}_${userId}_$chatId';
      return prefs.getBool(key) ?? false;
    } catch (e) {
      debugPrint('hasChatReward hatası: $e');
      return false;
    }
  }

  /// İlk mesaj gönderme ödülü alınmış mı?
  Future<bool> hasFirstMessageSentReward(String userId, String chatId) async {
    return await hasChatReward(userId, chatId, _firstMessageSentKey);
  }

  /// İlk mesaj alma ödülü alınmış mı?
  Future<bool> hasFirstMessageReceivedReward(String userId, String chatId) async {
    return await hasChatReward(userId, chatId, _firstMessageReceivedKey);
  }

  /// Sohbet için ödül kaydeder
  Future<void> setChatReward(String userId, String chatId, String rewardType) async {
    if (userId.isEmpty || chatId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${rewardType}_${userId}_$chatId';
      await prefs.setBool(key, true);
    } catch (e) {
      debugPrint('setChatReward hatası: $e');
    }
  }

  /// İlk mesaj gönderme ödülü kaydeder ve XP verir
  Future<void> rewardFirstMessageSent(String userId, String chatId) async {
    // Daha önce ödül almamış olmalı
    if (await hasFirstMessageSentReward(userId, chatId)) {
      return;
    }

    // Ödülü kaydet
    await setChatReward(userId, chatId, _firstMessageSentKey);

    // XP ekle
    await earnXpForEvent(userId, XpEvent.sendMessage);
  }

  /// İlk mesaj alma ödülü kaydeder ve XP verir
  Future<void> rewardFirstMessageReceived(String userId, String chatId) async {
    // Daha önce ödül almamış olmalı
    if (await hasFirstMessageReceivedReward(userId, chatId)) {
      return;
    }

    // Ödülü kaydet
    await setChatReward(userId, chatId, _firstMessageReceivedKey);

    // XP ekle
    await earnXpForEvent(userId, XpEvent.receiveMessage);
  }

  /// Mesaj ödüllerini işle
  Future<void> processMessageRewards(
      {required String userId, required String chatId, required bool isFirstMessageFromUs, required bool isFirstMessageFromOther}) async {
    if (userId.isEmpty) {
      debugPrint('⚠️ Kullanıcı ID bulunamadı, ödül işlemi iptal edildi');
      return;
    }

    // Bizim ilk mesajımız ise
    if (isFirstMessageFromUs) {
      await rewardFirstMessageSent(userId, chatId);
    }

    // Karşıdan gelen ilk mesaj ise
    if (isFirstMessageFromOther) {
      await rewardFirstMessageReceived(userId, chatId);
    }
  }

  //
  // AKILLI EYLEM İŞLEME METODLARI
  //

  /// İlan oluşturma işlemlerini otomatik olarak işler
  /// İlk ilan ise firstListing, her durumda createListing XP'sini verir
  Future<int> handleListingCreation(String userId) async {
    if (userId.isEmpty) return 0;

    int totalEarnedXp = 0;

    // İlk kez ilan oluşturma kontrolü
    final isFirstListing = await canCompleteTask(userId, XpEvent.firstListing);
    if (isFirstListing) {
      // İlk ilan oluşturma XP'sini ver
      debugPrint('👑 İlk ilan oluşturma ödülü veriliyor...');
      final earnedXp = await earnXpForEvent(userId, XpEvent.firstListing);
      totalEarnedXp += XpEvent.firstListing.xpAmount;
    }

    // Her ilan oluşturma için XP ver
    debugPrint('📋 İlan oluşturma ödülü veriliyor...');
    final earnedXp = await earnXpForEvent(userId, XpEvent.createListing);
    totalEarnedXp += XpEvent.createListing.xpAmount;

    // Günlük ilan oluşturma görevi
    final canCompleteDaily = await canCompleteTask(userId, XpEvent.dailyCreateListing);
    if (canCompleteDaily) {
      debugPrint('📅 Günlük ilan oluşturma ödülü veriliyor...');
      await earnXpForEvent(userId, XpEvent.dailyCreateListing);
      totalEarnedXp += XpEvent.dailyCreateListing.xpAmount;
    }

    return totalEarnedXp;
  }

  /// Mesaj gönderme işlemlerini otomatik olarak işler
  /// İlk mesaj ise firstMessage, her durumda sendMessage XP'sini verir
  Future<int> handleMessageSent(String userId, {String? chatId}) async {
    if (userId.isEmpty) return 0;

    int totalEarnedXp = 0;

    // Eğer chatId verilmişse sohbet bazlı kontrol yap
    if (chatId != null) {
      final hasReward = await hasFirstMessageSentReward(userId, chatId);
      if (!hasReward) {
        // İlk mesaj gönderme XP'sini ver
        debugPrint('💬 İlk mesaj gönderme ödülü veriliyor (chatId: $chatId)...');
        await rewardFirstMessageSent(userId, chatId);
        totalEarnedXp += XpEvent.sendMessage.xpAmount;
        return totalEarnedXp; // Sohbet bazlı ödüllendirme yapıldıysa diğer kontrollere gerek yok
      }
      return 0; // Bu sohbette zaten ödül alınmış
    }

    // Sohbet ID yoksa genel kontrollerle devam et

    // İlk kez mesaj gönderme kontrolü
    final isFirstMessage = await canCompleteTask(userId, XpEvent.firstMessage);
    if (isFirstMessage) {
      // İlk mesaj gönderme XP'sini ver
      debugPrint('👑 İlk mesaj gönderme ödülü veriliyor...');
      await earnXpForEvent(userId, XpEvent.firstMessage);
      totalEarnedXp += XpEvent.firstMessage.xpAmount;
    }

    // Her mesaj gönderme için XP ver
    debugPrint('💬 Mesaj gönderme ödülü veriliyor...');
    await earnXpForEvent(userId, XpEvent.sendMessage);
    totalEarnedXp += XpEvent.sendMessage.xpAmount;

    // Günlük mesaj gönderme görevi
    final canCompleteDaily = await canCompleteTask(userId, XpEvent.dailySendMessage);
    if (canCompleteDaily) {
      debugPrint('📅 Günlük mesaj gönderme ödülü veriliyor...');
      await earnXpForEvent(userId, XpEvent.dailySendMessage);
      totalEarnedXp += XpEvent.dailySendMessage.xpAmount;
    }

    return totalEarnedXp;
  }

  /// Mesaj alma işlemlerini otomatik olarak işler
  Future<int> handleMessageReceived(String userId, {String? chatId}) async {
    if (userId.isEmpty) return 0;

    int totalEarnedXp = 0;

    // Eğer chatId verilmişse sohbet bazlı kontrol yap
    if (chatId != null) {
      final hasReward = await hasFirstMessageReceivedReward(userId, chatId);
      if (!hasReward) {
        // İlk mesaj alma XP'sini ver
        debugPrint('📩 İlk mesaj alma ödülü veriliyor (chatId: $chatId)...');
        await rewardFirstMessageReceived(userId, chatId);
        totalEarnedXp += XpEvent.receiveMessage.xpAmount;
      }
      return totalEarnedXp;
    }

    // Her mesaj alma için XP ver
    debugPrint('📩 Mesaj alma ödülü veriliyor...');
    await earnXpForEvent(userId, XpEvent.receiveMessage);
    totalEarnedXp += XpEvent.receiveMessage.xpAmount;

    return totalEarnedXp;
  }
}
