import 'dart:async';
import 'package:palseapp/features/achievement/achievements.dart';
import 'package:palseapp/features/achievement/premium_rewards.dart';

/// Achievement ve XP sistemini yöneten sınıf
class AchievementManager {
  /// Singleton örneği
  static final AchievementManager _instance = AchievementManager._internal();

  /// Factory constructor
  factory AchievementManager() => _instance;

  /// Gerçek constructor
  AchievementManager._internal();

  /// Kullanıcının başarıları
  UserAchievements _userAchievements = UserAchievements();

  /// Kullanıcının başarılarını döndürür
  UserAchievements get userAchievements => _userAchievements;

  /// Dinleyiciler
  final List<Function(UserAchievements)> _listeners = [];

  /// Kullanıcı başarılarını başlangıç değerleriyle ayarlar
  void initialize(UserAchievements achievements) {
    _userAchievements = achievements;
    _notifyListeners();
  }

  /// Kullanıcının XP kazanmasını sağlar
  void earnXp(XpEvent event) {
    final previousXp = _userAchievements.totalXp;
    final newAchievements = _userAchievements.earnXp(event);

    if (newAchievements.totalXp != previousXp) {
      _userAchievements = newAchievements;
      _notifyListeners();
    }
  }

  /// Özel bir XP miktarını ekler
  void earnCustomXp(int amount) {
    if (amount <= 0) return;

    _userAchievements = _userAchievements.earnCustomXp(amount);
    _notifyListeners();
  }

  /// Günlük görevleri sıfırlar
  void resetDailyTasks() {
    _userAchievements = _userAchievements.resetDailyTasks();
    _notifyListeners();
  }

  /// Premium ödüller için XP eşiklerini döndürür
  List<int> getPremiumThresholds(int maxXp) {
    return PremiumRewards.getPremiumThresholds(maxXp);
  }

  /// Kullanıcının eriştiği premium ödül sayısını döndürür
  int getEarnedPremiumRewardCount() {
    return PremiumRewards.earnedPremiumRewards(_userAchievements.totalXp);
  }

  /// Bir sonraki premium ödüle kalan XP miktarını döndürür
  int getXpToNextPremium() {
    return PremiumRewards.xpToNextPremium(_userAchievements.totalXp);
  }

  /// Dinleyici ekler
  void addListener(Function(UserAchievements) listener) {
    _listeners.add(listener);
  }

  /// Dinleyiciyi kaldırır
  void removeListener(Function(UserAchievements) listener) {
    _listeners.remove(listener);
  }

  /// Tüm dinleyicileri bilgilendirir
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener(_userAchievements);
    }
  }
}

/// XP Arayüzü
/// Bu mixin'i kullanarak bir sınıfa XP sistemi ekleyebilirsiniz
mixin XpInterface {
  /// XP kazanma fonksiyonu - bu methodu çağırarak XP kazanabilirsiniz
  void earnXp(XpEvent event) {
    AchievementManager().earnXp(event);
  }

  /// Günlük görevlerin bugün tamamlanıp tamamlanmadığını kontrol eder
  bool isDailyTaskCompletedToday() {
    return AchievementManager().userAchievements.isDailyTaskCompletedToday();
  }

  /// Belirli bir görevin tamamlanıp tamamlanmadığını kontrol eder
  bool isTaskCompleted(XpEvent event) {
    return AchievementManager().userAchievements.isTaskCompleted(event);
  }

  /// Kullanıcının toplam XP miktarını döndürür
  int get totalXp => AchievementManager().userAchievements.totalXp;

  /// Kullanıcının unvanını döndürür
  UserRank get userRank => AchievementManager().userAchievements.rank;
}

/// Günlük görevleri yöneten sınıf
/// Bu sınıf günlük görevlerin zamanında sıfırlanmasını sağlar
class DailyTaskScheduler {
  /// Singleton örneği
  static final DailyTaskScheduler _instance = DailyTaskScheduler._internal();

  /// Factory constructor
  factory DailyTaskScheduler() => _instance;

  /// Gerçek constructor
  DailyTaskScheduler._internal();

  /// Timer nesnesi
  Timer? _timer;

  /// Günlük görev zamanlayıcısını başlatır
  void startScheduler() {
    _checkAndResetDailyTasks();

    // Her dakika kontrol et
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkAndResetDailyTasks();
    });
  }

  /// Zamanlayıcıyı durdurur
  void stopScheduler() {
    _timer?.cancel();
    _timer = null;
  }

  /// Günlük görevleri gerekirse sıfırlar
  void _checkAndResetDailyTasks() {
    final now = DateTime.now();

    // Eğer saat gece 12'yi geçtiyse (00:00 - 00:05 arası) ve
    // görevler bugün için henüz sıfırlanmadıysa, görevleri sıfırla
    if (now.hour == 0 && now.minute < 5) {
      // UserAchievements'te lastDailyTaskDate varsa ve bugünden farklıysa
      // ya da lastDailyTaskDate null ise görevleri sıfırla
      final lastResetDate = AchievementManager().userAchievements.lastDailyTaskDate;

      if (lastResetDate == null || lastResetDate.day != now.day || lastResetDate.month != now.month || lastResetDate.year != now.year) {
        AchievementManager().resetDailyTasks();
      }
    }
  }
}
