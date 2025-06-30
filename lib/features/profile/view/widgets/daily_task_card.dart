import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/features/achievement/achievements.dart';
import 'package:palseapp/features/profile/view/widgets/daily_task_item.dart';
import 'package:provider/provider.dart';

// Günlük görev kartı
class DailyTaskCard extends StatefulWidget {
  const DailyTaskCard({super.key});

  @override
  State<DailyTaskCard> createState() => _DailyTaskCardState();
}

class _DailyTaskCardState extends State<DailyTaskCard> {
  final bool _isTestMode = false;
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
      final achievementService = AchievementService();

      try {
        // Görevlerin tamamlanma durumlarını kontrol et
        final isDailyLoginCompleted = !(await achievementService
            .canCompleteTask(user!.userID!, XpEvent.dailyLogin));
        final isDailyCreateListingCompleted = !(await achievementService
            .canCompleteTask(user.userID!, XpEvent.dailyCreateListing));
        final isDailySendMessageCompleted = !(await achievementService
            .canCompleteTask(user.userID!, XpEvent.dailySendMessage));

        // Widget hala monte edilmişse state'i güncelle
        if (mounted) {
          setState(() {
            _isDailyLoginCompleted = isDailyLoginCompleted;
            _isDailyCreateListingCompleted = isDailyCreateListingCompleted;
            _isDailySendMessageCompleted = isDailySendMessageCompleted;
          });
        }

        debugPrint('✅ Günlük görev durumları başarıyla yüklendi');
      } catch (e) {
        debugPrint('⚠️ Günlük görev durumları yüklenirken hata: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Toplam XP hesapla (tamamlanan görevler için)
    int totalDailyXp = 0;
    if (_isDailyLoginCompleted) totalDailyXp += XpEvent.dailyLogin.xpAmount;
    if (_isDailyCreateListingCompleted)
      totalDailyXp += XpEvent.dailyCreateListing.xpAmount;
    if (_isDailySendMessageCompleted)
      totalDailyXp += XpEvent.dailySendMessage.xpAmount;

    // Bir sonraki yenilemeye kalan süreyi al - bu metod artık yok, basit bir metin kullanacağız
    final String timeUntilReset = context.tr('daily_task_next_reset_time');

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

          // Bir sonraki yenilemeye kalan süre
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Icon(Icons.access_time,
                    color: Colors.white.withOpacity(0.7), size: 16),
                const SizedBox(width: 4),
                Text(
                  '${context.tr('next_reset')}: $timeUntilReset',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Günlük görevleri listele
          // 1. Günlük Giriş
          DailyTaskItem(
            text: context.tr('daily_login_description'),
            isCompleted: _isDailyLoginCompleted,
            xpAmount: XpEvent.dailyLogin.xpAmount,
            index: 1,
          ),

          // 2. İlan Oluşturma
          DailyTaskItem(
            text: context.tr('daily_create_listing_description'),
            isCompleted: _isDailyCreateListingCompleted,
            xpAmount: XpEvent.dailyCreateListing.xpAmount,
            index: 2,
          ),

          // 3. Mesaj Gönderme
          DailyTaskItem(
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
                '${context.tr('completed_tasks')} ${(_isDailyLoginCompleted ? 1 : 0) + (_isDailyCreateListingCompleted ? 1 : 0) + (_isDailySendMessageCompleted ? 1 : 0)}/3',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                '$totalDailyXp/${XpEvent.dailyLogin.xpAmount + XpEvent.dailyCreateListing.xpAmount + XpEvent.dailySendMessage.xpAmount} XP',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
