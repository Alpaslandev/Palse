// XP İlerleme kartı
import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:provider/provider.dart';

class XPProgressCard extends StatelessWidget {
  const XPProgressCard({super.key, required this.onLeaderboardPressed});
  final VoidCallback onLeaderboardPressed;
  @override
  Widget build(BuildContext context) {
    final customer = context.read<AuthProvider>().user!;

    return Card(
      child: Column(
        spacing: 2,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${context.tr(customer.rank.titleKey)} ${customer.rank.icon}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              )),
          if (customer.achievements.xpToNextRank > 0)
            RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(text: context.tr('to_next_level_part1'), style: const TextStyle(color: Colors.grey)),
                  TextSpan(
                    text: '${customer.achievements.xpToNextRank} XP',
                    style: const TextStyle(color: AppTheme.primaryColor),
                  ),
                  TextSpan(text: context.tr('to_next_level_part2'), style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          LinearProgressIndicator(
            value: customer.achievements.totalXp / customer.achievements.rank.maxXp,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: '${customer.achievements.totalXp}',
                    style: const TextStyle(color: AppTheme.primaryColor),
                  ),
                  TextSpan(text: '/${customer.achievements.rank.maxXp + 1}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(text: context.tr('to_next_premium_part1'), style: const TextStyle(color: Colors.grey)),
                TextSpan(
                  text: '${customer.achievements.xpToNextPremium} XP',
                  style: const TextStyle(color: AppTheme.primaryColor),
                ),
                TextSpan(text: context.tr('to_next_premium_part2'), style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: customer.achievements.totalXp / customer.achievements.xpToNextPremium,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: '${customer.achievements.totalXp}',
                    style: const TextStyle(color: AppTheme.primaryColor),
                  ),
                  TextSpan(text: '/${customer.achievements.xpToNextPremium}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onLeaderboardPressed,
              child: Text(context.tr('leaderboard')),
            ),
          )
        ],
      ),
    );
  }
}
