import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/features/achievement/achievements.dart';
import 'package:palseapp/features/achievement/user_achievements.dart';

class XpEventsView extends StatelessWidget {
  final UserAchievements? userAchievements;

  const XpEventsView({
    super.key,
    this.userAchievements,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('xp_system')),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: [
          // Unvanlar kartı
          _buildRanksCard(context),
          const SizedBox(height: 16),
          // XP kazanma yolları
          ...XpEventGroup.values.map((group) => Column(
                children: [
                  _buildEventCard(context, group, group.events),
                  const SizedBox(height: 16),
                ],
              )),
        ],
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

  Widget _buildEventCard(BuildContext context, XpEventGroup group, List<XpEvent> events) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              context.tr(group.titleKey),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            ...group.events.map((event) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '• ${context.tr(event.descriptionKey)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  subtitle: Text(
                    '${userAchievements?.getTotalXpFromEvent(event) ?? 0} XP',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  trailing: Container(
                    width: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('+${event.xpAmount} XP', style: const TextStyle(color: Colors.white)),
                  ),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
