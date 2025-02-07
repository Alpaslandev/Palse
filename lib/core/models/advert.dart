import 'package:cloud_firestore/cloud_firestore.dart';

enum LastUsageType {
  dependantOnDate,
  sevenDays,
  fifteenDays,
  thirtyDays,
}

class Advert {
  String advertID;
  String advertName;
  String advertContext;
  String creatorUserID;
  String advertDate;
  String advertTime;
  String advertLastUsage;
  String advertType;
  String city;
  String district;
  String phoneNumber;
  String creatorName;
  String creatorLastName;
  String advertImage;
  int count;
  List<String> countUUIDs;
  GeoPoint? geoPoint;
  Timestamp? createdAt;

  Advert({
    required this.advertID,
    required this.advertName,
    required this.advertContext,
    required this.creatorUserID,
    required this.advertDate,
    required this.advertTime,
    required this.advertLastUsage,
    required this.advertType,
    required this.city,
    required this.district,
    required this.phoneNumber,
    required this.creatorName,
    required this.creatorLastName,
    required this.advertImage,
    required this.count,
    required this.countUUIDs,
    this.geoPoint,
    this.createdAt,
  });
  factory Advert.fromJson(Map<String, dynamic> parsedJson) {
    return Advert(
      advertID: parsedJson['advertID'] ?? '',
      advertName: parsedJson['advertName'] ?? '',
      advertContext: parsedJson['advertContext'] ?? '',
      creatorUserID: parsedJson['creatorUserID'] ?? '',
      advertDate: parsedJson['advertDate'] ?? '',
      advertTime: parsedJson['advertTime'] ?? '',
      advertLastUsage: parsedJson['advertLastUsage'] ?? '',
      advertType: parsedJson['advertType'] ?? '',
      city: parsedJson['city'] ?? '',
      district: parsedJson['district'] ?? '',
      phoneNumber: parsedJson['phoneNumber'] ?? '',
      creatorName: parsedJson['creatorName'] ?? '',
      creatorLastName: parsedJson['creatorLastName'] ?? '',
      advertImage: parsedJson['advertImage'] ?? '',
      count: parsedJson['count'] ?? 0,
      countUUIDs: List<String>.from(parsedJson['countUUIDs'] ?? []),
      geoPoint: parsedJson['geoPoint'] != null
          ? GeoPoint(
              parsedJson['geoPoint']['latitude'] as double,
              parsedJson['geoPoint']['longitude'] as double,
            )
          : null,
      createdAt: parsedJson['createdAt'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'advertID': advertID,
      'advertName': advertName,
      'advertContext': advertContext,
      'creatorUserID': creatorUserID,
      'advertDate': advertDate,
      'advertTime': advertTime,
      'advertLastUsage': advertLastUsage,
      'advertType': advertType,
      'city': city,
      'district': district,
      'phoneNumber': phoneNumber,
      'creatorName': creatorName,
      'creatorLastName': creatorLastName,
      'advertImage': advertImage,
      'count': count,
      'countUUIDs': countUUIDs,
      'geoPoint': geoPoint != null
          ? {'latitude': geoPoint!.latitude, 'longitude': geoPoint!.longitude}
          : null,
      'createdAt': createdAt,
    };
  }

  static LastUsageType parseLastUsageType(String value) {
    switch (value) {
      case 'dependantOnDate':
        return LastUsageType.dependantOnDate;
      case 'sevenDays':
        return LastUsageType.sevenDays;
      case 'fifteenDays':
        return LastUsageType.fifteenDays;
      case 'thirtyDays':
        return LastUsageType.thirtyDays;
      default:
        return LastUsageType.dependantOnDate;
    }
  }
}
