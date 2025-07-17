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
  int? _matchedCityId;

  // Getters
  List<Map<String, dynamic>> get cityEvents => _cityVenues;
  List<EventCategoryModel> get eventCategories => _eventCategories;
  List<EventCategoryModel> get eventCities => _eventCities;
  List<EventModel> get events => _events;
  bool get isLoading => _isLoading;
  String? get selectedEventCategory => _selectedEventCategory;
  int? get matchedCityId => _matchedCityId;

  // Etkinlik kategorilerini ve şehir etkinliklerini yükle
  Future<void> loadEventCategories(Customer user) async {
    try {
      _isLoading = true;
      notifyListeners();
      debugPrint("Etkinlik kategorileri ve etkinlikler yükleniyor...");

      // Önce kategorileri yükle
      _eventCategories = await _service.getEventsCategories();

      // Hepsi kategorisini başa ekle
      _eventCategories.insert(
          0, EventCategoryModel(id: -1, name: "Hepsi", slug: "hepsi"));

      debugPrint("Kategoriler yüklendi: ${_eventCategories.length} adet");

      // Kullanıcının şehrini eşleştir
      if (user.location?.city != null) {
        debugPrint("Kullanıcı şehri: ${user.location!.city}");
        _matchedCityId = await _service.findMatchingCityId(user.location!.city);

        if (_matchedCityId != null) {
          debugPrint('Kullanıcının şehri eşleşti. Şehir ID: $_matchedCityId');

          // İlk açılışta kategori seçili olmasın (Hepsi)
          _selectedEventCategory = "Hepsi";
          debugPrint("Başlangıç kategorisi: Hepsi");

          // Tüm etkinlikleri çek
          await loadEventsForCategory(null, _matchedCityId!);
        } else {
          debugPrint("Eşleşen şehir bulunamadı.");
        }
      } else {
        debugPrint("Kullanıcı lokasyon veya şehir bilgisi bulunamadı.");
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Etkinlik kategorileri yüklenirken hata: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Seçili kategoriyi güncelle ve etkinlikleri yeniden yükle
  Future<void> updateSelectedEventCategory(String categoryName) async {
    try {
      _selectedEventCategory = categoryName;
      notifyListeners();

      if (_matchedCityId != null) {
        if (categoryName == "Hepsi") {
          // Hepsi seçiliyse categoryId null olarak gönder
          await loadEventsForCategory(null, _matchedCityId!);
        } else {
          // Seçilen kategorinin ID'sini bul
          final selectedCategory = _eventCategories.firstWhere(
            (c) => c.name == categoryName,
            orElse: () => _eventCategories.first,
          );

          debugPrint(
              'Seçilen kategori: ${selectedCategory.name} (ID: ${selectedCategory.id})');

          await loadEventsForCategory(selectedCategory.id, _matchedCityId!);
        }
      } else {
        debugPrint('Şehir ID bulunamadı, etkinlikler yüklenemedi.');
      }
    } catch (e) {
      debugPrint('Kategori güncellenirken hata: $e');
    }
  }

  // Belirli bir kategori için etkinlikleri yükle
  Future<void> loadEventsForCategory(int? categoryId, int cityId) async {
    try {
      debugPrint(
          'Etkinlikler yükleniyor... Kategori ID: ${categoryId ?? "Hepsi"}, Şehir ID: $cityId');
      _isLoading = true;
      notifyListeners();

      _events = await _service.getEvents(
        categoryId: categoryId,
        cityId: cityId,
      );

      debugPrint(
          'Etkinlikler yüklendi. Kategori: ${categoryId ?? "Hepsi"}, Toplam: ${_events.length}');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Etkinlikler yüklenirken hata: $e');
      _events = []; // Hata durumunda listeyi boşalt
      _isLoading = false;
      notifyListeners();
    }
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
