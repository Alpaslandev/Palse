import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/features/chats/model/chat_model.dart';

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
  List<String>? events;
  bool? verification;
  bool? isPremium;
  String? country;
  String? city;
  String? district;
  Gender? gender;
  DateTime? birthday;
  int? age;
  GeoPoint? geoPoint;
  List<String>? favoriteCategories;
  List<String>? blockUsers;
  List<String>? favoriteAdverts;
  List<String>? profileViewers;
  Map<String, Chat>? chatInfos;
  List<Comment>? comments;

  Customer({
    this.profilePictureUrl,
    this.email,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    this.nickname,
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
    this.geoPoint,
    this.favoriteAdverts,
    this.chatInfos,
    this.profileViewers,
    this.comments,
  }) : appIdentifier = 'Customer App';

  String fullName() => '$firstName $lastName';

  // Yorumların ortalamasını hesaplar
  double getAverage() {
    if (comments == null || comments!.isEmpty) return 0.0; // 0.0 döndür
    return comments!.map((comment) => comment.rating ?? 0).fold(0.0, (sum, rating) => sum + rating) /
        comments!.length; // null değerleri 0 olarak değerlendir
  }

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

    List<Comment> parseComments(dynamic commentsData) {
      if (commentsData == null) return [];
      if (commentsData is! List) return [];

      return commentsData.map((commentData) {
        try {
          if (commentData is Map<String, dynamic>) {
            return Comment.fromJson(commentData);
          }
        } catch (e) {
          debugPrint('Yorum parse hatası: $e');
        }
        return Comment(); // Boş bir Comment döndür
      }).toList();
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
      events: List<String>.from(parsedJson['events'] ?? List<String>.from(parsedJson['adverts'] ?? [])),
      verification: parsedJson['verification'] ?? false,
      isPremium: parsedJson['isPremium'] ?? false,
      country: parsedJson['country'] ?? '',
      city: parsedJson['city'] ?? '',
      district: parsedJson['district'] ?? '',
      gender: parseGender(parsedJson['gender']),
      birthday: parseDateTime(parsedJson['birthday']),
      age: parsedJson['age'] ?? 0,
      geoPoint: parsedJson['geoPoint'],
      chatInfos: chatInfos,
      profileViewers: List<String>.from(parsedJson['profileViewers'] ?? []),
      comments: parseComments(parsedJson['comments']),
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
      'userID': userID,
      'appIdentifier': appIdentifier,
      'average': average,
      'events': events,
      'verification': verification,
      'isPremium': isPremium,
      'country': country,
      'city': city,
      'district': district,
      'blockUsers': blockUsers,
      'profileViewers': profileViewers,
      'gender': gender?.name,
      'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
      'favoriteCategories': favoriteCategories,
      'favoriteAdverts': favoriteAdverts,
      'geoPoint': geoPoint,
      'chatInfos': chatInfos?.map((key, chat) => MapEntry(
            key,
            {
              'chatId': chat.id,
              'lastMessageTime': chat.lastMessageTime,
              'unreadCount': chat.unreadCount,
            },
          )),
      'comments': comments?.map((comment) => comment.toJson()).toList(),
    };
  }

  Customer copyWith({
    String? profilePictureUrl,
    String? email,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? nickname,
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
    GeoPoint? geoPoint,
    Map<String, Chat>? chatInfos,
    List<String>? profileViewers,
    List<Comment>? comments,
  }) {
    return Customer(
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      nickname: nickname ?? this.nickname,
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
      geoPoint: geoPoint ?? this.geoPoint,
      chatInfos: chatInfos ?? this.chatInfos,
      profileViewers: profileViewers ?? this.profileViewers,
      comments: comments ?? this.comments,
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

class Comment {
  String? comment;
  double? rating;
  String? commenterID;
  String? commenterName;
  String? commenterProfilePictureUrl;
  DateTime? commentDate;

  Comment({
    this.comment = '',
    this.rating = 0.0,
    this.commenterID = '',
    this.commenterName = '',
    this.commenterProfilePictureUrl = '',
    this.commentDate,
  });

  factory Comment.fromJson(Map<String, dynamic> parsedJson) {
    try {
      DateTime? parseDateTime(dynamic dateData) {
        if (dateData == null) return null;
        if (dateData is DateTime) return dateData;
        if (dateData is Timestamp) return dateData.toDate();
        return null;
      }

      return Comment(
        comment: parsedJson['comment'] as String? ?? '',
        rating: (parsedJson['rating'] ?? 0.0).toDouble(),
        commenterID: parsedJson['commenterID'] as String? ?? '',
        commenterName: parsedJson['commenterName'] as String? ?? '',
        commenterProfilePictureUrl: parsedJson['commenterProfilePictureUrl'] as String? ?? '',
        commentDate: parseDateTime(parsedJson['commentDate']),
      );
    } catch (e) {
      debugPrint('Comment.fromJson hatası: $e');
      return Comment(); // Hata durumunda boş bir Comment döndür
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'comment': comment,
      'rating': rating,
      'commenterID': commenterID,
      'commenterName': commenterName,
      'commenterProfilePictureUrl': commenterProfilePictureUrl,
      'commentDate': commentDate != null ? Timestamp.fromDate(commentDate!) : null,
    };
  }
}
