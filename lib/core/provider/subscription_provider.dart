// Abonelik durumunu yöneten provider
import 'package:flutter/material.dart';
import 'package:palseapp/core/services/subscription_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final _subscriptionService = SubscriptionService();
  bool _isPremium = false;
  bool get isPremium => _isPremium;

  // Başlangıçta premium durumunu kontrol et
  Future<void> checkPremiumStatus() async {
    _isPremium = await _subscriptionService.checkActiveSubscription();
    notifyListeners();
  }

  // Premium durumunu güncelle
  Future<void> updatePremiumStatus(bool status) async {
    _isPremium = status;
    notifyListeners();
  }
}
