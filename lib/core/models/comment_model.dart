import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Comment {
  String? comment;
  int? rating;
  String? commenterID;
  String? commenterName;
  String? commenterProfilePictureUrl;
  DateTime? commentDate;

  Comment({
    this.comment = '',
    this.rating = 0,
    this.commenterID = '',
    this.commenterName = '',
    this.commenterProfilePictureUrl = '',
    this.commentDate,
  });

  factory Comment.fromJson(Map<String, dynamic> parsedJson) {
    try {
      return Comment(
        comment: parsedJson['comment'] as String? ?? '',
        rating: parsedJson['rating'] as int? ?? 0,
        commenterID: parsedJson['commenterID'] as String? ?? '',
        commenterName: parsedJson['commenterName'] as String? ?? '',
        commenterProfilePictureUrl: parsedJson['commenterProfilePictureUrl'] as String? ?? '',
        commentDate: (parsedJson['commentDate'] as Timestamp).toDate(),
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
      'commentDate': Timestamp.fromDate(commentDate ?? DateTime.now()),
    };
  }

  @override
  String toString() {
    return 'Comment(comment: $comment, rating: $rating, commenterID: $commenterID, commenterName: $commenterName, commenterProfilePictureUrl: $commenterProfilePictureUrl, commentDate: $commentDate)';
  }
}
