// Sohbetler listesi ekranı
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:palseapp/features/chats/widgets/chat_list_item.dart';
import 'package:provider/provider.dart';
import 'package:palseapp/features/chats/viewmodel/chats_view_model.dart';

class ChatsView extends StatelessWidget {
  const ChatsView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Kullanıcı bilgisi bulunamadı'),
        ),
      );
    }

    return ChangeNotifierProvider(
      create: (context) => ChatsViewModel(user),
      child: Consumer<ChatsViewModel>(
        builder: (context, viewModel, child) {
          // Kullanıcının chatMap'ini al
          final chatMap = viewModel.currentUser?.chatMap ?? {};

          // Map'i son mesaj zamanına göre sıralanmış bir listeye dönüştür
          final sortedChats = chatMap.entries.toList()..sort((a, b) => b.value.lastMessageTime.compareTo(a.value.lastMessageTime));

          return Scaffold(
            appBar: AppBar(
              title: const Text('Sohbetler'),
            ),
            body: sortedChats.isEmpty
                ? const Center(child: Text('Henüz sohbet bulunmuyor'))
                : ListView.builder(
                    itemCount: sortedChats.length,
                    itemBuilder: (context, index) {
                      final otherUserId = sortedChats[index].key;
                      final chatSummary = sortedChats[index].value;

                      return ChatListItem(
                        customerService: CustomerService(),
                        chatSummary: chatSummary,
                        onTap: () => _navigateToChat(context, chatSummary.id, otherUserId),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  void _navigateToChat(BuildContext context, String chatId, String otherUserId) {
    // URL parametreleri ile yönlendir
    context.push('/chats/$chatId?otherId=$otherUserId');
  }
}
