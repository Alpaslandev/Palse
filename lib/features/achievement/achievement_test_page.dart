import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/services/achievement_service.dart';
import 'package:palseapp/features/achievement/achievements.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:provider/provider.dart';

/// XP sistemini test etmek için kullanılan sayfa
class AchievementTestPage extends StatefulWidget {
  const AchievementTestPage({Key? key}) : super(key: key);

  @override
  State<AchievementTestPage> createState() => _AchievementTestPageState();
}

class _AchievementTestPageState extends State<AchievementTestPage> {
  // XP sıfırlama işlemi
  Future<void> _resetAllXp(AuthProvider authProvider) async {
    if (authProvider.user?.userID == null) return;

    // Toplam XP'yi sıfırla
    await AchievementSystem.saveTotalXp(authProvider.user!.userID!, 0);

    // Tamamlanan görevleri sıfırla
    await AchievementSystem.saveCompletedTasks(authProvider.user!.userID!, {});

    // Günlük görevlerin son tarihini sıfırla
    await AchievementSystem.saveLastDailyTaskDate(authProvider.user!.userID!, null);

    // Kullanıcıyı güncelle
    final updatedUser = authProvider.user!.copyWith(
      totalXp: 0,
      completedTasks: {},
      lastDailyTaskDate: null,
    );

    // AuthProvider'a güncellemeyi bildir
    authProvider.updateUser(updatedUser);

    // Ekranı yenile
    setState(() {});
  }

  // Görev tamamlama işlemi
  Future<void> _completeTask(String taskName, AuthProvider authProvider, AchievementService achievementService) async {
    if (authProvider.user == null) return;

    // XP kazan
    final updatedUser = await achievementService.earnXp(user: authProvider.user!, taskName: taskName);

    // AuthProvider'a güncellemeyi bildir
    authProvider.updateUser(updatedUser);

    // Ekranı yenile
    setState(() {});
  }

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

    // Tüm görev gruplarını al
    final taskGroups = achievementService.getAllTaskGroups();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('xp_system_test')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _resetAllXp(authProvider),
            tooltip: context.tr('reset_xp'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Kullanıcı XP ve seviye bilgileri
          _buildUserXpCard(authProvider, achievementService, context),

          // Görev grupları
          Expanded(
            child: ListView.builder(
              itemCount: taskGroups.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final groupKey = taskGroups.keys.elementAt(index);
                final tasks = taskGroups[groupKey] ?? [];
                final emoji = achievementService.getGroupEmoji(groupKey);

                return _buildTaskGroupCard(
                  context: context,
                  groupKey: groupKey,
                  tasks: tasks,
                  emoji: emoji,
                  authProvider: authProvider,
                  achievementService: achievementService,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Kullanıcı XP kartı
  Widget _buildUserXpCard(AuthProvider authProvider, AchievementService achievementService, BuildContext context) {
    final user = authProvider.user!;
    final rank = achievementService.getUserRank(user.totalXp);
    final Color rankColor = (rank['color'] as Color?) ?? Colors.blue;

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
                    color: rankColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    rank['icon'] as String? ?? '🌟',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${context.tr('rank')}: ${context.tr(rank['titleKey'] as String? ?? 'rank_beginner')}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${context.tr('total_xp')}: ${user.totalXp}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(context.tr('level_progress')),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: achievementService.getRankProgressPercentage(user.totalXp),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(rankColor),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    const TextSpan(text: 'XP: '),
                    TextSpan(
                      text: '${user.totalXp}',
                      style: TextStyle(color: rankColor, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: ' / ${achievementService.getXpToNextRank(user.totalXp) + user.totalXp}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('${context.tr('premium_rewards')}: ${achievementService.getPremiumRewardsCount(user.totalXp)}'),
            const SizedBox(height: 4),
            Text('${context.tr('next_premium_in')}: ${achievementService.getXpToNextPremium(user.totalXp)} XP'),
          ],
        ),
      ),
    );
  }

  // Görev grubu kartı
  Widget _buildTaskGroupCard({
    required BuildContext context,
    required String groupKey,
    required List<String> tasks,
    required String emoji,
    required AuthProvider authProvider,
    required AchievementService achievementService,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grup başlığı
            Row(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  context.tr(groupKey),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Görevler
            ...tasks
                .map((taskName) => _buildTaskButton(
                      context: context,
                      taskName: taskName,
                      xpAmount: achievementService.getTaskXpValue(taskName),
                      authProvider: authProvider,
                      achievementService: achievementService,
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  // Görev butonu
  Widget _buildTaskButton({
    required BuildContext context,
    required String taskName,
    required int xpAmount,
    required AuthProvider authProvider,
    required AchievementService achievementService,
  }) {
    return FutureBuilder<bool>(
      future: achievementService.isTaskCompleted(authProvider.user!, taskName),
      builder: (context, snapshot) {
        final isCompleted = snapshot.data ?? false;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: isCompleted ? Colors.white : null,
              backgroundColor: isCompleted ? Colors.green : null,
              minimumSize: const Size(double.infinity, 44),
            ),
            onPressed: isCompleted
                ? null // Tamamlanmışsa devre dışı bırak (zaten rengi yeşil)
                : () => _completeTask(taskName, authProvider, achievementService),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(context.tr(taskName)),
                ),
                Row(
                  children: [
                    Text('+$xpAmount XP'),
                    if (isCompleted) const Icon(Icons.check, color: Colors.white),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
