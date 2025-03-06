import 'package:flutter/material.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/models/chat_model.dart';
import 'package:palseapp/features/messages/widgets/message_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:palseapp/features/messages/viewmodel/messages_view_model.dart';
import 'package:palseapp/features/messages/widgets/message_bubble.dart';
import 'package:palseapp/features/messages/widgets/message_input.dart';

class MessagesView extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String currentUserId;

  const MessagesView({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.currentUserId,
  });

  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> {
  final ScrollController _scrollController = ScrollController();
  late final MessagesViewModel _viewModel;

  late final String currentUserId;
  late final String otherUserId;

  @override
  void initState() {
    super.initState();
    _viewModel = MessagesViewModel(widget.chatId, widget.currentUserId, widget.otherUserId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Klavyeyi kapatmak için kullanılacak fonksiyon
  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final senderName = user?.firstName ?? '';
    final isPremium = user?.isPremium ?? false;

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<MessagesViewModel>(
        builder: (context, vm, _) => GestureDetector(
          // Ekranın herhangi bir yerine dokunulduğunda klavyeyi kapat
          onTap: _dismissKeyboard,
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: MessageAppBar(
              vm: vm,
              otherUserId: widget.otherUserId,
            ),
            body: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    // Mesaj listesine dokunulduğunda da klavyeyi kapat
                    onTap: _dismissKeyboard,
                    child: StreamBuilder<List<Message>>(
                      stream: vm.getMessages(widget.chatId),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(child: Text('Bir hata oluştu'));
                        }

                        // İlk yüklemede loading göster
                        if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final messages = snapshot.data ?? [];

                        // Yeni mesaj geldiğinde otomatik olarak okundu olarak işaretle
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          // Karşı taraftan gelen ve okunmamış mesajlar varsa işaretle
                          final unreadMessages = messages.where((msg) => msg.senderId == widget.otherUserId && !msg.isRead).toList();

                          if (unreadMessages.isNotEmpty) {
                            vm.markMessagesAsRead();
                          }
                        });

                        if (messages.isEmpty) {
                          return const Center(
                            child: Text('Henüz mesaj yok'),
                          );
                        }

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
                ),
                MessageInput(
                  chatId: widget.chatId,
                  currentUserId: widget.currentUserId,
                  otherUserId: widget.otherUserId,
                  isPremium: isPremium,
                  senderName: senderName,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
