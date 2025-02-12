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
  late final MessagesViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MessagesViewModel(widget.otherUserId);
    _viewModel.initialize(widget.chatId, widget.currentUserId);

    // Mesajları okundu olarak işaretle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.markMessagesAsRead(
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
    return ChangeNotifierProvider.value(
      value: _viewModel,
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

                    // Yeni mesaj geldiğinde otomatik olarak okundu olarak işaretle
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final unreadMessages = messages.where((msg) => msg.senderId == widget.otherUserId && !msg.isRead).toList();

                      if (unreadMessages.isNotEmpty) {
                        vm.markMessagesAsRead(
                          widget.chatId,
                          widget.currentUserId,
                          widget.otherUserId,
                        );
                      }
                    });

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
