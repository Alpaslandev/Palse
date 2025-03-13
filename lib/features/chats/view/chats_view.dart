// Sohbetler listesi ekranı
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:palseapp/features/chats/widgets/chat_list_item.dart';
import 'package:provider/provider.dart';

class ChatsView extends StatelessWidget {
  const ChatsView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<AuthProvider, Customer?>(
      selector: (_, authProvider) => authProvider.user,
      builder: (context, user, child) {
        if (user == null) {
          return Scaffold(
            body: Center(child: Text(context.tr('user_not_found'))),
          );
        }

        // chatMap doğrudan user'dan alınır
        final chatMap = user.chatMap ?? {};
        final sortedChats = chatMap.entries.toList()..sort((a, b) => b.value.lastMessageTime.compareTo(a.value.lastMessageTime));

        return Scaffold(
          appBar: child as PreferredSizeWidget, // AppBar'ı child olarak vermek rebuild'i engeller
          body: sortedChats.isEmpty
              ? Center(child: Text(context.tr('no_chats_yet')))
              : ListView.builder(
                  itemCount: sortedChats.length,
                  itemBuilder: (context, index) {
                    final otherUserId = sortedChats[index].key;
                    final chatSummary = sortedChats[index].value;

                    // Sola kaydırarak silme özelliği
                    return Dismissible(
                      key: Key(chatSummary.id),
                      direction: DismissDirection.endToStart, // Sadece sağdan sola kaydırma
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        // Silme işlemi için onay al
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(context.tr('delete_chat')),
                              content: Text(context.tr('delete_chat_confirmation')),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: Text(context.tr('cancel')),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: Text(context.tr('delete')),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) async {
                        // Sohbeti sil
                        final customerService = CustomerService();
                        try {
                          await customerService.deleteChat(user.userID!, otherUserId);

                          // Kullanıcıya bilgi ver
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.tr('chat_deleted'))),
                          );

                          // Stream ile veriler otomatik güncelleniyor, refreshUser'a gerek yok
                        } catch (e) {
                          // Hata durumunda kullanıcıya bilgi ver
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${context.tr('error')}: $e')),
                          );
                        }
                      },
                      child: ChatListItem(
                        customerService: CustomerService(),
                        chatSummary: chatSummary,
                        onTap: () => _navigateToChat(context, chatSummary.id, otherUserId),
                      ),
                    );
                  },
                ),
        );
      },
      child: AppBar(title: Text(context.tr('chats'))), // değişmeyen widget'lar child olarak verilebilir
    );
  }

  void _navigateToChat(BuildContext context, String chatId, String otherUserId) {
    // URL parametreleri ile yönlendir
    context.push('/chats/$chatId?otherId=$otherUserId');
  }
}
