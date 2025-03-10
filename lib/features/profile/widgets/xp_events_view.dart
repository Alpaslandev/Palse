import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/features/achievement/achievements.dart';
import 'package:provider/provider.dart';

class XpEventsView extends StatelessWidget {
  const XpEventsView({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthProvider'ı kullan
    final authProvider = Provider.of<AuthProvider>(context);

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
                _buildUserLevelCard(context, authProvider),
                const SizedBox(height: 16),
                // Unvanlar kartı
                _buildRanksCard(context),
                const SizedBox(height: 16),
                // XP kazanma yolları
                ...XpEventGroup.values.map((group) => Column(
                      children: [
                        _buildEventCard(context, group, group.events, authProvider),
                        const SizedBox(height: 16),
                      ],
                    )),
              ],
            ),
    );
  }

  // Kullanıcı seviye kartı
  Widget _buildUserLevelCard(BuildContext context, AuthProvider authProvider) {
    final rank = authProvider.userRank;
    final currentXp = authProvider.user!.totalXp;

    // İlerleme yüzdesi hesaplama
    double progressPercentage = 0.0;
    if (rank == UserRank.master) {
      progressPercentage = 1.0;
    } else {
      final minXp = rank.minXp;
      final maxXp = rank.maxXp as int;
      progressPercentage = ((currentXp - minXp) / (maxXp - minXp)).clamp(0.0, 1.0);
    }

    // Bir sonraki seviyeye kalan XP
    int xpToNextRank = 0;
    if (rank != UserRank.master) {
      final maxXp = rank.maxXp as int;
      xpToNextRank = maxXp - currentXp + 1;
    }

    return Card(
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
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    rank.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(rank.titleKey),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${context.tr('total_xp')}: $currentXp',
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
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressPercentage,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              rank == UserRank.master ? context.tr('max_level_reached') : '${context.tr('next_level')}: $xpToNextRank XP',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '${context.tr('premium_rewards')}: ${authProvider.getEarnedPremiumRewardCount()}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.hourglass_empty, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '${context.tr('next_reward')}: ${authProvider.getXpToNextPremium()} XP',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
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

  Widget _buildEventCard(BuildContext context, XpEventGroup group, List<XpEvent> events, AuthProvider authProvider) {
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
              final completionCount = authProvider.getTaskCompletionCount(event);

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
