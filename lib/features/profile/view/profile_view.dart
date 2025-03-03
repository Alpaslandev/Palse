import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/features/profile/widgets/leader_board.dart';
import 'package:palseapp/features/profile/widgets/xp_events_view.dart';
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
                  xp: 200,
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
                const VerifyProfileButton(),

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
  return Row(
    children: [
      CircleAvatar(
        radius: 30,
        backgroundImage: NetworkImage(authProvider.user?.profilePictureUrl ?? ''),
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${authProvider.user?.fullName()} (${authProvider.user?.getAge()})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (authProvider.user?.nickname != null)
            Text(
              '@${authProvider.user?.nickname}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
        ],
      ),
      const Spacer(),
      IconButton(
        icon: const Icon(Icons.settings_outlined),
        onPressed: () {
          context.push(settings);
        },
      ),
    ],
  );
}

// Yorumlar kartı
Widget _ratingCard(Customer customer, BuildContext context) {
  return Card(
      child: ListTile(
    onTap: () => context.pushNamed(comment, extra: customer),
    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            Text('Yorumlar (${customer.comments?.length ?? 0})'),
          ],
        ),
      ],
    ),
    trailing: Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey, width: 1)), // Sol kenara gri çizgi ekleniyor
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
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
                  const Text(
                    'Bugünkü Görev',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.bolt, color: Colors.yellow),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
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
          const Text(
            '1. Bir ilan oluştur ve bir mesaj gönder!',
            style: TextStyle(color: Colors.white),
          ),
          const Text(
            '2. Görevi tamamla, toplamda +100 XP kazan!',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              child: const Text('Görevi Tamamla'),
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
        onPressed: () {},
        icon: const Icon(Icons.check_circle, color: Colors.white),
        label: const Text(
          'Gerçek bir profil olduğunu doğrula ve\nekstra görünürlük kazan!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {
          context.push(subscription);
        },
        icon: const Icon(Icons.diamond, color: Colors.amber, size: 30),
        label: const Text(
          'Premium Ol',
          style: TextStyle(color: Colors.white),
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
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {
          context.push(xpEvents);
        },
        icon: const Icon(Icons.settings),
        label: const Text('XP Sistemi ve Ünvanlar'),
      ),
    );
  }
}
