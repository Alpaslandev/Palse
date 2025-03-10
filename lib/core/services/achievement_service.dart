import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/features/achievement/achievements.dart';
import 'package:palseapp/features/achievement/premium_rewards.dart';

class AchievementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Customer modeline XP ekler
  Future<Customer> earnXp(Customer user, XpEvent event) async {
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
      await updateUserAchievement(user.userID!, updatedUser);
      debugPrint('${event.name} görevi tamamlandı, +${event.xpAmount} XP kazanıldı. Toplam XP: ${updatedUser.totalXp}');
    } catch (e) {
      debugPrint('XP eklenirken hata: $e');
    }

    return updatedUser;
  }

  // Özel miktar XP ekler
  Future<Customer> earnCustomXp(Customer user, int amount) async {
    if (user.userID == null || amount <= 0) {
      return user;
    }

    final updatedUser = user.copyWith(
      totalXp: user.totalXp + amount,
    );

    try {
      await updateUserAchievement(user.userID!, updatedUser);
      debugPrint('Özel XP eklendi: +$amount XP. Toplam XP: ${updatedUser.totalXp}');
    } catch (e) {
      debugPrint('Özel XP eklenirken hata: $e');
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
      await updateUserAchievement(user.userID!, updatedUser);
      debugPrint('Günlük görevler sıfırlandı');
    } catch (e) {
      debugPrint('Günlük görevler sıfırlanırken hata: $e');
    }

    return updatedUser;
  }

  // Kullanıcı başarılarını Firestore'a kaydeder
  Future<void> updateUserAchievement(String uuid, Customer customer) async {
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
}
