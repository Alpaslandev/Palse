import 'package:flutter/widgets.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/features/achievement/premium_rewards.dart';

/// XP seviyelerine göre kullanıcı unvanlarını tanımlayan enum
enum UserRank {
  /// 0-99 XP: Keşfe Başlayan
  beginner(
    titleKey: 'rank_beginner',
    minXp: 0,
    maxXp: 99,
    icon: '🌟',
  ),

  /// 100-499 XP: Sosyal Keşifçi
  explorer(
    titleKey: 'rank_explorer',
    minXp: 100,
    maxXp: 499,
    icon: '🔍',
  ),

  /// 500-999 XP: Bağlantı Ustası
  connector(
    titleKey: 'rank_connector',
    minXp: 500,
    maxXp: 999,
    icon: '🧩',
  ),

  /// 1000-2999 XP: Etkinlik Lideri
  leader(
    titleKey: 'rank_leader',
    minXp: 1000,
    maxXp: 2999,
    icon: '🎯',
  ),

  /// 3000+ XP: Sosyal Usta
  master(
    titleKey: 'rank_master',
    minXp: 3000,
    maxXp: double.infinity,
    icon: '👑',
  );

  /// Constructor
  const UserRank({
    required this.titleKey,
    required this.minXp,
    required this.maxXp,
    required this.icon,
  });

  /// Unvan başlığının anahtar değeri
  final String titleKey;

  /// Minimum XP değeri
  final int minXp;

  /// Maksimum XP değeri
  final num maxXp;

  /// Unvan ikonu
  final String icon;

  /// Yerelleştirilmiş unvan başlığını al
  String getLocalizedTitle(BuildContext context) {
    return context.tr(titleKey);
  }

  /// XP değerine göre uygun unvanı döndüren yardımcı metod
  static UserRank fromXp(int xp) {
    return UserRank.values.firstWhere(
      (rank) => xp >= rank.minXp && xp <= rank.maxXp,
      orElse: () => UserRank.master,
    );
  }

  /// Unvanın ilerleme yüzdesini hesaplayan yardımcı metod
  double getProgressPercentage(int currentXp) {
    if (this == UserRank.master) {
      return 1.0; // Sosyal Usta için her zaman %100
    }

    final totalRangeXp = maxXp - minXp;
    final userProgressInRange = currentXp - minXp;

    return (userProgressInRange / totalRangeXp).clamp(0.0, 1.0);
  }

  /// Bir sonraki unvana geçmek için gereken XP miktarını hesaplayan yardımcı metod
  int xpToNextRank(int currentXp) {
    if (this == UserRank.master) {
      return 0; // En üst seviyede olduğu için 0
    }

    return (maxXp - currentXp + 1).toInt();
  }

  /// Bir sonraki premium ödülüne ne kadar XP kaldığını hesaplayan yardımcı metod
  int xpToNextPremium(int currentXp) {
    if (this == UserRank.master) {
      return 0; // En üst seviyede olduğu için 0
    }

    return (PremiumRewards.xpToNextPremium(currentXp) - currentXp).toInt();
  }
}

/// XP kazandıran olay türlerini tanımlayan enum
/// Basitleştirilmiş versiyonu
enum XpEvent {
  // Tek seferlik görevler
  firstListing(500, 'İlk ilanını oluşturma', 'first_listing_description', isRepeatable: false, isDaily: false),
  firstMessage(500, 'İlk mesajını gönderme', 'first_message_description', isRepeatable: false, isDaily: false),

  // Tekrarlanabilir görevler
  createListing(100, 'Yeni ilan oluştur', 'create_listing_description', isRepeatable: true, isDaily: false),
  sendMessage(35, 'İlk defa mesaj gönderilen kullanıcı başına', 'send_message_description', isRepeatable: true, isDaily: false),
  receiveMessage(10, 'İlanınıza gelen her ilk mesaj', 'receive_message_description', isRepeatable: true, isDaily: false),
  writeComment(15, 'Birine yorum yazma', 'write_comment_description', isRepeatable: true, isDaily: false),
  receiveComment(10, 'Profiline yorum alma', 'receive_comment_description', isRepeatable: true, isDaily: false),

  // Günlük görevler
  dailyTaskCreateListingAndMessage(100, 'Bir ilan oluştur ve bir mesaj gönder', 'daily_task_description', isRepeatable: false, isDaily: true),
  dailyLogin(10, 'Uygulamaya günlük giriş', 'daily_login_description', isRepeatable: false, isDaily: true);

  /// Constructor
  const XpEvent(this.xpAmount, this.description, this.descriptionKey, {required this.isRepeatable, required this.isDaily});

  /// Kazanılan XP miktarı
  final int xpAmount;

  /// Olay açıklaması (Türkçe)
  final String description;

  /// Olay açıklaması için çeviri anahtarı
  final String descriptionKey;

  /// Görevin tekrarlanabilir olup olmadığı
  final bool isRepeatable;

  /// Görevin günlük görev olup olmadığı
  final bool isDaily;

  /// Yerelleştirilmiş açıklama metni
  String getLocalizedDescription(BuildContext context) {
    return context.tr(descriptionKey);
  }

  /// Görevin kategorisini döndüren getter
  String get category {
    if (isDaily) {
      return 'Günlük Görevler';
    } else if (!isRepeatable) {
      return 'Hoş Geldin Ödülleri';
    } else if (this == XpEvent.createListing || this == XpEvent.receiveMessage) {
      return 'İlan Verme';
    } else if (this == XpEvent.sendMessage) {
      return 'Mesajlaşma';
    } else if (this == XpEvent.writeComment || this == XpEvent.receiveComment) {
      return 'Yorumlama ve Yorum Almak';
    }
    return 'Genel';
  }
}

/// XP event gruplarını tanımlayan enum
enum XpEventGroup {
  welcomeRewards(
      'welcome_rewards',
      [
        XpEvent.firstListing,
        XpEvent.firstMessage,
      ],
      '🎁'),

  listing(
      'listing',
      [
        XpEvent.createListing,
        XpEvent.receiveMessage,
      ],
      '📋'),

  messaging(
      'messaging',
      [
        XpEvent.sendMessage,
      ],
      '💬'),

  commenting(
      'commenting',
      [
        XpEvent.writeComment,
        XpEvent.receiveComment,
      ],
      '💭'),

  dailyTasks(
      'daily_tasks',
      [
        XpEvent.dailyTaskCreateListingAndMessage,
        XpEvent.dailyLogin,
      ],
      '📅');

  const XpEventGroup(this.titleKey, this.events, this.emoji);

  /// Grup başlığı için çeviri anahtarı
  final String titleKey;

  /// Bu gruba ait eventler
  final List<XpEvent> events;

  /// Grup için emoji getirir
  final String emoji;

  /// Yerelleştirilmiş başlık
  String getLocalizedTitle(BuildContext context) {
    return context.tr(titleKey);
  }
}

/// Kullanıcı Achievement Sistemi
class UserAchievements {
  /// Toplam XP miktarı
  final int totalXp;

  /// Tamamlanan görevler ve tamamlanma sayıları
  final Map<XpEvent, int> completedTasks;

  /// Son günlük görev tamamlama tarihi
  final DateTime? lastDailyTaskDate;

  UserAchievements({
    this.totalXp = 0,
    this.completedTasks = const {},
    this.lastDailyTaskDate,
  });

  /// Kullanıcının mevcut unvanı
  UserRank get rank => UserRank.fromXp(totalXp);

  /// Kullanıcının mevcut unvanda ilerleme yüzdesi
  double get progressPercentage => rank.getProgressPercentage(totalXp);

  /// Bir sonraki unvana geçmek için gereken XP
  int get xpToNextRank => rank.xpToNextRank(totalXp);

  /// Bir sonraki premium ödüle kalan XP
  int get xpToNextPremium => PremiumRewards.xpToNextPremium(totalXp);

  /// Kullanıcının kazandığı premium ödül sayısı
  int get earnedPremiumRewards => PremiumRewards.earnedPremiumRewards(totalXp);

  /// Görevin bugün tamamlanıp tamamlanmadığını kontrol eder
  bool isDailyTaskCompletedToday() {
    if (lastDailyTaskDate == null) return false;

    final now = DateTime.now();
    return lastDailyTaskDate!.year == now.year && lastDailyTaskDate!.month == now.month && lastDailyTaskDate!.day == now.day;
  }

  /// Belirli bir görevin tamamlanıp tamamlanmadığını kontrol eder
  bool isTaskCompleted(XpEvent event) {
    if (event.isDaily) {
      return isDailyTaskCompletedToday();
    }

    return completedTasks.containsKey(event) && completedTasks[event]! > 0;
  }

  /// Belirli bir görevin kaç kez tamamlandığını döndürür
  int getTaskCompletionCount(XpEvent event) {
    return completedTasks[event] ?? 0;
  }

  /// XP kazanma işlemi
  UserAchievements earnXp(XpEvent event) {
    // Eğer günlük görevse ve bugün zaten tamamlanmışsa, XP verme
    if (event.isDaily && isDailyTaskCompletedToday()) {
      return this;
    }

    // Eğer tekrarlanamaz bir görevse ve zaten tamamlanmışsa, XP verme
    if (!event.isRepeatable && isTaskCompleted(event)) {
      return this;
    }

    // Yeni XP ve tamamlanan görevleri güncelle
    var newCompletedTasks = Map<XpEvent, int>.from(completedTasks);
    newCompletedTasks[event] = (newCompletedTasks[event] ?? 0) + 1;

    // Günlük görev için son tamamlanma tarihini güncelle
    DateTime? newLastDailyTaskDate = lastDailyTaskDate;
    if (event.isDaily) {
      newLastDailyTaskDate = DateTime.now();
    }

    return UserAchievements(
      totalXp: totalXp + event.xpAmount,
      completedTasks: newCompletedTasks,
      lastDailyTaskDate: newLastDailyTaskDate,
    );
  }

  /// XpEvent kullanmadan özel XP kazanma (ödül vb. için)
  UserAchievements earnCustomXp(int amount) {
    return UserAchievements(
      totalXp: totalXp + amount,
      completedTasks: completedTasks,
      lastDailyTaskDate: lastDailyTaskDate,
    );
  }

  /// Tüm günlük görevleri sıfırlar (Gece 12'de çağrılabilir)
  UserAchievements resetDailyTasks() {
    return UserAchievements(
      totalXp: totalXp,
      completedTasks: completedTasks,
      lastDailyTaskDate: null,
    );
  }

  /// JSON'dan UserAchievements oluşturur
  factory UserAchievements.fromJson(Map<String, dynamic> json) {
    final taskCompletions = <XpEvent, int>{};
    final taskData = json['completedTasks'] as Map<String, dynamic>? ?? {};

    taskData.forEach((key, value) {
      try {
        final event = XpEvent.values.firstWhere((e) => e.name == key);
        taskCompletions[event] = value as int;
      } catch (e) {
        print('Bilinmeyen XpEvent: $key');
      }
    });

    return UserAchievements(
      totalXp: json['totalXp'] ?? 0,
      completedTasks: taskCompletions,
      lastDailyTaskDate: json['lastDailyTaskDate'] != null ? DateTime.parse(json['lastDailyTaskDate']) : null,
    );
  }

  /// UserAchievements'ı JSON'a dönüştürür
  Map<String, dynamic> toJson() {
    return {
      'totalXp': totalXp,
      'completedTasks': completedTasks.map((key, value) => MapEntry(key.name, value)),
      'lastDailyTaskDate': lastDailyTaskDate?.toIso8601String(),
    };
  }
}
