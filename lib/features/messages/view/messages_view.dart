import 'package:flutter/material.dart';
import 'package:palseapp/core/models/chat_model.dart';
import 'package:palseapp/features/messages/widgets/message_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:palseapp/features/messages/viewmodel/messages_view_model.dart';
import 'package:palseapp/features/messages/widgets/message_bubble.dart';
import 'package:palseapp/features/messages/widgets/message_input.dart';

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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MessagesViewModel(widget.otherUserId),
      child: Consumer<MessagesViewModel>(
        builder: (context, vm, _) => Scaffold(
          appBar: MessageAppBar(vm: vm),
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
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: MessageInput(
              chatId: widget.chatId,
              currentUserId: widget.currentUserId,
              otherUserId: widget.otherUserId,
            ),
          ),
        ),
      ),
    );
  }
}
