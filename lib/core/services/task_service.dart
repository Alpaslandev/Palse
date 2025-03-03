// // Günlük görevi kaydet
// import 'dart:convert';

// import 'package:palseapp/features/achievement/daily_task.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class TaskService {
//   final SharedPreferences _prefs;

//   TaskService({required SharedPreferences prefs}) : _prefs = prefs;

//   Future<void> saveDailyTask(DailyTask task) async {
//     await _prefs.setString('daily_task', jsonEncode(task.toJson()));
//   }

//   // Günlük görevi yükle
//   Future<DailyTask?> loadDailyTask() async {
//     final prefs = await SharedPreferences.getInstance();
//     final taskJson = prefs.getString('daily_task');
//     if (taskJson == null) return null;
//     return DailyTask.fromJson(jsonDecode(taskJson));
//   }
// }
