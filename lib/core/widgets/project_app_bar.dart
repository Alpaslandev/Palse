import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ProjectAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ProjectAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('Palse'),
      actions: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: SvgPicture.asset(
            'assets/vectors/ringtone_iconly_pro_1_x2.svg',
            width: 24,
            height: 24,
          ),
        ),
        const SizedBox(width: 10),
        SvgPicture.asset(
          'assets/vectors/chat_iconly_pro_x2.svg',
          width: 24,
          height: 24,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
