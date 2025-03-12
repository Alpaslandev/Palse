import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/widgets/circle_profile_picture.dart';
import 'package:palseapp/features/achievement/achievement_test_page.dart';
import 'package:palseapp/features/achievement/achievements.dart';
import 'package:palseapp/features/profile/widgets/leader_board.dart';
import 'package:palseapp/features/profile/widgets/xp_progress_card.dart';
import 'package:palseapp/features/achievement/achievement_manager.dart';
import 'package:palseapp/features/achievement/xp_events.dart';
import 'package:provider/provider.dart';
import 'package:palseapp/core/services/shared_pref_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    // Profil ekranı açıldığında günlük görevleri kontrol et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyTasks();
    });
  }

  // Günlük görevleri kontrol etme fonksiyonu
  Future<void> _checkDailyTasks() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user != null) {
        final achievementManager = AchievementManager();

        // Günlük görevleri kontrol et ve gerekirse sıfırla
        if (user.userID != null) {
          await achievementManager.resetDailyTasks(user.userID!);
        }

        // Kullanıcının tamamlanan görevlerini local storage'dan yükle
        if (user.userID != null) {
          // Tamamlanan görevleri local storage'dan al
          final completedTasks = await _getCompletedTasksFromLocalStorage(user.userID!);

          // Kullanıcı modelini güncelle
          if (completedTasks.isNotEmpty) {
            final updatedUser = user.copyWith(completedTasks: completedTasks);
            // AuthProvider'da kullanıcı modelini güncelle
            authProvider.updateUser(updatedUser);
            debugPrint('Tamamlanan görevler local storage\'dan yüklendi: ${completedTasks.length} görev');
          }
        }

        debugPrint('🔄 Günlük görevler kontrol edildi');
      }
    } catch (e) {
      debugPrint('Günlük görev kontrolü sırasında hata: $e');
    }
  }

  // Tamamlanan görevleri local storage'dan getir
  Future<Map<String, int>> _getCompletedTasksFromLocalStorage(String userId) async {
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
                ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AchievementTestPage()));
                    },
                    child: Text(context.tr('xp_system')))
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
class DailyTaskCard extends StatefulWidget {
  const DailyTaskCard({super.key});

  @override
  State<DailyTaskCard> createState() => _DailyTaskCardState();
}

class _DailyTaskCardState extends State<DailyTaskCard> {
  bool _isTestMode = false;
  bool _isDailyLoginCompleted = false;
  bool _isDailyCreateListingCompleted = false;
  bool _isDailySendMessageCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadDailyTasksStatus();
  }

  // Günlük görev durumlarını yükle
  Future<void> _loadDailyTasksStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user?.userID != null) {
      final achievementManager = AchievementManager();

      // Görevlerin tamamlanma durumlarını kontrol et
      final isDailyLoginCompleted = !(await achievementManager.canCompleteTask(user!.userID!, XpEvent.dailyLogin));
      final isDailyCreateListingCompleted = !(await achievementManager.canCompleteTask(user.userID!, XpEvent.dailyCreateListing));
      final isDailySendMessageCompleted = !(await achievementManager.canCompleteTask(user.userID!, XpEvent.dailySendMessage));

      setState(() {
        _isDailyLoginCompleted = isDailyLoginCompleted;
        _isDailyCreateListingCompleted = isDailyCreateListingCompleted;
        _isDailySendMessageCompleted = isDailySendMessageCompleted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final achievementManager = AchievementManager();

    // Toplam XP hesapla (tamamlanan görevler için)
    int totalDailyXp = 0;
    if (_isDailyLoginCompleted) totalDailyXp += XpEvent.dailyLogin.xpAmount;
    if (_isDailyCreateListingCompleted) totalDailyXp += XpEvent.dailyCreateListing.xpAmount;
    if (_isDailySendMessageCompleted) totalDailyXp += XpEvent.dailySendMessage.xpAmount;

    // Tüm görevlerin tamamlanıp tamamlanmadığını kontrol et
    final bool allTasksCompleted = _isDailyLoginCompleted && _isDailyCreateListingCompleted && _isDailySendMessageCompleted;

    // Bir sonraki yenilemeye kalan süreyi al - bu metod artık yok, basit bir metin kullanacağız
    final String timeUntilReset = "24 saat";

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
                    context.tr('daily_tasks'),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.bolt, color: Colors.yellow),
                ],
              ),
              Row(
                children: [
                  // Test butonu
                  if (user != null)
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () async {
                        // Test için dünün tarihini ayarla
                        final achievementManager = AchievementManager();

                        // Test modunu aktifleştir
                        setState(() {
                          _isTestMode = true;
                        });

                        // Görevleri sıfırla
                        if (user.userID != null) {
                          await achievementManager.resetDailyTasks(user.userID!);
                        }

                        // Görev durumlarını yeniden yükle
                        await _loadDailyTasksStatus();

                        // Bildirim göster
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Günlük görevler sıfırlandı! Yeni görevleri tamamlayabilirsiniz.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  // XP göstergesi
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+${XpEvent.dailyLogin.xpAmount + XpEvent.dailyCreateListing.xpAmount + XpEvent.dailySendMessage.xpAmount} XP',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Bir sonraki yenilemeye kalan süre
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.white.withOpacity(0.7), size: 16),
                const SizedBox(width: 4),
                Text(
                  '${context.tr('next_reset')}: $timeUntilReset',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Günlük görevleri listele
          // 1. Günlük Giriş
          _buildTaskItem(
            context: context,
            text: context.tr('daily_login_description'),
            isCompleted: _isDailyLoginCompleted,
            xpAmount: XpEvent.dailyLogin.xpAmount,
            index: 1,
          ),

          // 2. İlan Oluşturma
          _buildTaskItem(
            context: context,
            text: context.tr('daily_create_listing_description'),
            isCompleted: _isDailyCreateListingCompleted,
            xpAmount: XpEvent.dailyCreateListing.xpAmount,
            index: 2,
          ),

          // 3. Mesaj Gönderme
          _buildTaskItem(
            context: context,
            text: context.tr('daily_send_message_description'),
            isCompleted: _isDailySendMessageCompleted,
            xpAmount: XpEvent.dailySendMessage.xpAmount,
            index: 3,
          ),

          const SizedBox(height: 12),

          // Tamamlanan görevler için özet
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('completed_tasks') +
                    ' ${(_isDailyLoginCompleted ? 1 : 0) + (_isDailyCreateListingCompleted ? 1 : 0) + (_isDailySendMessageCompleted ? 1 : 0)}/3',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                '${totalDailyXp}/${XpEvent.dailyLogin.xpAmount + XpEvent.dailyCreateListing.xpAmount + XpEvent.dailySendMessage.xpAmount} XP',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Görev öğesi oluşturmak için yardımcı metod
  Widget _buildTaskItem({
    required BuildContext context,
    required String text,
    required bool isCompleted,
    required int xpAmount,
    required int index,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          // Görev numarası
          Text(
            '$index.',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(width: 8),

          // Görev metni
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),

          // XP miktarı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+$xpAmount XP',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),

          // Tik işareti (tamamlanmışsa)
          if (isCompleted)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
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
