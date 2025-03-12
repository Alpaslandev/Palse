import 'package:flutter/material.dart';

/// XP seviyelerine göre kullanıcı unvanlarını tanımlayan enum
enum UserRank {
  /// 0-99 XP: Keşfe Başlayan
  beginner(
    'rank_beginner',
    0,
    99,
    '🌟',
    Colors.blue,
  ),

  /// 100-499 XP: Sosyal Keşifçi
  explorer(
    'rank_explorer',
    100,
    499,
    '🔍',
    Colors.green,
  ),

  /// 500-999 XP: Bağlantı Ustası
  connector(
    'rank_connector',
    500,
    999,
    '🧩',
    Colors.amber,
  ),

  /// 1000-2999 XP: Etkinlik Lideri
  leader(
    'rank_leader',
    1000,
    2999,
    '🎯',
    Colors.orange,
  ),

  /// 3000+ XP: Sosyal Usta
  master(
    'rank_master',
    3000,
    double.infinity,
    '👑',
    Colors.purple,
  );

  /// Constructor
  const UserRank(
    this.titleKey,
    this.minXp,
    this.maxXp,
    this.icon,
    this.color,
  );

  /// Unvan başlığının anahtar değeri
  final String titleKey;

  /// Minimum XP değeri
  final int minXp;

  /// Maksimum XP değeri
  final num maxXp;

  /// Unvan ikonu
  final String icon;

  /// Unvan rengi
  final Color color;

  /// XP değerine göre uygun unvanı döndüren yardımcı metod
  static UserRank fromXp(int xp) {
    return UserRank.values.firstWhere(
      (rank) => xp >= rank.minXp && xp <= rank.maxXp,
      orElse: () => UserRank.master,
    );
  }
}
