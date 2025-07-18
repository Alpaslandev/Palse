import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/features/matching/match_model.dart';

class MatchService {
  final _firestore = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instance;
  final String uid;

  MatchService({required this.uid});

  /// Kullanıcının eşleştiği kişileri getirir
  Future<List<MatchModel>> getMatches() async {
    final snapshot = await _firestore
        .collection('customers')
        .doc(uid)
        .collection('matches')
        .orderBy('matchedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => MatchModel.fromJson(doc.data())).toList();
  }

  /// Bu haftaki eşleşme sayısını getirir
  Future<int> getWeeklyMatchCount() async {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final snapshot = await _firestore
        .collection('customers')
        .doc(uid)
        .collection('matches')
        .where('matchedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monday))
        .get();

    return snapshot.docs.length;
  }

  /// Haftalık sınır dolmuş mu?
  Future<bool> hasReachedWeeklyLimit({int limit = 5}) async {
    final count = await getWeeklyMatchCount();
    return count >= limit;
  }

  /// Bir sonraki eşleşme hakkı ne zaman olacak?
  Future<DateTime?> getNextMatchDate({int limit = 5}) async {
    final snapshot = await _firestore
        .collection('customers')
        .doc(uid)
        .collection('matches')
        .orderBy('matchedAt', descending: true)
        .limit(limit)
        .get();

    if (snapshot.docs.length < limit) return null;

    final lastMatch =
        (snapshot.docs.last.data()['matchedAt'] as Timestamp).toDate();
    final nextMonday = DateTime(lastMatch.year, lastMatch.month, lastMatch.day)
        .add(Duration(days: 7 - lastMatch.weekday));

    return nextMonday;
  }

  /// Smart Match Cloud Function'ı tetikler (eşleştirme yapar)
  Future<List<MatchModel>> triggerSmartMatch() async {
    try {
      final callable = _functions.httpsCallable('getSmartMatches');
      final result = await callable();

      // Gelen yanıtı terminalde görmek için print ifadesi
      debugPrint("--- RAW RESPONSE FROM getSmartMatches ---");
      debugPrint("result.data type: ${result.data.runtimeType}");
      debugPrint("result.data: ${result.data}");

      if (result.data is Map) {
        debugPrint("result.data keys: ${(result.data as Map).keys}");
        debugPrint("result.data values: ${(result.data as Map).values}");
      }
      debugPrint("---------------------------------------");

      // Gelen 'matches' listesini alıyoruz.
      final List<dynamic> matchesData = result.data['matches'];
      // Her bir map elemanını MatchModel.fromJson kullanarak MatchModel nesnesine çeviriyoruz.
      return matchesData
          .map((data) => MatchModel.fromJson(Map<String, dynamic>.from(data)))
          .toList();
    } catch (e) {
      debugPrint("Error triggering smart match: $e");
      rethrow;
    }
  }
}
