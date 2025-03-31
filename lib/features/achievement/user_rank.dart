import 'package:flutter/material.dart';

/// XP seviyelerine göre kullanıcı unvanlarını tanımlayan enum
enum UserRank {
  beginner(
    'rank_beginner',
    0,
    199,
    '🌟',
    Colors.blue,
  ),

  explorer(
    'rank_explorer',
    200,
    999,
    '🔍',
    Colors.green,
  ),

  connector(
    'rank_connector',
    1000,
    1999,
    '🧩',
    Colors.amber,
  ),

  leader(
    'rank_leader',
    2000,
    5999,
    '🎯',
    Colors.orange,
  ),

  master(
    'rank_master',
    6000,
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

  /// Rütbe ilerleme yüzdesini hesaplar
  static double calculateProgressPercentage(UserRank rank, int currentXp) {
    if (rank == UserRank.master) {
      return 1.0; // En üst seviye için %100
    }

    final totalRangeXp = rank.maxXp - rank.minXp;
    final userProgressInRange = currentXp - rank.minXp;

    return (userProgressInRange / totalRangeXp).clamp(0.0, 1.0);
  }

  /// Bir sonraki unvana geçmek için gereken XP miktarını hesaplayan metod
  static int calculateXpToNextRank(UserRank rank, int currentXp) {
    if (rank == UserRank.master) {
      return 0; // En üst seviyede olduğu için 0
    }

    return (rank.maxXp - currentXp + 1).toInt();
  }
}
