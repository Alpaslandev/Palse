import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/services/achievement_service.dart';
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
    final achievementService = Provider.of<AchievementService>(context);

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
            icon: const Icon(Icons.refresh),
            onPressed: () => _resetAllXp(authProvider),
            tooltip: 'XP Sıfırla',
          ),
        ],
      ),
      body: Column(
        children: [
          // Kullanıcı XP ve seviye bilgileri
          _xpAndLevel(authProvider, context),

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

  Widget _xpAndLevel(AuthProvider authProvider, BuildContext context) {
    final achievementService = Provider.of<AchievementService>(context);
    return Card(
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
                    color: achievementService.getUserRank(authProvider.user!.totalXp).getRankColor(),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    achievementService.getUserRank(authProvider.user!.totalXp).icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unvan: ${achievementService.getUserRank(authProvider.user!.totalXp).getLocalizedTitle(context)}',
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
                value: achievementService.getXpToNextRankPercentage(authProvider.user!.totalXp),
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                color: achievementService.getUserRank(authProvider.user!.totalXp).getRankColor(),
              ),
            ),
            const SizedBox(height: 8),
            Text('Bir sonraki seviyeye: ${AchievementService().getXpToNextRank(authProvider.user!.totalXp)} XP'),
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
                        'Premium Ödüller: ${AchievementService().getEarnedPremiumRewardCount(authProvider.user!.totalXp)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Bir sonraki premium ödüle: ${AchievementService().getXpToNextPremium(authProvider.user!.totalXp)} XP'),
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
              onPressed: () {
                AchievementService().resetUserXp(authProvider.user!.userID!);
                Navigator.pop(context);
              },
              child: const Text('Tamam'),
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
    final achievementService = Provider.of<AchievementService>(context);
    final isCompleted = achievementService.isTaskCompleted(authProvider.user!, event);
    final completionCount = achievementService.getTaskCompletionCount(authProvider.user!, event);
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
                  : () => achievementService.earnXp(user: authProvider.user!, event: event),
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
