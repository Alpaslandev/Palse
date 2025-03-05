import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/constant/categories.dart';
import 'package:palseapp/core/helper/categorie_parse.dart';
import 'package:palseapp/core/helper/date_parse.dart';
import 'package:palseapp/core/helper/location_parse.dart';
import 'package:palseapp/core/models/comment_model.dart';
import 'package:palseapp/core/models/location_model.dart';
import 'package:palseapp/core/models/chat_model.dart';

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
  List<Categories>? favoriteCategories;
  List<String>? blockUsers;
  List<String>? favoriteAdverts;
  List<String>? profileViewers;
  Map<String, Chat>? chatMap;

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
    this.chatMap = const {},
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

  // Yardımcı metotlar
  List<Chat>? getSortedChats() {
    final chats = chatMap?.values.toList();
    chats?.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    return chats;
  }

  Chat? getChatWithUser(String otherUserId) {
    return chatMap?[otherUserId];
  }

  bool get hasUnreadChats {
    return chatMap?.values.any((chat) => chat.unreadCount > 0) ?? false;
  }

  int getTotalUnreadCount() {
    return chatMap?.values.fold(0, (sum, chat) => sum! + chat.unreadCount) ?? 0;
  }

  int getAge() {
    if (birthday == null) return 0;
    final now = DateTime.now();
    final age = now.year - birthday!.year;
    return age;
  }

  factory Customer.fromJson(Map<String, dynamic> parsedJson, String userID) {
    final chatMapJson = parsedJson['chatMap'] as Map<String, dynamic>? ?? {};
    final chatMap = <String, Chat>{};

    chatMapJson.forEach((otherUserId, summaryJson) {
      chatMap[otherUserId] = Chat.fromUserDocument(summaryJson);
    });

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

    try {
      return Customer(
        profilePictureUrl: parsedJson['profilePictureUrl'] ?? '',
        email: parsedJson['email'] ?? '',
        phoneNumber: parsedJson['phoneNumber'] ?? '',
        nickname: parsedJson['nickname'] ?? '',
        firstName: parsedJson['firstName'] ?? '',
        lastName: parsedJson['lastName'] ?? '',
        userID: userID,
        blockUsers: parsedJson['blockUsers'] != null ? List<String>.from(parsedJson['blockUsers']) : [],
        favoriteCategories: parsedJson['favoriteCategories'] != null
            ? (parsedJson['favoriteCategories'] as List<dynamic>?)
                    ?.map((item) => parseCategoryType(item))
                    .whereType<Categories>() // null değerleri filtrele
                    .toList() ??
                []
            : [],
        favoriteAdverts: parsedJson['favoriteAdverts'] != null ? List<String>.from(parsedJson['favoriteAdverts']) : [],
        adverts: parsedJson['adverts'] != null ? List<String>.from(parsedJson['adverts']) : [],
        verification: parsedJson['verification'] ?? false,
        isPremium: parsedJson['isPremium'] ?? false,
        gender: parsedJson['gender'] != null ? parseGender(parsedJson['gender']) : Gender.others,
        birthday: parsedJson['birthday'] != null ? parseDateTime(parsedJson['birthday'], parsedJson['birthdayTime']) : null,
        chatMap: chatMap,
        profileViewers: parsedJson['profileViewers'] != null ? List<String>.from(parsedJson['profileViewers']) : [],
        comments: parsedJson['comments'] != null ? List<Comment>.from(parsedJson['comments'].map((comment) => Comment.fromJson(comment))) : [],
        location: parsedJson['location'] != null ? parseCustomerLocation(parsedJson) : parseCustomerLocation(parsedJson),
        xp: parsedJson['xp'] ?? 0,
        isWelcomeReward: parsedJson['isWelcomeReward'] ?? false,
      );
    } catch (e) {
      debugPrint('Customer.fromJson error: $e');
      return throw Exception(e);
    }
  }

  Map<String, dynamic> toJson() {
    final chatMapJson = <String, dynamic>{};
    chatMap?.forEach((otherUserId, summary) {
      chatMapJson[otherUserId] = summary.toUserDocumentJson(userID!);
    });

    return {
      'profilePictureUrl': profilePictureUrl ?? '',
      'email': email ?? '',
      'phoneNumber': phoneNumber ?? '',
      'firstName': firstName ?? '',
      'lastName': lastName ?? '',
      'nickname': nickname ?? '',
      'appIdentifier': appIdentifier ?? '',
      'adverts': adverts ?? [],
      'verification': verification ?? false,
      'isPremium': isPremium ?? false,
      'blockUsers': blockUsers ?? [],
      'profileViewers': profileViewers ?? [],
      'gender': gender?.name ?? Gender.others.name,
      'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
      'favoriteCategories': favoriteCategories?.map((category) => category.name).toList() ?? [],
      'favoriteAdverts': favoriteAdverts ?? [],
      'location': location?.toJson() ?? {},
      'chatMap': chatMapJson,
      'comments': comments?.map((comment) => comment.toJson()).toList() ?? [],
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
    List<Categories>? favoriteCategories,
    List<String>? blockUsers,
    List<String>? favoriteAdverts,
    List<String>? profileViewers,
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
      chatMap: chatMap,
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
