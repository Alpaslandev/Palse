import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/routes/routes.dart';

class ProjectAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ProjectAppBar({super.key});

  @override
  Widget build(BuildContext context) {
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
              onPressed: () {
                debugPrint('ringtone');
                context.push(notification);
              },
              icon: SvgPicture.asset(
                'assets/vectors/ringtone_iconly_pro_1_x2.svg',
                width: 24,
                height: 24,
              ),
            ),
          ),
        ),
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
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
