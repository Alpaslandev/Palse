import 'package:flutter/material.dart';
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

/// Achievement sistemini tamamen local olarak yöneten servis
class AchievementService {
  final NotificationService _notificationService = NotificationService();

  // SharedPreferences anahtarları
  static const String _dailyTaskResetTimeKey = 'dailyTaskResetTime';
  static const String _completedTasksKey = 'completedTasks';
  static const String _totalXpKey = 'totalXp';
  static const String _lastDailyTaskDateKey = 'lastDailyTaskDate';

  // Ödüllendirilmiş sohbetleri tutacak anahtarlar
  static const String _firstMessageSentKey = 'firstMessageSent';
  static const String _firstMessageReceivedKey = 'firstMessageReceived';

  // Görev sıfırlama süresi (24 saat)
  static const Duration _dailyTaskResetDuration = Duration(hours: 24);

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
  // RANK VE PROGRESS HESAPLAMA METODLARI
  //

  /// Unvanın ilerleme yüzdesini hesaplayan metod
  double getRankProgressPercentage(UserRank rank, int currentXp) {
    if (rank == UserRank.master) {
      return 1.0; // Sosyal Usta için her zaman %100
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

  /// Premium ödül açıklamasını getiren metod
  String getPremiumRewardDescription(int rewardIndex) {
    switch (rewardIndex) {
      case 0:
        return "1 ay ücretsiz premium üyelik";
      case 1:
        return "3 adet özel rozet";
      case 2:
        return "İlanlarda öne çıkma hakkı";
      case 3:
        return "Özel profil tasarımı";
      case 4:
        return "1 yıl ücretsiz premium üyelik";
      default:
        return "Premium ödül";
    }
  }

  //
  // GÖREV GRUPLARI VE GÖREVLER
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
    // Burada taskName'i XpEvent'e eşleştirme mantığı
    // Örnek olarak, taskName doğrudan XpEvent'in descriptionKey'i olabilir
    try {
      return XpEvent.values.firstWhere((event) => event.descriptionKey == taskName);
    } catch (e) {
      debugPrint('Bu taskName için tanımsız bir XpEvent var: $taskName');
      return null;
    }
  }

  //
  // XP KAZANMA VE GÖREV TAMAMLAMA
  //

  /// XP ekler ve görev tamamlama işlemlerini yapar
  Future<int> earnXp({required String userId, required XpEvent event}) async {
    if (userId.isEmpty) {
      debugPrint('Kullanıcı ID bulunamadı, XP eklenemedi');
      return 0;
    }

    // Local veriyi yükle
    final localData = await _loadLocalAchievementData(userId);

    // Görevin tamamlanıp tamamlanamayacağını kontrol et
    if (!_canCompleteTask(userId, event, localData)) {
      debugPrint('${event.name} görevi zaten tamamlanmış, XP eklenmedi');
      return localData['totalXp'] as int;
    }

    // Yeni görev tamamlama sayılarını hazırla
    final completedTasks = Map<String, int>.from(localData['completedTasks'] as Map<String, dynamic>);
    completedTasks[event.name] = (completedTasks[event.name] ?? 0) + 1;

    // Local veriyi güncelle
    final now = DateTime.now();
    DateTime? lastDailyTaskDate = localData['lastDailyTaskDate'] as DateTime?;
    DateTime? resetTime;

    if (event.isDaily) {
      lastDailyTaskDate = now;
      // Görev sıfırlanma zamanını 24 saat sonrasına ayarla
      resetTime = now.add(_dailyTaskResetDuration);

      // Local olarak sıfırlanma zamanını kaydet
      await _saveLocalResetTime(userId, resetTime);
    }

    // Toplam XP'yi güncelle
    final oldTotalXp = localData['totalXp'] as int;
    final newTotalXp = oldTotalXp + event.xpAmount;

    // Local veriyi kaydet
    await _saveLocalAchievementData(userId, newTotalXp, completedTasks, lastDailyTaskDate);

    // Görev tamamlama bildirimleri
    await _sendTaskCompletionNotification(event, completedTasks);

    // Seviye atlama ve ödül bildirimleri
    await _checkAndSendRankNotifications(oldTotalXp, newTotalXp);

    return newTotalXp;
  }

  /// Özel XP ekler (ödül vb. için)
  Future<int> earnCustomXp({required String userId, required int amount}) async {
    if (userId.isEmpty || amount <= 0) {
      debugPrint('Kullanıcı ID bulunamadı veya geçersiz XP miktarı, XP eklenemedi');
      return 0;
    }

    // Local veriyi yükle
    final localData = await _loadLocalAchievementData(userId);

    // Toplam XP'yi güncelle
    final oldTotalXp = localData['totalXp'] as int;
    final newTotalXp = oldTotalXp + amount;

    // Local veriyi kaydet (sadece totalXp güncelleniyor)
    await _saveLocalAchievementData(
        userId, newTotalXp, Map<String, int>.from(localData['completedTasks'] as Map<String, dynamic>), localData['lastDailyTaskDate'] as DateTime?);

    // Seviye atlama ve ödül bildirimleri
    await _checkAndSendRankNotifications(oldTotalXp, newTotalXp);

    return newTotalXp;
  }

  //
  // VERİ YÜKLEME VE KAYDETME
  //

  /// Local achievement verilerini yükler
  Future<Map<String, dynamic>> _loadLocalAchievementData(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    // Reset time'ı yükle
    final resetTimeStr = prefs.getString('${_dailyTaskResetTimeKey}_$userId');
    final resetTime = resetTimeStr != null ? DateTime.parse(resetTimeStr) : null;

    // Tamamlanan görevleri yükle
    final tasksJson = prefs.getString('${_completedTasksKey}_$userId');
    final completedTasks = tasksJson != null ? Map<String, dynamic>.from(json.decode(tasksJson)) : <String, int>{};

    // Toplam XP'yi yükle
    final totalXp = prefs.getInt('${_totalXpKey}_$userId') ?? 0;

    // Son günlük görev tarihini yükle
    final lastDailyTaskStr = prefs.getString('${_lastDailyTaskDateKey}_$userId');
    final lastDailyTaskDate = lastDailyTaskStr != null ? DateTime.parse(lastDailyTaskStr) : null;

    return {
      'resetTime': resetTime,
      'completedTasks': completedTasks,
      'totalXp': totalXp,
      'lastDailyTaskDate': lastDailyTaskDate,
    };
  }

  /// Local achievement verilerini kaydeder
  Future<void> _saveLocalAchievementData(String userId, int totalXp, Map<String, int> completedTasks, DateTime? lastDailyTaskDate) async {
    final prefs = await SharedPreferences.getInstance();

    // Toplam XP'yi kaydet
    await prefs.setInt('${_totalXpKey}_$userId', totalXp);

    // Tamamlanan görevleri kaydet
    await prefs.setString('${_completedTasksKey}_$userId', json.encode(completedTasks));

    // Son günlük görev tarihini kaydet
    if (lastDailyTaskDate != null) {
      await prefs.setString('${_lastDailyTaskDateKey}_$userId', lastDailyTaskDate.toIso8601String());
    }
  }

  /// Local olarak sıfırlanma zamanını kaydeder
  Future<void> _saveLocalResetTime(String userId, DateTime resetTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_dailyTaskResetTimeKey}_$userId', resetTime.toIso8601String());
  }

  /// Local olarak sıfırlanma zamanını yükler
  Future<DateTime?> _loadLocalResetTime(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final resetTimeStr = prefs.getString('${_dailyTaskResetTimeKey}_$userId');
    return resetTimeStr != null ? DateTime.parse(resetTimeStr) : null;
  }

  //
  // GÖREV KONTROL METODLARI
  //

  /// Bir görevin tamamlanabilir olup olmadığını kontrol eder
  bool _canCompleteTask(String userId, XpEvent event, Map<String, dynamic> localData) {
    // Günlük görev kontrolü
    if (event.isDaily) {
      return !_isDailyTaskActive(localData);
    }

    // Tekrarlanamaz görev kontrolü
    if (!event.isRepeatable) {
      final completedTasks = localData['completedTasks'] as Map<String, dynamic>;
      return !(completedTasks.containsKey(event.name) && completedTasks[event.name] > 0);
    }

    return true;
  }

  /// Günlük görevin halen aktif olup olmadığını kontrol eder
  bool _isDailyTaskActive(Map<String, dynamic> localData) {
    final lastDailyTaskDate = localData['lastDailyTaskDate'] as DateTime?;

    // Hiç görev yapılmadıysa aktif değil
    if (lastDailyTaskDate == null) return false;

    // Reset time kontrolü - eğer reset time geçmişse aktif değil
    final resetTime = localData['resetTime'] as DateTime?;
    if (resetTime != null) {
      final now = DateTime.now();
      return now.isBefore(resetTime);
    }

    // Reset time yoksa eski mantıkla devam et - aynı gün içinde yapıldıysa aktif
    final now = DateTime.now();
    return lastDailyTaskDate.year == now.year && lastDailyTaskDate.month == now.month && lastDailyTaskDate.day == now.day;
  }

  //
  // BİLDİRİM METODLARI
  //

  /// Görev tamamlama bildirimleri gönderir
  Future<void> _sendTaskCompletionNotification(XpEvent event, Map<String, int> completedTasks) async {
    // Görevin ilk kez tamamlanıp tamamlanmadığını kontrol et
    final bool isFirstCompletion = (completedTasks[event.name] ?? 0) <= 1;

    // Görev ilk kez tamamlandıysa
    if (isFirstCompletion) {
      await SharedPrefService.saveNotificationWithEnum(
        type: NotificationsEnum.taskCompleted.name,
        title: LocaleManager.translate('notification_task_completed_title'),
        body: LocaleManager.translateWithParams(
            'notification_task_completed_body', {'task': getLocalizedTaskDescription(event), 'xp': event.xpAmount.toString()}),
      );
      ScaffoldMess.showSuccessSnackBar(LocaleManager.translateWithParams(
          'notification_task_completed_body', {'task': getLocalizedTaskDescription(event), 'xp': event.xpAmount.toString()}));
    } else {
      // Tekrarlanan görevler için
      await SharedPrefService.saveNotificationWithEnum(
        type: NotificationsEnum.xpEarned.name,
        title: LocaleManager.translate('notification_xp_earned_title'),
        body: LocaleManager.translateWithParams(
            'notification_xp_earned_body', {'task': getLocalizedTaskDescription(event), 'xp': event.xpAmount.toString()}),
      );
      ScaffoldMess.showSuccessSnackBar(LocaleManager.translateWithParams(
          'notification_xp_earned_body', {'task': getLocalizedTaskDescription(event), 'xp': event.xpAmount.toString()}));
    }
  }

  /// Seviye atlama ve ödül bildirimlerini kontrol eder ve gönderir
  Future<void> _checkAndSendRankNotifications(int oldTotalXp, int newTotalXp) async {
    // Eğer bu XP ile bir sonraki seviyeye geçildiyse
    final oldRank = UserRank.fromXp(oldTotalXp);
    final newRank = UserRank.fromXp(newTotalXp);

    if (oldRank != newRank) {
      await SharedPrefService.saveNotificationWithEnum(
        type: NotificationsEnum.rankUp.name,
        title: LocaleManager.translate('notification_rank_up_title'),
        body: LocaleManager.translateWithParams(
            'notification_rank_up_body', {'xp': newTotalXp.toString(), 'rank': getLocalizedRankTitle(newRank), 'icon': newRank.icon}),
      );
      ScaffoldMess.showSuccessSnackBar(LocaleManager.translateWithParams(
          'notification_rank_up_body', {'xp': newTotalXp.toString(), 'rank': getLocalizedRankTitle(newRank), 'icon': newRank.icon}));
    }

    // Eğer bu XP ile premium ödül kazanıldıysa
    final oldPremiumCount = PremiumRewards.earnedPremiumRewards(oldTotalXp);
    final newPremiumCount = PremiumRewards.earnedPremiumRewards(newTotalXp);
    final xpToNextPremium = PremiumRewards.xpToNextPremium(newTotalXp);

    if (newPremiumCount > oldPremiumCount) {
      await SharedPrefService.saveNotificationWithEnum(
        type: NotificationsEnum.premiumReward.name,
        title: LocaleManager.translate('notification_premium_reward_title'),
        body: LocaleManager.translateWithParams('notification_premium_reward_body', {'xp': newTotalXp.toString()}),
      );
      ScaffoldMess.showSuccessSnackBar(LocaleManager.translateWithParams('notification_premium_reward_body', {'xp': newTotalXp.toString()}));
    }

    // Bir sonraki premium ödüle kalan XP bildirimini gönder
    await SharedPrefService.saveNotificationWithEnum(
      type: NotificationsEnum.premiumReward.name,
      title: LocaleManager.translate('notification_next_premium_title'),
      body: LocaleManager.translateWithParams('notification_next_premium_body', {'xp': xpToNextPremium.toString()}),
    );
  }

  //
  // GÖREV SIFIRLAMA METODLARI
  //

  /// Günlük görevleri sıfırlar
  Future<void> resetDailyTasks(String userId) async {
    if (userId.isEmpty) {
      return;
    }

    // Local veriyi sıfırla
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_dailyTaskResetTimeKey}_$userId');
    await prefs.remove('${_lastDailyTaskDateKey}_$userId');

    // Bildirim kaydet
    await SharedPrefService.saveNotificationWithEnum(
      type: NotificationsEnum.dailyTask.name,
      title: LocaleManager.translate('notification_daily_task_reset_title'),
      body: LocaleManager.translate('notification_daily_task_reset_body'),
    );

    debugPrint('Günlük görevler sıfırlandı');
  }

  /// Günlük görevlerin süresi dolmuşsa otomatik olarak sıfırlar
  Future<void> checkAndResetDailyTasks(String userId) async {
    if (userId.isEmpty) {
      return;
    }

    // Local reset time'ı kontrol et
    final resetTime = await _loadLocalResetTime(userId);

    // Eğer reset time geçmişse ya da yoksa görevleri sıfırla
    final now = DateTime.now();
    if (resetTime != null && now.isAfter(resetTime)) {
      await resetDailyTasks(userId);
    }
  }

  //
  // VERİ SORGULAMA METODLARI
  //

  /// Kullanıcının toplam XP'sini getirir
  Future<int> getTotalXp(String userId) async {
    if (userId.isEmpty) return 0;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('${_totalXpKey}_$userId') ?? 0;
  }

  /// Kullanıcının tamamladığı görevleri getirir
  Future<Map<String, int>> getCompletedTasks(String userId) async {
    if (userId.isEmpty) return {};

    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString('${_completedTasksKey}_$userId');
    return tasksJson != null ? Map<String, int>.from(json.decode(tasksJson)) : {};
  }

  /// Bir sonraki seviyeye kalan Xp miktarını yüzdelik olarak döndürür
  Future<double> getXpToNextRankPercentage(String userId) async {
    final totalXp = await getTotalXp(userId);
    final userRank = UserRank.fromXp(totalXp);
    return getRankProgressPercentage(userRank, totalXp);
  }

  /// Bir sonraki seviyeye kalan XP miktarını hesaplar
  Future<int> getXpToNextRank(String userId) async {
    final totalXp = await getTotalXp(userId);
    final userRank = UserRank.fromXp(totalXp);
    return calculateXpToNextRank(userRank, totalXp);
  }

  /// Premium ödül bilgilerini hesaplar
  Future<int> getEarnedPremiumRewardCount(String userId) async {
    final totalXp = await getTotalXp(userId);
    return PremiumRewards.earnedPremiumRewards(totalXp);
  }

  /// Bir sonraki premium ödüle kalan XP miktarını hesaplar
  Future<int> getXpToNextPremium(String userId) async {
    final totalXp = await getTotalXp(userId);
    return PremiumRewards.xpToNextPremium(totalXp);
  }

  /// Kullanıcının unvanını hesaplar
  Future<UserRank> getUserRank(String userId) async {
    final totalXp = await getTotalXp(userId);
    return UserRank.fromXp(totalXp);
  }

  /// Belirli bir görevin tamamlanıp tamamlanmadığını kontrol eder
  Future<bool> isTaskCompleted(String userId, XpEvent event) async {
    final localData = await _loadLocalAchievementData(userId);

    if (event.isDaily) {
      return _isDailyTaskActive(localData);
    }

    final completedTasks = localData['completedTasks'] as Map<String, dynamic>;
    final count = completedTasks[event.name] ?? 0;
    return count > 0;
  }

  /// Belirli bir görevin kaç kez tamamlandığını hesaplar
  Future<int> getTaskCompletionCount(String userId, XpEvent event) async {
    final completedTasks = await getCompletedTasks(userId);
    return completedTasks[event.name] ?? 0;
  }

  /// Kullanıcının XP'sini sıfırlar (local)
  Future<void> resetUserXp(String userId) async {
    if (userId.isEmpty) {
      return;
    }

    // Local veriyi sıfırla
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_totalXpKey}_$userId');
    await prefs.remove('${_completedTasksKey}_$userId');
    await prefs.remove('${_lastDailyTaskDateKey}_$userId');
    await prefs.remove('${_dailyTaskResetTimeKey}_$userId');

    // Bildirim kaydet
    await SharedPrefService.saveNotificationWithEnum(
      type: NotificationsEnum.xpReset.name,
      title: LocaleManager.translate('notification_xp_reset_title'),
      body: LocaleManager.translate('notification_xp_reset_body'),
    );
  }

  //
  // MESAJ ÖDÜLLERİ METODLARI
  //

  /// Belirli bir sohbet için ödül alınıp alınmadığını kontrol eder (local)
  Future<bool> hasChatReward(String userId, String chatId, String rewardType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${rewardType}_${userId}_$chatId';
      return prefs.getBool(key) ?? false;
    } catch (e) {
      debugPrint('hasChatReward hatası: $e');
      return false; // Hata durumunda ödül vermek daha güvenli
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

  /// Sohbet için ödül kaydeder (local)
  Future<void> saveChatReward(String userId, String chatId, String rewardType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${rewardType}_${userId}_$chatId';
      await prefs.setBool(key, true);
      debugPrint('💾 Ödül kaydedildi: $rewardType, sohbet: $chatId, kullanıcı: $userId');
    } catch (e) {
      debugPrint('saveChatReward hatası: $e');
    }
  }

  /// İlk mesaj gönderme ödülünü kaydet
  Future<void> saveFirstMessageSentReward(String userId, String chatId) async {
    await saveChatReward(userId, chatId, _firstMessageSentKey);
  }

  /// İlk mesaj alma ödülünü kaydet
  Future<void> saveFirstMessageReceivedReward(String userId, String chatId) async {
    await saveChatReward(userId, chatId, _firstMessageReceivedKey);
  }

  /// Mesaj ödüllerini işle ve XP ver (eğer daha önce verilmediyse)
  Future<void> processMessageRewards(
      {required String userId, required String chatId, required bool isFirstMessageFromUs, required bool isFirstMessageFromOther}) async {
    if (userId.isEmpty) {
      debugPrint('⚠️ Kullanıcı ID bulunamadı, ödül işlemi iptal edildi');
      return;
    }

    // Bizim ilk mesajımız ise
    if (isFirstMessageFromUs) {
      final hasReward = await hasFirstMessageSentReward(userId, chatId);
      if (!hasReward) {
        debugPrint('🎮 İlk mesaj gönderme ödülü verilecek - Sohbet: $chatId');
        await earnXp(userId: userId, event: XpEvent.sendMessage);
        await saveFirstMessageSentReward(userId, chatId);
      } else {
        debugPrint('ℹ️ İlk mesaj gönderme ödülü daha önce verilmiş - Sohbet: $chatId');
      }
    }

    // Karşıdan gelen ilk mesaj ise
    if (isFirstMessageFromOther) {
      final hasReward = await hasFirstMessageReceivedReward(userId, chatId);
      if (!hasReward) {
        debugPrint('🎮 İlk mesaj alma ödülü verilecek - Sohbet: $chatId');
        await earnXp(userId: userId, event: XpEvent.receiveMessage);
        await saveFirstMessageReceivedReward(userId, chatId);
      } else {
        debugPrint('ℹ️ İlk mesaj alma ödülü daha önce verilmiş - Sohbet: $chatId');
      }
    }
  }
}
