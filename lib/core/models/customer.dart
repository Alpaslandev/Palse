import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/models/chat_model.dart';

enum Gender {
  male(icon: 'assets/images/male.png'),
  female(icon: 'assets/images/female.png'),
  others(icon: 'assets/images/others.png');

  const Gender({required this.icon});
  final String icon;
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
  int? coins;
  List<String>? events;
  bool? verification;
  bool? isPremium;
  String? country;
  String? city;
  String? district;
  Gender? gender;
  DateTime? birthday;
  List<double>? userReview;
  double? average;
  List<String>? userReviewUUIDs;
  List<String>? messagefriends;
  List<String>? userComments;
  List<String>? userCommentsDate;
  List<String>? userCommentUUIDs;
  List<String>? commenderUrl;
  List<String>? commenderFullName;
  int? age;
  GeoPoint? geoPoint;
  List<String>? favoriteCategories;
  List<String>? blockUsers;
  List<String>? favoriteAdverts;
  bool? firstNotification;
  Map<String, Chat>? chatInfos;

  Customer({
    this.profilePictureUrl,
    this.email,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    this.nickname,
    this.coins,
    this.average,
    this.firstNotification,
    this.userReview,
    this.userReviewUUIDs,
    this.favoriteCategories,
    this.events,
    this.blockUsers,
    this.verification,
    this.isPremium,
    this.city,
    this.country,
    this.district,
    this.gender,
    this.birthday,
    this.age,
    this.userID,
    this.messagefriends,
    this.userComments,
    this.userCommentsDate,
    this.userCommentUUIDs,
    this.commenderFullName,
    this.commenderUrl,
    this.geoPoint,
    this.favoriteAdverts,
    this.chatInfos,
  }) : appIdentifier = 'Customer App';

  String fullName() => '$firstName $lastName';

  int getAge() {
    if (birthday == null) return 0;
    final now = DateTime.now();
    final age = now.year - birthday!.year;
    return age;
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

    return Customer(
      profilePictureUrl: parsedJson['profilePictureUrl'] ?? '',
      email: parsedJson['email'] ?? '',
      phoneNumber: parsedJson['phoneNumber'] ?? '',
      nickname: parsedJson['nickname'] ?? '',
      firstName: parsedJson['firstName'] ?? '',
      lastName: parsedJson['lastName'] ?? '',
      userID: userID,
      coins: parsedJson['coins'] ?? 10,
      average: (parsedJson['average'] is int) ? (parsedJson['average'] as int).toDouble() : (parsedJson['average'] ?? 0.0),
      userReview: List<double>.from(parsedJson['userReview'] ?? []),
      userReviewUUIDs: List<String>.from(parsedJson['userReviewUUIDs'] ?? []),
      userComments: List<String>.from(parsedJson['userComments'] ?? []),
      userCommentsDate: List<String>.from(parsedJson['userCommentsDate'] ?? []),
      userCommentUUIDs: List<String>.from(parsedJson['userCommentUUIDs'] ?? []),
      blockUsers: List<String>.from(parsedJson['blockUsers'] ?? []),
      commenderFullName: List<String>.from(parsedJson['commenderFullName'] ?? []),
      commenderUrl: List<String>.from(parsedJson['commenderUrl'] ?? []),
      favoriteCategories: List<String>.from(parsedJson['favoriteCategories'] ?? []),
      favoriteAdverts: List<String>.from(parsedJson['favoriteAdverts'] ?? []),
      events: List<String>.from(parsedJson['adverts'] ?? List<String>.from(parsedJson['events'] ?? [])),
      verification: parsedJson['verification'] ?? false,
      isPremium: parsedJson['isPremium'] ?? false,
      firstNotification: parsedJson['firstNotification'] ?? false,
      country: parsedJson['country'] ?? '',
      city: parsedJson['city'] ?? '',
      district: parsedJson['district'] ?? '',
      gender: parseGender(parsedJson['gender']),
      birthday: parseDateTime(parsedJson['birthday']),
      age: parsedJson['age'] ?? 0,
      messagefriends: List<String>.from(parsedJson['messageFriends'] ?? []),
      geoPoint: parsedJson['geoPoint'],
      chatInfos: chatInfos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profilePictureUrl': profilePictureUrl,
      'nickname': nickname,
      'email': email,
      'phoneNumber': phoneNumber,
      'firstName': firstName,
      'lastName': lastName,
      'id': userID,
      'appIdentifier': appIdentifier,
      'coins': coins,
      'average': average,
      'userReviewUUIDs': userReviewUUIDs,
      'events': events,
      'verification': verification,
      'isPremium': isPremium,
      'firstNotification': firstNotification,
      'city': city,
      'blockUsers': blockUsers,
      'district': district,
      'gender': gender?.name,
      'birthday': Timestamp.fromDate(birthday!),
      'favoriteCategories': favoriteCategories,
      'favoriteAdverts': favoriteAdverts,
      'messageFriends': messagefriends,
      'userCommentUUIDs': userCommentUUIDs,
      'userCommentsDate': userCommentsDate,
      'userComments': userComments,
      'commenderUrl': commenderUrl,
      'commenderFullName': commenderFullName,
      'geoPoint': geoPoint,
      'chatInfos': chatInfos?.map((key, chat) => MapEntry(
            key,
            {
              'chatId': chat.id,
              'lastMessageTime': chat.lastMessageTime,
              'unreadCount': chat.unreadCount,
            },
          )),
    };
  }

  Customer copyWith({
    String? profilePictureUrl,
    String? email,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? nickname,
    int? coins,
    double? average,
    List<double>? userReview,
    List<String>? userReviewUUIDs,
    List<String>? favoriteCategories,
    List<String>? favoriteAdverts,
    List<String>? events,
    bool? verification,
    bool? isPremium,
    String? country,
    String? city,
    String? district,
    Gender? gender,
    DateTime? birthday,
    int? age,
    String? userID,
    List<String>? messagefriends,
    List<String>? userComments,
    List<String>? userCommentsDate,
    List<String>? userCommentUUIDs,
    List<String>? commenderUrl,
    List<String>? commenderFullName,
    GeoPoint? geoPoint,
    Map<String, Chat>? chatInfos,
  }) {
    return Customer(
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      nickname: nickname ?? this.nickname,
      coins: coins ?? this.coins,
      average: average ?? this.average,
      userReview: userReview ?? this.userReview,
      userReviewUUIDs: userReviewUUIDs ?? this.userReviewUUIDs,
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
      favoriteAdverts: favoriteAdverts ?? this.favoriteAdverts,
      events: events ?? this.events,
      verification: verification ?? this.verification,
      isPremium: isPremium ?? this.isPremium,
      country: country ?? this.country,
      city: city ?? this.city,
      district: district ?? this.district,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      age: age ?? this.age,
      userID: userID ?? this.userID,
      messagefriends: messagefriends ?? this.messagefriends,
      userComments: userComments ?? this.userComments,
      userCommentsDate: userCommentsDate ?? this.userCommentsDate,
      userCommentUUIDs: userCommentUUIDs ?? this.userCommentUUIDs,
      commenderUrl: commenderUrl ?? this.commenderUrl,
      commenderFullName: commenderFullName ?? this.commenderFullName,
      geoPoint: geoPoint ?? this.geoPoint,
      chatInfos: chatInfos ?? this.chatInfos,
    );
  }

  static Gender parseGender(String value) {
    switch (value.toLowerCase()) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      default:
        return Gender.others;
    }
  }
}
