import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/features/achievement/achievement_service.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/features/achievement/achievements.dart';
import 'package:palseapp/features/achievement/premium_rewards.dart';
import 'package:provider/provider.dart';

class XpEventsView extends StatelessWidget {
  const XpEventsView({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthProvider'ı kullan
    final authProvider = Provider.of<AuthProvider>(context);
    // AchievementService'i doğrudan oluştur
    final achievementService = Provider.of<AchievementService>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('xp_system')),
      ),
      body: authProvider.user == null
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              children: [
                // Kullanıcı seviye bilgileri
                _xpAndLevel(authProvider, context, achievementService),
                const SizedBox(height: 16),
                // Unvanlar kartı
                _buildRanksCard(context),
                const SizedBox(height: 16),
                // XP kazanma yolları
                ...XpEventGroup.values.map((group) => Column(
                      children: [
                        _buildEventCard(context, group, group.events, authProvider, achievementService),
                        const SizedBox(height: 16),
                      ],
                    )),
              ],
            ),
    );
  }

  Widget _xpAndLevel(AuthProvider authProvider, BuildContext context, AchievementService achievementService) {
    // Kullanıcının unvanını hesapla
    final userId = authProvider.user!.userID!;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<UserRank>(
                future: achievementService.getUserRank(userId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final userRank = snapshot.data!;

                  return Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: userRank.color,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          userRank.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${context.tr('rank')}: ${achievementService.getLocalizedRankTitle(userRank, context)}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            FutureBuilder<int>(
                                future: achievementService.getUserXp(userId),
                                builder: (context, xpSnapshot) {
                                  return Text(
                                    '${context.tr('total_xp')}: ${xpSnapshot.data ?? 0}',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  );
                                }),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
            const SizedBox(height: 16),
            Text(
              context.tr('level_progress'),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            FutureBuilder<double>(
                future: achievementService.getXpToNextRankPercentage(userId),
                builder: (context, progressSnapshot) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progressSnapshot.data ?? 0.0,
                      minHeight: 10,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  );
                }),
            const SizedBox(height: 8),
            FutureBuilder<int>(
                future: achievementService.getXpToNextRank(userId),
                builder: (context, xpToNextSnapshot) {
                  return Text(
                    '${context.tr('to_next_level')}: ${xpToNextSnapshot.data ?? 0} XP',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  );
                }),
            Divider(
              height: 24,
              color: Theme.of(context).dividerColor,
            ),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<int>(
                          future: achievementService.getEarnedPremiumRewardCount(userId),
                          builder: (context, premiumSnapshot) {
                            return Text(
                              '${context.tr('earned_premium_rewards')}: ${premiumSnapshot.data ?? 0}',
                              style: Theme.of(context).textTheme.titleMedium,
                            );
                          }),
                      FutureBuilder<int>(
                          future: achievementService.getXpToNextPremium(userId),
                          builder: (context, nextPremiumSnapshot) {
                            return Text(
                              '${context.tr('to_next_premium')}: ${nextPremiumSnapshot.data ?? 0} XP',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            );
                          }),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${context.tr('premium_thresholds')}: ${PremiumRewards.xpThresholds.join(", ")}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  // Unvanlar kartı
  Widget _buildRanksCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('ranks'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('ranks_description'),
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ...UserRank.values.map((rank) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            rank.icon,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(rank.titleKey),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              rank == UserRank.master ? '${rank.minXp}+ XP' : '${rank.minXp} - ${rank.maxXp} XP',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(
      BuildContext context, XpEventGroup group, List<XpEvent> events, AuthProvider authProvider, AchievementService achievementService) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  context.tr(group.titleKey),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  group.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...group.events.map((event) {
              // Görevin kaç kez tamamlandığını kontrol et
              return FutureBuilder<int>(
                  future: achievementService.getTaskCompletionCount(authProvider.user!.userID!, event),
                  builder: (context, snapshot) {
                    final completionCount = snapshot.data ?? 0;

                    // Bu görevden toplam ne kadar XP kazanıldığını hesapla
                    final totalXpFromEvent = event.xpAmount * completionCount;

                    final isCompleted = completionCount > 0;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(
                        '•',
                        style: TextStyle(
                          fontSize: 24,
                          color: isCompleted ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      title: Text(
                        achievementService.getLocalizedTaskDescription(event, context),
                        style: TextStyle(
                          color: isCompleted ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.6),
                          decoration: isCompleted && !event.isRepeatable ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                      ),
                      // Görev tamamlanma sayısı ve toplam kazanılan XP
                      subtitle: completionCount > 0
                          ? Text(
                              '${completionCount}x • $totalXpFromEvent XP ${context.tr('total')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            )
                          : null,
                      // Her görevin sağ tarafında XP değeri
                      trailing: Container(
                        width: 70,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCompleted && !event.isRepeatable ? theme.disabledColor : colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '+${event.xpAmount} XP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  });
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
