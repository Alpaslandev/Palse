import 'package:flutter/material.dart';
import 'package:palseapp/features/matching/match_model.dart';
import 'package:palseapp/features/matching/match_service.dart';

// Eşleşme görünümünün durumunu ve iş mantığını yönetir.
class MatchViewModel extends ChangeNotifier {
  late final MatchService _matchService;

  MatchViewModel({required String uid}) {
    _matchService = MatchService(uid: uid);
    initialize();
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isMatching = false;
  bool get isMatching => _isMatching;

  List<MatchModel> _matches = [];
  List<MatchModel> get matches => _matches;

  DateTime? _nextMatchDate;
  DateTime? get nextMatchDate => _nextMatchDate;

  bool get canMatch => _nextMatchDate == null;

  // İlk veri yüklemesi için kullanılır.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await _fetchData();

    _isLoading = false;
    notifyListeners();
  }

  // Verileri yeniden çeker. RefreshIndicator için.
  Future<void> refresh() async {
    await _fetchData();
    notifyListeners();
  }

  // Asıl veri çekme mantığı
  Future<void> _fetchData() async {
    try {
      _matches = await _matchService.getMatches();
      final hasReachedLimit = await _matchService.hasReachedWeeklyLimit();
      if (hasReachedLimit) {
        _nextMatchDate = await _matchService.getNextMatchDate();
      } else {
        _nextMatchDate = null;
      }
    } catch (e) {
      debugPrint("Error fetching match data: $e");
      // Hata durumunda eşleşmeyi engelle
      _nextMatchDate = DateTime.now().add(const Duration(days: 999));
    }
  }

  // Yeni eşleşmeler bulmak için Cloud Function'ı tetikler.
  Future<void> findNewMatches() async {
    _isMatching = true;
    notifyListeners();
    try {
      await _matchService.triggerSmartMatch();
      await _fetchData(); // Eşleşme sonrası verileri yenile
    } catch (e) {
      debugPrint("Error triggering smart match: $e");
    } finally {
      _isMatching = false;
      notifyListeners();
    }
  }
}
