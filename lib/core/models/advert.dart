import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Advert {
  String? advertID;
  String advertName;
  String description;
  String creatorUserID;
  DateTime? startEventDate;
  //  DateTime? endEventDate;
  String advertType;
  String advertImage;
  List<String> countUUIDs;
  GeoPoint? geoPoint;

  final String? country; // Yeni alan
  final String? city; // Yeni alan
  final String? district; // Yeni alan

  DateTime? createdAt;

  Advert({
    this.advertID,
    required this.advertName,
    required this.description,
    required this.creatorUserID,
    required this.startEventDate,
    //  required this.endEventDate,
    required this.advertType,
    required this.advertImage,
    required this.countUUIDs,
    this.geoPoint,
    this.country,
    this.city,
    this.district,
    this.createdAt,
  });

  factory Advert.fromJson(Map<String, dynamic> json, String advertID) {
    // GeoPoint dönüşümü için yardımcı fonksiyon
    GeoPoint? parseGeoPoint(dynamic geoData) {
      if (geoData == null) return null;

      // Eğer direkt GeoPoint objesi ise
      if (geoData is GeoPoint) return geoData;

      // Eğer Map formatında ise
      if (geoData is Map<String, dynamic>) {
        try {
          return GeoPoint(
            (geoData['latitude'] as num).toDouble(),
            (geoData['longitude'] as num).toDouble(),
          );
        } catch (e) {
          debugPrint('GeoPoint parse hatası: $e');
          return null;
        }
      }

      return null;
    }

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

    return Advert(
      advertID: advertID,
      advertName: json['advertName'] ?? '',
      description: json['description'] ?? json['advertContext'] ?? '',
      creatorUserID: json['creatorUserID'] ?? '',
      startEventDate: parseDateTime(json['startEventDate'] ?? json['advertDate'], json['advertTime']),
      advertType: json['advertType'] ?? '',
      advertImage: json['advertImage'] ?? '',
      countUUIDs: List<String>.from(json['countUUIDs'] ?? []),
      geoPoint: parseGeoPoint(json['geoPoint']),
      country: json['country'] ?? '',
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'advertName': advertName,
      'description': description,
      'creatorUserID': creatorUserID,
      'startEventDate': startEventDate != null ? Timestamp.fromDate(startEventDate!) : null,
      //   'endEventDate': endEventDate != null ? Timestamp.fromDate(endEventDate!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'advertType': advertType,
      'advertImage': advertImage,
      'countUUIDs': countUUIDs,
      'geoPoint': geoPoint,
      'country': country,
      'city': city,
      'district': district,
    };
  }
}
