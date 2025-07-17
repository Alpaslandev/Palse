import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/features/city_events/model/event_category_model.dart';

class CityEventService {
  final Dio _dio = Dio();
  final String _apiKey = 'AIzaSyC8PCN-nERTdquXI0Ueyl_DL6gP1QQrg6M';
  final String _etkinlikIoKey = '32b8cd063ea854ffbf510af8e10a2899';

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
      debugPrint(response.data.toString());
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

  Future<List<EventCategoryModel>> getEventsCategories({
    required String city,
  }) async {
    final url = "https://backend.etkinlik.io/api/v2/categories";
    final response = await _dio.get(url, queryParameters: {
      "city": city,
      "key": _etkinlikIoKey,
    });

    if (response.statusCode == 200 && response.data['status'] == "OK") {
      return List<EventCategoryModel>.from(
        response.data['data'].map((e) => EventCategoryModel.fromJson(e)),
      );
    } else {
      throw Exception("Events API hatası: ${response.data['status']}");
    }
  }
}
