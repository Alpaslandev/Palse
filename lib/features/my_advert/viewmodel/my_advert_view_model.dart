import 'package:flutter/material.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/services/firestore/advert_service.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';

class MyAdvertViewModel extends ChangeNotifier {
  final AdvertService _advertService = AdvertService();
  final CustomerService _customerService = CustomerService();

  final AuthProvider _authProvider;
  final List<Advert?> _myAdverts = [];
  final List<Advert?> _favorites = [];
  final Map<String, Customer> _customers = {}; // userId -> Customer eşleşmesi
  bool _isLoading = false;
  final List<Advert?> _recentlyViewed = [];

  List<Advert?> get myAdverts => _myAdverts;
  List<Advert?> get favorites => _favorites;
  Map<String, Customer> get customers => _customers;
  bool get isLoading => _isLoading;
  List<Advert?> get recentlyViewed => _recentlyViewed;

  MyAdvertViewModel({required AuthProvider authProvider}) : _authProvider = authProvider {
    fetchAdvertsWithCustomers();
  }

  Future<void> fetchAdvertsWithCustomers() async {
    _setLoading(true);
    try {
      // İlanları paralel olarak çek
      await Future.wait([
        fetchMyAdverts(),
        fetchFavorites(),
      ]);

      // Tüm ilanlardan benzersiz userId'leri topla
      final Set<String> userIds = {};

      // Favori ilanların sahiplerini ekle
      for (var advert in _favorites) {
        if (advert != null) {
          userIds.add(advert.creatorUserID);
        }
      }

      // Her userId için Customer bilgisini çek
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
      debugPrint('Error fetching adverts with customers: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMyAdverts() async {
    if (_authProvider.user?.events != null) {
      final List<Future<Advert?>> futures = _authProvider.user!.events!.map((advertId) => _advertService.fetchAdvertById(advertId)).toList();

      final List<Advert?> adverts = await Future.wait(futures);
      _myAdverts.addAll(adverts.where((advert) => advert != null));
    }
  }

  Future<void> fetchFavorites() async {
    if (_authProvider.user?.favoriteAdverts != null) {
      final List<Future<Advert?>> futures = _authProvider.user!.favoriteAdverts!.map((advertId) => _advertService.fetchAdvertById(advertId)).toList();

      final List<Advert?> adverts = await Future.wait(futures);

      _favorites.addAll(adverts.where((advert) => advert != null));
    }
  }

  Customer? getCustomerForAdvert(Advert? advert) {
    if (advert == null) return null;
    return _customers[advert.creatorUserID];
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _myAdverts.clear();
    _favorites.clear();
    _customers.clear();
    super.dispose();
  }
}
