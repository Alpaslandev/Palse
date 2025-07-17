import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/features/city_events/model/event_category_model.dart';

class CityEventService {
  final Dio _dio = Dio();
  final String _apiKey = 'AIzaSyC8PCN-nERTdquXI0Ueyl_DL6gP1QQrg6M';
  final String _etkinlikIoKey = '32b8cd063ea854ffbf510af8e10a2899';

  CityEventService() {
    _dio.options.headers['Content-Type'] = 'application/json';
  }

  // String benzerlik oranını hesaplayan yardımcı metod
  double _calculateSimilarity(String s1, String s2) {
    s1 = s1.toLowerCase().trim();
    s2 = s2.toLowerCase().trim();

    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    int matches = 0;
    int maxLength = s1.length > s2.length ? s1.length : s2.length;

    for (int i = 0; i < s1.length && i < s2.length; i++) {
      if (s1[i] == s2[i]) matches++;
    }

    return matches / maxLength;
  }

  // Kullanıcının şehrini API şehirleriyle eşleştiren metod
  Future<String?> findMatchingCityId(String userCity) async {
    try {
      final cities = await getEventCities();
      String? matchedCityId;
      double highestSimilarity = 0.0;

      for (var city in cities) {
        double similarity = _calculateSimilarity(userCity, city.name);

        if (similarity > 0.9 && similarity > highestSimilarity) {
          highestSimilarity = similarity;
          matchedCityId = city.id.toString();
          debugPrint(
              'Eşleşen şehir bulundu: ${city.name} (ID: ${city.id}) - Benzerlik: ${(similarity * 100).toStringAsFixed(2)}%');
        }
      }

      return matchedCityId;
    } catch (e) {
      debugPrint('Şehir eşleştirme hatası: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getNearbyPlaces({
    required double lat,
    required double lng,
    required String type,
    int radius = 2000,
  }) async {
    final apiKey = _apiKey;
    final url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json";

    final response = await _dio.get(url, queryParameters: {
      "location": "$lat,$lng",
      "radius": radius,
      "type": type,
      "key": apiKey,
    });

    if (response.statusCode == 200 && response.data['status'] == "OK") {
      //  debugPrint(response.data.toString());
      return List<Map<String, dynamic>>.from(response.data['results']);
    } else {
      throw Exception("Places API hatası: ${response.data['status']}");
    }
  }

  String generatePhotoUrl(String photoReference) {
    final apiKey = _apiKey;
    return "https://maps.googleapis.com/maps/api/place/photo"
        "?maxwidth=400"
        "&photo_reference=$photoReference"
        "&key=$apiKey";
  }

  Future<List<EventCategoryModel>> getEventsCategories() async {
    final url = "https://backend.etkinlik.io/api/v2/categories";

    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'X-Etkinlik-Token': _etkinlikIoKey,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('Etkinlik.io API yanıtı: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data != null) {
          return List<EventCategoryModel>.from(
            (response.data as List).map((e) => EventCategoryModel.fromJson(e)),
          );
        }
      }

      throw Exception("Kategori verisi alınamadı: ${response.statusCode}");
    } catch (e) {
      debugPrint('Etkinlik.io API hatası: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getEvents({
    required String categoryId,
    required String cityId,
  }) async {
    final url = "https://backend.etkinlik.io/api/v2/events";

    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'X-Etkinlik-Token': _etkinlikIoKey,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
        queryParameters: {'category_ids': categoryId, 'city_ids': cityId},
      );
      debugPrint('Etkinlik.io API yanıtı: ${response.data}');
      if (response.statusCode == 200) {
        if (response.data != null) {
          return List<Map<String, dynamic>>.from(
            (response.data as List).map((e) => e),
          );
        }
      }

      throw Exception("Kategori verisi alınamadı: ${response.statusCode}");
    } catch (e) {
      debugPrint('Etkinlik.io API hatası: $e');
      rethrow;
    }
  }

  Future<List<EventCategoryModel>> getEventCities() async {
    final url = "https://backend.etkinlik.io/api/v2/cities";

    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'X-Etkinlik-Token': _etkinlikIoKey,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      if (response.statusCode == 200) {
        if (response.data != null) {
          return List<EventCategoryModel>.from(
            (response.data as List).map((e) => EventCategoryModel.fromJson(e)),
          );
        }
      }
      throw Exception("Şehir verisi alınamadı: ${response.statusCode}");
    } catch (e) {
      debugPrint('Etkinlik.io API hatası: $e');
      rethrow;
    }
  }
}
