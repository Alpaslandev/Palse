import 'package:flutter/material.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/features/city_events/service/city_event_service.dart';

// Şehrimdeki etkinlikler için ViewModel
class CityEventsViewModel extends ChangeNotifier {
  final CityEventService _cityEventService = CityEventService();

  List<Map<String, dynamic>> _cityEvents = [];
  bool _isLoading = false;

  // Getter'lar
  List<Map<String, dynamic>> get cityEvents => _cityEvents;
  bool get isLoading => _isLoading;

  // Şehirdeki etkinlikleri yükle
  Future<void> loadCityEvents(
    Customer user, {
    required String type,
  }) async {
    if (_isLoading) return;

    _setLoading(true);

    try {
      _cityEvents = await _cityEventService.getNearbyPlaces(
          lat: user.location!.lat, lng: user.location!.lon, type: type);

      debugPrint('Şehirdeki etkinlik sayısı: ${_cityEvents.length}');
    } catch (e) {
      debugPrint('Şehirdeki etkinlikler yüklenirken hata: $e');
    } finally {
      _setLoading(false);
    }
  }

  String generatePhotoUrl(String photoReference) {
    return _cityEventService.generatePhotoUrl(photoReference);
  }

  // Yükleme durumunu güncelle
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Yenile
  Future<void> refresh(Customer user, {required String type}) async {
    _cityEvents.clear();
    await loadCityEvents(user, type: type);
  }
}
