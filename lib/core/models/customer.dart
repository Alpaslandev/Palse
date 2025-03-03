import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/models/comment_model.dart';
import 'package:palseapp/core/models/location_model.dart';
import 'package:palseapp/core/helper/calculate_distance.dart';
import 'package:palseapp/features/chats/model/chat_model.dart';

enum Gender {
  male(icon: 'assets/images/male.png', trName: 'Erkek', enName: 'Male'),
  female(icon: 'assets/images/female.png', trName: 'Kadın', enName: 'Female'),
  others(icon: 'assets/images/others.png', trName: 'Diğer', enName: 'Others');

  const Gender({required this.icon, required this.trName, required this.enName});
  final String icon;
  final String trName;
  final String enName;
}

class Customer {
  String? profilePictureUrl;
  String? email;
  String? phoneNumber;
  String? firstName;
  String? lastName;
  String? nickname;
  String? userID;
  String? appIdentifier;
  List<String>? adverts;
  bool? verification;
  bool? isPremium;
  Gender? gender;
  DateTime? birthday;
  List<String>? favoriteCategories;
  List<String>? blockUsers;
  List<String>? favoriteAdverts;
  List<String>? profileViewers;
  Map<String, Chat>? chatInfos;
  List<Comment>? comments;
  LocationModel? location;
  int xp;
  bool isWelcomeReward;

  Customer({
    this.profilePictureUrl,
    this.email,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    this.nickname,
    this.favoriteCategories = const [],
    this.adverts = const [],
    this.blockUsers = const [],
    this.verification,
    this.isPremium,
    this.gender,
    this.birthday,
    this.userID,
    this.favoriteAdverts = const [],
    this.chatInfos = const {},
    this.profileViewers = const [],
    this.comments = const [],
    this.location,
    this.xp = 0,
    this.isWelcomeReward = false,
  }) : appIdentifier = 'Customer App';

  String fullName() => '$firstName $lastName';

  // Yorumların ortalamasını hesaplar
  double getAverage() {
    if (comments == null || comments!.isEmpty) return 0.0; // 0.0 döndür
    // ignore: avoid_types_as_parameter_names
    return comments!.map((comment) => comment.rating ?? 0).fold(0.0, (sum, rating) => sum + rating) /
        comments!.length; // null değerleri 0 olarak değerlendir
  }

  int getAge() {
    if (birthday == null) return 0;
    final now = DateTime.now();
    final age = now.year - birthday!.year;
    return age;
  }

  String getDistanceFromCurrentLocation(double latitude, double longitude) {
    return calculateDistance(latitude1: latitude, longitude1: longitude, latitude2: location!.lat, longitude2: location!.lon);
  }

  factory Customer.fromJson(Map<String, dynamic> parsedJson, String userID) {
    Map<String, Chat> chatInfos = {};
    if (parsedJson['chatInfos'] != null) {
      final chatInfosMap = parsedJson['chatInfos'] as Map<String, dynamic>;
      chatInfosMap.forEach((key, value) {
        chatInfos[key] = Chat.fromChatInfo(
          value as Map<String, dynamic>,
          value['chatId'] as String? ?? '',
          key,
        );
      });
    }
    // Tarih ve saat parse etme fonksiyonu güncellendi
    DateTime? parseDateTime(dynamic dateData) {
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
            // tarih oluştur
            return DateTime(
              int.parse(dateParts[2]), // yıl
              int.parse(dateParts[1]), // ay
              int.parse(dateParts[0]), // gün
            );
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

    LocationModel parseLocation(dynamic locationData, Map<String, dynamic> parsedJson) {
      // Önce yeni yapıyı kontrol et
      if (locationData != null && locationData is Map<String, dynamic>) {
        return LocationModel.fromFirestore(locationData);
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

    Gender parseGender(dynamic genderData) {
      if (genderData == null) return Gender.others;

      // String ise
      if (genderData is String) {
        // Küçük harfe çevir ve boşlukları temizle
        String normalizedGender = genderData.toLowerCase().trim();

        // Farklı yazım şekillerini kontrol et
        if (normalizedGender == 'male' || normalizedGender == 'erkek' || normalizedGender == 'm') {
          return Gender.male;
        } else if (normalizedGender == 'female' || normalizedGender == 'kadın' || normalizedGender == 'kadin' || normalizedGender == 'f') {
          return Gender.female;
        }

        // Enum adını doğrudan kontrol et (try-catch ile güvenli hale getir)
        try {
          return Gender.values.byName(normalizedGender);
        } catch (e) {
          // Hata durumunda varsayılan değer
          return Gender.others;
        }
      }

      return Gender.others;
    }

    return Customer(
      profilePictureUrl: parsedJson['profilePictureUrl'] ?? '',
      email: parsedJson['email'] ?? '',
      phoneNumber: parsedJson['phoneNumber'] ?? '',
      nickname: parsedJson['nickname'] ?? '',
      firstName: parsedJson['firstName'] ?? '',
      lastName: parsedJson['lastName'] ?? '',
      userID: userID,
      blockUsers: List<String>.from(parsedJson['blockUsers'] ?? []),
      favoriteCategories: List<String>.from(parsedJson['favoriteCategories'] ?? []),
      favoriteAdverts: List<String>.from(parsedJson['favoriteAdverts'] ?? []),
      adverts: List<String>.from(parsedJson['adverts'] ?? []),
      verification: parsedJson['verification'] ?? false,
      isPremium: parsedJson['isPremium'] ?? false,
      gender: parseGender(parsedJson['gender']),
      birthday: parseDateTime(parsedJson['birthday']),
      chatInfos: chatInfos,
      profileViewers: List<String>.from(parsedJson['profileViewers'] ?? []),
      comments: List<Comment>.from(parsedJson['comments']?.map((comment) => Comment.fromJson(comment)) ?? []),
      location: parseLocation(parsedJson['location'], parsedJson),
      xp: parsedJson['xp'] ?? 0,
      isWelcomeReward: parsedJson['isWelcomeReward'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profilePictureUrl': profilePictureUrl,
      'email': email,
      'phoneNumber': phoneNumber,
      'firstName': firstName,
      'lastName': lastName,
      'nickname': nickname,
      'appIdentifier': appIdentifier,
      'events': adverts,
      'verification': verification,
      'isPremium': isPremium,
      'blockUsers': blockUsers,
      'profileViewers': profileViewers,
      'gender': gender?.name,
      'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
      'favoriteCategories': favoriteCategories,
      'favoriteAdverts': favoriteAdverts,
      'location': location?.toJson(),
      'chatInfos': chatInfos?.map((key, chat) => MapEntry(
            key,
            {
              'chatId': chat.id,
              'lastMessageTime': chat.lastMessageTime,
              'unreadCount': chat.unreadCount,
            },
          )),
      'comments': comments?.map((comment) => comment.toJson()).toList(),
      'xp': xp,
      'isWelcomeReward': isWelcomeReward,
    };
  }

  Customer copyWith({
    String? profilePictureUrl,
    String? email,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? nickname,
    String? userID,
    String? appIdentifier,
    List<String>? adverts,
    bool? verification,
    bool? isPremium,
    Gender? gender,
    DateTime? birthday,
    List<String>? favoriteCategories,
    List<String>? blockUsers,
    List<String>? favoriteAdverts,
    List<String>? profileViewers,
    Map<String, Chat>? chatInfos,
    List<Comment>? comments,
    LocationModel? location,
    int? xp,
    bool? isWelcomeReward,
  }) {
    return Customer(
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      nickname: nickname ?? this.nickname,
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
      favoriteAdverts: favoriteAdverts ?? this.favoriteAdverts,
      adverts: adverts ?? this.adverts,
      verification: verification ?? this.verification,
      isPremium: isPremium ?? this.isPremium,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      userID: userID ?? this.userID,
      chatInfos: chatInfos ?? this.chatInfos,
      profileViewers: profileViewers ?? this.profileViewers,
      comments: comments ?? this.comments,
      xp: xp ?? this.xp,
      isWelcomeReward: isWelcomeReward ?? this.isWelcomeReward,
      location: location ?? this.location,
      blockUsers: blockUsers ?? this.blockUsers,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
    );
  }
}
