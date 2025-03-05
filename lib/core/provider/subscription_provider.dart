// Abonelik durumunu yöneten provider
import 'package:flutter/material.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:palseapp/core/services/subscription_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final _subscriptionService = SubscriptionService();
  final _customerService = CustomerService();
  bool _isPremium = false;
  bool get isPremium => _isPremium;

  SubscriptionProvider() {
    checkPremiumStatus();
    debugPrint('SubscriptionProvider oluşturuldu: $_isPremium');
  }

  // Başlangıçta premium durumunu kontrol et
  Future<void> checkPremiumStatus() async {
    try {
      _isPremium = await _subscriptionService.checkActiveSubscription();
      debugPrint('checkPremiumStatus: $_isPremium');
      notifyListeners();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // Premium durumunu güncelle
  Future<void> updatePremiumStatus(bool status, String uuid) async {
    try {
      await _customerService.updateCustomerSubscription(uuid, status);
      _isPremium = status;
      notifyListeners();
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
