import 'package:flutter/material.dart';
import 'package:palseapp/features/achievement/achievements.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

/// XP sistemini test etmek için kullanılan sayfa
class AchievementTestPage extends StatefulWidget {
  const AchievementTestPage({super.key});

  @override
  State<AchievementTestPage> createState() => _AchievementTestPageState();
}

class _AchievementTestPageState extends State<AchievementTestPage> {
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
        final debugInfo = await _achievementService.checkDailyTasksStatus(userId);
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
        await _achievementService.resetDailyTasks(userId);
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
        await _achievementService.completeTaskForTesting(userId, event);
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
        await _achievementService.setDailyTaskAsExpired(userId);
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

  // Tüm görevleri sıfırlar
  Future<void> _resetAllTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = context.read<AuthProvider>().user?.userID;
      if (userId != null) {
        await _achievementService.resetAllTasks(userId);
        await _loadDebugInfo();
      }
    } catch (e) {
      debugPrint('Tüm görevler sıfırlanırken hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // XP'yi sıfırlar
  Future<void> _resetAllXp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = context.read<AuthProvider>().user?.userID;
      if (userId != null) {
        // Onay isteyelim
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('XP Sıfırlama'),
            content: const Text(
                'Bu işlem tüm XP\'nizi hem yerel hem de Firestore veritabanında sıfırlayacaktır. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Evet, Sıfırla'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await _achievementService.resetAllXp(userId);
          await _loadDebugInfo();
        }
      }
    } catch (e) {
      debugPrint('XP sıfırlanırken hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fabrika ayarlarına döndürür (Tam Sıfırlama)
  Future<void> _factoryReset() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = context.read<AuthProvider>().user?.userID;
      if (userId != null) {
        // Onay isteyelim
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('UYARI: Fabrika Ayarlarına Dönüş'),
            content: const Text(
                'Bu işlem tüm görevleri ve XP\'yi sıfırlayacaktır. Bu işlem geri alınamaz ve her şey sıfırdan başlayacaktır. Devam etmek istiyor musunuz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Evet, Tam Sıfırla'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await _achievementService.factoryReset(userId);
          await _loadDebugInfo();
        }
      }
    } catch (e) {
      debugPrint('Fabrika ayarlarına dönerken hata: $e');
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
        final newXp = await _achievementService.earnXpForEvent(userId, event);
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

                          // İLK SATIR: Günlük görevleri sıfırla ve zamanı ayarla
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

                          const SizedBox(height: 8),

                          // İKİNCİ SATIR: Yeni sıfırlama butonları
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.delete_sweep),
                                  label: const Text('Tüm Görevleri Sıfırla'),
                                  onPressed: _resetAllTasks,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.fitness_center),
                                  label: const Text('XP\'yi Sıfırla'),
                                  onPressed: _resetAllXp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // ÜÇÜNCÜ SATIR: Fabrika ayarları
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.warning),
                              label: const Text('TAM SIFIRLAMA (Fabrika Ayarları)'),
                              onPressed: _factoryReset,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          // Tüm görev tiplerini gruplar halinde göster

                          // 1. Tek Seferlik Görevler
                          _buildTaskGroupSection(
                              context: context,
                              title: 'Tek Seferlik Görevler',
                              emoji: '🏆',
                              description: 'Bu görevler sadece bir kez tamamlanabilir',
                              tasks: [
                                XpEvent.firstListing,
                                XpEvent.firstMessage,
                              ]),

                          const SizedBox(height: 16),

                          // 2. Tekrarlanabilir Görevler
                          _buildTaskGroupSection(
                              context: context,
                              title: 'Tekrarlanabilir Görevler',
                              emoji: '🔄',
                              description: 'Bu görevleri istediğiniz kadar tekrarlayabilirsiniz',
                              tasks: [
                                XpEvent.createListing,
                                XpEvent.sendMessage,
                                XpEvent.receiveMessage,
                                XpEvent.writeComment,
                                XpEvent.receiveComment,
                              ]),

                          const SizedBox(height: 16),

                          // 3. Günlük Görevler
                          _buildTaskGroupSection(
                              context: context,
                              title: 'Günlük Görevler',
                              emoji: '📆',
                              description: 'Bu görevler her gün bir kez tamamlanabilir',
                              tasks: [
                                XpEvent.dailyLogin,
                                XpEvent.dailyCreateListing,
                                XpEvent.dailySendMessage,
                              ]),
                        ],
                      ),
                    ),
                  ),

                  // Tamamlanan görevler
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

  // Görev grubunu oluşturan yardımcı metot
  Widget _buildTaskGroupSection({
    required BuildContext context,
    required String title,
    required String emoji,
    required String description,
    required List<XpEvent> tasks,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bölüm başlığı
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),

        // Açıklama
        Padding(
          padding: const EdgeInsets.only(left: 32.0, top: 4, bottom: 8),
          child: Text(
            description,
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ),

        // Görevler listesi
        ...tasks.map((task) => _buildTaskItem(context, task)),
      ],
    );
  }

  // Tek bir görev öğesini oluşturan yardımcı metot
  Widget _buildTaskItem(BuildContext context, XpEvent task) {
    final canCompleteTask = _debugInfo.containsKey(task.name) ? _debugInfo[task.name]['completable'] : true;

    final completionCount = _debugInfo.containsKey(task.name) ? _debugInfo[task.name]['completion_count'] ?? 0 : 0;

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTaskDisplayName(task),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: canCompleteTask ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '+${task.xpAmount} XP',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tamamlanma: $completionCount kez',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    if (task.isDaily)
                      Text(
                        canCompleteTask ? ' (Yapılabilir)' : ' (Tamamlandı)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: canCompleteTask ? Colors.green : Colors.red,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Tamamla butonu
          ElevatedButton(
            onPressed: () => _earnXp(task),
            style: ElevatedButton.styleFrom(
              backgroundColor: canCompleteTask ? Colors.green : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Tamamla'),
          ),
        ],
      ),
    );
  }

  // Görev ismini daha okunabilir formata dönüştüren yardımcı metot
  String _getTaskDisplayName(XpEvent task) {
    switch (task) {
      case XpEvent.firstListing:
        return 'İlk İlan Oluşturma';
      case XpEvent.firstMessage:
        return 'İlk Mesaj Gönderme';
      case XpEvent.createListing:
        return 'İlan Oluşturma';
      case XpEvent.sendMessage:
        return 'Mesaj Gönderme';
      case XpEvent.receiveMessage:
        return 'Mesaj Alma';
      case XpEvent.writeComment:
        return 'Yorum Yazma';
      case XpEvent.receiveComment:
        return 'Yorum Alma';
      case XpEvent.dailyLogin:
        return 'Günlük Giriş';
      case XpEvent.dailyCreateListing:
        return 'Günlük İlan Oluşturma';
      case XpEvent.dailySendMessage:
        return 'Günlük Mesaj Gönderme';
      default:
        return task.name;
    }
  }
}
