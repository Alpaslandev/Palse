import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:palseapp/core/models/location_model.dart';

LocationModel parseCustomerLocation(Map<String, dynamic> parsedJson) {
  // Önce yeni yapıyı kontrol et
  if (parsedJson['location'] != null && parsedJson['location'] is Map<String, dynamic>) {
    return LocationModel.fromFirestore(parsedJson['location']);
  }

  // Eski yapıyı kontrol et - doğrudan Customer içindeki alanlar
  String city = parsedJson['city'] ?? '';
  String district = parsedJson['district'] ?? '';
  String country = parsedJson['country'] ?? 'TR';
  GeoPoint? geoPoint = parsedJson['geoPoint'];

  double lat = 0;
  double lon = 0;

  // Eğer geoPoint varsa, koordinatları al
  if (geoPoint != null) {
    lat = geoPoint.latitude;
    lon = geoPoint.longitude;
  }

  // Eski yapıdaki bilgilerle LocationModel oluştur
  if (city.isNotEmpty || district.isNotEmpty || geoPoint != null) {
    return LocationModel(
      city: city,
      district: district,
      country: country,
      lat: lat,
      lon: lon,
    );
  }

  // Hiçbir konum bilgisi yoksa boş model döndür
  return LocationModel(lat: 0, lon: 0, city: '', district: '', country: '');
}

// Konum bilgisini parse etme fonksiyonu
LocationModel? parseAdvertLocation(Map<String, dynamic> json) {
  // Önce yeni yapıyı kontrol et
  if (json['location'] != null && json['location'] is Map<String, dynamic>) {
    return LocationModel.fromFirestore(json['location']);
  }

  // Eski yapıyı kontrol et - doğrudan Advert içindeki alanlar
  String city = json['city'] ?? '';
  String district = json['district'] ?? '';
  String country = json['country'] ?? 'TR';

  double lat = 0;
  double lon = 0;

  // Eski yapıda geoPoint bir map olarak saklanmış
  if (json['geoPoint'] != null && json['geoPoint'] is Map<String, dynamic>) {
    var geoPointMap = json['geoPoint'] as Map<String, dynamic>;
    lat = (geoPointMap['latitude'] as num?)?.toDouble() ?? 0;
    lon = (geoPointMap['longitude'] as num?)?.toDouble() ?? 0;
  }

  // Eski yapıdaki bilgilerle LocationModel oluştur
  if (city.isNotEmpty || district.isNotEmpty || lat != 0 || lon != 0) {
    return LocationModel(
      city: city,
      district: district,
      country: country,
      lat: lat,
      lon: lon,
    );
  }

  return null;
}
