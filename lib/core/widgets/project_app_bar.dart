import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/features/chats/model/chat_model.dart';
import 'package:palseapp/features/chats/service/chat_service.dart';
import 'package:palseapp/features/chats/viewmodel/chats_view_model.dart';
import 'package:provider/provider.dart';

class ProjectAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ProjectAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return AppBar(
      backgroundColor: Colors.white,
      scrolledUnderElevation: 0,
      title: Row(
        children: [
          Image.asset('assets/images/dostum_olsana.png', width: 50, height: 50),
          const SizedBox(width: 5),
          const Text('PALSE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
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
              onPressed: () async {
                debugPrint('ringtone');
                await authProvider.logout();
                //       context.push(notification);
              },
              icon: SvgPicture.asset(
                'assets/vectors/ringtone_iconly_pro_1_x2.svg',
                width: 24,
                height: 24,
              ),
            ),
          ),
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
                  onPressed: () {
                    debugPrint('chat');
                    context.push(chats);
                  },
                  icon: SvgPicture.asset(
                    'assets/vectors/chat_iconly_pro_x2.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            ),
            // Okunmamış mesaj sayısı badge'i
            StreamBuilder<List<Chat>>(
              stream: Provider.of<ChatsViewModel>(context, listen: false).getChats(authProvider.firebaseUser!.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                final totalUnreadCount = snapshot.data!.fold<int>(
                  0,
                  (sum, chat) => sum + chat.unreadCount,
                );

                if (totalUnreadCount == 0) return const SizedBox.shrink();

                return Positioned(
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
                      totalUnreadCount > 99 ? '99+' : totalUnreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
