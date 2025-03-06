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
enum XpEvent {
  /// Hoş Geldin Ödülleri (Tek Seferlik)
  firstListing(500, 'İlk ilanını oluşturma', 'first_listing_description'),
  firstMessage(500, 'İlk mesajını gönderme', 'first_message_description'),

  /// İlan Verme
  createListing(100, 'Yeni ilan oluştur', 'create_listing_description'),
  receiveFirstMessage(10, 'İlanınıza gelen her ilk mesaj', 'receive_first_message_description'),

  /// Mesajlaşma
  sendFirstMessage(35, 'İlk defa mesaj gönderilen kullanıcı başına', 'send_first_message_description'),

  /// Yorumlama ve Yorum Almak
  writeComment(15, 'Birine yorum yazma', 'write_comment_description'),
  receiveComment(10, 'Profiline yorum alma', 'receive_comment_description'),

  /// Günlük Görev
  dailyTaskListingAndMessage(100, 'Bir ilan oluştur ve bir mesaj gönder', 'daily_task_listing_and_message_description'),
  dailyLogin(10, 'Uygulamaya günlük giriş', 'daily_login_description');

  /// Constructor
  const XpEvent(this.xpAmount, this.description, this.descriptionKey);

  /// Kazanılan XP miktarı
  final int xpAmount;

  /// Olay açıklaması (Türkçe)
  final String description;

  /// Olay açıklaması için çeviri anahtarı
  final String descriptionKey;

  /// Yerelleştirilmiş açıklama metni
  String getLocalizedDescription(BuildContext context) {
    return context.tr(descriptionKey);
  }

  /// Event'in ait olduğu grubu bulan yardımcı metod
  XpEventGroup get group {
    for (final group in XpEventGroup.values) {
      if (group.events.contains(this)) {
        return group;
      }
    }
    throw Exception('Event bir gruba ait değil: $this');
  }
}

/// XP event gruplarını tanımlayan enum
enum XpEventGroup {
  welcomeRewards('Hoş Geldin Ödülleri (Tek Seferlik)', 'welcome_rewards', [
    XpEvent.firstListing,
    XpEvent.firstMessage,
  ]),

  listing('İlan Verme', 'listing', [
    XpEvent.createListing,
    XpEvent.receiveFirstMessage,
  ]),

  messaging('Mesajlaşma', 'messaging', [
    XpEvent.sendFirstMessage,
  ]),

  commenting('Yorumlama ve Yorum Almak', 'commenting', [
    XpEvent.writeComment,
    XpEvent.receiveComment,
  ]),

  dailyTasks('Günlük Görev', 'daily_tasks', [
    XpEvent.dailyTaskListingAndMessage,
    XpEvent.dailyLogin,
  ]);

  const XpEventGroup(this.title, this.titleKey, this.events);

  /// Grup başlığı (Türkçe)
  final String title;

  /// Grup başlığı için çeviri anahtarı
  final String titleKey;

  /// Bu gruba ait eventler
  final List<XpEvent> events;

  /// Yerelleştirilmiş başlık
  String getLocalizedTitle(BuildContext context) {
    return context.tr(titleKey);
  }
}

// /// XP eventlerine erişim için yardımcı sınıf (isteğe bağlı)
// class XpEventHelper {
//   /// Tüm grupları ve içindeki eventleri map olarak döndürür
//   static Map<XpEventGroup, List<XpEvent>> getAllGroupedEvents() {
//     final Map<XpEventGroup, List<XpEvent>> result = {};
    
//     for (final group in XpEventGroup.values) {
//       result[group] = group.events;
//     }
    
//     return result;
//   }
  
//   /// Belirli bir türdeki tüm eventleri döndürür (örn: tüm günlük görevler)
//   static List<XpEvent> getEventsByType({bool? isWelcomeReward, bool? isDailyTask}) {
//     return XpEvent.values.where((event) => 
//       (isWelcomeReward == null || event.isWelcomeReward == isWelcomeReward) &&
//       (isDailyTask == null || event.isDailyTask == isDailyTask)
//     ).toList();
//   }
// }