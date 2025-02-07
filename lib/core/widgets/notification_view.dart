import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationView extends StatelessWidget {
  const NotificationView({super.key});

  Future<List<String>> _getStoredNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('notifications') ?? [];
  }

  Future<void> _removeNotification(int index, BuildContext context) async {
    // final prefs = await SharedPreferences.getInstance();
    // List<String> notifications = prefs.getStringList('notifications') ?? [];
    // notifications.removeAt(index); // Bildirimi listeden kaldır
    // await prefs.setStringList('notifications', notifications);
  }

  @override
  Widget build(BuildContext context) {
    // final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 100,
          ),
          Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Text(
                  'Bildirimler',
                ),
              ),
              GestureDetector(
                onTap: () => {Navigator.pop(context)},
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationZ(-1.5708), // Rotate 90 degrees to the left (negative direction)
                      child: Container(
                        width: 48,
                        height: 48,
                        margin: EdgeInsets.only(left: 16), // Adjust left margin as needed
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFFEEEEEE)),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: SvgPicture.asset(
                          'assets/vectors/stroke_11_x2.svg',
                          width: 14,
                          height: 7,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: FutureBuilder<List<String>>(
              future: _getStoredNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                } else {
                  final notifications = snapshot.data ?? [];

                  if (notifications.isEmpty) {
                    return Center(child: Text('Bildirim bulunamadı'));
                  }

                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
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
                                      children: [],
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    notification,
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
