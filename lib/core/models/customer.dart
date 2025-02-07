import 'package:cloud_firestore/cloud_firestore.dart';

enum Gender {
  Male,
  Female,
  Others,
}

class Customer {
  String profilePictureUrl;
  String email;
  String phoneNumber;
  String firstName;
  String lastName;
  String userID;
  String appIdentifier;
  int? coins;
  List<String> adverts;
  bool verification;
  bool isPremium;
  String? city;
  String? district;
  Gender gender;
  String birthday;
  List<double> userReview;
  double average;
  List<String> userReviewUUIDs;
  List<String> messagefriends;
  List<String> userComments;
  List<String> userCommentsDate;
  List<String> userCommentUUIDs;
  List<String> commenderUrl;
  List<String> commenderFullName;
  int age;
  GeoPoint? geoPoint;
  List<String> favoriteCategories;
  List<String> blockUsers;
  List<String> favoriteAdverts;
  bool firstNotification;

  Customer({
    this.profilePictureUrl = '',
    this.email = '',
    this.phoneNumber = '',
    this.firstName = '',
    this.lastName = '',
    this.userID = '',
    this.coins = 10,
    this.average = 0.0,
    this.firstNotification = false,
    this.userReview = const [],
    this.userReviewUUIDs = const [],
    this.favoriteCategories = const [],
    this.adverts = const [],
    this.blockUsers = const [],
    this.verification = false,
    this.isPremium = false,
    this.city = '',
    this.district = '',
    this.gender = Gender.Others,
    this.birthday = '',
    this.age = 18,
    this.messagefriends = const [],
    this.userComments = const [],
    this.userCommentsDate = const [],
    this.userCommentUUIDs = const [],
    this.commenderFullName = const [],
    this.commenderUrl = const [],
    this.geoPoint,
    this.favoriteAdverts = const [],
  }) : appIdentifier = 'Customer App';

  String fullName() => '$firstName $lastName';

  factory Customer.fromJson(Map<String, dynamic> parsedJson) {
    return Customer(
      profilePictureUrl: parsedJson['profilePictureUrl'],
      email: parsedJson['email'] ?? '',
      phoneNumber: parsedJson['phoneNumber'] ?? '',
      firstName: parsedJson['firstName'] ?? '',
      lastName: parsedJson['lastName'] ?? '',
      userID: parsedJson['id'] ?? parsedJson['userID'] ?? '',
      coins: parsedJson['coins'] ?? 10,
      // average: parsedJson['average'] ?? 0.0,
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
      adverts: List<String>.from(parsedJson['usedCampaigns'] ?? []),
      verification: parsedJson['verification'] ?? false,
      isPremium: parsedJson['isPremium'] ?? false,
      firstNotification: parsedJson['firstNotification'] ?? false,

      city: parsedJson['city'] ?? '',
      district: parsedJson['district'] ?? '',
      gender: parseGender(parsedJson['gender']),
      birthday: parsedJson['birthday'] ?? '',
      age: parsedJson['age'] ?? '',
      messagefriends: List<String>.from(parsedJson['messageFriends'] ?? []),
      geoPoint: parsedJson['geoPoint'] != null
          ? GeoPoint(
              parsedJson['geoPoint'].latitude,
              parsedJson['geoPoint'].longitude,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profilePictureUrl': profilePictureUrl,
      'email': email,
      'phoneNumber': phoneNumber,
      'firstName': firstName,
      'lastName': lastName,
      'id': userID,
      'appIdentifier': appIdentifier,
      'coins': coins,
      'average': average,
      'userReview': userReview,
      'userReviewUUIDs': userReviewUUIDs,
      'adverts': adverts,
      'verification': verification,
      'isPremium': isPremium,
      'firstNotification': firstNotification,
      'city': city,
      'blockUsers': blockUsers,
      'district': district,
      'gender': gender.toString().split('.').last,
      'birthday': birthday,
      'age': age,
      'favoriteCategories': favoriteCategories,
      'favoriteAdverts': favoriteAdverts,
      'messageFriends': messagefriends,
      'userCommentUUIDs': userCommentUUIDs,
      'userCommentsDate': userCommentsDate,
      'userComments': userComments,
      'commenderUrl': commenderUrl,
      'commenderFullName': commenderFullName,
      'geoPoint': geoPoint != null ? {'latitude': geoPoint!.latitude, 'longitude': geoPoint!.longitude} : null,
    };
  }

  static Gender parseGender(String value) {
    switch (value) {
      case 'Male':
        return Gender.Male;
      case 'Female':
        return Gender.Female;
      case 'Others':
        return Gender.Others;
      default:
        return Gender.Others;
    }
  }

  static List<String> getAllGenders() {
    return Gender.values.map((gender) => gender.name).toList();
  }

  factory Customer.empty() {
    return Customer(
      messagefriends: [],
    );
  }
}
