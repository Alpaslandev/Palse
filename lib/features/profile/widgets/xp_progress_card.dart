// XP İlerleme kartı
import 'package:flutter/material.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/features/achievement/user_achievements.dart';

class XPProgressCard extends StatelessWidget {
  const XPProgressCard({super.key, required this.xp, required this.onLeaderboardPressed});
  final int xp;
  final VoidCallback onLeaderboardPressed;
  @override
  Widget build(BuildContext context) {
    final userAchievements = UserAchievements(xp: xp);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 2,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(userAchievements.rank.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                )),
            if (userAchievements.xpToNextRank > 0)
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    const TextSpan(text: 'Bir sonraki seviyeye ', style: TextStyle(color: Colors.grey)),
                    TextSpan(
                      text: '${userAchievements.xpToNextRank} XP',
                      style: const TextStyle(color: AppTheme.primaryColor),
                    ),
                    const TextSpan(text: ' kaldı!', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            LinearProgressIndicator(
              value: xp / userAchievements.rank.maxXp,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: '$xp',
                      style: const TextStyle(color: AppTheme.primaryColor),
                    ),
                    TextSpan(text: '/${userAchievements.rank.maxXp + 1}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  const TextSpan(text: 'Bir sonraki premium ödülüne ', style: TextStyle(color: Colors.grey)),
                  TextSpan(
                    text: '${userAchievements.xpToNextPremium} XP',
                    style: const TextStyle(color: AppTheme.primaryColor),
                  ),
                  const TextSpan(text: ' kaldı!', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            LinearProgressIndicator(
              value: xp / userAchievements.nextPremiumThreshold,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: '$xp',
                      style: const TextStyle(color: AppTheme.primaryColor),
                    ),
                    TextSpan(text: '/${userAchievements.nextPremiumThreshold}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onLeaderboardPressed,
                child: const Text(
                  'Liderlik Tablosu',
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
