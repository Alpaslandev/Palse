class StoryModel {
  final String id;
  final String userId;
  final String username;
  final String profilePictureUrl;
  final String imageUrl;
  final String createdAt;
  final List<String> viewedBy;
  final bool isPublic;

  StoryModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.profilePictureUrl,
    required this.imageUrl,
    required this.createdAt,
    required this.viewedBy,
    required this.isPublic,
  });

  // Firestore'dan veri okumak için
  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      profilePictureUrl: json['profilePictureUrl'] as String,
      imageUrl: json['imageUrl'] as String,
      createdAt: json['createdAt'] as String,
      viewedBy: List<String>.from(json['viewedBy'] as List),
      isPublic: json['isPublic'] as bool,
    );
  }

  // Firestore'a veri yazmak için
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'profilePictureUrl': profilePictureUrl,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'viewedBy': viewedBy,
      'isPublic': isPublic,
    };
  }
}
