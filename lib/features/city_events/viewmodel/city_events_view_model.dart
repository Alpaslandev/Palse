import 'package:flutter/material.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/features/city_events/model/event_category_model.dart';
import 'package:palseapp/features/city_events/service/city_event_service.dart';

// Şehir etkinlikleri için view model
class CityEventsViewModel extends ChangeNotifier {
  final CityEventService _service = CityEventService();
  List<Map<String, dynamic>> _cityEvents = [];
  List<EventCategoryModel> _eventCategories = [];
  List<EventCategoryModel> _eventCities = [];
  bool _isLoading = false;
  String? _selectedEventCategory;

  // Getters
  List<Map<String, dynamic>> get cityEvents => _cityEvents;
  List<EventCategoryModel> get eventCategories => _eventCategories;
  List<EventCategoryModel> get eventCities => _eventCities;
  bool get isLoading => _isLoading;
  String? get selectedEventCategory => _selectedEventCategory;

  // Etkinlik kategorilerini yükle
  Future<void> loadEventCategories(Customer user) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('Kategoriler yükleniyor...');
      _eventCategories = await _service.getEventsCategories();
      _eventCities = await _service.getEventCities();
      debugPrint('Yüklenen kategori sayısı: ${_eventCategories.length}');

      if (_eventCategories.isNotEmpty) {
        _selectedEventCategory = _eventCategories.first.name;
        debugPrint('Seçili kategori: $_selectedEventCategory');
      }
    } catch (e) {
      debugPrint('Kategoriler yüklenirken hata: $e');
      _eventCategories = [];
    } finally {
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

  Future<void> loadCityEvents(Customer user, {required String type}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final lat = user.location?.lat ?? 41.0082;
      final lng = user.location?.lon ?? 28.9784;

      _cityEvents = await _service.getNearbyPlaces(
        lat: lat,
        lng: lng,
        type: type,
      );
    } catch (e) {
      debugPrint('Mekanlar yüklenirken hata: $e');
      _cityEvents = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
