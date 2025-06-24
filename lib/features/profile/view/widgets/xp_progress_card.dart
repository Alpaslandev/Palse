// XP İlerleme kartı
import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/features/achievement/achievement_service.dart';
import 'package:palseapp/features/achievement/user_rank.dart';
import 'package:provider/provider.dart';

class XPProgressCard extends StatelessWidget {
  const XPProgressCard({super.key, required this.onLeaderboardPressed});
  final VoidCallback onLeaderboardPressed;
  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user!.userID!;
    final achievementService = Provider.of<AchievementService>(context, listen: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          spacing: 2,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<UserRank>(
                future: achievementService.getUserRank(userId),
                builder: (context, rankSnapshot) {
                  if (!rankSnapshot.hasData) {
                    return const SizedBox(height: 20);
                  }

                  final rank = rankSnapshot.data!;
                  return Text('${achievementService.getLocalizedRankTitle(rank, context)} ${rank.icon}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ));
                }),
            FutureBuilder<int>(
                future: achievementService.getXpToNextRank(userId),
                builder: (context, xpToNextSnapshot) {
                  if (!xpToNextSnapshot.hasData || xpToNextSnapshot.data! <= 0) {
                    return const SizedBox(height: 4);
                  }

                  return RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(text: context.tr('to_next_level_part1'), style: const TextStyle(color: Colors.grey)),
                        TextSpan(
                          text: '${xpToNextSnapshot.data} XP',
                          style: const TextStyle(color: AppTheme.primaryColor),
                        ),
                        TextSpan(text: context.tr('to_next_level_part2'), style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }),
            FutureBuilder<double>(
                future: achievementService.getXpToNextRankPercentage(userId),
                builder: (context, progressSnapshot) {
                  return LinearProgressIndicator(
                    value: progressSnapshot.data ?? 0.0,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  );
                }),
            FutureBuilder<int>(
                future: Future.wait([achievementService.getUserXp(userId), achievementService.getXpToNextRank(userId)]).then((values) {
                  final totalXp = values[0];
                  final xpToNext = values[1];
                  final maxXp = totalXp + xpToNext;
                  return maxXp;
                }),
                builder: (context, maxXpSnapshot) {
                  return FutureBuilder<int>(
                      future: achievementService.getUserXp(userId),
                      builder: (context, totalXpSnapshot) {
                        if (!totalXpSnapshot.hasData || !maxXpSnapshot.hasData) {
                          return const SizedBox(height: 4);
                        }

                        return Align(
                          alignment: Alignment.bottomRight,
                          child: RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                              children: [
                                TextSpan(
                                  text: '${totalXpSnapshot.data}',
                                  style: const TextStyle(color: AppTheme.primaryColor),
                                ),
                                TextSpan(text: '/${maxXpSnapshot.data}'),
                              ],
                            ),
                          ),
                        );
                      });
                }),
            const SizedBox(height: 8),
            FutureBuilder<int>(
                future: achievementService.getXpToNextPremium(userId),
                builder: (context, xpToNextPremiumSnapshot) {
                  if (!xpToNextPremiumSnapshot.hasData) {
                    return const SizedBox(height: 4);
                  }

                  return RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(text: context.tr('to_next_premium_part1'), style: const TextStyle(color: Colors.grey)),
                        TextSpan(
                          text: '${xpToNextPremiumSnapshot.data} XP',
                          style: const TextStyle(color: AppTheme.primaryColor),
                        ),
                        TextSpan(text: context.tr('to_next_premium_part2'), style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }),
            FutureBuilder<double>(
                future: Future.wait([achievementService.getUserXp(userId), achievementService.getXpToNextPremium(userId)]).then((values) {
                  final totalXp = values[0];
                  final xpToNext = values[1];
                  if (xpToNext <= 0) return 1.0;
                  return totalXp / (totalXp + xpToNext);
                }),
                builder: (context, progressSnapshot) {
                  return LinearProgressIndicator(
                    value: progressSnapshot.data ?? 0.0,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  );
                }),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FutureBuilder<int>(
                    future: achievementService.getEarnedPremiumRewardCount(userId),
                    builder: (context, premiumCountSnapshot) {
                      return Text(
                        '${context.tr('premium_rewards')}: ${premiumCountSnapshot.data ?? 0}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      );
                    }),
                TextButton.icon(
                  onPressed: onLeaderboardPressed,
                  icon: const Icon(Icons.leaderboard, size: 16),
                  label: Text(context.tr('leaderboard')),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
