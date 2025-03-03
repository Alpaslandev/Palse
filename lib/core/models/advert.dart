import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/models/location_model.dart';
import 'package:palseapp/core/helper/calculate_distance.dart';

class Advert {
  String? advertID;
  String advertName;
  String description;
  DateTime? startEventDate;
  String advertType;
  String advertImage;
  List<String> likers;

  LocationModel? location;

  String creatorUserID;
  String creatorName;
  String creatorLastName;
  String creatorProfilePicture;
  Gender creatorGender;
  bool creatorIsVerified;
  bool creatorIsPremium;
  int creatorAverageRating;

  DateTime? createdAt;

  Advert({
    this.advertID,
    required this.advertName,
    required this.description,
    required this.startEventDate,
    required this.advertType,
    required this.advertImage,
    required this.likers,
    required this.location,
    this.createdAt,
    this.creatorUserID = '',
    this.creatorName = '',
    this.creatorLastName = '',
    this.creatorProfilePicture = '',
    this.creatorGender = Gender.others,
    this.creatorIsVerified = false,
    this.creatorIsPremium = false,
    this.creatorAverageRating = 0,
  });

  String getDistanceFromCurrentLocation(double latitude, double longitude) {
    return calculateDistance(latitude1: latitude, longitude1: longitude, latitude2: location!.lat, longitude2: location!.lon);
  }

  factory Advert.fromJson(Map<String, dynamic> json, String advertID) {
    // Tarih ve saat parse etme fonksiyonu güncellendi
    DateTime? parseDateTime(dynamic dateData, dynamic timeData) {
      if (dateData == null) return null;

      // Eğer zaten DateTime ise
      if (dateData is DateTime) return dateData;

      // Eğer Timestamp ise
      if (dateData is Timestamp) return dateData.toDate();

      // Eğer String ise
      if (dateData is String) {
        try {
          // Önce "dd/MM/yyyy" formatını dene (eski format)
          if (dateData.contains('/')) {
            final dateParts = dateData.split('/');
            if (dateParts.length == 3) {
              // Saat bilgisini kontrol et
              if (timeData is String && timeData.contains(':')) {
                final timeParts = timeData.split(':');
                if (timeParts.length == 2) {
                  return DateTime(
                    int.parse(dateParts[2]), // yıl
                    int.parse(dateParts[1]), // ay
                    int.parse(dateParts[0]), // gün
                    int.parse(timeParts[0]), // saat
                    int.parse(timeParts[1]), // dakika
                  );
                }
              }
              // Saat bilgisi yoksa sadece tarih oluştur
              return DateTime(
                int.parse(dateParts[2]), // yıl
                int.parse(dateParts[1]), // ay
                int.parse(dateParts[0]), // gün
              );
            }
          }
          // Eğer başarısız olursa ISO formatını dene
          return DateTime.parse(dateData);
        } catch (e) {
          debugPrint('Tarih parse hatası: $e');
          return null;
        }
      }
      return null;
    }

    // Konum bilgisini parse etme fonksiyonu
    LocationModel? parseLocation(Map<String, dynamic> json) {
      // Önce yeni yapıyı kontrol et
      if (json['location'] != null && json['location'] is Map<String, dynamic>) {
        return LocationModel.fromFirestore(json['location']);
      }

      // Eski yapıyı kontrol et - doğrudan Advert içindeki alanlar
      String city = json['city'] ?? '';
      String district = json['district'] ?? '';
      String country = json['country'] ?? 'tr';

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

    return Advert(
      advertID: advertID,
      advertName: json['advertName'] ?? '',
      description: json['description'] ?? json['advertContext'] ?? '',
      creatorUserID: json['creatorUserID'] ?? '',
      startEventDate: parseDateTime(json['startEventDate'] ?? json['advertDate'], json['advertTime']),
      advertType: json['advertType'] ?? '',
      advertImage: json['advertImage'] ?? '',
      likers: List<String>.from(json['likers'] ?? List<String>.from(json['countUUIDs'] ?? [])),
      location: parseLocation(json),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),

      // Yeni alanlar için null kontrolü
      creatorLastName: json['creatorLastName'] ?? '',
      creatorName: json['creatorName'] ?? '',
      creatorProfilePicture: json['creatorProfilePicture'] ?? '',
      creatorGender: json['creatorGender']?.toLowerCase() == 'male'
          ? Gender.male
          : json['creatorGender']?.toLowerCase() == 'female'
              ? Gender.female
              : Gender.others,
      creatorIsVerified: json['creatorIsVerified'] ?? false,
      creatorIsPremium: json['creatorIsPremium'] ?? false,
      creatorAverageRating: json['creatorAverageRating'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'advertName': advertName,
      'description': description,
      'creatorUserID': creatorUserID,
      'startEventDate': startEventDate != null ? Timestamp.fromDate(startEventDate!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'advertType': advertType,
      'advertImage': advertImage,
      'likers': likers,
      'location': location?.toJson(),
      'creatorLastName': creatorLastName,
      'creatorName': creatorName,
      'creatorProfilePicture': creatorProfilePicture,
      'creatorGender': creatorGender.name,
      'creatorIsVerified': creatorIsVerified,
      'creatorIsPremium': creatorIsPremium,
      'creatorAverageRating': creatorAverageRating,
    };
  }
}
