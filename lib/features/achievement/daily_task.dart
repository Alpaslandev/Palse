import 'package:palseapp/features/achievement/achievements.dart';

/// Günlük görev sistemini yöneten sınıf
class DailyTask {
  /// Günün görevi
  final XpEvent task;

  /// Görevin tamamlanıp tamamlanmadığı
  final bool isCompleted;

  /// Görevin oluşturulma tarihi
  final DateTime createdAt;

  DailyTask({
    required this.task,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Görevin bugüne ait olup olmadığını kontrol eder
  bool get isForToday {
    final now = DateTime.now();
    return createdAt.year == now.year && createdAt.month == now.month && createdAt.day == now.day;
  }

  /// Yeni bir günlük görev oluşturur
  static DailyTask createNewTask() {
    // Şimdilik sadece bir görev var, ileride farklı görevler eklenebilir
    return DailyTask(task: XpEvent.dailyTaskListingAndMessage);
  }

  /// Görevi tamamlandı olarak işaretler
  DailyTask complete() {
    return DailyTask(
      task: task,
      isCompleted: true,
      createdAt: createdAt,
    );
  }
}
