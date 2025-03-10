import 'package:flutter/material.dart';
import 'package:palseapp/features/achievement/achievements.dart';
import 'package:palseapp/features/achievement/achievement_manager.dart';
import 'package:palseapp/features/achievement/premium_rewards.dart';

/// XP sistemini test etmek için kullanılan sayfa
class AchievementTestPage extends StatefulWidget {
  const AchievementTestPage({Key? key}) : super(key: key);

  @override
  State<AchievementTestPage> createState() => _AchievementTestPageState();
}

class _AchievementTestPageState extends State<AchievementTestPage> with XpInterface {
  // Kullanıcı başarılarının durumunu alma
  UserAchievements get _achievements => AchievementManager().userAchievements;

  @override
  void initState() {
    super.initState();

    // Dinleyici ekle
    AchievementManager().addListener(_onAchievementsChanged);

    // Eğer gerekirse günlük görev zamanlayıcısını başlat
    DailyTaskScheduler().startScheduler();
  }

  @override
  void dispose() {
    // Dinleyiciyi kaldır
    AchievementManager().removeListener(_onAchievementsChanged);
    super.dispose();
  }

  // XP değişikliklerinde çağrılacak metod
  void _onAchievementsChanged(UserAchievements achievements) {
    setState(() {
      // UI'ı güncelle
    });
  }

  // Test için özel XP ekleme metodu
  void _addCustomXp() {
    // Dialog göster
    showDialog(
      context: context,
      builder: (context) {
        int amount = 100; // Varsayılan değer

        return AlertDialog(
          title: const Text('Özel XP Ekle'),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'XP Miktarı',
            ),
            onChanged: (value) {
              amount = int.tryParse(value) ?? 100;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                AchievementManager().earnCustomXp(amount);
                Navigator.pop(context);
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  // Görevleri gruplarına göre düzenle
  Map<XpEventGroup, List<XpEvent>> _getGroupedEvents() {
    final map = <XpEventGroup, List<XpEvent>>{};

    for (final group in XpEventGroup.values) {
      map[group] = group.events;
    }

    return map;
  }

  // Tüm XP'yi sıfırla
  void _resetAllXp() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('XP Sıfırla'),
          content: const Text('Tüm XP ve görev durumları sıfırlanacak. Bu işlem geri alınamaz! Devam etmek istiyor musunuz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                // Boş bir UserAchievements ile başlat
                AchievementManager().initialize(UserAchievements());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('XP ve görevler sıfırlandı')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sıfırla'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedEvents = _getGroupedEvents();

    return Scaffold(
      appBar: AppBar(
        title: const Text('XP Sistemi Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _addCustomXp,
            tooltip: 'Özel XP Ekle',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetAllXp,
            tooltip: 'XP Sıfırla',
          ),
        ],
      ),
      body: Column(
        children: [
          // Kullanıcı XP ve seviye bilgileri
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _getRankColor(_achievements.rank),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _achievements.rank.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unvan: ${_achievements.rank.getLocalizedTitle(context)}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              'Toplam XP: ${_achievements.totalXp}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Seviye İlerlemesi: ${(_achievements.progressPercentage * 100).toStringAsFixed(1)}%'),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _achievements.progressPercentage,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      color: _getRankColor(_achievements.rank),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Bir sonraki seviyeye: ${_achievements.xpToNextRank} XP'),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Premium Ödüller: ${_achievements.earnedPremiumRewards}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Bir sonraki premium ödüle: ${_achievements.xpToNextPremium} XP'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Premium Eşikler: ${PremiumRewards.getPremiumThresholds(50000).join(", ")}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          // Görevlerin listesi
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final entry in groupedEvents.entries) _buildEventGroup(entry.key, entry.value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Görev grubu widget'ı
  Widget _buildEventGroup(XpEventGroup group, List<XpEvent> events) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  group.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  group.getLocalizedTitle(context),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final event in events) _buildEventButton(event),
          ],
        ),
      ),
    );
  }

  // Görev butonu widget'ı
  Widget _buildEventButton(XpEvent event) {
    final isCompleted = _achievements.isTaskCompleted(event);
    final completionCount = _achievements.getTaskCompletionCount(event);
    final isDailyTask = event.isDaily;

    // Butonun rengini belirleme
    Color buttonColor = isDailyTask
        ? isCompleted
            ? Colors.orange.shade200 // Tamamlanmış günlük görev
            : Colors.orange // Tamamlanmamış günlük görev
        : isCompleted && !event.isRepeatable
            ? Colors.grey.shade400 // Tamamlanmış tekrarlanamaz görev
            : _getEventGroupColor(event); // Diğer görevler için grup rengini kullan

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: isCompleted ? Colors.grey.shade100 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isCompleted ? Colors.grey.shade300 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.circle_outlined,
              color: isCompleted ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.description,
                    style: TextStyle(
                      fontWeight: isCompleted ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${event.xpAmount} XP · Tamamlama: $completionCount',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: isCompleted && !event.isRepeatable
                  ? null // Tamamlanmış ve tekrarlanamaz görevleri devre dışı bırak
                  : () => earnXp(event),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                isCompleted && !event.isRepeatable ? 'Tamamlandı' : 'Tamamla',
                style: TextStyle(
                  color: isCompleted && !event.isRepeatable ? Colors.grey.shade700 : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Rank rengini döndüren yardımcı metod
  Color _getRankColor(UserRank rank) {
    switch (rank) {
      case UserRank.beginner:
        return Colors.blue.shade300;
      case UserRank.explorer:
        return Colors.green.shade400;
      case UserRank.connector:
        return Colors.amber.shade600;
      case UserRank.leader:
        return Colors.orange.shade600;
      case UserRank.master:
        return Colors.purple.shade600;
    }
  }

  // Görev grubunun rengini döndüren yardımcı metod
  Color _getEventGroupColor(XpEvent event) {
    if (!event.isRepeatable) {
      return Colors.purple; // Hoş geldin ödülleri için mor
    } else if (event == XpEvent.createListing || event == XpEvent.receiveMessage) {
      return Colors.blue.shade700; // İlan verme için mavi
    } else if (event == XpEvent.sendMessage) {
      return Colors.green.shade600; // Mesajlaşma için yeşil
    } else if (event == XpEvent.writeComment || event == XpEvent.receiveComment) {
      return Colors.teal.shade600; // Yorumlar için teal
    }
    return Colors.indigo; // Varsayılan
  }
}
