import 'package:cloud_firestore/cloud_firestore.dart';

class MatchModel {
  final String uid; // Burası 'uid' olarak kalmalı
  final String? name;
  final String? photoUrl;
  final int score;
  final DateTime matchedAt;

  MatchModel({
    required this.uid, // Constructor 'uid' bekliyor
    this.name,
    this.photoUrl,
    required this.score,
    required this.matchedAt,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      uid: json[
          'matchedUserId'], // Sunucudan gelen 'matchedUserId' 'uid'ye atanır
      name: json['name'],
      photoUrl: json['photoUrl'],
      score: json['score'],
      matchedAt: _parseTimestamp(json['matchedAt']),
    );
  }

  // Cloud Function'dan gelen Timestamp formatını parse etmek için helper metod
  static DateTime _parseTimestamp(dynamic timestampData) {
    if (timestampData is Timestamp) {
      return timestampData.toDate();
    } else if (timestampData is Map) {
      // Cloud Function'dan gelen format: {_seconds: ..., _nanoseconds: ...}
      final seconds = timestampData['_seconds'] as int;
      final nanoseconds = timestampData['_nanoseconds'] as int;
      return Timestamp(seconds, nanoseconds).toDate();
    } else {
      // Fallback: şu anki zaman
      return DateTime.now();
    }
  }
}
