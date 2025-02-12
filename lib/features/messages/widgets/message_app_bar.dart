import 'package:flutter/material.dart';
import 'package:palseapp/features/messages/viewmodel/messages_view_model.dart';

class MessageAppBar extends StatelessWidget implements PreferredSizeWidget {
  final MessagesViewModel vm;
  const MessageAppBar({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF2196F3), // Mavi renk
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            backgroundImage: vm.otherUser?.profilePictureUrl != null
                ? NetworkImage(vm.otherUser!.profilePictureUrl!)
                : const AssetImage('assets/images/dostum_olsana.png') as ImageProvider,
            radius: 18,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${vm.otherUser?.firstName ?? vm.otherUser?.lastName ?? ''} ${vm.otherUser?.getAge() != null ? '(${vm.otherUser?.getAge()})' : ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (vm.otherUser?.nickname != null && vm.otherUser?.nickname != '')
                Text(
                  '@${vm.otherUser?.nickname ?? ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              if (vm.otherUser?.isPremium != true)
                Row(
                  children: [
                    const Icon(Icons.workspace_premium, color: Colors.yellow, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Sosyal Usta (${vm.otherUser?.coins ?? 0} XP)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
