import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportType {
  inappropriateContent,
  inappropriateLanguage,
  inappropriateImages,
  inappropriateVideos,
  inappropriateProfile,
  inappropriateAdvert,
  inappropriateComment,
  inappropriateMessage,
  inappropriateNotification,
  inappropriateOther,
}

class Report {
  String? id;
  final String reportedUserId;
  final String reporterUserId;
  final String reportType;
  final String description;
  final String createdAt;

  Report(
      {this.id,
      required this.reportedUserId,
      required this.reporterUserId,
      required this.reportType,
      required this.description,
      required this.createdAt});

  factory Report.fromJson(Map<String, dynamic> json, String id) {
    return Report(
        id: id,
        reportedUserId: json['reportedUserId'],
        reporterUserId: json['reporterUserId'],
        reportType: json['reportType'],
        description: json['description'],
        createdAt: json['createdAt']);
  }

  Map<String, dynamic> toJson() {
    return {
      'reportedUserId': reportedUserId,
      'reporterUserId': reporterUserId,
      'reportType': reportType,
      'description': description,
      'createdAt': createdAt,
    };
  }
}

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createReport(Report report) async {
    await _firestore.collection('reports').doc().set(report.toJson());
  }

  Future<void> blockUser(String userId) async {
    await _firestore.collection('customers').doc(userId).update({
      'blockUsers': FieldValue.arrayUnion([userId])
    });
  }

  Future<void> unblockUser(String userId) async {
    await _firestore.collection('customers').doc(userId).update({
      'blockUsers': FieldValue.arrayRemove([userId])
    });
  }
}
