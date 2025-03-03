// Abonelik servisi
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  // Singleton pattern
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  // Mevcut paketleri getir
  Future<List<Package>> getPackages() async {
    try {
      // Offering'leri al
      final offerings = await Purchases.getOfferings();
      debugPrint(offerings.current?.toString());
      if (offerings.current != null) {
        return offerings.current!.availablePackages;
      }
      return [];
    } catch (e) {
      debugPrint('Paketler alınırken hata: $e');
      return [];
    }
  }

  // Satın alımları geri yükle
  Future<void> restorePurchases() async {
    try {
      await Purchases.restorePurchases();
      debugPrint('Satın alımları geri yüklendi');
    } catch (e) {
      debugPrint('Satın alımları geri yükleme sırasında hata: $e');
    }
  }

  // Satın alma işlemi
  Future<bool> purchasePackage(Package package) async {
    try {
      final purchaserInfo = await Purchases.purchasePackage(package);
      // Satın alma başarılı mı kontrol et
      return purchaserInfo.entitlements.active.isNotEmpty;
    } catch (e) {
      debugPrint('Satın alma sırasında hata: $e');
      return false;
    }
  }

  // Aktif abonelikleri kontrol et
  Future<bool> checkActiveSubscription() async {
    try {
      final purchaserInfo = await Purchases.getCustomerInfo();
      return purchaserInfo.entitlements.active.isNotEmpty;
    } catch (e) {
      debugPrint('Abonelik kontrolünde hata: $e');
      return false;
    }
  }
}
