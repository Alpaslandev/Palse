import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/constant/categories.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/models/location_model.dart';

class Advert {
  String? advertID;
  String title;
  String description;
  DateTime startEventDate;
  Categories advertType;
  String advertImage;
  List<String> likers;
  LocationModel location;

  String creatorUserID;
  bool isCreatorPremium;

  Gender creatorGender;
  DateTime createdAt;

  Advert({
    this.advertID,
    required this.title,
    required this.description,
    required this.startEventDate,
    required this.advertType,
    required this.advertImage,
    required this.likers,
    required this.location,
    required this.createdAt,
    required this.creatorUserID,
    required this.isCreatorPremium,
    required this.creatorGender,
  });

  factory Advert.fromJson(Map<String, dynamic> json, String advertID) {
    // Gender değerini önceden normalize edelim
    final genderValue = json['creatorGender'];
    final normalizedGender = genderValue != null ? Gender.fromString(genderValue.toString()) : Gender.others;
    try {
      return Advert(
        advertID: advertID,
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        creatorUserID: json['creatorUserID'] ?? '',
        isCreatorPremium: json['isCreatorPremium'] ?? false,
        startEventDate: (json['startEventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        advertType: Categories.values.byName(json['advertType'] ?? 'diger'),
        advertImage: json['advertImage'] ?? '',
        likers: json['likers'] != null ? List<String>.from(json['likers']) : [],
        location: LocationModel.fromFirestore(json['location']),
        createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        creatorGender: normalizedGender, // Normalize edilmiş gender değerini kullan
      );
    } catch (e) {
      debugPrint('İlan oluşturulurken hata: $e');
      return Advert(
        createdAt: DateTime.now(),
        isCreatorPremium: false,
        creatorGender: Gender.others,
        advertID: advertID,
        title: '',
        description: '',
        creatorUserID: '',
        startEventDate: DateTime.now(),
        advertType: Categories.diger,
        advertImage: '',
        likers: [],
        location: LocationModel(city: '', district: '', country: '', lat: 0, lon: 0),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'creatorUserID': creatorUserID,
      'isCreatorPremium': isCreatorPremium,
      'startEventDate': Timestamp.fromDate(startEventDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'advertType': advertType.name,
      'advertImage': advertImage,
      'likers': likers,
      'location': location.toJson(),
      'creatorGender': creatorGender.name.toLowerCase(),
    };
  }

  Advert copyWith({
    String? advertID,
    String? title,
    String? description,
    String? advertImage,
    String? creatorUserID,
    bool? isCreatorPremium,
    Categories? advertType,
    DateTime? createdAt,
    Gender? creatorGender,
    DateTime? startEventDate,
    LocationModel? location,
    List<String>? likers,
  }) {
    return Advert(
      advertID: advertID ?? this.advertID,
      title: title ?? this.title,
      description: description ?? this.description,
      advertImage: advertImage ?? this.advertImage,
      creatorUserID: creatorUserID ?? this.creatorUserID,
      isCreatorPremium: isCreatorPremium ?? this.isCreatorPremium,
      creatorGender: creatorGender ?? this.creatorGender,
      advertType: advertType ?? this.advertType,
      createdAt: createdAt ?? this.createdAt,
      startEventDate: startEventDate ?? this.startEventDate,
      location: location ?? this.location,
      likers: likers ?? this.likers,
    );
  }
}
