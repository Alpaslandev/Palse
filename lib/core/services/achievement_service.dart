import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:palseapp/core/services/notification_service.dart';
import 'package:palseapp/core/services/shared_pref_service.dart';
import 'package:palseapp/core/constant/notifications_enum.dart';
import 'package:palseapp/core/widgets/scaffold_mess.dart';
import 'package:palseapp/features/achievement/achievements.dart';
import 'package:palseapp/features/achievement/premium_rewards.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/localization/locale_manager.dart';

class AchievementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final CustomerService _customerService = CustomerService();

  // Customer modeline XP ekler
  Future<Customer> earnXp({required Customer user, required XpEvent event}) async {
    // Erken kontrol - kullanıcı yoksa işlem yapma
    if (user.userID == null) {
      debugPrint('Kullanıcı ID bulunamadı, XP eklenemedi');
      return user;
    }

    // Görevin tamamlanıp tamamlanamayacağını kontrol et
    bool shouldEarnXp = true;

    // Günlük görev kontrolü
    if (event.isDaily) {
      shouldEarnXp = !isDailyTaskCompletedToday(user);
    }

    // Tekrarlanamaz görev kontrolü
    if (!event.isRepeatable && isTaskCompleted(user, event)) {
      shouldEarnXp = false;
    }

    // XP kazanma koşulu sağlanmadıysa aynı kullanıcıyı değiştirmeden döndür
    if (!shouldEarnXp) {
      debugPrint('${event.name} görevi zaten tamamlanmış, XP eklenmedi');
      return user;
    }

    // Yeni görev tamamlama sayılarını hazırla
    var newCompletedTasks = Map<String, int>.from(user.completedTasks);
    newCompletedTasks[event.name] = (newCompletedTasks[event.name] ?? 0) + 1;

    // Günlük görev için son tamamlanma tarihini güncelle
    DateTime? newLastDailyTaskDate = user.lastDailyTaskDate;
    if (event.isDaily) {
      newLastDailyTaskDate = DateTime.now();
    }

    // Kullanıcı modelini güncelle
    final updatedUser = user.copyWith(
      totalXp: user.totalXp + event.xpAmount,
      completedTasks: newCompletedTasks,
      lastDailyTaskDate: newLastDailyTaskDate,
    );

    // Firestore'a kaydet
    try {
      await _updateUserAchievement(user.userID!, updatedUser);
      // Bildirim kaydet
      final bool isFirstCompletion = (newCompletedTasks[event.name] ?? 0) <= 1;

      // Görev ilk kez tamamlandıysa
      if (isFirstCompletion) {
        await SharedPrefService.saveNotificationWithEnum(
          type: NotificationsEnum.taskCompleted.name,
          title: LocaleManager.translate('notification_task_completed_title'),
          body: LocaleManager.translateWithParams(
              'notification_task_completed_body', {'task': event.getLocalizedDescriptionWithoutContext(), 'xp': event.xpAmount.toString()}),
        );
        ScaffoldMess.showSuccessSnackBar(LocaleManager.translateWithParams(
            'notification_task_completed_body', {'task': event.getLocalizedDescriptionWithoutContext(), 'xp': event.xpAmount.toString()}));
      } else {
        // Tekrarlanan görevler için
        await SharedPrefService.saveNotificationWithEnum(
          type: NotificationsEnum.xpEarned.name,
          title: LocaleManager.translate('notification_xp_earned_title'),
          body: LocaleManager.translateWithParams(
              'notification_xp_earned_body', {'task': event.getLocalizedDescriptionWithoutContext(), 'xp': event.xpAmount.toString()}),
        );
        ScaffoldMess.showSuccessSnackBar(LocaleManager.translateWithParams(
            'notification_xp_earned_body', {'task': event.getLocalizedDescriptionWithoutContext(), 'xp': event.xpAmount.toString()}));
      }

      // Eğer bu XP ile bir sonraki seviyeye geçildiyse
      final oldRank = UserRank.fromXp(user.totalXp);
      final newRank = UserRank.fromXp(updatedUser.totalXp);

      if (oldRank != newRank) {
        await SharedPrefService.saveNotificationWithEnum(
          type: NotificationsEnum.rankUp.name,
          title: LocaleManager.translate('notification_rank_up_title'),
          body: LocaleManager.translateWithParams('notification_rank_up_body',
              {'xp': updatedUser.totalXp.toString(), 'rank': newRank.getLocalizedTitleWithoutContext(), 'icon': newRank.icon}),
        );
        ScaffoldMess.showSuccessSnackBar(LocaleManager.translateWithParams('notification_rank_up_body',
            {'xp': updatedUser.totalXp.toString(), 'rank': newRank.getLocalizedTitleWithoutContext(), 'icon': newRank.icon}));
      }

      // Eğer bu XP ile premium ödül kazanıldıysa
      final oldPremiumCount = PremiumRewards.earnedPremiumRewards(user.totalXp);
      final newPremiumCount = PremiumRewards.earnedPremiumRewards(updatedUser.totalXp);
      final xpToNextPremium = PremiumRewards.xpToNextPremium(updatedUser.totalXp);
      await _customerService.updateCustomer(updatedUser.userID!, updatedUser.copyWith(isPremium: true));

      if (newPremiumCount > oldPremiumCount) {
        await SharedPrefService.saveNotificationWithEnum(
          type: NotificationsEnum.premiumReward.name,
          title: LocaleManager.translate('notification_premium_reward_title'),
          body: LocaleManager.translateWithParams('notification_premium_reward_body', {'xp': updatedUser.totalXp.toString()}),
        );
        ScaffoldMess.showSuccessSnackBar(
            LocaleManager.translateWithParams('notification_premium_reward_body', {'xp': updatedUser.totalXp.toString()}));
      }
      await SharedPrefService.saveNotificationWithEnum(
        type: NotificationsEnum.premiumReward.name,
        title: LocaleManager.translate('notification_next_premium_title'),
        body: LocaleManager.translateWithParams('notification_next_premium_body', {'xp': xpToNextPremium.toString()}),
      );
    } catch (e) {
      debugPrint('XP eklenirken hata: $e');
    }

    return updatedUser;
  }

  // Günlük görevleri sıfırlar
  Future<Customer> resetDailyTasks(Customer user) async {
    if (user.userID == null) {
      return user;
    }

    final updatedUser = user.copyWith(
      lastDailyTaskDate: null,
    );

    try {
      await _updateUserAchievement(user.userID!, updatedUser);
      debugPrint('Günlük görevler sıfırlandı');

      // Bildirim kaydet
      await SharedPrefService.saveNotificationWithEnum(
        type: NotificationsEnum.dailyTask.name,
        title: LocaleManager.translate('notification_daily_task_reset_title'),
        body: LocaleManager.translate('notification_daily_task_reset_body'),
      );
    } catch (e) {
      debugPrint('Günlük görevler sıfırlanırken hata: $e');
    }

    return updatedUser;
  }

  // Kullanıcı başarılarını Firestore'a kaydeder
  Future<void> _updateUserAchievement(String uuid, Customer customer) async {
    try {
      // Customer modeli içindeki achievements alanlarını güncelle
      await _firestore.collection("customers").doc(uuid).update({
        'totalXp': customer.totalXp,
        'completedTasks': customer.completedTasks,
        'lastDailyTaskDate': customer.lastDailyTaskDate != null ? Timestamp.fromDate(customer.lastDailyTaskDate!) : null,
      });
    } catch (e) {
      debugPrint('Achievement güncellenirken hata: $e');
      throw e;
    }
  }

  //Bir sonraki seviyeye kalan Xp miktarını yüzdelik oalrak döndürür
  double getXpToNextRankPercentage(int totalXp) {
    final userRank = UserRank.fromXp(totalXp);

    // Master seviyesi için %100 ilerleme göster
    if (userRank == UserRank.master) {
      return 1.0;
    }

    final xpForCurrentRank = totalXp - userRank.minXp;
    final xpRangeForRank = (userRank.maxXp as int) - userRank.minXp;

    return xpForCurrentRank / xpRangeForRank;
  }

  // Bir sonraki seviyeye kalan XP miktarını hesaplar
  int getXpToNextRank(int totalXp) {
    final userRank = UserRank.fromXp(totalXp);

    // Master seviyesi için 0 değeri döndür (en üst seviye)
    if (userRank == UserRank.master) {
      return 0;
    }

    return (userRank.maxXp as int) - totalXp;
  }

  // Premium ödül bilgilerini hesaplar
  int getEarnedPremiumRewardCount(int totalXp) {
    return PremiumRewards.earnedPremiumRewards(totalXp);
  }

  // Bir sonraki premium ödüle kalan XP miktarını hesaplar
  int getXpToNextPremium(int totalXp) {
    return PremiumRewards.xpToNextPremium(totalXp);
  }

  // Kullanıcının unvanını hesaplar
  UserRank getUserRank(int totalXp) {
    return UserRank.fromXp(totalXp);
  }

  // Belirli bir görevin tamamlanıp tamamlanmadığını kontrol eder
  bool isTaskCompleted(Customer user, XpEvent event) {
    if (event.isDaily) {
      return isDailyTaskCompletedToday(user);
    }

    final count = user.completedTasks[event.name] ?? 0;
    return count > 0;
  }

  // Belirli bir görevin kaç kez tamamlandığını hesaplar
  int getTaskCompletionCount(Customer user, XpEvent event) {
    return user.completedTasks[event.name] ?? 0;
  }

  // Günlük görevin bugün tamamlanıp tamamlanmadığını kontrol eder
  bool isDailyTaskCompletedToday(Customer user) {
    if (user.lastDailyTaskDate == null) {
      return false;
    }

    final now = DateTime.now();
    final lastDate = user.lastDailyTaskDate!;

    return lastDate.year == now.year && lastDate.month == now.month && lastDate.day == now.day;
  }

  // Kullanıcının XP'sini sıfırlar
  Future<void> resetUserXp(String uuid) async {
    await _firestore.collection("customers").doc(uuid).update({
      'totalXp': 0,
      'completedTasks': {},
      'lastDailyTaskDate': null,
    });

    // Bildirim kaydet
    await SharedPrefService.saveNotificationWithEnum(
      type: NotificationsEnum.xpReset.name,
      title: LocaleManager.translate('notification_xp_reset_title'),
      body: LocaleManager.translate('notification_xp_reset_body'),
    );
  }
}
