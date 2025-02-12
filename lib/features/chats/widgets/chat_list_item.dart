import 'package:flutter/material.dart';
import 'package:palseapp/core/models/chat_model.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/features/chats/viewmodel/chats_view_model.dart';
import 'package:provider/provider.dart';

class ChatListItem extends StatelessWidget {
  final Chat chat;
  final String otherUserId;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.otherUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: StreamBuilder<Customer?>(
        stream: context.read<ChatsViewModel>().getUserInfo(otherUserId),
        builder: (context, snapshot) {
          final user = snapshot.data;
          return CircleAvatar(
            backgroundImage: user?.profilePictureUrl != null && user!.profilePictureUrl!.isNotEmpty ? NetworkImage(user.profilePictureUrl!) : null,
            child: user?.profilePictureUrl == null || user!.profilePictureUrl!.isEmpty ? const Icon(Icons.person) : null,
          );
        },
      ),
      title: StreamBuilder<Customer?>(
        stream: context.read<ChatsViewModel>().getUserInfo(otherUserId),
        builder: (context, snapshot) {
          final user = snapshot.data;
          return Text(user?.fullName() ?? 'Kullanıcı');
        },
      ),
      subtitle: Text(
        chat.lastMessage.isNotEmpty ? chat.lastMessage : 'Henüz mesaj yok',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: chat.unreadCount > 0
          ? CircleAvatar(
              radius: 12,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                chat.unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}
