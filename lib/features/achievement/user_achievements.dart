import 'package:palseapp/features/achievement/achievements.dart';
import 'package:palseapp/features/achievement/daily_task.dart';
import 'package:palseapp/features/achievement/premium_rewards.dart';

/// XP kazanım kaydını temsil eden sınıf
class XpRecord {
  /// Kazanılan XP miktarı
  final int amount;

  /// XP kazanımının kaynağı
  final XpSource source;

  /// Kazanılma tarihi
  final DateTime timestamp;

  XpRecord({
    required this.amount,
    required this.source,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// XpEvent'ten XpRecord oluşturan fabrika metodu
  factory XpRecord.fromEvent(XpEvent event) {
    return XpRecord(
      amount: event.xpAmount,
      source: XpSource.event(event),
    );
  }

  /// Özel XP için XpRecord oluşturan fabrika metodu
  factory XpRecord.custom(int amount, {String? reason}) {
    return XpRecord(
      amount: amount,
      source: XpSource.custom(reason),
    );
  }
}

/// XP kaynağını temsil eden sınıf
class XpSource {
  /// Kaynak türü
  final XpSourceType type;

  /// Eğer type == XpSourceType.event ise, ilgili XpEvent
  final XpEvent? event;

  /// Eğer type == XpSourceType.custom ise, özel açıklama
  final String? customReason;

  /// Event kaynağı oluşturan constructor
  const XpSource.event(this.event)
      : type = XpSourceType.event,
        customReason = null;

  /// Özel kaynak oluşturan constructor
  const XpSource.custom(this.customReason)
      : type = XpSourceType.custom,
        event = null;
}

/// XP kaynak türlerini tanımlayan enum
enum XpSourceType {
  /// Standart XP olayı
  event,

  /// Özel XP kazanımı
  custom,
}

/// Kullanıcı başarılarını temsil eden genişletilmiş sınıf
class UserAchievements {
  final int xp;
  final UserRank rank;
  final Set<XpEvent> completedWelcomeRewards;
  final Set<XpEvent> completedEvents; // Tüm tamamlanan etkinlikleri tutan yeni alan
  final DailyTask? currentDailyTask;
  final int leaderboardRank; // Liderlik tablosundaki sıralaması
  final List<XpRecord> xpHistory; // XP kazanım geçmişi

  /// Görev türlerine göre kazanılan toplam XP değerlerini tutan harita
  final Map<XpEventGroup, int> xpEarnedByGroup;

  /// Belirli bir görevden kaç kez XP kazanıldığını tutan harita
  final Map<XpEvent, int> eventCompletionCount;

  UserAchievements({
    required this.xp,
    this.completedWelcomeRewards = const {},
    this.completedEvents = const {}, // Varsayılan olarak boş bir Set
    this.currentDailyTask,
    this.leaderboardRank = 0,
    this.xpHistory = const [],
    this.xpEarnedByGroup = const {},
    this.eventCompletionCount = const {},
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

  /// Belirli bir grup için tamamlanan görevlerin yüzdesini hesaplar
  double getGroupCompletionPercentage(XpEventGroup group) {
    final totalEvents = group.events.length;
    if (totalEvents == 0) return 0.0;

    int completedCount = 0;

    for (var event in group.events) {
      if (isEventCompleted(event)) {
        completedCount++;
      }
    }

    return completedCount / totalEvents;
  }

  /// Bir eventi tamamlanıp tamamlanmadığını kontrol eder
  bool isEventCompleted(XpEvent event) {
    // Hoş geldin ödülleri
    if (event.group == XpEventGroup.welcomeRewards) {
      return completedWelcomeRewards.contains(event);
    }

    // Günlük görevler
    if (event.group == XpEventGroup.dailyTasks) {
      if (event == XpEvent.dailyTaskListingAndMessage) {
        return isDailyTaskCompleted;
      } else if (event == XpEvent.dailyLogin) {
        return currentDailyTask?.isForToday ?? false;
      }
    }

    // Diğer tüm görevler için completedEvents'i kontrol et
    return completedEvents.contains(event);
  }

  /// Belirli bir görevden kazanılan toplam XP miktarını döndürür
  int getTotalXpFromEvent(XpEvent event) {
    final count = eventCompletionCount[event] ?? 0;
    return count * event.xpAmount;
  }

  /// Belirli bir grup için kazanılan toplam XP miktarını döndürür
  int getTotalXpFromGroup(XpEventGroup group) {
    return xpEarnedByGroup[group] ?? 0;
  }

  /// Son n adet XP kazanımını döndürür
  List<XpRecord> getRecentXpRecords({int count = 10}) {
    if (xpHistory.isEmpty) return [];
    final sortedHistory = List<XpRecord>.from(xpHistory)..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // En yeniden en eskiye sırala

    return sortedHistory.take(count).toList();
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
      completedEvents: completedEvents,
      currentDailyTask: DailyTask.createNewTask(),
      leaderboardRank: leaderboardRank,
      xpHistory: xpHistory,
      xpEarnedByGroup: xpEarnedByGroup,
      eventCompletionCount: eventCompletionCount,
    );
  }

  /// Günlük görevi tamamlar ve XP kazandırır
  UserAchievements completeDailyTask() {
    if (currentDailyTask == null || !currentDailyTask!.isForToday || currentDailyTask!.isCompleted) {
      return this;
    }

    final event = currentDailyTask!.task;
    final newXpRecord = XpRecord.fromEvent(event);
    final newXpHistory = List<XpRecord>.from(xpHistory)..add(newXpRecord);

    // Grup bazında XP takibi
    final newXpEarnedByGroup = Map<XpEventGroup, int>.from(xpEarnedByGroup);
    final groupXp = newXpEarnedByGroup[event.group] ?? 0;
    newXpEarnedByGroup[event.group] = groupXp + event.xpAmount;

    // Event tamamlama sayısı takibi
    final newEventCompletionCount = Map<XpEvent, int>.from(eventCompletionCount);
    final count = newEventCompletionCount[event] ?? 0;
    newEventCompletionCount[event] = count + 1;

    return UserAchievements(
      xp: xp + event.xpAmount,
      completedWelcomeRewards: completedWelcomeRewards,
      completedEvents: completedEvents,
      currentDailyTask: currentDailyTask!.complete(),
      leaderboardRank: leaderboardRank,
      xpHistory: newXpHistory,
      xpEarnedByGroup: newXpEarnedByGroup,
      eventCompletionCount: newEventCompletionCount,
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

    // Eğer diğer etkinliklerden biri ise ve zaten tamamlanmışsa, XP verme
    if (event.group != XpEventGroup.welcomeRewards && event.group != XpEventGroup.dailyTasks && completedEvents.contains(event)) {
      return this;
    }

    // XP kaydı oluştur
    final newXpRecord = XpRecord.fromEvent(event);
    final newXpHistory = List<XpRecord>.from(xpHistory)..add(newXpRecord);

    // Grup bazında XP takibi
    final newXpEarnedByGroup = Map<XpEventGroup, int>.from(xpEarnedByGroup);
    final groupXp = newXpEarnedByGroup[event.group] ?? 0;
    newXpEarnedByGroup[event.group] = groupXp + event.xpAmount;

    // Event tamamlama sayısı takibi
    final newEventCompletionCount = Map<XpEvent, int>.from(eventCompletionCount);
    final count = newEventCompletionCount[event] ?? 0;
    newEventCompletionCount[event] = count + 1;

    final newCompletedWelcomeRewards = Set<XpEvent>.from(completedWelcomeRewards);
    if (event.group == XpEventGroup.welcomeRewards) {
      newCompletedWelcomeRewards.add(event);
    }

    final newCompletedEvents = Set<XpEvent>.from(completedEvents);
    if (event.group != XpEventGroup.welcomeRewards && event.group != XpEventGroup.dailyTasks) {
      newCompletedEvents.add(event);
    }

    DailyTask? newDailyTask = currentDailyTask;
    if (event.group == XpEventGroup.dailyTasks && currentDailyTask != null && currentDailyTask!.isForToday && !currentDailyTask!.isCompleted) {
      newDailyTask = currentDailyTask!.complete();
    }
    return UserAchievements(
      xp: xp + event.xpAmount,
      completedWelcomeRewards: newCompletedWelcomeRewards,
      completedEvents: newCompletedEvents,
      currentDailyTask: newDailyTask,
      leaderboardRank: leaderboardRank,
      xpHistory: newXpHistory,
      xpEarnedByGroup: newXpEarnedByGroup,
      eventCompletionCount: newEventCompletionCount,
    );
  }

  /// Özel miktarda XP kazandırır
  UserAchievements earnCustomXp(int amount, {String? reason}) {
    if (amount <= 0) return this;

    // XP kaydı oluştur
    final newXpRecord = XpRecord.custom(amount, reason: reason);
    final newXpHistory = List<XpRecord>.from(xpHistory)..add(newXpRecord);

    return UserAchievements(
      xp: xp + amount,
      completedWelcomeRewards: completedWelcomeRewards,
      completedEvents: completedEvents,
      currentDailyTask: currentDailyTask,
      leaderboardRank: leaderboardRank,
      xpHistory: newXpHistory,
      xpEarnedByGroup: xpEarnedByGroup,
      eventCompletionCount: eventCompletionCount,
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
