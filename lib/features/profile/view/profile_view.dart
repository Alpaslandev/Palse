import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:provider/provider.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profil başlığı
              profileHeader(context, authProvider),

              // Yorumlar kartı
              const RatingCard(),

              // XP İlerleme kartı
              const XPProgressCard(),

              // Liderlik tablosu butonu
              const LeaderboardButton(),

              const SizedBox(height: 16),

              // Günlük görev kartı
              const DailyTaskCard(),

              const SizedBox(height: 16),

              // Profil doğrulama butonu
              const VerifyProfileButton(),

              const SizedBox(height: 16),

              // Premium buton
              const PremiumButton(),

              const SizedBox(height: 16),

              // XP Sistemi butonu
              const XPSystemButton(),
            ],
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
class RatingCard extends StatelessWidget {
  const RatingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                Text('Yorumlar'),
              ],
            ),
            Text('0.0'),
          ],
        ),
      ),
    );
  }
}

// XP İlerleme kartı
class XPProgressCard extends StatelessWidget {
  const XPProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Sedo Champ'),
                Icon(Icons.emoji_events, color: Colors.amber),
                Text('Sosyal Usta'),
              ],
            ),
            Text('Bir sonraki premium için 2800 XP kaldı!'),
            LinearProgressIndicator(
              value: 3200 / 6000,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0 XP'),
                Text('3200/6000'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Liderlik tablosu butonu
class LeaderboardButton extends StatelessWidget {
  const LeaderboardButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {},
        child: const Text(
          'Liderlik Tablosu',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

// Günlük görev kartı
class DailyTaskCard extends StatelessWidget {
  const DailyTaskCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
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
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
              ),
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {},
        icon: const Icon(Icons.diamond, color: Colors.amber),
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
        onPressed: () {},
        icon: const Icon(Icons.settings),
        label: const Text('XP Sistemi ve Ünvanlar'),
      ),
    );
  }
}
