import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:palseapp/core/models/location_model.dart';

// Basit ve anlaşılır konum servisi
class LocationService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://nominatim.openstreetmap.org',
    headers: {'User-Agent': 'YourAppName/1.0'}, // Özel kullanıcı ajanı zorunlu
  ));

  // Mevcut konumu al ve LocationModel'e dönüştür
  Future<LocationModel?> getCurrentLocationModel() async {
    try {
      // Konum servisini kontrol et
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // İzinleri kontrol et
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      // Konumu al
      final position = await Geolocator.getCurrentPosition();

      // Adres bilgilerini al
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      debugPrint('Placemarks: ${placemarks.first}');

      if (placemarks.isNotEmpty) {
        debugPrint('Placemarks: ${placemarks.first}');
        // LocationModel oluştur
        return LocationModel.fromPlacemark(placemarks.first, lat: position.latitude, lon: position.longitude);
      } else {
        // Sadece koordinatları içeren model
        return LocationModel(
          city: '',
          district: '',
          country: '',
          lat: position.latitude,
          lon: position.longitude,
        );
      }
    } catch (e) {
      debugPrint('Konum alınamadı: $e');
      return null;
    }
  }

  // Koordinatlardan adres bilgilerini al
  Future<Placemark?> getAddressFromCoordinates(GeoPoint geoPoint) async {
    try {
      final placemarks = await placemarkFromCoordinates(geoPoint.latitude, geoPoint.longitude);
      debugPrint('Adres bilgileri: ${placemarks.first}');
      if (placemarks.isEmpty) return null;
      return placemarks.first;
    } catch (e) {
      debugPrint('Adres alınamadı: $e');
      return null;
    }
  }

  // Konum arama - OpenStreetMap API
  Future<List<LocationModel>> searchLocation(String query) async {
    debugPrint('Konum arama başladı: $query');
    try {
      final response = await _dio.get('/search', queryParameters: {
        'q': query,
        'format': 'json',
        'addressdetails': 1,
        'limit': 5,
      });

      debugPrint('API yanıtı alındı: ${response.statusCode}');

      if (response.data is List && response.data.isNotEmpty) {
        debugPrint('Bulunan sonuç sayısı: ${response.data.length}');

        final List<LocationModel> locations = [];

        for (var i = 0; i < response.data.length; i++) {
          debugPrint('Sonuç $i işleniyor...');
          final item = response.data[i];
          debugPrint('JSON veri: ${item.toString().substring(0, item.toString().length > 100 ? 100 : item.toString().length)}...');

          final model = LocationModel.fromOpenStreetMap(item);
          locations.add(model);
          debugPrint('Model oluşturuldu: ${model.toString()}');
        }

        debugPrint('Toplam ${locations.length} konum modeli oluşturuldu');
        return locations;
      } else {
        debugPrint('API yanıtında veri bulunamadı veya uygun formatta değil');
        return [];
      }
    } catch (e) {
      debugPrint('Konum arama hatası: ${e.toString()}');
      throw Exception('Konum bulunamadı: ${e.toString()}');
    }
  }
}
