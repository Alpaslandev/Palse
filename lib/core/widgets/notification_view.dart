import 'package:flutter/material.dart';
import 'package:palseapp/core/constant/notifications_enum.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/services/shared_pref_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationView extends StatelessWidget {
  const NotificationView({super.key});

  Future<void> _removeNotification(int index, BuildContext context) async {
    await SharedPrefService.removeNotification(index);
  }

  @override
  Widget build(BuildContext context) {
    // final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('notifications')),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 100,
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: SharedPrefService.getNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('${context.tr('error_occurred')}: ${snapshot.error}'));
                } else {
                  final notifications = snapshot.data ?? [];

                  if (notifications.isEmpty) {
                    return Center(child: Text(context.tr('no_notifications')));
                  }

                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final notificationType = NotificationsEnum.values.firstWhere((e) => e.name == notification['type']);
                      debugPrint('bildirimler notification: ${notifications[index]}');
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            padding: EdgeInsets.fromLTRB(12, 12, 0, 12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: EdgeInsets.fromLTRB(0, 0, 0, 4),
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(notificationType.title),
                                      ],
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    notificationType.nonPremium,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topRight,
                                  child: IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _removeNotification(index, context);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
