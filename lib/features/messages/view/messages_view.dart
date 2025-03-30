import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/models/chat_model.dart';
import 'package:palseapp/core/services/firestore/report_service.dart';
import 'package:palseapp/core/widgets/scaffold_mess.dart';
import 'package:palseapp/features/achievement/achievement_service.dart';
import 'package:palseapp/features/achievement/achievements.dart';
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

  // İlk mesaj kontrolü için flag
  bool _hasCheckedFirstMessage = false;

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

  // İlk mesaj için XP ödülü ver
  void _checkAndRewardFirstMessage(List<Message> messages) async {
    // Hemen flag'i true yap ki birden fazla kontrol olmasın
    _hasCheckedFirstMessage = true;
    debugPrint('🔒 XP kontrolü kilitleniyor - yeni kontroller engelleniyor');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      debugPrint('⚠️ Kullanıcı bilgisi bulunamadı, XP kontrolü yapılamıyor.');
      return;
    }

    // Mesaj durumunu analiz et
    final messagesFromOther = messages.where((msg) => msg.senderId == widget.otherUserId).isNotEmpty;
    final messagesFromUs = messages.where((msg) => msg.senderId == widget.currentUserId).isNotEmpty;

    debugPrint('📊 Mesaj Durumu:');
    debugPrint('- Karşı taraftan mesaj var mı: $messagesFromOther');
    debugPrint('- Bizden mesaj var mı: $messagesFromUs');

    final userId = authProvider.user!.userID!;
    final chatId = widget.chatId;
    final achievementService = AchievementService();

    // Doğrudan yeni işleme metodunu kullan - sohbet bazlı daha güvenli kontrol
    await achievementService.processMessageRewards(
        userId: userId, chatId: chatId, isFirstMessageFromUs: messagesFromUs, isFirstMessageFromOther: messagesFromOther);

    debugPrint('✅ Mesaj ödülleri kontrol edildi');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final senderName = user?.firstName ?? '';
    final isPremium = user?.isPremium ?? false;
    final theme = Theme.of(context);

    // Kullanıcının engellediği kişilerin listesi
    final blockedUsers = user?.blockUsers ?? [];
    final isUserBlocked = blockedUsers.contains(widget.otherUserId);

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
              // Engelleme butonu için ekstra parametre
              actions: [
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'block') {
                      _blockUser(context, authProvider);
                    } else if (value == 'unblock') {
                      _unblockUser(context, authProvider);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    if (!isUserBlocked)
                      PopupMenuItem<String>(
                        value: 'block',
                        child: Row(
                          children: [
                            Icon(Icons.block, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(context.tr('block_user')),
                          ],
                        ),
                      )
                    else
                      PopupMenuItem<String>(
                        value: 'unblock',
                        child: Row(
                          children: [
                            Icon(Icons.person_add, color: Colors.green),
                            SizedBox(width: 8),
                            Text(context.tr('unblock_user')),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
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
                          return Center(
                            child: Text(
                              context.tr('error_occurred'),
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          );
                        }

                        // İlk yüklemede loading göster
                        if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.primary,
                            ),
                          );
                        }

                        final messages = snapshot.data ?? [];

                        // Kullanıcı engellenmiş ise, sadece kendi mesajlarımızı göster
                        // Filtrelemeyi burada yapıyoruz ki, okundu işaretleme ve diğer işlemler engellenen mesajlar için çalışmasın
                        final filteredMessages = isUserBlocked ? messages.where((msg) => msg.senderId == widget.currentUserId).toList() : messages;

                        // İlk mesaj kontrolü ve ödül verme - sadece engellenmemiş kullanıcılar için
                        if (!isUserBlocked) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!_hasCheckedFirstMessage && filteredMessages.isNotEmpty) {
                              debugPrint('🔍 İlk kez mesaj kontrolü yapılıyor...');
                              _checkAndRewardFirstMessage(filteredMessages);
                            }
                          });

                          // Yeni mesaj geldiğinde otomatik olarak okundu olarak işaretle
                          // Sadece engellenmemiş kullanıcılardan gelen mesajlar için
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            // Karşı taraftan gelen ve okunmamış mesajlar varsa işaretle
                            final unreadMessages = filteredMessages.where((msg) => msg.senderId == widget.otherUserId && !msg.isRead).toList();

                            if (unreadMessages.isNotEmpty) {
                              vm.markMessagesAsRead();
                            }
                          });
                        }

                        if (filteredMessages.isEmpty) {
                          return Center(
                            child: Text(
                              context.tr('no_messages'),
                              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                            ),
                          );
                        }

                        // Artık filtreleme yukarıda yapıldığı için burada tekrar yapmaya gerek yok
                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          itemCount: filteredMessages.length,
                          itemBuilder: (context, index) {
                            final message = filteredMessages[index];
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

  // Kullanıcıyı engelleme metodu
  void _blockUser(BuildContext context, AuthProvider authProvider) async {
    final reportService = ReportService();
    final currentUser = authProvider.user;

    try {
      // Kullanıcı modelini güncelle
      if (currentUser != null && currentUser.userID != null) {
        final updatedBlockList = List<String>.from(currentUser.blockUsers ?? []);

        // Eğer zaten engellenmiş ise tekrar ekleme
        if (!updatedBlockList.contains(widget.otherUserId)) {
          updatedBlockList.add(widget.otherUserId);

          final updatedUser = currentUser.copyWith(
            blockUsers: updatedBlockList,
          );

          authProvider.updateUser(updatedUser);

          // Firestore'da güncelle - kendi kullanıcı ID'mizi gönderiyoruz
          await reportService.blockUser(widget.otherUserId, currentUserId: currentUser.userID!);
        }
      }

      if (context.mounted) {
        ScaffoldMess.showSuccessSnackBar(context.tr('user_blocked'));
        // UI'ı güncellemek için setState çağır
        setState(() {});
      }
    } catch (e) {
      debugPrint('Kullanıcı engellenirken hata: ${e.toString()}');
      if (context.mounted) {
        ScaffoldMess.showErrorSnackBar(context.tr('error_occurred'));
      }
    }
  }

  // Kullanıcının engelini kaldırma metodu
  void _unblockUser(BuildContext context, AuthProvider authProvider) async {
    final reportService = ReportService();
    final currentUser = authProvider.user;

    try {
      // Kullanıcı modelini güncelle
      if (currentUser != null && currentUser.userID != null) {
        final updatedBlockList = List<String>.from(currentUser.blockUsers ?? []);

        // Listeden kaldır
        updatedBlockList.remove(widget.otherUserId);

        final updatedUser = currentUser.copyWith(
          blockUsers: updatedBlockList,
        );

        authProvider.updateUser(updatedUser);

        // Firestore'da güncelle - kendi kullanıcı ID'mizi gönderiyoruz
        await reportService.unblockUser(widget.otherUserId, currentUserId: currentUser.userID!);
      }

      if (context.mounted) {
        ScaffoldMess.showSuccessSnackBar(context.tr('user_unblocked'));
        // UI'ı güncellemek için setState çağır
        setState(() {});
      }
    } catch (e) {
      debugPrint('Kullanıcının engeli kaldırılırken hata: ${e.toString()}');
      if (context.mounted) {
        ScaffoldMess.showErrorSnackBar(context.tr('error_occurred'));
      }
    }
  }
}
