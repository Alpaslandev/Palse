import 'package:flutter/material.dart';
import 'package:palseapp/core/models/chat_model.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:provider/provider.dart';
import 'package:palseapp/features/messages/viewmodel/messages_view_model.dart';
import 'package:palseapp/features/messages/widgets/message_bubble.dart';

class MessagesView extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserId;

  const MessagesView({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
  });

  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Mesajları okundu olarak işaretle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessagesViewModel>().markMessagesAsRead(
            widget.chatId,
            widget.currentUserId,
            widget.otherUserId,
          );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MessagesViewModel(widget.otherUserId),
      child: Consumer<MessagesViewModel>(
        builder: (context, vm, _) => Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                CircleAvatar(
                  backgroundImage: vm.otherUser?.profilePictureUrl != null
                      ? NetworkImage(vm.otherUser!.profilePictureUrl!)
                      : const AssetImage('assets/images/dostum_olsana.png') as ImageProvider,
                  radius: 18,
                ),
                const SizedBox(width: 12),
                Text(vm.otherUser?.nickname ?? vm.otherUser?.firstName ?? vm.otherUser?.lastName ?? ''),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Message>>(
                  stream: vm.getMessages(widget.chatId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('Bir hata oluştu'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data ?? [];

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == widget.currentUserId;

                        return MessageBubble(
                          message: message,
                          isMe: isMe,
                        );
                      },
                    );
                  },
                ),
              ),
              _buildMessageInput(vm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(MessagesViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          if (vm.quotedMessage != null) _buildQuotePreview(vm.quotedMessage!, vm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Mesajınızı yazın...',
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                ),
              ),
              IconButton(
                icon: vm.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                onPressed: vm.isLoading ? null : () => _sendMessage(vm),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuotePreview(Message quotedMessage, MessagesViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alıntı: ${quotedMessage.senderId}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  quotedMessage.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => vm.clearQuotedMessage(),
          ),
        ],
      ),
    );
  }

  void _sendMessage(MessagesViewModel vm) async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    await vm.sendMessage(
      widget.chatId,
      widget.currentUserId,
      widget.otherUserId,
      content,
    );
  }
}
