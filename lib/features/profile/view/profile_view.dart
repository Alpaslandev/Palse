import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/core/widgets/circle_profile_picture.dart';
import 'package:palseapp/features/achievement/achievement_test_page.dart';
import 'package:palseapp/features/achievement/achievements.dart';
import 'package:palseapp/features/profile/widgets/leader_board.dart';
import 'package:palseapp/features/profile/widgets/xp_progress_card.dart';
import 'package:provider/provider.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              spacing: 10,
              children: [
                // Profil başlığı
                profileHeader(context, authProvider),

                // Yorumlar kartı
                _ratingCard(authProvider.user!, context),

                // XP İlerleme kartı
                XPProgressCard(
                  onLeaderboardPressed: () {
                    showModalBottomSheet(
                      isScrollControlled: true,
                      context: context,
                      builder: (context) => const LeaderBoard(),
                    );
                    //  context.push(leaderBoard);
                  },
                ),
                // Günlük görev kartı
                const DailyTaskCard(),

                // Profil doğrulama butonu
                if (authProvider.user?.verification == false) const VerifyProfileButton(),

                // Premium buton
                if (authProvider.user?.isPremium == false) const PremiumButton(),

                // XP Sistemi butonu
                const XPSystemButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Profil başlığı bileşeni
Widget profileHeader(BuildContext context, AuthProvider authProvider) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return Row(
    children: [
      CircleProfilePicture(
        radius: 30,
        imageUrl: authProvider.user?.profilePictureUrl ?? '',
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${authProvider.user?.fullName()} (${authProvider.user?.getAge()})',
                style: theme.textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 2),
              if (authProvider.user?.isPremium == false) const Icon(Icons.verified, color: Colors.yellow, size: 16),
              if (authProvider.user?.verification == false) Icon(Icons.verified, color: colorScheme.primary, size: 16),
            ],
          ),
          if (authProvider.user?.nickname != null)
            Text(
              '@${authProvider.user?.nickname}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      const Spacer(),
      IconButton(
        icon: Icon(Icons.settings_outlined, color: colorScheme.onSurface),
        onPressed: () {
          context.pushNamed(settings);
        },
      ),
    ],
  );
}

// Yorumlar kartı
Widget _ratingCard(Customer customer, BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return Card(
      color: theme.brightness == Brightness.light ? Colors.grey.shade200 : colorScheme.surfaceVariant,
      child: ListTile(
        onTap: () => context.pushNamed(comment, extra: customer),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                Text(
                  '${context.tr('comments')} (${customer.comments?.length ?? 0})',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: theme.dividerColor, width: 1)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              customer.getAverage().toStringAsFixed(1),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ),
        ),
      ));
}

// Günlük görev kartı
class DailyTaskCard extends StatelessWidget {
  const DailyTaskCard({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userAchievements = authProvider.user?.achievements;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Günlük görevin tamamlanıp tamamlanmadığını kontrol et
    final bool isDailyTaskCompleted = userAchievements?.lastDailyTaskDate != null;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    context.tr('daily_task'),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.bolt, color: Colors.yellow),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '+100 XP',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '1. ${context.tr('daily_task_step1')}',
            style: TextStyle(
              color: Colors.white,
              decoration: isDailyTaskCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          Text(
            '2. ${context.tr('daily_task_step2')}',
            style: TextStyle(
              color: Colors.white,
              decoration: isDailyTaskCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isDailyTaskCompleted
                  ? null // Görev tamamlandıysa buton devre dışı
                  : () async {
                      // Görevi tamamla butonuna basıldığında
                      if (userAchievements != null) {
                        // Günlük görevi tamamla ve XP kazan (XpEvent.dailyTaskListingAndMessage görevi için)
                        final updatedAchievements = userAchievements.earnXp(XpEvent.dailyTaskCreateListingAndMessage);

                        // Kullanıcı bilgilerini güncelle
                        //   await authProvider.updateUserAchievements(updatedAchievements);

                        // Başarılı mesajı göster
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.tr('daily_task_completed')),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
              child: Text(
                isDailyTaskCompleted ? context.tr('task_completed') : context.tr('complete_task'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Profil doğrulama butonu
class VerifyProfileButton extends StatelessWidget {
  const VerifyProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {
          context.pushNamed(verified);
          // context.pushNamed(verified).then((value) {
          //   if (value == true) {
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(content: Text('Doğrulama başarılı')),
          //     );
          //   }
          // });
        },
        icon: const Icon(Icons.check_circle, color: Colors.white),
        label: Text(
          context.tr('verify_profile_text'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

// Premium buton
class PremiumButton extends StatelessWidget {
  const PremiumButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.brightness == Brightness.dark ? Colors.grey.shade800 : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {
          context.pushNamed(paywall);
        },
        icon: const Icon(Icons.diamond, color: Colors.amber, size: 30),
        label: Text(
          context.tr('get_premium'),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

// XP Sistemi butonu
class XPSystemButton extends StatelessWidget {
  const XPSystemButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          foregroundColor: colorScheme.primary,
        ),
        onPressed: () {
          context.pushNamed(xpEvents);
        },
        icon: Icon(Icons.settings, color: colorScheme.primary),
        label: Text(
          context.tr('xp_system'),
          style: TextStyle(color: colorScheme.primary),
        ),
      ),
    );
  }
}
