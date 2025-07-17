import 'package:cloud_firestore/cloud_firestore.dart';

class MatchModel {
  final String uid;
  final String name;
  final String? photoUrl;
  final int score;
  final DateTime matchedAt;

  MatchModel({
    required this.uid,
    required this.name,
    required this.score,
    required this.matchedAt,
    this.photoUrl,
  });

  factory MatchModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchModel(
      uid: doc.id,
      name: data['name'] ?? 'Bilinmeyen',
      photoUrl: data['photoUrl'],
      score: data['score'] ?? 0,
      matchedAt: (data['matchedAt'] as Timestamp).toDate(),
    );
  }
}
