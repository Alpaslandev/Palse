import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

class LocationModel {
  final String city;
  final String district;
  final String country;
  final double lat;
  final double lon;

  final String? displayName;

  // GeoPoint ekleyelim
  GeoPoint? get geoPoint => lat != 0 && lon != 0 ? GeoPoint(lat, lon) : null;

  LocationModel({
    required this.city,
    required this.district,
    required this.country,
    required this.lat,
    required this.lon,
    this.displayName,
  });

  // 1. OpenStreetMap API'den gelen JSON'ı işle
  factory LocationModel.fromOpenStreetMap(Map<String, dynamic> json) {
    // debugPrint('OpenStreetMap: ${json.toString()}');
    final Map<String, dynamic> addressData = json['address'] ?? {};

    final locationModel = LocationModel(
      city: addressData['city'] ?? addressData['state'] ?? addressData['province'] ?? '',
      district: addressData['town'] ?? addressData['village'] ?? addressData['county'] ?? '',
      country: addressData['country_code'] ?? '',
      lat: double.parse(json['lat'] ?? '0'),
      lon: double.parse(json['lon'] ?? '0'),
      displayName: json['display_name'] ?? '',
    );

    debugPrint('LocationModel: ${locationModel.toString()}');
    return locationModel;
  }

  // 2. Placemark'tan LocationModel oluştur (Geocoding için)
  factory LocationModel.fromPlacemark(Placemark placemark, {required double lat, required double lon}) {
    // debugPrint('Placemark: ${placemark.toString()}');
    final locationModel = LocationModel(
      city: placemark.administrativeArea ?? '',
      district: placemark.subAdministrativeArea ?? placemark.locality ?? placemark.subLocality ?? '',
      country: placemark.isoCountryCode ?? '',
      lat: lat,
      lon: lon,
    );

    debugPrint('LocationModel: ${locationModel.toString()}');
    return locationModel;
  }

  factory LocationModel.fromFirestore(Map<String, dynamic> json) {
    GeoPoint? geoPoint = json['geoPoint'];

    double lat = 0;
    double lon = 0;

    if (geoPoint != null) {
      lat = geoPoint.latitude;
      lon = geoPoint.longitude;
    }
    return LocationModel(
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      country: json['country'] ?? 'TR',
      lat: lat,
      lon: lon,
    );
  }

  // Firestore için JSON formatına dönüştür
  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'district': district,
      'country': country,
      'geoPoint': geoPoint,
    };
  }

  @override
  String toString() {
    return 'LocationModel(city: $city, district: $district, country: $country, lat: $lat, lon: $lon) ${displayString()}';
  }

  String displayString() {
    return '$city, $district, $country';
  }

  // Km bazlı mesafe hesaplama
  double distanceTo(LocationModel other) {
    return _calculateDistance(lat, lon, other.lat, other.lon);
  }

  // Haversine formülü ile mesafe hesaplama (km)
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Dünya yarıçapı (km)

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) + cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
}
