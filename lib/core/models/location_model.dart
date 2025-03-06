import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:palseapp/core/helper/calculate_distance.dart';

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
    required String city,
    required String district,
    required String country,
    required this.lat,
    required this.lon,
    String? displayName,
  })  :
        // String değerleri burada otomatik olarak büyük harfe dönüştürüyoruz
        city = city.toUpperCase(),
        district = district.toUpperCase(),
        country = country.toUpperCase(),
        displayName = displayName?.toUpperCase();

  // 1. OpenStreetMap API'den gelen JSON'ı işle
  factory LocationModel.fromOpenStreetMap(Map<String, dynamic> json) {
    debugPrint('OpenStreetMap JSON başlangıç: ${json.toString()}');

    final Map<String, dynamic> addressData = json['address'] ?? {};
    debugPrint('Adres verisi: $addressData');

    // Veri dönüşümlerini detaylı loglayalım
    final String city = addressData['city'] ?? addressData['state'] ?? addressData['province'] ?? '';
    final String district = addressData['town'] ?? addressData['village'] ?? addressData['county'] ?? '';
    final String country = addressData['country_code'] ?? 'TR';
    final double lat = double.parse(json['lat'] ?? '0');
    final double lon = double.parse(json['lon'] ?? '0');
    final String displayName = json['display_name'] ?? '';

    debugPrint('Dönüştürülen veriler:');
    debugPrint('city: $city');
    debugPrint('district: $district');
    debugPrint('country: $country');
    debugPrint('lat: $lat');
    debugPrint('lon: $lon');
    debugPrint('displayName: $displayName');

    final locationModel = LocationModel(
      city: city,
      district: district,
      country: country,
      lat: lat,
      lon: lon,
      displayName: displayName,
    );

    debugPrint('Oluşturulan LocationModel: ${locationModel.toString()}');
    return locationModel;
  }

  // 2. Placemark'tan LocationModel oluştur (Geocoding için)
  factory LocationModel.fromPlacemark(Placemark placemark, {required double lat, required double lon}) {
    debugPrint('Placemark: ${placemark.toString()}');
    final locationModel = LocationModel(
      city: placemark.administrativeArea ?? '',
      district: placemark.subAdministrativeArea ?? placemark.locality ?? placemark.subLocality ?? '',
      country: placemark.isoCountryCode ?? '',
      lat: lat,
      lon: lon,
    );

    debugPrint('fromPlacemark: ${locationModel.toString()}');
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
      'city': city, // Zaten büyük harf
      'district': district, // Zaten büyük harf
      'country': country, // Zaten büyük harf
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

  String displayStringWithDistance(LocationModel other) {
    return '$city, $district (${distanceTo(other)} km)';
  }

  // Km bazlı mesafe hesaplama
  int distanceTo(LocationModel other) {
    return calculateDistance(latitude1: lat, longitude1: lon, latitude2: other.lat, longitude2: other.lon);
  }
}
