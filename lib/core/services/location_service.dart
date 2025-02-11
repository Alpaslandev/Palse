import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';

// Basit ve anlaşılır konum servisi
class LocationService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://nominatim.openstreetmap.org',
    headers: {'User-Agent': 'YourAppName/1.0'}, // Özel kullanıcı ajanı zorunlu
  ));

  // Mevcut konumu al
  Future<LatLng?> getCurrentPosition() async {
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
      return LatLng(position.latitude, position.longitude);
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

  // Seçilen il ve ilçeden GeoPoint oluştur
  Future<GeoPoint?> getGeoPoint(String city, String district, String country) async {
    try {
      final List<Location> locations = await locationFromAddress('$district, $city, $country');

      if (locations.isNotEmpty) {
        return GeoPoint(
          locations.first.latitude,
          locations.first.longitude,
        );
      }
      return null;
    } catch (e) {
      debugPrint('GeoPoint oluşturulamadı: $e');
      return null;
    }
  }

  Future<List<LocationSuggestion>> searchLocation(String query) async {
    try {
      final response = await _dio.get('/search', queryParameters: {
        'q': query,
        'format': 'json',
        'addressdetails': 1,
        'limit': 5,
        'countrycodes': 'tr', // Sadece Türkiye için
      });

      return (response.data as List).map((json) => LocationSuggestion.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Konum bulunamadı: ${e.toString()}');
    }
  }
}

class LocationSuggestion {
  final String displayName;
  final double lat;
  final double lon;
  final Map<String, dynamic> address;

  LocationSuggestion({
    required this.displayName,
    required this.lat,
    required this.lon,
    required this.address,
  });

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    return LocationSuggestion(
      displayName: json['display_name'],
      lat: double.parse(json['lat']),
      lon: double.parse(json['lon']),
      address: json['address'],
    );
  }

  String get city => address['city'] ?? address['state'] ?? '';
  String get district => address['town'] ?? address['village'] ?? '';
}
