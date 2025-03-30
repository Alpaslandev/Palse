/// Premium ödüllerin yönetimini sağlayan sınıf
class PremiumRewards {
  /// XP eşik değerleri - bu değerlere ulaşıldığında premium ödüller kazanılır
  static const List<int> xpThresholds = [
    6000, // İlk premium ödül
    12000, // İkinci premium ödül
    24000, // Üçüncü premium ödül
    48000, // Dördüncü premium ödül
  ];

  /// Belirli bir XP değerine göre kazanılan premium ödül sayısını hesaplar
  static int earnedPremiumRewards(int xp) {
    int count = 0;
    for (var threshold in xpThresholds) {
      if (xp >= threshold) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  /// Bir sonraki premium ödül için gereken XP değerini döndürür
  static int xpToNextPremium(int currentXp) {
    for (var threshold in xpThresholds) {
      if (currentXp < threshold) {
        return threshold - currentXp; // Kullanıcının mevcut XP'sini çıkararak KALAN XP'yi döndür
      }
    }
    // Tüm ödülleri kazanmışsa 0 döndür (gereken XP kalmadı)
    return 0;
  }
}
