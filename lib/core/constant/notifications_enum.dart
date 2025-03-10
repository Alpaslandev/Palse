import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';

enum NotificationsEnum {
  likeAdvert(
      title: 'Harika!',
      nonPremium: '💖 İlanınız beğenildi! Beğenenleri görmek için tıklayın.',
      premium: '💖 İlanınız beğenildi! Kimin beğendiğini görmek için ✨ premium üye olun.'),
  comment(title: 'Dikkatler Üzerinde!', nonPremium: 'Profiline yorum yaptı! Hemen görüntüle'),
  newAdvertInCity(title: 'Yalnız Değilsin!', nonPremium: '🏙️ Şehrinizde harika bir ilan eklendi, hemen göz atın! 👀'),
  newAdvertInInterestArea(title: 'Aradığını Buldun!', nonPremium: '✨ İlgi alanınıza hitap eden yepyeni bir ilan var! Hadi, kaçırmadan inceleyin! 🔍'),
  message(title: '', nonPremium: 'Birisi mesaj gönderdi! Hemen görüntüle'),
  dailyTask(title: '', nonPremium: 'Bugün Palse’de XP kazanma zamanı! Bir ilan oluştur ve bir mesaj gönder, +100 XP senin olsun! 🎯'),
  dailyTaskCompleted(title: '', nonPremium: 'Günlük görevlerin tamamlandı! Hemen görüntüle'),

  welcomeNotification(title: 'Çaylak!', nonPremium: 'Hoş geldin! İlk ilanını oluştur ve ilk mesajını gönder, toplam 1000 XP kazan! 🎉'),
  messageFromOldFriend(title: '', nonPremium: 'Uzun zamandır görüşmedik! Giriş yap ve bir mesaj gönder, hemen +35 XP kazan!');

  final String nonPremium;
  final String? premium;
  final String title;

  const NotificationsEnum({required this.nonPremium, this.premium, required this.title});

  // Çevirilmiş metni döndüren getter
  String getText(BuildContext context) {
    return context.tr(nonPremium);
  }
}
