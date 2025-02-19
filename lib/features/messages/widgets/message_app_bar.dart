import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/features/messages/viewmodel/messages_view_model.dart';

class MessageAppBar extends StatelessWidget implements PreferredSizeWidget {
  final MessagesViewModel vm;
  final String otherUserId;

  const MessageAppBar({
    super.key,
    required this.vm,
    required this.otherUserId,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF2196F3),
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
      title: StreamBuilder<Customer?>(
        stream: vm.getUserInfo(otherUserId),
        builder: (context, snapshot) {
          final user = snapshot.data;
          return Row(
            children: [
              CircleAvatar(
                backgroundImage: user?.profilePictureUrl != null && user!.profilePictureUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(user.profilePictureUrl!) as ImageProvider
                    : const AssetImage('assets/images/dostum_olsana.png'),
                radius: 18,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user?.firstName ?? user?.lastName ?? ''} ${user?.getAge() != null ? '(${user?.getAge()})' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (user?.nickname != null && user?.nickname != '')
                    Text(
                      '@${user?.nickname ?? ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  if (user?.isPremium != true)
                    Row(
                      children: [
                        const Icon(Icons.workspace_premium, color: Colors.yellow, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Sosyal Usta (${0} XP)',
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
          );
        },
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
