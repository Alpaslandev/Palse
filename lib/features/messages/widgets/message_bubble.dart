// Mesaj baloncuğu widget'ı - WhatsApp tarzı alıntılama
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:palseapp/core/models/chat_model.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/features/messages/viewmodel/messages_view_model.dart';
import 'package:provider/provider.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe; // Mesaj bana mı ait

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.read<MessagesViewModel>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Dismissible(
        key: Key(message.timestamp.toString()),
        direction: DismissDirection.startToEnd, // Sadece sağa kaydırma
        confirmDismiss: (direction) async {
          // Direkt alıntıla ve false döndür ki mesaj silinmesin
          context.read<MessagesViewModel>().setQuotedMessage(message);
          return false;
        },
        background: _buildSwipeBackground(),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              StreamBuilder<Customer?>(
                stream: vm.getUserInfo(message.senderId),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  return CircleAvatar(
                    radius: 16,
                    backgroundImage: user?.profilePictureUrl != null && user!.profilePictureUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(user.profilePictureUrl!) as ImageProvider
                        : const AssetImage('assets/images/dostum_olsana.png'),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65,
                ),
                decoration: BoxDecoration(
                  color: isMe ? Colors.blue : Colors.grey[300],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(isMe ? 12 : 0),
                    bottomRight: Radius.circular(isMe ? 0 : 12),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.quotedMessage != null) _buildQuotedMessage(message),

                    // Mesaj tipine göre içeriği göster
                    if (message.type == 'image')
                      _buildImageMessage(message.content)
                    else
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black,
                          fontSize: 16,
                        ),
                      ),

                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.timestamp.toDate()),
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead ? Icons.done_all : Icons.done,
                            size: 14,
                            color: message.isRead ? Colors.white : Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotedMessage(Message message) {
    if (message.quotedMessage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Text(
        message.quotedMessage!,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildImageMessage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 200,
          height: 200,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) {
          debugPrint('Görsel yükleme hatası: $error');
          return Container(
            width: 200,
            height: 200,
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.error_outline, color: Colors.red, size: 40),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwipeBackground() {
    return Container(
      padding: const EdgeInsets.only(left: 16),
      alignment: Alignment.centerLeft,
      color: Colors.blue.withOpacity(0.2),
      child: const Icon(
        Icons.format_quote,
        color: Colors.blue,
      ),
    );
  }
}
