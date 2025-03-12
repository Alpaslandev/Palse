import 'package:flutter/material.dart';
import 'package:palseapp/features/achievement/achievements.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:palseapp/features/achievement/achievement_manager.dart';
import 'dart:convert';

/// XP sistemini test etmek için kullanılan sayfa
class AchievementTestPage extends StatefulWidget {
  const AchievementTestPage({Key? key}) : super(key: key);

  @override
  State<AchievementTestPage> createState() => _AchievementTestPageState();
}

class _AchievementTestPageState extends State<AchievementTestPage> {
  final AchievementManager _achievementManager = AchievementManager();
  final AchievementService _achievementService = AchievementService();
  Map<String, dynamic> _debugInfo = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  // Debug bilgisini yükler
  Future<void> _loadDebugInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = context.read<AuthProvider>().user?.userID;
      if (userId != null) {
        final debugInfo = await _achievementManager.checkDailyTasksStatus(userId);
        setState(() {
          _debugInfo = debugInfo;
        });
      }
    } catch (e) {
      debugPrint('Debug bilgisi yüklenirken hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Günlük görevleri sıfırlar
  Future<void> _resetDailyTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = context.read<AuthProvider>().user?.userID;
      if (userId != null) {
        await _achievementManager.resetDailyTasks(userId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Günlük görevler sıfırlandı!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadDebugInfo();
      }
    } catch (e) {
      debugPrint('Günlük görevler sıfırlanırken hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Görevleri tamamlanmış olarak işaretler
  Future<void> _completeTask(XpEvent event) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = context.read<AuthProvider>().user?.userID;
      if (userId != null) {
        await _achievementManager.completeTaskForTesting(userId, event);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${event.name} görevi test için tamamlandı!'),
            backgroundColor: Colors.blue,
          ),
        );
        await _loadDebugInfo();
      }
    } catch (e) {
      debugPrint('Görev tamamlanırken hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Sıfırlama zamanını geçmiş olarak ayarlar
  Future<void> _setTasksAsExpired() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = context.read<AuthProvider>().user?.userID;
      if (userId != null) {
        await _achievementManager.setDailyTaskAsExpired(userId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sıfırlama zamanı dün olarak ayarlandı!'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadDebugInfo();
      }
    } catch (e) {
      debugPrint('Sıfırlama zamanı ayarlanırken hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // XP kazandır
  Future<void> _earnXp(XpEvent event) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = context.read<AuthProvider>().user?.userID;
      if (userId != null) {
        final newXp = await _achievementManager.earnXpForEvent(userId, event);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${event.xpAmount} XP kazanıldı! Toplam XP: $newXp'),
            backgroundColor: Colors.purple,
          ),
        );
        await _loadDebugInfo();
      }
    } catch (e) {
      debugPrint('XP kazanılırken hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.userID;
    final userXp = context.watch<AuthProvider>().user?.totalXp ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('XP Sistemi Test Sayfası'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kullanıcı bilgileri
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kullanıcı ID: $userId'),
                          Text('Toplam XP: $userXp'),
                          const SizedBox(height: 8),
                          Text(
                            'Debug Bilgisi',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text('Son sıfırlama zamanı: ${_debugInfo['last_reset_time'] ?? 'Yüklenemedi'}'),
                          Text('Son görev tarihi: ${_debugInfo['last_daily_task_date'] ?? 'Yüklenemedi'}'),
                          Text('Sıfırlamaya kalan süre: ${_debugInfo['time_until_reset'] ?? 'Yüklenemedi'}'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Günlük görev durumları
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Günlük Görev Durumları',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (_debugInfo.containsKey('daily_login'))
                            ListTile(
                              title: const Text('Günlük Giriş'),
                              subtitle: Text(
                                  'Tamamlanabilir: ${_debugInfo['daily_login']['completable']} | Tamamlanma sayısı: ${_debugInfo['daily_login']['completion_count']}'),
                              trailing: _debugInfo['daily_login']['completable']
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : const Icon(Icons.cancel, color: Colors.red),
                            ),
                          if (_debugInfo.containsKey('daily_create_listing'))
                            ListTile(
                              title: const Text('İlan Oluşturma'),
                              subtitle: Text(
                                  'Tamamlanabilir: ${_debugInfo['daily_create_listing']['completable']} | Tamamlanma sayısı: ${_debugInfo['daily_create_listing']['completion_count']}'),
                              trailing: _debugInfo['daily_create_listing']['completable']
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : const Icon(Icons.cancel, color: Colors.red),
                            ),
                          if (_debugInfo.containsKey('daily_send_message'))
                            ListTile(
                              title: const Text('Mesaj Gönderme'),
                              subtitle: Text(
                                  'Tamamlanabilir: ${_debugInfo['daily_send_message']['completable']} | Tamamlanma sayısı: ${_debugInfo['daily_send_message']['completion_count']}'),
                              trailing: _debugInfo['daily_send_message']['completable']
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : const Icon(Icons.cancel, color: Colors.red),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Test düğmeleri
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Test İşlemleri',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),

                          // Günlük görevleri sıfırla
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Günlük Görevleri Sıfırla'),
                                  onPressed: _resetDailyTasks,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.timer),
                                  label: const Text('Sıfırlama Zamanını Eskiye Ayarla'),
                                  onPressed: _setTasksAsExpired,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          const Text('Görevleri Tamamla (Test İçin):'),
                          const SizedBox(height: 8),

                          // Görev tamamlama düğmeleri
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton(
                                onPressed: () => _completeTask(XpEvent.dailyLogin),
                                child: const Text('Günlük Giriş Tamamla'),
                              ),
                              ElevatedButton(
                                onPressed: () => _completeTask(XpEvent.dailyCreateListing),
                                child: const Text('İlan Oluşturma Tamamla'),
                              ),
                              ElevatedButton(
                                onPressed: () => _completeTask(XpEvent.dailySendMessage),
                                child: const Text('Mesaj Gönderme Tamamla'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          const Text('XP Kazan (Görev Kontrolü İle):'),
                          const SizedBox(height: 8),

                          // XP kazanma düğmeleri
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton(
                                onPressed: () => _earnXp(XpEvent.dailyLogin),
                                child: Text('Günlük Giriş (+${XpEvent.dailyLogin.xpAmount} XP)'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _earnXp(XpEvent.dailyCreateListing),
                                child: Text('İlan Oluşturma (+${XpEvent.dailyCreateListing.xpAmount} XP)'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _earnXp(XpEvent.dailySendMessage),
                                child: Text('Mesaj Gönderme (+${XpEvent.dailySendMessage.xpAmount} XP)'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tamamlanmış görevler
                  if (_debugInfo.containsKey('completed_tasks'))
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tamamlanmış Görevler',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              const JsonEncoder.withIndent('  ').convert(_debugInfo['completed_tasks']),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontFamily: 'monospace',
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadDebugInfo,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
