/// Premium ödül kazanma eşiklerini yöneten sınıf
class PremiumRewards {
  /// İlk premium ödül eşiği
  static const int firstRewardThreshold = 3000;

  /// Premium ödül kazanma eşiklerini hesaplar
  static List<int> getPremiumThresholds(int maxXp) {
    final thresholds = <int>[];
    int threshold = firstRewardThreshold;

    while (threshold <= maxXp) {
      thresholds.add(threshold);
      threshold *= 2; // Her seferinde ikiye katla (3000, 6000, 12000, ...)
    }

    return thresholds;
  }

  /// Kullanıcının bir sonraki premium ödül eşiğini döndürür
  static int getNextPremiumThreshold(int currentXp) {
    if (currentXp < firstRewardThreshold) {
      return firstRewardThreshold;
    }

    int threshold = firstRewardThreshold;
    while (threshold <= currentXp) {
      threshold *= 2;
    }

    return threshold;
  }

  /// Kullanıcının bir sonraki premium ödüle ne kadar XP kaldığını hesaplar
  static int xpToNextPremium(int currentXp) {
    final nextThreshold = getNextPremiumThreshold(currentXp);
    return nextThreshold - currentXp;
  }

  /// Kullanıcının toplam kaç premium ödül kazandığını hesaplar
  static int earnedPremiumRewards(int currentXp) {
    if (currentXp < firstRewardThreshold) {
      return 0;
    }

    final thresholds = getPremiumThresholds(currentXp);
    return thresholds.length;
  }
}
