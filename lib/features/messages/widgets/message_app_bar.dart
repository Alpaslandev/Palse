import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/core/widgets/circle_profile_picture.dart';
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
      backgroundColor: AppTheme.primaryColor,
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
          return GestureDetector(
            onTap: () => context.pushNamed(friendProfile, extra: otherUserId),
            child: Row(
              children: [
                CircleProfilePicture(
                  imageUrl: user?.profilePictureUrl!,
                  radius: 24,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${user?.firstName ?? user?.lastName ?? ''} (${user?.getAge()})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationThickness: 2,
                            decorationColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 2),
                        if (user?.isPremium == true) const Icon(Icons.verified, color: Colors.yellow, size: 14),
                        if (user?.verification == true) const Icon(Icons.verified, color: Colors.blue, size: 14),
                      ],
                    ),
                    if (user?.nickname != null && user?.nickname != '')
                      Text(
                        '@${user?.nickname ?? ''}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
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
            ),
          );
        },
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
