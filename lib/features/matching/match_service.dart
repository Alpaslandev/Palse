import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:palseapp/features/matching/match_model.dart';

class MatchService {
  final _firestore = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instance;
  final String uid;

  MatchService({required this.uid});

  /// Kullanıcının eşleştiği kişileri getirir
  Future<List<MatchModel>> getMatches() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('matches')
        .orderBy('matchedAt', descending: true)
        .get();

    return snapshot.docs.map(MatchModel.fromDoc).toList();
  }

  /// Bu haftaki eşleşme sayısını getirir
  Future<int> getWeeklyMatchCount() async {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final snapshot = await _firestore
        .collection('users')
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
        .collection('users')
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
      final List matches = result.data['matches'];
      return List<MatchModel>.from(matches);
    } catch (e) {
      rethrow;
    }
  }
}
