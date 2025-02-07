import 'package:flutter/material.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/services/firestore/advert_service.dart';

class HomeViewModel extends ChangeNotifier {
  final AdvertService advertService = AdvertService();
  List<Advert> _adverts = [];
  bool _isLoading = false;

  List<Advert> get adverts => _adverts;
  bool get isLoading => _isLoading;

  Future<List<Advert>?> getAdverts() async {
    _setLoading(true);
    try {
      _adverts = await advertService.fetchAdvertsFromFirestore() ?? [];
      notifyListeners();
      return _adverts;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
