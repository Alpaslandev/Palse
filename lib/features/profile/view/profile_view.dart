import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/features/achievement/achievements.dart';
import 'package:palseapp/features/profile/view/widgets/premium_button.dart';
import 'package:palseapp/features/profile/view/widgets/verify_profile_button.dart';
import 'package:palseapp/features/profile/view/widgets/xp_system_button.dart';
import 'package:palseapp/features/profile/view/widgets/leader_board.dart';
import 'package:palseapp/features/profile/view/widgets/xp_progress_card.dart';
import 'package:palseapp/features/profile/view/widgets/follow_list_modal.dart';
import 'package:palseapp/features/profile/view/widgets/profile_header.dart';
import 'package:palseapp/features/profile/view/widgets/daily_task_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  // Daha önce uygulamaya giriş yapılıp yapılmadığını kontrol eden değişken
  bool _checkedDailyLoginReward = false;

  @override
  void initState() {
    super.initState();
    // Profil ekranına girildiğinde günlük giriş ödülünü kontrol et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRewardDailyLogin();
    });
  }

  // Günlük giriş ödülünü kontrol eden ve veren metod
  Future<void> _checkAndRewardDailyLogin() async {
    // Eğer daha önce kontrol edildiyse tekrar kontrol etme
    if (_checkedDailyLoginReward) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null && user.userID != null) {
      final achievementService = AchievementService();

      // Yeni metodu kullan - tarih bazlı kontrol yapan
      final rewardGiven =
          await achievementService.checkDailyLoginReward(user.userID!);

      // Sadece durum göstergesi olarak flag'i güncelle
      setState(() {
        _checkedDailyLoginReward = true;
      });

      // Eğer ödül verildiyse günlük görev kartını yeniden yükleyelim
      if (rewardGiven) {
        debugPrint('✅ Günlük giriş ödülü verildi, görevi yeniden yüklüyoruz');
        await _checkDailyTasks();
      }
    }
  }

  // Günlük görevleri kontrol etme fonksiyonu
  Future<void> _checkDailyTasks() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user != null && user.userID != null) {
        final achievementService = AchievementService();

        // Kullanıcının tamamlanan görevlerini local storage'dan yükle
        final completedTasks =
            await _getCompletedTasksFromLocalStorage(user.userID!);

        // Kullanıcı modelini güncelle
        if (completedTasks.isNotEmpty) {
          final updatedUser = user.copyWith(completedTasks: completedTasks);
          // AuthProvider'da kullanıcı modelini güncelle
          authProvider.updateUser(updatedUser);
          debugPrint(
              'Tamamlanan görevler local storage\'dan yüklendi: ${completedTasks.length} görev');
        }

        debugPrint('🔄 Kullanıcı görev bilgileri güncellendi');
      }
    } catch (e) {
      debugPrint('Kullanıcı görev bilgileri güncellenirken hata: $e');
    }
  }

  // Tamamlanan görevleri local storage'dan getir
  Future<Map<String, int>> _getCompletedTasksFromLocalStorage(
      String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'completed_tasks_$userId';
      final tasksJson = prefs.getString(key);
      if (tasksJson == null) {
        return {};
      }

      final Map<String, dynamic> decodedTasks = jsonDecode(tasksJson);
      // String anahtarları ve int değerleri olan bir Map'e dönüştür
      return decodedTasks.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      debugPrint('Tamamlanan görevler getirilirken hata: $e');
      return {};
    }
  }

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
                if (authProvider.user != null)
                  ProfileHeader(user: authProvider.user!),

                // Takipçi/Takip istatistikleri
                _buildFollowStats(context, authProvider.user!),

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
                if (authProvider.user?.verification == false)
                  const VerifyProfileButton(),

                // Premium buton
                if (authProvider.user?.isPremium == false)
                  const PremiumButton(),

                // XP Sistemi butonu
                const XPSystemButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Takipçi ve takip istatistiklerini gösteren widget
  Widget _buildFollowStats(BuildContext context, Customer user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final followersCount = user.followers?.length ?? 0;
    final followingCount = user.followings?.length ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? Colors.grey.shade50
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Takipçiler
          _buildStatItem(
            context: context,
            count: followersCount,
            label: 'Takipçi',
            onTap: () {
              // Takipçi listesi sayfasına git
              FollowListModal.show(
                context: context,
                title: 'Takipçiler',
                userIds: user.followers ?? [],
                onNavigateTap: (userId) {
                  context.pushNamed(friendProfile, extra: userId);
                },
              );
            },
          ),

          // Ayırıcı çizgi
          Container(
            height: 40,
            width: 1,
            color: theme.dividerColor.withValues(alpha: 0.5),
          ),

          // Takip edilenler
          _buildStatItem(
            context: context,
            count: followingCount,
            label: 'Takip',
            onTap: () {
              // Takip edilen listesi sayfasına git
              FollowListModal.show(
                context: context,
                title: 'Takip Edilenler',
                userIds: user.followings ?? [],
                onNavigateTap: (userId) {
                  context.pushNamed(friendProfile, extra: userId);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // Tek bir istatistik öğesi oluşturan yardımcı widget
  Widget _buildStatItem({
    required BuildContext context,
    required int count,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count.toString(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Yorumlar kartı
Widget _ratingCard(Customer customer, BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return Card(
      color: theme.brightness == Brightness.light
          ? Colors.grey.shade200
          : colorScheme.surfaceContainerHighest,
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
            border:
                Border(left: BorderSide(color: theme.dividerColor, width: 1)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              customer.getAverage().toStringAsFixed(1),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange),
            ),
          ),
        ),
      ));
}
