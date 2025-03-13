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
import 'package:firebase_auth/firebase_auth.dart';

/// Achievement sistemi için tek merkezi sınıf
class AchievementService {
  // Singleton yapısı
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  // Servisin ilk başlatılma işlemi
  Future<void> init() async {
    // Kullanıcı giriş yapmışsa, günlük görevleri kontrol et
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null && userId.isNotEmpty) {
      // Gün değişimi kontrolü ve görevlerin sıfırlanması
      await _checkForDayChangeAndResetTasks(userId);

      // Cache'i SharedPreferences'dan yükle
      await _loadCacheFromPrefs(userId);

      debugPrint('🌟 AchievementService başlatıldı - Günlük görevler kontrol edildi');
    }
  }

  /// Gün değişimi kontrolü ve görevlerin sıfırlanması
  Future<void> _checkForDayChangeAndResetTasks(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Bugünün tarihini al (YYYY-MM-DD formatında)
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Son kontrol tarihini al
      final lastResetCheckKey = 'lastDailyTasksResetCheck_$userId';
      final lastResetCheck = prefs.getString(lastResetCheckKey);

      // Eğer son kontrol tarihi bugün değilse, görevleri sıfırla
      if (lastResetCheck != today) {
        debugPrint('📅 Gün değişimi tespit edildi, günlük görevler sıfırlanıyor...');
        await resetDailyTasks(userId);

        // Bugünün tarihini kaydet
        await prefs.setString(lastResetCheckKey, today);
      } else {
        debugPrint('📅 Günlük görevler bugün zaten kontrol edilmiş, tekrar sıfırlanmıyor');
      }
    } catch (e) {
      debugPrint('⚠️ Gün değişimi kontrolü sırasında hata: $e');
    }
  }

  /// Cache'i SharedPreferences'dan yükle
  Future<void> _loadCacheFromPrefs(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Tüm günlük görevler için cache'i yükle
      for (final event in XpEvent.values.where((e) => e.isDaily)) {
        final taskDateKey = '${_dailyTaskDateKey}_${userId}_${event.name}';
        final lastTaskDate = prefs.getString(taskDateKey);

        // Cache'e ekle
        final cacheKey = '${userId}_${event.name}_$today';
        _taskCompletionCache[cacheKey] = lastTaskDate == today ? false : true;
      }

      // Mesaj ödülleri için cache'i yükle
      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        if (key.startsWith('${_firstMessageSentKey}_$userId') || key.startsWith('${_firstMessageReceivedKey}_$userId')) {
          final value = prefs.getBool(key) ?? false;
          _chatRewardCache[key] = value;
        }
      }

      debugPrint('💾 Cache SharedPreferences\'dan yüklendi');
    } catch (e) {
      debugPrint('⚠️ Cache yüklenirken hata: $e');
    }
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SharedPreferences anahtarları
  static const String _dailyTaskResetTimeKey = 'dailyTaskResetTime';
  static const String _completedTasksKey = 'completedTasks';
  static const String _totalXpKey = 'totalXp';
  static const String _lastDailyTaskDateKey = 'lastDailyTaskDate';
  static const String _recentRankUpKey = 'recentRankUp';
  static const String _lastCheckDateKey = 'lastCheckDate';
  static const String _dailyTaskDateKey = 'dailyTaskDate';

  // Ödüllendirilmiş sohbetleri tutacak anahtarlar
  static const String _firstMessageSentKey = 'firstMessageSent';
  static const String _firstMessageReceivedKey = 'firstMessageReceived';

  // Görev kontrolü optimizasyonu için cache mekanizması
  final Map<String, bool> _chatRewardCache = {};
  final Map<String, bool> _taskCompletionCache = {};
  DateTime? _lastDailyTaskCheck;

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

      // Premium ödül kontrolü yap
      await _checkAndHandlePremiumRewards(currentXp, newXp, userId);

      return newXp;
    } catch (e) {
      debugPrint('XP ekleme hatası: $e');
      return await getUserXp(userId);
    }
  }

  /// Premium ödül kontrolü yapar ve gerekli işlemleri gerçekleştirir
  Future<void> _checkAndHandlePremiumRewards(int oldTotalXp, int newTotalXp, String userId) async {
    try {
      // Eski ve yeni premium ödül sayılarını hesapla
      final oldPremiumCount = PremiumRewards.earnedPremiumRewards(oldTotalXp);
      final newPremiumCount = PremiumRewards.earnedPremiumRewards(newTotalXp);

      // Eğer yeni premium ödül kazanıldıysa
      if (newPremiumCount > oldPremiumCount) {
        // Kazanılan premium ödül sayısı
        final earnedCount = newPremiumCount - oldPremiumCount;

        debugPrint('🎁 Kullanıcı $earnedCount yeni premium ödül kazandı! Toplam: $newPremiumCount');
        final premiumRewardEnd = DateTime.now().add(const Duration(days: 7));
        // Premium durumunu Firestore'da güncelle
        await _firestore.collection('customers').doc(userId).update({
          'premiumRewardCount': newPremiumCount,
          'isPremium': true,
          'premiumUpdatedAt': FieldValue.serverTimestamp(),
          'premiumRewardEnd': Timestamp.fromDate(premiumRewardEnd),
        });

        debugPrint('🎁 Premium ödül süresi: $premiumRewardEnd');

        // Premium kazanma bildirimini SharedPreferences'a kaydet
        await SharedPrefService.saveNotificationWithEnum(
          type: NotificationsEnum.premiumReward.name,
          title: LocaleManager.translate('notification_premium_earned_title'),
          body: LocaleManager.translateWithParams('notification_premium_earned_body', {'count': earnedCount.toString()}),
        );

        // Ekranda bildirim göster
        ScaffoldMess.showSuccessSnackBar(LocaleManager.translateWithParams('notification_premium_earned_body', {'count': earnedCount.toString()}));
      }
    } catch (e) {
      debugPrint('⚠️ Premium ödül kontrolü sırasında hata: $e');
    }
  }

  /// Hem görev tamamlama hem de XP ekleme işlemlerini yapar
  Future<int> earnXpForEvent(String userId, XpEvent event) async {
    if (userId.isEmpty) {
      return 0;
    }

    try {
      // Görevin tamamlanabilir olup olmadığını kontrol et
      if (!await canCompleteTask(userId, event)) {
        debugPrint('⚠️ ${event.name} görevi şu anda tamamlanamaz, işlem iptal edildi');
        return await getUserXp(userId);
      }

      debugPrint('✅ ${event.name} görevi tamamlanabilir, XP veriliyor');

      // Görev tamamlama sayısını güncelle
      await _updateTaskCompletionCount(userId, event);

      // Eğer bu günlük görevse, tamamlandığını tarih bazlı kaydet
      if (event.isDaily) {
        final prefs = await SharedPreferences.getInstance();
        final todayStr = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
        final checkKey = '${_lastCheckDateKey}_${userId}_${event.name}';
        await prefs.setString(checkKey, todayStr);

        // Cache'i güncelle
        final cacheKey = '${userId}_${event.name}_$todayStr';
        _taskCompletionCache[cacheKey] = false; // Artık tamamlanamaz

        // Günlük görev tamamlandığında SharedPreferences'a da kaydet
        final taskDateKey = '${_dailyTaskDateKey}_${userId}_${event.name}';
        await prefs.setString(taskDateKey, todayStr);
      }

      // XP ekle
      final newXp = await addXp(userId, event.xpAmount);

      // Görev tamamlama bildirimini göster (ScaffoldMessenger)
      _showTaskCompletionMessage(event);

      return newXp;
    } catch (e) {
      debugPrint('⚠️ XP verme işlemi sırasında hata: $e');
      return await getUserXp(userId);
    }
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
    // Cache mekanizması - günlük görevler için tarih bazlı kontrol
    if (event.isDaily) {
      // Bugünün tarihini al
      final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD formatı

      // Cache anahtarı oluştur - userId_eventName_date
      final cacheKey = '${userId}_${event.name}_$today';

      // Eğer cache'de varsa, sonucu doğrudan döndür
      if (_taskCompletionCache.containsKey(cacheKey)) {
        return _taskCompletionCache[cacheKey]!;
      }

      // Cache'de yoksa, hesapla ve cache'e ekle
      final canComplete = await _canCompleteDailyTask(userId, event);
      _taskCompletionCache[cacheKey] = canComplete;

      // Cache'i SharedPreferences'a da kaydet
      await _saveCacheToPrefs(userId, event, canComplete);

      return canComplete;
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

    // Bugünün tarihini al (YYYY-MM-DD formatında)
    final todayDate = DateTime.now().toIso8601String().split('T')[0];

    // Son görev tamamlama tarihini kontrol et (yeni sistem için)
    final lastTaskDateKey = '${_dailyTaskDateKey}_${userId}_${event.name}';
    final lastTaskDate = prefs.getString(lastTaskDateKey);

    // Eğer son tamamlama tarihi bugün değilse, görev tamamlanabilir
    if (lastTaskDate != todayDate) {
      debugPrint('✅ ${event.name} görevi bugün henüz tamamlanmamış, tamamlanabilir');
      return true;
    }

    debugPrint('⚠️ ${event.name} görevi bugün zaten tamamlanmış, tekrar tamamlanamaz');
    return false;
  }

  /// Cache'i SharedPreferences'a kaydet
  Future<void> _saveCacheToPrefs(String userId, XpEvent event, bool canComplete) async {
    if (!event.isDaily) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Eğer görev tamamlanamıyorsa, bugünün tarihini kaydet
      if (!canComplete) {
        final taskDateKey = '${_dailyTaskDateKey}_${userId}_${event.name}';
        await prefs.setString(taskDateKey, today);
      }
    } catch (e) {
      debugPrint('⚠️ Cache kaydedilirken hata: $e');
    }
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

    // Eğer bu bir günlük görevse, bugünün tarihini kaydet
    if (event.isDaily) {
      final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
      final taskDateKey = '${_dailyTaskDateKey}_${userId}_${event.name}';
      await prefs.setString(taskDateKey, today);

      debugPrint('📆 ${event.name} görevi bugün (${today}) için tamamlandı olarak işaretlendi');
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

  /// Günlük görevleri sıfırlar (otomatik olarak çağrılacak)
  Future<void> resetDailyTasks(String userId) async {
    if (userId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Tüm günlük görev tarihlerini sıfırla
      final allKeys = prefs.getKeys().toList();
      int resetCount = 0;

      for (final key in allKeys) {
        // Yeni sistemdeki günlük görev kayıtlarını temizle
        if (key.startsWith('${_dailyTaskDateKey}_$userId')) {
          await prefs.remove(key);
          resetCount++;
        }

        // Eski sistemdeki günlük görev kayıtlarını da temizle
        if (key.startsWith('${_dailyTaskResetTimeKey}_$userId') || key.startsWith('${_lastDailyTaskDateKey}_$userId')) {
          await prefs.remove(key);
        }

        // Tarih kontrolü kayıtlarını da temizle
        if (key.startsWith('${_lastCheckDateKey}_$userId')) {
          await prefs.remove(key);
        }
      }

      // Cache'i temizle
      _taskCompletionCache.clear();

      // Günlük görevlerin sıfırlandığı tarihi kaydet
      final today = DateTime.now().toIso8601String().split('T')[0];
      final lastResetDateKey = 'lastDailyTasksResetDate_$userId';
      await prefs.setString(lastResetDateKey, today);

      debugPrint('🔄 Günlük görevler sıfırlandı! $resetCount görev sıfırlandı');

      // Bildirim göster
      ScaffoldMess.showSnackBar(LocaleManager.translate('notification_daily_task_reset_body'));
    } catch (e) {
      debugPrint('⚠️ Günlük görevler sıfırlanırken hata: $e');
    }
  }

  /// Günlük görevlerin sıfırlanması gerekip gerekmediğini kontrol eder
  Future<bool> checkAndResetDailyTasksIfNeeded(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Bugünün tarihini al (YYYY-MM-DD formatında)
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Son kontrol tarihini al
      final lastResetCheckKey = 'lastDailyTasksResetCheck_$userId';
      final lastResetCheck = prefs.getString(lastResetCheckKey);

      // Eğer bugün zaten kontrol edilmişse, tekrar kontrol etme
      if (lastResetCheck == today) {
        debugPrint('📆 Günlük görevler bugün zaten kontrol edilmiş, tekrar kontrol edilmiyor');
        return false;
      }

      // Görevleri sıfırla
      await resetDailyTasks(userId);

      // Bugünün tarihini kaydet
      await prefs.setString(lastResetCheckKey, today);

      debugPrint('✅ Gün değiştiği için günlük görevler sıfırlandı');
      return true;
    } catch (e) {
      debugPrint('⚠️ Günlük görev kontrol ve sıfırlama sırasında hata: $e');
      return false;
    }
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
      await prefs.setString('${_dailyTaskDateKey}_$userId', now.toIso8601String());

      // Eski sistemdeki kayıtları da temizleyelim
      if (prefs.containsKey('${_dailyTaskResetTimeKey}_$userId')) {
        await prefs.remove('${_dailyTaskResetTimeKey}_$userId');
      }

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
      // Önce cache'i kontrol et
      final cacheKey = '${rewardType}_${userId}_$chatId';
      if (_chatRewardCache.containsKey(cacheKey)) {
        return _chatRewardCache[cacheKey]!;
      }

      final prefs = await SharedPreferences.getInstance();
      final key = '${rewardType}_${userId}_$chatId';
      final result = prefs.getBool(key) ?? false;

      // Sonucu cache'e ekle
      _chatRewardCache[cacheKey] = result;

      return result;
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

      // Cache'i güncelle
      _chatRewardCache[key] = true;
    } catch (e) {
      debugPrint('setChatReward hatası: $e');
    }
  }

  /// İlk mesaj gönderme ödülü kaydeder ve XP verir
  Future<void> rewardFirstMessageSent(String userId, String chatId) async {
    // Daha önce ödül almamış olmalı
    if (await hasFirstMessageSentReward(userId, chatId)) {
      debugPrint('⚠️ Bu sohbet için zaten ilk mesaj gönderme ödülü alınmış');
      return;
    }

    debugPrint('✅ İlk mesaj gönderme ödülü veriliyor');

    // Ödülü kaydet
    await setChatReward(userId, chatId, _firstMessageSentKey);

    // XP ekle
    await earnXpForEvent(userId, XpEvent.sendMessage);

    // Cache'i güncelle
    final cacheKey = '${_firstMessageSentKey}_${userId}_$chatId';
    _chatRewardCache[cacheKey] = true;
  }

  /// İlk mesaj alma ödülü kaydeder ve XP verir
  Future<void> rewardFirstMessageReceived(String userId, String chatId) async {
    // Daha önce ödül almamış olmalı
    if (await hasFirstMessageReceivedReward(userId, chatId)) {
      debugPrint('⚠️ Bu sohbet için zaten ilk mesaj alma ödülü alınmış');
      return;
    }

    debugPrint('✅ İlk mesaj alma ödülü veriliyor');

    // Ödülü kaydet
    await setChatReward(userId, chatId, _firstMessageReceivedKey);

    // XP ekle
    await earnXpForEvent(userId, XpEvent.receiveMessage);

    // Cache'i güncelle
    final cacheKey = '${_firstMessageReceivedKey}_${userId}_$chatId';
    _chatRewardCache[cacheKey] = true;
  }

  /// Mesaj ödüllerini işle
  Future<void> processMessageRewards(
      {required String userId, required String chatId, required bool isFirstMessageFromUs, required bool isFirstMessageFromOther}) async {
    if (userId.isEmpty) {
      debugPrint('⚠️ Kullanıcı ID bulunamadı, ödül işlemi iptal edildi');
      return;
    }

    // Önce SharedPreferences'dan kontrol et, sonra cache'e bak
    final prefs = await SharedPreferences.getInstance();

    // Bizim ilk mesajımız ise
    if (isFirstMessageFromUs) {
      final sentKey = '${_firstMessageSentKey}_${userId}_$chatId';
      final hasReward = prefs.getBool(sentKey) ?? _chatRewardCache[sentKey] ?? false;

      if (!hasReward) {
        await rewardFirstMessageSent(userId, chatId);
      }
    }

    // Karşıdan gelen ilk mesaj ise
    if (isFirstMessageFromOther) {
      final receivedKey = '${_firstMessageReceivedKey}_${userId}_$chatId';
      final hasReward = prefs.getBool(receivedKey) ?? _chatRewardCache[receivedKey] ?? false;

      if (!hasReward) {
        await rewardFirstMessageReceived(userId, chatId);
      }
    }
  }

  /// Günlük görevlerin durumunu ve tarih bazlı kontrolleri sıfırlar
  Future<void> clearTaskCache() async {
    _taskCompletionCache.clear();
    _chatRewardCache.clear();
    _lastDailyTaskCheck = null;
    debugPrint('📋 Görev cache\'i temizlendi');
  }

  /// Test için tarih bazlı kontrolleri sıfırlama (test sayfasından çağrılır)
  Future<void> resetDateChecks(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Tüm tarih kontrollerini sıfırla
      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        if (key.startsWith('${_lastCheckDateKey}_$userId')) {
          await prefs.remove(key);
        }
      }

      // Cache'i temizle
      _taskCompletionCache.clear();

      ScaffoldMess.showSnackBar('Tarih kontrolleri sıfırlandı!');
    } catch (e) {
      debugPrint('Tarih kontrolleri sıfırlanırken hata: $e');
    }
  }

  /// Profil sayfası için günlük giriş ödülü kontrolü
  Future<bool> checkDailyLoginReward(String userId) async {
    if (userId.isEmpty) return false;

    try {
      // Gün değişimi kontrolü yapmadan doğrudan görev kontrolü yap
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
      final lastCheckKey = '${_lastCheckDateKey}_${userId}_dailyCheckDate';
      final lastCheck = prefs.getString(lastCheckKey);

      // Bugün zaten kontrol edilmiş mi?
      if (lastCheck == today) {
        debugPrint('📆 Bugün için günlük giriş kontrolü zaten yapılmış');
        return false;
      }

      // Görevi tamamlayabilir mi?
      final canComplete = await canCompleteTask(userId, XpEvent.dailyLogin);

      // Kontrol tarihini kaydet
      await prefs.setString(lastCheckKey, today);

      if (canComplete) {
        // XP ver
        await earnXpForEvent(userId, XpEvent.dailyLogin);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Günlük giriş ödülü kontrolünde hata: $e');
      return false;
    }
  }

  /// Uygulama başlatıldığında çağrılacak - gün değişimi kontrol ve görev sıfırlama
  Future<void> checkForDayChange(String userId) async {
    await _checkForDayChangeAndResetTasks(userId);
  }

  //
  // YORUM ÖDÜLLERİ METODLARI
  //

  // Yorum ödülleri için anahtarlar
  static const String _writeCommentKey = 'writeComment';
  static const String _receiveCommentKey = 'receiveComment';

  /// Belirli bir kullanıcıya yorum yazma ödülü alınıp alınmadığını kontrol eder
  Future<bool> hasWriteCommentReward(String commenterId, String receiverId) async {
    if (commenterId.isEmpty || receiverId.isEmpty) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_writeCommentKey}_${commenterId}_$receiverId';
      return prefs.getBool(key) ?? false;
    } catch (e) {
      debugPrint('hasWriteCommentReward hatası: $e');
      return false;
    }
  }

  /// Belirli bir kullanıcıdan yorum alma ödülü alınıp alınmadığını kontrol eder
  Future<bool> hasReceiveCommentReward(String receiverId, String commenterId) async {
    if (receiverId.isEmpty || commenterId.isEmpty) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_receiveCommentKey}_${receiverId}_$commenterId';
      return prefs.getBool(key) ?? false;
    } catch (e) {
      debugPrint('hasReceiveCommentReward hatası: $e');
      return false;
    }
  }

  /// Yorum ödülü kaydeder
  Future<void> setCommentReward(String userId, String otherUserId, String rewardType) async {
    if (userId.isEmpty || otherUserId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${rewardType}_${userId}_$otherUserId';
      await prefs.setBool(key, true);
    } catch (e) {
      debugPrint('setCommentReward hatası: $e');
    }
  }

  /// Yorum yazma ödülü kaydeder ve XP verir
  Future<int> rewardWriteComment(String commenterId, String receiverId) async {
    if (commenterId.isEmpty || receiverId.isEmpty) return 0;

    // Daha önce ödül almamış olmalı
    if (await hasWriteCommentReward(commenterId, receiverId)) {
      debugPrint('⚠️ Bu kullanıcıya daha önce yorum yazma ödülü verilmiş: $commenterId -> $receiverId');
      return 0;
    }

    // Ödülü kaydet
    await setCommentReward(commenterId, receiverId, _writeCommentKey);

    // XP ekle
    debugPrint('✍️ Yorum yazma ödülü veriliyor...');
    await earnXpForEvent(commenterId, XpEvent.writeComment);
    return XpEvent.writeComment.xpAmount;
  }

  /// Yorum alma ödülü kaydeder ve XP verir
  Future<int> rewardReceiveComment(String receiverId, String commenterId) async {
    if (receiverId.isEmpty || commenterId.isEmpty) return 0;

    // Daha önce ödül almamış olmalı
    if (await hasReceiveCommentReward(receiverId, commenterId)) {
      debugPrint('⚠️ Bu kullanıcıdan daha önce yorum alma ödülü verilmiş: $receiverId <- $commenterId');
      return 0;
    }

    // Ödülü kaydet
    await setCommentReward(receiverId, commenterId, _receiveCommentKey);

    // XP ekle
    debugPrint('📝 Yorum alma ödülü veriliyor...');
    await earnXpForEvent(receiverId, XpEvent.receiveComment);
    return XpEvent.receiveComment.xpAmount;
  }

  /// Yorum işlemlerini otomatik olarak işler
  Future<Map<String, int>> handleCommentAction(String commenterId, String receiverId) async {
    if (commenterId.isEmpty || receiverId.isEmpty) {
      return {'commenterXp': 0, 'receiverXp': 0};
    }

    // Kendine yorum yazma durumunu kontrol et
    if (commenterId == receiverId) {
      debugPrint('⚠️ Kullanıcı kendine yorum yazamaz, ödül verilmedi');
      return {'commenterXp': 0, 'receiverXp': 0};
    }

    // Yorum yazana ödül ver
    final commenterXp = await rewardWriteComment(commenterId, receiverId);

    // Yorum alana ödül ver
    final receiverXp = await rewardReceiveComment(receiverId, commenterId);

    return {'commenterXp': commenterXp, 'receiverXp': receiverXp};
  }

  /// Belirli bir kullanıcı için tüm yorum ödüllerini sıfırlar (test için)
  Future<void> resetCommentRewards(String userId) async {
    if (userId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // SharedPreferences'daki tüm anahtarları al
      final allKeys = prefs.getKeys();

      // Yorum ödülleriyle ilgili anahtarları filtrele
      final commentKeys = allKeys.where((key) => (key.startsWith('${_writeCommentKey}_$userId') || key.startsWith('${_receiveCommentKey}_$userId')));

      // Filtrelenen anahtarları sil
      for (final key in commentKeys) {
        await prefs.remove(key);
      }

      ScaffoldMess.showSnackBar('Yorum ödülleri sıfırlandı!');
    } catch (e) {
      debugPrint('Yorum ödüllerini sıfırlarken hata: $e');
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
      }

      // chatId olsa bile günlük görevleri kontrol et
      final canCompleteDaily = await canCompleteTask(userId, XpEvent.dailySendMessage);
      if (canCompleteDaily) {
        debugPrint('📅 Günlük mesaj gönderme ödülü veriliyor...');
        await earnXpForEvent(userId, XpEvent.dailySendMessage);
        totalEarnedXp += XpEvent.dailySendMessage.xpAmount;
      }

      return totalEarnedXp;
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
