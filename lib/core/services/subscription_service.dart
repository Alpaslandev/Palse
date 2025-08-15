// Abonelik servisi
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  // Singleton pattern
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

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
