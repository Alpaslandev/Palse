import 'package:flutter/material.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/features/city_events/model/event_category_model.dart';
import 'package:palseapp/features/city_events/model/event_model.dart';
import 'package:palseapp/features/city_events/service/city_event_service.dart';

// Şehir etkinlikleri için view model
class CityEventsViewModel extends ChangeNotifier {
  final CityEventService _service = CityEventService();
  List<Map<String, dynamic>> _cityVenues = [];
  List<EventCategoryModel> _eventCategories = [];
  List<EventCategoryModel> _eventCities = [];
  List<EventModel> _events = [];
  bool _isLoading = false;
  String? _selectedEventCategory;
  String? _matchedCityId;

  // Getters
  List<Map<String, dynamic>> get cityEvents => _cityVenues;
  List<EventCategoryModel> get eventCategories => _eventCategories;
  List<EventCategoryModel> get eventCities => _eventCities;
  List<EventModel> get events => _events;
  bool get isLoading => _isLoading;
  String? get selectedEventCategory => _selectedEventCategory;
  String? get matchedCityId => _matchedCityId;

  // Etkinlik kategorilerini ve şehir etkinliklerini yükle
  Future<void> loadEventCategories(Customer user) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Önce kategorileri yükle
      _eventCategories = await _service.getEventsCategories();

      // Kullanıcının şehrini eşleştir
      if (user.location?.city != null) {
        _matchedCityId = await _service.findMatchingCityId(user.location!.city);

        if (_matchedCityId != null) {
          debugPrint('Kullanıcının şehri eşleşti. Şehir ID: $_matchedCityId');

          // Rastgele bir kategori seç
          if (_eventCategories.isNotEmpty) {
            final randomCategory = _eventCategories[0]; // İlk kategoriyi alalım
            _selectedEventCategory = randomCategory.name;

            // Etkinlikleri çek
            final events = await _service.getEvents(
              categoryId: randomCategory.id.toString(),
              cityId: _matchedCityId!,
            );

            debugPrint('Etkinlikler yüklendi. Toplam: ${events.length}');
            _events = events;
            notifyListeners();
          }
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Etkinlik kategorileri yüklenirken hata: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Seçili kategoriyi güncelle
  void updateSelectedEventCategory(String category) {
    _selectedEventCategory = category;
    notifyListeners();
  }

  // Mevcut metodlar...
  String generatePhotoUrl(String photoReference) {
    return _service.generatePhotoUrl(photoReference);
  }

  Future<void> loadCityVenues(Customer user, {required String type}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final lat = user.location?.lat ?? 41.0082;
      final lng = user.location?.lon ?? 28.9784;

      _cityVenues = await _service.getNearbyPlaces(
        lat: lat,
        lng: lng,
        type: type,
      );
    } catch (e) {
      debugPrint('Mekanlar yüklenirken hata: $e');
      _cityVenues = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
