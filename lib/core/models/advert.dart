import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:palseapp/core/constant/categories.dart';
import 'package:palseapp/core/helper/categorie_parse.dart';
import 'package:palseapp/core/helper/date_parse.dart';
import 'package:palseapp/core/helper/location_parse.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/models/location_model.dart';

class Advert {
  String? advertID;
  String advertName;
  String description;
  DateTime? startEventDate;
  Categories advertType;
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

  factory Advert.fromJson(Map<String, dynamic> json, String advertID) {
    return Advert(
      advertID: advertID,
      advertName: json['advertName'] ?? '',
      description: json['description'] ?? json['advertContext'] ?? '',
      creatorUserID: json['creatorUserID'] ?? '',
      startEventDate: parseDateTime(json['startEventDate'] ?? json['advertDate'], json['advertTime']),
      advertType: parseCategoryType(json['advertType']) ?? Categories.diger,
      advertImage: json['advertImage'] ?? '',
      likers: json['likers'] != null ? List<String>.from(json['likers']) : [],
      location: parseAdvertLocation(json),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),

      // Yeni alanlar için null kontrolü
      creatorLastName: json['creatorLastName'] ?? '',
      creatorName: json['creatorName'] ?? '',
      creatorProfilePicture: json['creatorProfilePicture'] ?? '',
      creatorGender: json['creatorGender'] != null ? Gender.values.byName(json['creatorGender']) : Gender.others,
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
      'advertType': advertType.name,
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

  Advert copyWith({
    String? advertID,
    String? advertName,
    String? description,
    String? advertImage,
    String? creatorUserID,
    String? creatorName,
    String? creatorProfilePicture,
    bool? creatorIsVerified,
    bool? creatorIsPremium,
    double? creatorAverageRating,
    Categories? advertType,
    DateTime? createdAt,
    DateTime? startEventDate,
    LocationModel? location,
    List<String>? likers,
  }) {
    return Advert(
      advertID: advertID ?? this.advertID,
      advertName: advertName ?? this.advertName,
      description: description ?? this.description,
      advertImage: advertImage ?? this.advertImage,
      creatorUserID: creatorUserID ?? this.creatorUserID,
      creatorName: creatorName ?? this.creatorName,
      creatorProfilePicture: creatorProfilePicture ?? this.creatorProfilePicture,
      creatorIsVerified: creatorIsVerified ?? this.creatorIsVerified,
      creatorIsPremium: creatorIsPremium ?? this.creatorIsPremium,
      creatorAverageRating: creatorAverageRating?.toInt() ?? this.creatorAverageRating,
      advertType: advertType ?? this.advertType,
      createdAt: createdAt ?? this.createdAt,
      startEventDate: startEventDate ?? this.startEventDate,
      location: location ?? this.location,
      likers: likers ?? this.likers,
    );
  }
}
