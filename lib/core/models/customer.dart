import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/constant/categories.dart';
import 'package:palseapp/core/helper/categorie_parse.dart';
import 'package:palseapp/core/helper/date_parse.dart';
import 'package:palseapp/core/helper/location_parse.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/models/comment_model.dart';
import 'package:palseapp/core/models/location_model.dart';
import 'package:palseapp/core/models/chat_model.dart';
import 'package:palseapp/features/achievement/achievements.dart';

enum Gender {
  male(icon: 'assets/images/male.png', textKey: 'gender_male'),
  female(icon: 'assets/images/female.png', textKey: 'gender_female'),
  others(icon: 'assets/images/others.png', textKey: 'gender_others');

  const Gender({required this.icon, required this.textKey});
  final String icon;
  final String textKey;

  // Gender enum'ını string değerden elde etmek için yardımcı metot
  static Gender fromString(String? value) {
    if (value == null) return Gender.others;

    // Lowercase ve trim işlemi yap
    final normalized = value.toLowerCase().trim();

    // Yaygın değerleri kontrol et
    if (normalized == 'male' || normalized == 'erkek' || normalized == 'm') {
      return Gender.male;
    } else if (normalized == 'female' || normalized == 'kadın' || normalized == 'kadin' || normalized == 'f') {
      return Gender.female;
    }

    // Enum adını kontrol et
    try {
      return Gender.values.byName(normalized);
    } catch (_) {
      return Gender.others;
    }
  }

  // Çevirilmiş metni döndüren getter
  String getText(BuildContext context) {
    return context.tr(textKey);
  }
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

  final int totalXp;
  final Map<String, int> completedTasks;
  final DateTime? lastDailyTaskDate;

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
    this.totalXp = 0,
    this.completedTasks = const {},
    this.lastDailyTaskDate,
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

  // Kullanıcının unvanını döndüren getter
  UserRank get rank => UserRank.fromXp(totalXp);

  // UserAchievements nesnesini döndüren getter
  UserAchievements get achievements => UserAchievements(
        totalXp: totalXp,
        completedTasks: _parseCompletedTasks(),
        lastDailyTaskDate: lastDailyTaskDate,
      );

  // String->XpEvent dönüşümü yapan yardımcı metod
  Map<XpEvent, int> _parseCompletedTasks() {
    final result = <XpEvent, int>{};
    completedTasks.forEach((key, value) {
      try {
        final event = XpEvent.values.firstWhere((e) => e.name == key);
        result[event] = value;
      } catch (e) {
        print('Bilinmeyen XpEvent: $key');
      }
    });
    return result;
  }

  factory Customer.fromJson(Map<String, dynamic> parsedJson, String userID) {
    final chatMapJson = parsedJson['chatMap'] as Map<String, dynamic>? ?? {};
    final chatMap = <String, Chat>{};

    chatMapJson.forEach((otherUserId, summaryJson) {
      chatMap[otherUserId] = Chat.fromUserDocument(summaryJson);
    });

    // Gender değerini önceden normalize edelim
    final genderValue = parsedJson['gender'];
    final normalizedGender = genderValue != null ? Gender.fromString(genderValue.toString()) : Gender.others;

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
        gender: normalizedGender, // Normalize edilmiş gender değerini kullan
        birthday: parsedJson['birthday'] != null ? parseDateTime(parsedJson['birthday'], parsedJson['birthdayTime']) : null,
        chatMap: chatMap,
        profileViewers: parsedJson['profileViewers'] != null ? List<String>.from(parsedJson['profileViewers']) : [],
        comments: parsedJson['comments'] != null ? List<Comment>.from(parsedJson['comments'].map((comment) => Comment.fromJson(comment))) : [],
        location: parsedJson['location'] != null ? parseCustomerLocation(parsedJson) : parseCustomerLocation(parsedJson),
        totalXp: parsedJson['totalXp'] ?? 0,
        completedTasks: parsedJson['completedTasks'] != null ? Map<String, int>.from(parsedJson['completedTasks']) : {},
        lastDailyTaskDate:
            parsedJson['lastDailyTaskDate'] != null ? parseDateTime(parsedJson['lastDailyTaskDate'], parsedJson['lastDailyTaskDateTime']) : null,
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
      'gender': gender?.name.toLowerCase() ?? Gender.others.name.toLowerCase(),
      'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
      'favoriteCategories': favoriteCategories?.map((category) => category.name).toList() ?? [],
      'favoriteAdverts': favoriteAdverts ?? [],
      'location': location?.toJson() ?? {},
      'chatMap': chatMapJson,
      'comments': comments?.map((comment) => comment.toJson()).toList() ?? [],
      'totalXp': totalXp,
      'completedTasks': completedTasks,
      'lastDailyTaskDate': lastDailyTaskDate != null ? Timestamp.fromDate(lastDailyTaskDate!) : null,
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
    int? totalXp,
    Map<String, int>? completedTasks,
    DateTime? lastDailyTaskDate,
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
      location: location ?? this.location,
      blockUsers: blockUsers ?? this.blockUsers,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      totalXp: totalXp ?? this.totalXp,
      completedTasks: completedTasks ?? this.completedTasks,
      lastDailyTaskDate: lastDailyTaskDate ?? this.lastDailyTaskDate,
    );
  }
}
