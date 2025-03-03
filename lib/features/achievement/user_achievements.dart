import 'package:palseapp/features/achievement/achievements.dart';
import 'package:palseapp/features/achievement/daily_task.dart';
import 'package:palseapp/features/achievement/premium_rewards.dart';

/// Kullanıcı başarılarını temsil eden genişletilmiş sınıf
class UserAchievements {
  final int xp;
  final UserRank rank;
  final Set<XpEvent> completedWelcomeRewards;
  final DailyTask? currentDailyTask;
  final int leaderboardRank; // Liderlik tablosundaki sıralaması

  UserAchievements({
    required this.xp,
    this.completedWelcomeRewards = const {},
    this.currentDailyTask,
    this.leaderboardRank = 0,
  }) : rank = UserRank.fromXp(xp);

  /// Kullanıcının mevcut seviyedeki ilerleme yüzdesini döndürür
  double get progressPercentage => rank.getProgressPercentage(xp);

  /// Bir sonraki seviyeye geçmek için gereken XP miktarını döndürür
  int get xpToNextRank => rank.xpToNextRank(xp);

  /// Bir sonraki premium ödüle ne kadar XP kaldığını döndürür
  int get xpToNextPremium => PremiumRewards.xpToNextPremium(xp);

  /// Kullanıcının toplam kaç premium ödül kazandığını döndürür
  int get earnedPremiumRewards => PremiumRewards.earnedPremiumRewards(xp);

  /// Bir sonraki premium ödül eşiğini döndürür
  int get nextPremiumThreshold => PremiumRewards.getNextPremiumThreshold(xp);

  /// Hoş geldin ödüllerinin tamamlanıp tamamlanmadığını kontrol eder
  bool get hasCompletedAllWelcomeRewards {
    final welcomeRewards = XpEvent.values.where((e) => e.group == XpEventGroup.welcomeRewards);
    return completedWelcomeRewards.containsAll(welcomeRewards);
  }

  /// Günlük görevin olup olmadığını kontrol eder
  bool get hasDailyTask => currentDailyTask != null && currentDailyTask!.isForToday;

  /// Günlük görevin tamamlanıp tamamlanmadığını kontrol eder
  bool get isDailyTaskCompleted => currentDailyTask != null && currentDailyTask!.isForToday && currentDailyTask!.isCompleted;

  /// Yeni bir günlük görev oluşturur
  UserAchievements createNewDailyTask() {
    return UserAchievements(
      xp: xp,
      completedWelcomeRewards: completedWelcomeRewards,
      currentDailyTask: DailyTask.createNewTask(),
      leaderboardRank: leaderboardRank,
    );
  }

  /// Günlük görevi tamamlar ve XP kazandırır
  UserAchievements completeDailyTask() {
    if (currentDailyTask == null || !currentDailyTask!.isForToday || currentDailyTask!.isCompleted) {
      return this;
    }

    return UserAchievements(
      xp: xp + currentDailyTask!.task.xpAmount,
      completedWelcomeRewards: completedWelcomeRewards,
      currentDailyTask: currentDailyTask!.complete(),
      leaderboardRank: leaderboardRank,
    );
  }

  /// Belirli bir XP olayı için XP kazandırır
  UserAchievements earnXp(XpEvent event) {
    // Eğer hoş geldin ödülü ise ve zaten tamamlanmışsa, XP verme
    if (event.group == XpEventGroup.welcomeRewards && completedWelcomeRewards.contains(event)) {
      return this;
    }

    // Eğer günlük görev ise ve zaten tamamlanmışsa, XP verme
    if (event.group == XpEventGroup.dailyTasks && isDailyTaskCompleted) {
      return this;
    }

    final newCompletedWelcomeRewards = Set<XpEvent>.from(completedWelcomeRewards);
    if (event.group == XpEventGroup.welcomeRewards) {
      newCompletedWelcomeRewards.add(event);
    }

    DailyTask? newDailyTask = currentDailyTask;
    if (event.group == XpEventGroup.dailyTasks && currentDailyTask != null && currentDailyTask!.isForToday && !currentDailyTask!.isCompleted) {
      newDailyTask = currentDailyTask!.complete();
    }
    return UserAchievements(
      xp: xp + event.xpAmount,
      completedWelcomeRewards: newCompletedWelcomeRewards,
      currentDailyTask: newDailyTask,
      leaderboardRank: leaderboardRank,
    );
  }

  /// Özel miktarda XP kazandırır
  UserAchievements earnCustomXp(int amount, {String? reason}) {
    if (amount <= 0) return this;

    return UserAchievements(
      xp: xp + amount,
      completedWelcomeRewards: completedWelcomeRewards,
      currentDailyTask: currentDailyTask,
      leaderboardRank: leaderboardRank,
    );
  }

  /// Kullanıcının bir üst seviyeye geçip geçmediğini kontrol eder
  bool hasLeveledUp(int previousXp) {
    final previousRank = UserRank.fromXp(previousXp);
    return rank != previousRank;
  }

  /// Kullanıcının yeni bir premium ödül kazanıp kazanmadığını kontrol eder
  bool hasEarnedNewPremium(int previousXp) {
    final previousEarnedRewards = PremiumRewards.earnedPremiumRewards(previousXp);
    return earnedPremiumRewards > previousEarnedRewards;
  }
}
