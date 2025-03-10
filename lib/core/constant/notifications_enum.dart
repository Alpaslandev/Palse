import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';

enum NotificationsEnum {
  likeAdvert(
      title: 'Harika!',
      nonPremium: '💖 İlanınız beğenildi! Beğenenleri görmek için tıklayın.',
      premium: '💖 İlanınız beğenildi! Kimin beğendiğini görmek için ✨ premium üye olun.',
      isSaveable: true),
  comment(title: 'Dikkatler Üzerinde!', nonPremium: 'Profiline yorum yaptı! Hemen görüntüle', isSaveable: true),
  newAdvertInCity(title: 'Yalnız Değilsin!', nonPremium: '🏙️ Şehrinizde harika bir ilan eklendi, hemen göz atın! 👀', isSaveable: true),
  newAdvertInInterestArea(
      title: 'Aradığını Buldun!', nonPremium: '✨ İlgi alanınıza hitap eden yepyeni bir ilan var! Hadi, kaçırmadan inceleyin! 🔍', isSaveable: false),
  dailyTask(
      title: '', nonPremium: 'Bugün Palse’de XP kazanma zamanı! Bir ilan oluştur ve bir mesaj gönder, +100 XP senin olsun! 🎯', isSaveable: true),
  dailyTaskCompleted(title: '', nonPremium: 'Günlük görevlerin tamamlandı! Hemen görüntüle', isSaveable: true),

  welcomeNotification(
      title: 'Çaylak!', nonPremium: 'Hoş geldin! İlk ilanını oluştur ve ilk mesajını gönder, toplam 1000 XP kazan! 🎉', isSaveable: true),
  messageFromOldFriend(title: '', nonPremium: 'Uzun zamandır görüşmedik! Giriş yap ve bir mesaj gönder, hemen +35 XP kazan!', isSaveable: false);

  final String nonPremium;
  final String? premium;
  final String title;
  final bool isSaveable;

  const NotificationsEnum({required this.nonPremium, this.premium, required this.title, this.isSaveable = true});

  // Çevirilmiş metni döndüren getter
  String getText(BuildContext context) {
    return context.tr(nonPremium);
  }
}
