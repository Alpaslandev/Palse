import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/services/achievement_service.dart';
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
    final userRank = achievementService.getUserRank(authProvider.user!.totalXp);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                    color: userRank.getRankColor(),
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
                        'Unvan: ${userRank.getLocalizedTitle(context)}',
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        'Toplam XP: ${authProvider.user!.totalXp}',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Seviye İlerlemesi:',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: achievementService.getXpToNextRankPercentage(authProvider.user!.totalXp),
                minHeight: 10,
                backgroundColor: theme.brightness == Brightness.light ? Colors.grey.shade200 : theme.colorScheme.surfaceVariant,
                color: userRank.getRankColor(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bir sonraki seviyeye: ${achievementService.getXpToNextRank(authProvider.user!.totalXp)} XP',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            Divider(
              height: 24,
              color: theme.dividerColor,
            ),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Premium Ödüller: ${achievementService.getEarnedPremiumRewardCount(authProvider.user!.totalXp)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Bir sonraki premium ödüle: ${achievementService.getXpToNextPremium(authProvider.user!.totalXp)} XP',
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Premium Eşikler: ${PremiumRewards.getPremiumThresholds(50000).join(", ")}',
              style: theme.textTheme.bodySmall,
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
              // Görevin kaç kez tamamlandığı bilgisini al
              final completionCount = achievementService.getTaskCompletionCount(authProvider.user!, event);

              // Bu görevden toplam ne kadar XP kazanıldığını hesapla
              final totalXpFromEvent = event.xpAmount * completionCount;

              final isCompleted = completionCount > 0;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(
                  '•',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                title: Text(
                  context.tr(event.descriptionKey),
                  style: TextStyle(
                    fontSize: 14,
                    color: isCompleted ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.6),
                    decoration: isCompleted && !event.isRepeatable ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
                // Görev tamamlanma sayısı ve toplam kazanılan XP
                subtitle: completionCount > 0
                    ? Text(
                        '${completionCount}x • ${totalXpFromEvent} XP ${context.tr('total')}',
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
                  child: Text(
                    '+${event.xpAmount} XP',
                    style: TextStyle(
                      color: isCompleted && !event.isRepeatable ? Colors.white70 : Colors.white,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
