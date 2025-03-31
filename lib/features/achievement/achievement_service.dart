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
  AchievementService._internal() {
    _cacheHelper = _CacheHelper();
  }

  // Cache yardımcı sınıfı
  late final _CacheHelper _cacheHelper;

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
  /// İstanbul saatine göre 09:00'da sıfırlama yapılır
  Future<void> _checkForDayChangeAndResetTasks(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Şu anki İstanbul saatini al (UTC+3)
      final now = DateTime.now().toLocal();
      final today = now.toIso8601String().split('T')[0]; // YYYY-MM-DD

      // İstanbul'da saat 09:00 - sıfırlama zamanı
      final resetTime = DateTime(now.year, now.month, now.day, 9, 0, 0);

      // Son sıfırlama zamanını kontrol et
      final lastResetTimeKey = _PrefsKeys.forUser(_PrefsKeys.dailyTaskResetTime, userId);
      final lastResetCheck = prefs.getString(lastResetTimeKey);
      final lastResetTime = lastResetCheck != null ? DateTime.parse(lastResetCheck) : null;

      // Son kontrol tarihini al
      final lastResetDateKey = _PrefsKeys.forUser(_PrefsKeys.dailyTaskResetDate, userId);
      final lastResetDate = prefs.getString(lastResetDateKey);

      // Sıfırlama gerektiren durumları kontrol et:
      // 1. Şu an saat 09:00'dan sonra ve son sıfırlama saat 09:00'dan önce ise
      // 2. Son sıfırlama tarihi bugünden farklı ise
      if ((now.isAfter(resetTime) && (lastResetTime == null || lastResetTime.isBefore(resetTime))) || lastResetDate != today) {
        debugPrint('📅 Günlük görev sıfırlama zamanı (09:00) geldi veya gün değişimi tespit edildi');
        await resetDailyTasks(userId);

        // Son sıfırlama zamanını ve tarihini kaydet
        await prefs.setString(lastResetTimeKey, now.toIso8601String());
        await prefs.setString(lastResetDateKey, today);
      } else {
        debugPrint('📅 Günlük görevler için sıfırlama zamanı henüz gelmedi');
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
      for (final event in XpEvent.getDailyTasks()) {
        final taskDateKey = _PrefsKeys.forUser(_PrefsKeys.dailyTaskDate, userId, suffix: event.name);
        final lastTaskDate = prefs.getString(taskDateKey);

        // Cache'e ekle
        final cacheKey = '${userId}_${event.name}_$today';
        _cacheHelper.setTaskCompletion(cacheKey, lastTaskDate == today ? false : true);
      }

      // Mesaj ödülleri için cache'i yükle
      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        if (key.startsWith('${_PrefsKeys.firstMessageSent}_$userId') || key.startsWith('${_PrefsKeys.firstMessageReceived}_$userId')) {
          final value = prefs.getBool(key) ?? false;
          _cacheHelper.setChatReward(key, value);
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

  static const String _firstMessageSentCountKey = 'firstMessageSentCount'; // İlk mesaj gönderme ödülü sayısı anahtarı
  static const int _maxFirstMessageSentRewards = 3; // Maksimum ilk mesaj ödülü sayısı

  // Görev kontrolü optimizasyonu için cache mekanizması
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
      final localXp = prefs.getInt(_PrefsKeys.forUser(_PrefsKeys.totalXp, userId));

      if (localXp != null) {
        return localXp;
      }

      // Yerel veri yoksa Firestore'dan getir
      final userDoc = await _firestore.collection('customers').doc(userId).get();

      if (userDoc.exists && userDoc.data()!.containsKey('totalXp')) {
        final totalXp = userDoc.data()!['totalXp'] as int;

        // Yerel olarak da kaydet
        await prefs.setInt(_PrefsKeys.forUser(_PrefsKeys.totalXp, userId), totalXp);

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
      await prefs.setInt(_PrefsKeys.forUser(_PrefsKeys.totalXp, userId), newXp);

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
      // Eski ve yeni premium ödül sayılarını hesapla ve yeni ödül kazanıldı mı kontrol et
      if (PremiumRewards.hasEarnedNewReward(oldTotalXp, newTotalXp)) {
        final oldPremiumCount = PremiumRewards.earnedPremiumRewards(oldTotalXp);
        final newPremiumCount = PremiumRewards.earnedPremiumRewards(newTotalXp);

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
        _cacheHelper.setTaskCompletion(cacheKey, false); // Artık tamamlanamaz

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
      if (_cacheHelper.hasTaskCompletion(cacheKey)) {
        return _cacheHelper.getTaskCompletion(cacheKey)!;
      }

      // Cache'de yoksa, hesapla ve cache'e ekle
      final canComplete = await _canCompleteDailyTask(userId, event);
      _cacheHelper.setTaskCompletion(cacheKey, canComplete);

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

      debugPrint('📆 ${event.name} görevi bugün ($today) için tamamlandı olarak işaretlendi');
    }
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
      _cacheHelper.clear();

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
    return UserRank.calculateProgressPercentage(rank, currentXp);
  }

  /// Bir sonraki unvana geçmek için gereken XP miktarını hesaplayan metod
  int calculateXpToNextRank(UserRank rank, int currentXp) {
    return UserRank.calculateXpToNextRank(rank, currentXp);
  }

  /// Bir sonraki seviyeye kalan XP yüzdesini hesaplar
  Future<double> getXpToNextRankPercentage(String userId) async {
    final totalXp = await getUserXp(userId);
    final userRank = UserRank.fromXp(totalXp);
    return UserRank.calculateProgressPercentage(userRank, totalXp);
  }

  /// Bir sonraki seviyeye kalan XP miktarını hesaplar
  Future<int> getXpToNextRank(String userId) async {
    final totalXp = await getUserXp(userId);
    final userRank = UserRank.fromXp(totalXp);
    return UserRank.calculateXpToNextRank(userRank, totalXp);
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
  /// Premium ödüller tamamen kazanılmışsa 0 döndürür
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
    if (xpToNextPremium > 0) {
      // Kalan XP 0'dan büyükse bildirim göster
      await SharedPrefService.saveNotificationWithEnum(
        type: NotificationsEnum.premiumReward.name,
        title: LocaleManager.translate('notification_next_premium_title'),
        body: LocaleManager.translateWithParams('notification_next_premium_body', {'xp': xpToNextPremium.toString()}),
      );
    } else {
      // Tüm premium ödülleri kazanmışsa farklı bir bildirim göster
      await SharedPrefService.saveNotificationWithEnum(
        type: NotificationsEnum.premiumReward.name,
        title: LocaleManager.translate('notification_premium_complete_title'),
        body: LocaleManager.translate('notification_premium_complete_body'),
      );
    }
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
  //
  // MESAJ ÖDÜLLERİ METODLARI - OPTİMİZE EDİLMİŞ
  //

  /// İlk mesaj gönderme/alma ödüllerini işler (optimize edilmiş)
  Future<int> processMessageReward({
    required String userId,
    required String chatId,
    required bool isMessageSent, // Mesaj gönderildi mi (true) yoksa alındı mı (false)
  }) async {
    if (userId.isEmpty || chatId.isEmpty) return 0;

    try {
      // Ödül türünü belirle
      final rewardType = isMessageSent ? _PrefsKeys.firstMessageSent : _PrefsKeys.firstMessageReceived;
      final xpEvent = isMessageSent ? XpEvent.sendMessage : XpEvent.receiveMessage;

      // Önce cache kontrol et, sonra SharedPreferences
      final cacheKey = '${rewardType}_${userId}_$chatId';

      // Eğer zaten ödül alınmışsa, hemen dön
      if (_cacheHelper.hasChatReward(cacheKey) && _cacheHelper.getChatReward(cacheKey) == true) {
        return 0;
      }

      // Cache'de yoksa, SharedPreferences'dan kontrol et
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(cacheKey) == true) {
        // Cache'e ekle ve dön
        _cacheHelper.setChatReward(cacheKey, true);
        return 0;
      }

      // Mesaj gönderiliyorsa ve maksimum ödül limitine ulaşıldıysa kontrol et
      if (isMessageSent) {
        // Sadece ilk mesaj ödülü için limit kontrolü yap
        final currentCount = prefs.getInt('${_firstMessageSentCountKey}_$userId') ?? 0;
        if (currentCount >= _maxFirstMessageSentRewards) {
          // Limiti aştıysa, sadece kaydedip 0 dön
          await prefs.setBool(cacheKey, true);
          _cacheHelper.setChatReward(cacheKey, true);
          debugPrint('⚠️ İlk mesaj ödülü limiti (${_maxFirstMessageSentRewards}) dolduğu için XP verilmiyor');
          return 0;
        }

        // Ödül sayısını artır
        await prefs.setInt('${_firstMessageSentCountKey}_$userId', currentCount + 1);
        debugPrint('📊 Kullanıcının toplam ilk mesaj ödülü sayısı: ${currentCount + 1}/${_maxFirstMessageSentRewards}');
      }

      // Ödülü kaydet
      await prefs.setBool(cacheKey, true);
      _cacheHelper.setChatReward(cacheKey, true);

      // XP ekle
      final earnedXp = await earnXpForEvent(userId, xpEvent);

      final message = isMessageSent ? '✅ İlk mesaj gönderme ödülü verildi' : '✅ İlk mesaj alma ödülü verildi';
      debugPrint(message);

      return xpEvent.xpAmount;
    } catch (e) {
      debugPrint('⚠️ Mesaj ödülü işlenirken hata: $e');
      return 0;
    }
  }

  /// Mesaj gönderme ve alma ödüllerini işler (optimize edilmiş)
  Future<int> handleMessageEvents(
      {required String userId, required String chatId, required bool isFirstMessageFromUs, required bool isFirstMessageFromOther}) async {
    if (userId.isEmpty) {
      debugPrint('⚠️ Kullanıcı ID bulunamadı, ödül işlemi iptal edildi');
      return 0;
    }

    int totalXp = 0;

    // Bizim ilk mesajımız ise
    if (isFirstMessageFromUs) {
      totalXp += await processMessageReward(userId: userId, chatId: chatId, isMessageSent: true);
    }

    // Karşıdan gelen ilk mesaj ise
    if (isFirstMessageFromOther) {
      totalXp += await processMessageReward(userId: userId, chatId: chatId, isMessageSent: false);
    }

    return totalXp;
  }

  /// Günlük mesaj görevi için XP kazandırır (optimize edilmiş)
  Future<int> handleDailyMessageTask(String userId) async {
    if (userId.isEmpty) return 0;

    // Günlük mesaj gönderme görevi kontrolü
    final canCompleteDaily = await canCompleteTask(userId, XpEvent.dailySendMessage);
    if (canCompleteDaily) {
      debugPrint('📅 Günlük mesaj gönderme ödülü veriliyor...');
      await earnXpForEvent(userId, XpEvent.dailySendMessage);
      return XpEvent.dailySendMessage.xpAmount;
    }

    return 0;
  }

  /// Mesaj gönderme işlemlerini otomatik olarak işler
  Future<int> handleMessageSent(String userId, {String? chatId}) async {
    if (userId.isEmpty) return 0;

    int totalEarnedXp = 0;

    // Eğer chatId verilmişse sohbet bazlı kontrol yap
    if (chatId != null) {
      // Optimize edilmiş yeni metodu kullan
      totalEarnedXp += await processMessageReward(userId: userId, chatId: chatId, isMessageSent: true);

      // Günlük görev XP'sini ekle
      totalEarnedXp += await handleDailyMessageTask(userId);

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

    // Günlük mesaj görevi için optimize edilmiş metodu kullan
    totalEarnedXp += await handleDailyMessageTask(userId);

    return totalEarnedXp;
  }

  /// Mesaj alma işlemlerini otomatik olarak işler
  Future<int> handleMessageReceived(String userId, {String? chatId}) async {
    if (userId.isEmpty) return 0;

    int totalEarnedXp = 0;

    // Eğer chatId verilmişse sohbet bazlı kontrol yap
    if (chatId != null) {
      // Optimize edilmiş yeni metodu kullan
      totalEarnedXp += await processMessageReward(userId: userId, chatId: chatId, isMessageSent: false);

      return totalEarnedXp;
    }

    // Her mesaj alma için XP ver
    debugPrint('📩 Mesaj alma ödülü veriliyor...');
    await earnXpForEvent(userId, XpEvent.receiveMessage);
    totalEarnedXp += XpEvent.receiveMessage.xpAmount;

    return totalEarnedXp;
  }

  /// Mesaj ödüllerini işle
  Future<void> processMessageRewards(
      {required String userId, required String chatId, required bool isFirstMessageFromUs, required bool isFirstMessageFromOther}) async {
    await handleMessageEvents(
        userId: userId, chatId: chatId, isFirstMessageFromUs: isFirstMessageFromUs, isFirstMessageFromOther: isFirstMessageFromOther);
  }

  /// İlk mesaj gönderme ödülü alınmış mı?
  Future<bool> hasFirstMessageSentReward(String userId, String chatId) async {
    final key = '${_PrefsKeys.firstMessageSent}_${userId}_$chatId';

    // Önce cache kontrol et
    if (_cacheHelper.hasChatReward(key)) {
      return _cacheHelper.getChatReward(key)!;
    }

    // Sonra SharedPreferences'a bak
    final prefs = await SharedPreferences.getInstance();
    final result = prefs.getBool(key) ?? false;

    // Cache'e ekle
    _cacheHelper.setChatReward(key, result);

    return result;
  }

  /// İlk mesaj alma ödülü alınmış mı?
  Future<bool> hasFirstMessageReceivedReward(String userId, String chatId) async {
    final key = '${_PrefsKeys.firstMessageReceived}_${userId}_$chatId';

    // Önce cache kontrol et
    if (_cacheHelper.hasChatReward(key)) {
      return _cacheHelper.getChatReward(key)!;
    }

    // Sonra SharedPreferences'a bak
    final prefs = await SharedPreferences.getInstance();
    final result = prefs.getBool(key) ?? false;

    // Cache'e ekle
    _cacheHelper.setChatReward(key, result);

    return result;
  }

  /// Sohbet için ödül kaydeder
  Future<void> setChatReward(String userId, String chatId, String rewardType) async {
    if (userId.isEmpty || chatId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${rewardType}_${userId}_$chatId';
      await prefs.setBool(key, true);

      // Cache'i güncelle
      _cacheHelper.setChatReward(key, true);
    } catch (e) {
      debugPrint('setChatReward hatası: $e');
    }
  }

  /// İlk mesaj gönderme ödülü sayısını getirir
  Future<int> getFirstMessageSentRewardCount(String userId) async {
    if (userId.isEmpty) return 0;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('${_firstMessageSentCountKey}_$userId') ?? 0;
  }

  /// Kullanıcının daha fazla ilk mesaj ödülü alıp alamayacağını kontrol eder
  Future<bool> canReceiveMoreFirstMessageSentRewards(String userId) async {
    if (userId.isEmpty) return false;

    final currentCount = await getFirstMessageSentRewardCount(userId);
    return currentCount < _maxFirstMessageSentRewards;
  }

  /// İlk mesaj gönderme ödülü kaydeder ve XP verir (bu metod artık processMessageReward tarafından ele alınıyor)
  Future<void> rewardFirstMessageSent(String userId, String chatId) async {
    await processMessageReward(userId: userId, chatId: chatId, isMessageSent: true);
  }

  /// İlk mesaj alma ödülü kaydeder ve XP verir (bu metod artık processMessageReward tarafından ele alınıyor)
  Future<void> rewardFirstMessageReceived(String userId, String chatId) async {
    await processMessageReward(userId: userId, chatId: chatId, isMessageSent: false);
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
}

/// Cache yönetimi için yardımcı sınıf
class _CacheHelper {
  final Map<String, bool> _chatRewardCache = {};
  final Map<String, bool> _taskCompletionCache = {};

  // Task tamamlama cache işlemleri
  bool hasTaskCompletion(String key) => _taskCompletionCache.containsKey(key);
  bool? getTaskCompletion(String key) => _taskCompletionCache[key];
  void setTaskCompletion(String key, bool value) => _taskCompletionCache[key] = value;

  // Chat ödül cache işlemleri
  bool hasChatReward(String key) => _chatRewardCache.containsKey(key);
  bool? getChatReward(String key) => _chatRewardCache[key];
  void setChatReward(String key, bool value) => _chatRewardCache[key] = value;

  // Tüm cache'i temizle
  void clear() {
    _chatRewardCache.clear();
    _taskCompletionCache.clear();
  }
}

/// SharedPreferences anahtarlarını merkezi olarak yöneten sınıf
class _PrefsKeys {
  // Kullanıcı bazlı anahtar oluşturma
  static String forUser(String baseKey, String userId, {String? suffix}) {
    return suffix != null ? '${baseKey}_${userId}_$suffix' : '${baseKey}_$userId';
  }

  // Tarih kontrolü anahtarları
  static const String dailyTaskResetTime = 'dailyTaskResetTime';
  static const String dailyTaskResetDate = 'dailyTasksResetDate';
  static const String dailyTaskDate = 'dailyTaskDate';

  // XP ve görev anahtarları
  static const String totalXp = 'totalXp';

  // Mesaj ödül anahtarları
  static const String firstMessageSent = 'firstMessageSent';
  static const String firstMessageReceived = 'firstMessageReceived';
}
