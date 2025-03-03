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

      if (placemarks.isNotEmpty) {
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
    try {
      final response = await _dio.get('/search', queryParameters: {
        'q': query,
        'format': 'json',
        'addressdetails': 1,
        'limit': 5,
        'countrycodes': 'tr',
      });

      return (response.data as List).map((json) => LocationModel.fromOpenStreetMap(json)).toList();
    } catch (e) {
      throw Exception('Konum bulunamadı: ${e.toString()}');
    }
  }

  // GeoPoint oluştur
  Future<GeoPoint?> getGeoPoint(LocationModel location) async {
    return GeoPoint(location.lat, location.lon);
  }
}
