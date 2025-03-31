import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportType {
  inappropriateContent,
  inappropriateImages,
  inappropriateProfile,
  inappropriateAdvert,
  inappropriateComment,
  inappropriateMessage,
}

class Report {
  final String reportedUserId;
  final String reporterUserId;
  final String reportType;
  final String description;
  final String createdAt;

  Report({
    required this.reportedUserId,
    required this.reporterUserId,
    required this.reportType,
    required this.description,
    required this.createdAt,
  });

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

  Future<void> blockUser(String userId, {required String currentUserId}) async {
    await _firestore.collection('customers').doc(currentUserId).update({
      'blockUsers': FieldValue.arrayUnion([userId])
    });
  }

  Future<void> unblockUser(String userId, {required String currentUserId}) async {
    await _firestore.collection('customers').doc(currentUserId).update({
      'blockUsers': FieldValue.arrayRemove([userId])
    });
  }
}
