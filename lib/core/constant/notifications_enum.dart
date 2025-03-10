import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';

enum NotificationsEnum {
  likeAdvert(title: 'İlan Beğenildi!', description: 'Bir ilanı beğendiniz, hemen görüntüle'),
  comment(title: 'Yorum Eklendi!', description: 'Bir yorum eklendiniz, hemen görüntüle'),
  dailyTask(title: 'Bugün Palse\'de XP kazanma zamanı!', description: 'Bir ilan oluştur ve bir mesaj gönder, +100 XP senin olsun! 🎯'),

  dailyTaskCompleted(title: 'Günlük Görevler Tamamlandı!', description: 'Günlük görevlerin tamamlandı! Hemen görüntüle'),

  messageFromOldFriend(title: 'Eski Arkadaştan Mesaj!', description: 'Uzun zamandır görüşmedik! Giriş yap ve bir mesaj gönder, hemen +35 XP kazan!'),

  // XP sistemi bildirimleri
  taskCompleted(title: 'Görev Tamamlandı!', description: '🎯 Bir görevi tamamladınız ve XP kazandınız!'),

  xpEarned(title: 'XP Kazandınız!', description: '✨ Tebrikler! XP puanı kazandınız.'),

  rankUp(title: 'Seviye Atladınız!', description: '🏆 Tebrikler! Yeni bir seviyeye ulaştınız.'),

  premiumReward(title: 'Premium Ödül!', description: '🎁 Yeni bir premium ödül kazandınız!'),

  xpReset(title: 'XP Sıfırlandı', description: '🔄 XP puanlarınız sıfırlandı.');

  final String description;
  final String title;

  const NotificationsEnum({required this.description, required this.title});

  // Çevirilmiş metni döndüren getter
  String getText(BuildContext context) {
    return context.tr(description);
  }
}
