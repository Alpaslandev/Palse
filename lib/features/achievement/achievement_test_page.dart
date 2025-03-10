import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/features/achievement/achievements.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/features/achievement/premium_rewards.dart';
import 'package:provider/provider.dart';

/// XP sistemini test etmek için kullanılan sayfa
class AchievementTestPage extends StatefulWidget {
  const AchievementTestPage({Key? key}) : super(key: key);

  @override
  State<AchievementTestPage> createState() => _AchievementTestPageState();
}

class _AchievementTestPageState extends State<AchievementTestPage> {
  @override
  Widget build(BuildContext context) {
    // AuthProvider'ı kullan
    final authProvider = Provider.of<AuthProvider>(context);

    // Kullanıcı henüz yüklenmemişse yükleniyor göster
    if (authProvider.user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final groupedEvents = _getGroupedEvents();

    return Scaffold(
      appBar: AppBar(
        title: const Text('XP Sistemi Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _addCustomXp(authProvider),
            tooltip: 'Özel XP Ekle',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _resetAllXp(authProvider),
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
                          color: authProvider.userRank.getRankColor(),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          authProvider.userRank.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unvan: ${authProvider.userRank.getLocalizedTitle(context)}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              'Toplam XP: ${authProvider.user!.totalXp}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Seviye İlerlemesi:'),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _calculateProgress(authProvider),
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      color: authProvider.userRank.getRankColor(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Bir sonraki seviyeye: ${_xpToNextRank(authProvider)} XP'),
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
                              'Premium Ödüller: ${authProvider.getEarnedPremiumRewardCount()}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Bir sonraki premium ödüle: ${authProvider.getXpToNextPremium()} XP'),
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
                for (final entry in groupedEvents.entries) _buildEventGroup(entry.key, entry.value, authProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Özel XP ekleme dialog'u
  void _addCustomXp(AuthProvider authProvider) {
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
                authProvider.earnCustomXp(amount);
                Navigator.pop(context);
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  // Tüm XP'yi sıfırlama dialog'u
  void _resetAllXp(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('XP Sıfırla'),
          content: const Text('Henüz bu işlev desteklenmiyor. Yeni sürümde eklenecektir.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  // İlerleme çubuğu için değer hesaplama
  double _calculateProgress(AuthProvider authProvider) {
    final rank = authProvider.userRank;
    final totalXp = authProvider.user!.totalXp;

    if (rank == UserRank.master) {
      return 1.0; // En üst seviye için %100
    }

    final minXp = rank.minXp;
    final maxXp = rank.maxXp as int;

    return ((totalXp - minXp) / (maxXp - minXp)).clamp(0.0, 1.0);
  }

  // Bir sonraki seviyeye kalan XP hesaplama
  int _xpToNextRank(AuthProvider authProvider) {
    final rank = authProvider.userRank;
    final totalXp = authProvider.user!.totalXp;

    if (rank == UserRank.master) {
      return 0;
    }

    final maxXp = rank.maxXp as int;
    return maxXp - totalXp + 1;
  }

  // Görevleri gruplarına göre düzenle
  Map<XpEventGroup, List<XpEvent>> _getGroupedEvents() {
    final map = <XpEventGroup, List<XpEvent>>{};

    for (final group in XpEventGroup.values) {
      map[group] = group.events;
    }

    return map;
  }

  // Görev grubu widget'ı
  Widget _buildEventGroup(XpEventGroup group, List<XpEvent> events, AuthProvider authProvider) {
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
            for (final event in events) _buildEventButton(event, authProvider),
          ],
        ),
      ),
    );
  }

  // Görev butonu widget'ı
  Widget _buildEventButton(XpEvent event, AuthProvider authProvider) {
    final isCompleted = authProvider.isTaskCompleted(event);
    final completionCount = authProvider.getTaskCompletionCount(event);
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
                    context.tr(event.descriptionKey),
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
                  : () => authProvider.earnXp(event),
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
