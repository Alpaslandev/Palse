import 'package:flutter/material.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/widgets/circle_profile_picture.dart';
import 'package:palseapp/core/models/chat_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ChatListItem extends StatelessWidget {
  final Chat chatSummary;
  final VoidCallback onTap;
  final CustomerService customerService;

  const ChatListItem({
    super.key,
    required this.chatSummary,
    required this.onTap,
    required this.customerService,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).user?.userID;
    final bool isLastMessageMine = chatSummary.isMe(currentUserId ?? '');

    // Kullanıcı bilgilerini önbelleğe al
    final userCache = <String, Customer>{};

    return FutureBuilder<Customer?>(
      future: customerService.fetchUserFromFirestore(chatSummary.getOtherUserId(currentUserId ?? '')),
      builder: (context, snapshot) {
        // Yükleme durumu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            leading: const CircleAvatar(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: const Text('Yükleniyor...'),
            subtitle: Text(chatSummary.lastMessage),
            onTap: onTap,
          );
        }

        // Kullanıcı bilgisi
        final otherUser = snapshot.data;
        final userName = otherUser?.firstName ?? 'Bilinmeyen Kullanıcı';
        final userPhoto = otherUser?.profilePictureUrl;

        return ListTile(
          leading: CircleProfilePicture(
            imageUrl: userPhoto,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  userName,
                  style: TextStyle(
                    fontWeight: chatSummary.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              Text(
                _formatLastMessageTime(chatSummary.lastMessageTime),
                style: TextStyle(
                  fontSize: 12,
                  color: chatSummary.unreadCount > 0 ? Colors.black87 : Colors.grey,
                ),
              ),
            ],
          ),
          subtitle: Row(
            children: [
              // UI içinde:
              if (isLastMessageMine) ...[
                Icon(
                  chatSummary.isLastMessageRead ? Icons.done_all : Icons.done,
                  size: 16,
                  color: chatSummary.isLastMessageRead ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  chatSummary.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: chatSummary.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (chatSummary.hasUnreadMessages) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    chatSummary.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          onTap: onTap,
        );
      },
    );
  }

  // return old(userCache, isLastMessageMine, context);
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
