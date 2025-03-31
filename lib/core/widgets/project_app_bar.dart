import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/services/shared_pref_service.dart';
import 'package:provider/provider.dart';

class ProjectAppBar extends StatefulWidget implements PreferredSizeWidget {
  const ProjectAppBar({super.key});

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  State<ProjectAppBar> createState() => _ProjectAppBarState();
}

class _ProjectAppBarState extends State<ProjectAppBar> {
  int _unreadNotificationsCount = 0;
  late StreamSubscription<int> _notificationSubscription;

  @override
  void initState() {
    super.initState();

    // İlk değeri yükle
    _loadInitialUnreadCount();

    // Stream'i dinle
    _notificationSubscription = SharedPrefService.notificationCountStream.listen((count) {
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = count;
        });
      }
    });
  }

  @override
  void dispose() {
    _notificationSubscription.cancel();
    super.dispose();
  }

  // İlk değeri yükle
  Future<void> _loadInitialUnreadCount() async {
    final count = await SharedPrefService.getUnreadNotificationsCount();
    if (mounted) {
      setState(() {
        _unreadNotificationsCount = count;
      });
    }
  }

  void _navigateToNotifications() async {
    // Bildirim ekranına git
    context.pushNamed(notification);

    // Tüm bildirimleri okundu olarak işaretle
    await SharedPrefService.markAllNotificationsAsRead();

    // Not: Stream sayesinde otomatik olarak sayaç güncellenecek
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    return AppBar(
      scrolledUnderElevation: 0,
      title: Row(
        children: [
          // Logo görüntüsünü app bar'a uygun şekilde yerleştir
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Image.asset(
              'assets/images/dostum_olsana_trimmed.png',
              height: 50,
              width: 50,
              fit: BoxFit.cover,
            ),
          ),
          const Text('PALSE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        Stack(
          children: [
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.hardEdge,
                child: IconButton(
                  onPressed: _navigateToNotifications,
                  icon: SvgPicture.asset(
                    'assets/vectors/ringtone_iconly_pro_1_x2.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(theme.colorScheme.onSurface, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
            if (_unreadNotificationsCount > 0)
              Positioned(
                top: 0,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    _unreadNotificationsCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
          ],
        ),
        Stack(
          children: [
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 10, left: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.hardEdge,
                child: IconButton(
                  onPressed: () => context.pushNamed(chats),
                  icon: SvgPicture.asset(
                    'assets/vectors/chat_iconly_pro_x2.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(theme.colorScheme.onSurface, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
            if (authProvider.user?.hasUnreadChats ?? false)
              Positioned(
                top: 0,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    authProvider.user?.getTotalUnreadCount().toString() ?? '0',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
