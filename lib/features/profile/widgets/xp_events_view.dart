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

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('xp_system')),
      ),
      body: authProvider.user == null
          ? const Center(child: CircularProgressIndicator())
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
                color: userRank.getRankColor(),
              ),
            ),
            const SizedBox(height: 8),
            Text('Bir sonraki seviyeye: ${achievementService.getXpToNextRank(authProvider.user!.totalXp)} XP'),
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
                        'Premium Ödüller: ${achievementService.getEarnedPremiumRewardCount(authProvider.user!.totalXp)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Bir sonraki premium ödüle: ${achievementService.getXpToNextPremium(authProvider.user!.totalXp)} XP'),
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

  // Unvanlar kartı
  Widget _buildRanksCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('ranks'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('ranks_description'),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
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
                          color: AppTheme.primaryColor.withOpacity(0.1),
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
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              rank == UserRank.master ? '${rank.minXp}+ XP' : '${rank.minXp} - ${rank.maxXp} XP',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
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
                    color: Colors.black,
                  ),
                ),
                title: Text(
                  context.tr(event.descriptionKey),
                  style: TextStyle(
                    fontSize: 14,
                    color: isCompleted ? Colors.black : Colors.grey,
                    decoration: isCompleted && !event.isRepeatable ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
                // Görev tamamlanma sayısı ve toplam kazanılan XP
                subtitle: completionCount > 0
                    ? Text(
                        '${completionCount}x • ${totalXpFromEvent} XP ${context.tr('total')}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      )
                    : null,
                // Her görevin sağ tarafında XP değeri
                trailing: Container(
                  width: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted && !event.isRepeatable ? Colors.grey : AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '+${event.xpAmount} XP',
                    style: const TextStyle(color: Colors.white),
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
