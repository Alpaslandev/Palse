import 'package:flutter/material.dart';
import 'package:palseapp/features/achievement/achievement_manager.dart';
import 'package:palseapp/features/achievement/xp_events.dart';
import 'package:palseapp/features/achievement/user_rank.dart';

/// AchievementManager kullanım örneği
class AchievementExample extends StatefulWidget {
  const AchievementExample({Key? key}) : super(key: key);

  @override
  State<AchievementExample> createState() => _AchievementExampleState();
}

class _AchievementExampleState extends State<AchievementExample> {
  final AchievementManager _achievementManager = AchievementManager();
  String _userId = ''; // Kullanıcı ID'si
  int _userXp = 0;
  UserRank _userRank = UserRank.beginner;
  double _rankProgress = 0.0;
  int _xpToNextRank = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Kullanıcı verilerini yükler
  Future<void> _loadUserData() async {
    // Gerçek uygulamada kullanıcı ID'si oturum açma işleminden alınır
    _userId = 'test_user_id';

    // Kullanıcının XP değerini getir
    _userXp = await _achievementManager.getUserXp(_userId);

    // Kullanıcının rütbesini hesapla
    _userRank = _achievementManager.getUserRank(_userXp);

    // Rütbe ilerleme yüzdesini hesapla
    _rankProgress = _achievementManager.getRankProgressPercentage(_userXp);

    // Bir sonraki rütbeye geçmek için gereken XP miktarını hesapla
    _xpToNextRank = _achievementManager.getXpToNextRank(_userXp);

    setState(() {});
  }

  /// XP kazanma örneği
  Future<void> _earnXpForEvent(XpEvent event) async {
    // XP kazandır
    final newXp = await _achievementManager.earnXpForEvent(_userId, event);

    // Kullanıcı verilerini güncelle
    setState(() {
      _userXp = newXp;
      _userRank = _achievementManager.getUserRank(_userXp);
      _rankProgress = _achievementManager.getRankProgressPercentage(_userXp);
      _xpToNextRank = _achievementManager.getXpToNextRank(_userXp);
    });
  }

  /// Günlük görevleri sıfırlama örneği
  Future<void> _resetDailyTasks() async {
    await _achievementManager.resetDailyTasks(_userId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Günlük görevler sıfırlandı')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('XP Sistemi Örneği'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kullanıcı bilgileri
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kullanıcı: $_userId',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toplam XP: $_userXp',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rütbe: ${_achievementManager.getLocalizedRankTitle(_userRank, context)} ${_userRank.icon}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _userRank.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // İlerleme çubuğu
                    LinearProgressIndicator(
                      value: _rankProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(_userRank.color),
                      minHeight: 10,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bir sonraki seviyeye: $_xpToNextRank XP',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // XP kazanma butonları
            Text(
              'XP Kazanma Örnekleri',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Günlük görevler
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Günlük Görevler ${XpEventGroup.dailyTasks.emoji}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    // Günlük görev butonları
                    for (final event in XpEventGroup.dailyTasks.events)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: () => _earnXpForEvent(event),
                          icon: const Icon(Icons.add_circle),
                          label: Text(
                            '${_achievementManager.getLocalizedTaskDescription(event, context)} (+${event.xpAmount} XP)',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _resetDailyTasks,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Günlük görevleri sıfırla'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Diğer görevler
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diğer Görevler',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    // Mesajlaşma görevleri
                    for (final event in XpEventGroup.messaging.events)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: () => _earnXpForEvent(event),
                          icon: const Icon(Icons.message),
                          label: Text(
                            '${_achievementManager.getLocalizedTaskDescription(event, context)} (+${event.xpAmount} XP)',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),

                    // İlan görevleri
                    for (final event in XpEventGroup.listing.events)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: () => _earnXpForEvent(event),
                          icon: const Icon(Icons.post_add),
                          label: Text(
                            '${_achievementManager.getLocalizedTaskDescription(event, context)} (+${event.xpAmount} XP)',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
