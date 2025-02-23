// Sohbetler listesi ekranı
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/features/chats/widgets/chat_list_item.dart';
import 'package:provider/provider.dart';
import 'package:palseapp/features/chats/model/chat_model.dart';
import 'package:palseapp/features/chats/viewmodel/chats_view_model.dart';

class ChatsView extends StatelessWidget {
  const ChatsView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.userID;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Kullanıcı bilgisi bulunamadı'),
        ),
      );
    }

    return ChangeNotifierProvider(
      create: (context) => ChatsViewModel(context.read<AuthProvider>()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sohbetler'),
        ),
        body: StreamBuilder<List<Chat>>(
          stream: context.read<ChatsViewModel>().getChats(currentUserId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final chats = snapshot.data ?? [];

            if (chats.isEmpty) {
              return const Center(
                child: Text('Henüz bir sohbet bulunmuyor'),
              );
            }

            return ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];

                // Diğer kullanıcının ID'sini güvenli bir şekilde al
                final otherUserId = chat.participants.where((id) => id != currentUserId).firstOrNull;

                // Eğer diğer kullanıcı bulunamazsa bu sohbeti gösterme
                if (otherUserId == null) return const SizedBox.shrink();

                return ChatListItem(
                  chat: chat,
                  otherUserId: otherUserId,
                  onTap: () => _navigateToChat(context, chat.id, otherUserId),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _navigateToChat(BuildContext context, String chatId, String otherUserId) {
    context.pushNamed(
      'messages',
      extra: {
        'chatId': chatId,
        'otherUserId': otherUserId,
      },
    );
  }
}
