import 'package:flutter/material.dart';
import 'package:palseapp/core/models/chat_model.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/features/chats/viewmodel/chats_view_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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
    final bool isLastMessageMine = chat.lastMessageSenderId == Provider.of<ChatsViewModel>(context, listen: false).currentUserId;

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
      title: Row(
        children: [
          Expanded(
            child: StreamBuilder<Customer?>(
              stream: context.read<ChatsViewModel>().getUserInfo(otherUserId),
              builder: (context, snapshot) {
                final user = snapshot.data;
                return Text(
                  user?.fullName() ?? 'Kullanıcı',
                  style: TextStyle(
                    fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              },
            ),
          ),
          Text(
            _formatLastMessageTime(chat.lastMessageTime),
            style: TextStyle(
              fontSize: 12,
              color: chat.unreadCount > 0 ? Colors.black87 : Colors.grey,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          if (isLastMessageMine) ...[
            Icon(
              chat.unreadCount == 0 ? Icons.done_all : Icons.done,
              size: 16,
              color: chat.unreadCount == 0 ? Colors.blue : Colors.grey,
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              chat.lastMessage.isNotEmpty ? chat.lastMessage : 'Henüz mesaj yok',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: chat.unreadCount > 0 ? Colors.black87 : Colors.grey,
                fontWeight: chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          if (chat.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                chat.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  String _formatLastMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      // Bugün ise saat
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays == 1) {
      // Dün ise
      return 'Dün';
    } else if (difference.inDays < 7) {
      // Son 7 gün içinde ise gün adı
      return DateFormat('EEEE', 'tr_TR').format(time);
    } else {
      // Daha eski ise tarih
      return DateFormat('dd.MM.yyyy').format(time);
    }
  }
}
