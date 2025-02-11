import 'package:flutter/material.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/firestore/advert_service.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';

class HomeViewModel extends ChangeNotifier {
  final AdvertService _advertService = AdvertService();
  final CustomerService _customerService = CustomerService();

  List<Advert> _adverts = [];
  final Map<String, Customer> _customers = {}; // userId -> Customer
  bool _isLoading = false;

  List<Advert> get adverts => _adverts;
  Map<String, Customer> get customers => _customers;
  bool get isLoading => _isLoading;

  Future<void> getAdverts() async {
    _setLoading(true);
    try {
      _adverts = await _advertService.fetchAdvertsFromFirestore() ?? [];

      // Kullanıcı bilgilerini çek
      final userIds = _adverts.map((advert) => advert.creatorUserID).toSet();
      await Future.wait(
        userIds.map((userId) async {
          final customer = await _customerService.fetchUserFromFirestore(userId);
          if (customer != null) {
            _customers[userId] = customer;
          }
        }),
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Hata: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Helpers
  Customer? getCustomerForAdvert(Advert advert) {
    return _customers[advert.creatorUserID];
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _adverts.clear();
    _customers.clear();
    super.dispose();
  }
}
