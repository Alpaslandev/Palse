import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/models/chat_model.dart';
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

  // Karşı tarafın ilk mesajı mı kontrolü
  bool _isFirstMessageFromOtherUser(List<Message> messages) {
    if (messages.isEmpty) return false;

    // Karşı taraftan gelen mesajlar
    final messagesFromOther = messages.where((msg) => msg.senderId == widget.otherUserId).toList();
    // Bizden giden mesajlar
    final messagesFromUs = messages.where((msg) => msg.senderId == widget.currentUserId).toList();

    // Karşı taraftan mesaj varsa ve bizden hiç mesaj yoksa
    return messagesFromOther.isNotEmpty && messagesFromUs.isEmpty;
  }

  // Bizim ilk mesajımız mı kontrolü
  bool _isFirstMessageFromUs(List<Message> messages) {
    if (messages.isEmpty) return false;

    // Karşı taraftan gelen mesajlar
    final messagesFromOther = messages.where((msg) => msg.senderId == widget.otherUserId).toList();
    // Bizden giden mesajlar
    final messagesFromUs = messages.where((msg) => msg.senderId == widget.currentUserId).toList();

    // Bizden mesaj varsa ve karşı taraftan hiç mesaj yoksa
    return messagesFromUs.isNotEmpty && messagesFromOther.isEmpty;
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
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final senderName = user?.firstName ?? '';
    final isPremium = user?.isPremium ?? false;
    final theme = Theme.of(context);

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

                        // İlk mesaj kontrolü ve ödül verme
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!_hasCheckedFirstMessage && messages.isNotEmpty) {
                            debugPrint('🔍 İlk kez mesaj kontrolü yapılıyor...');
                            _checkAndRewardFirstMessage(messages);
                          }
                        });

                        // Yeni mesaj geldiğinde otomatik olarak okundu olarak işaretle
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          // Karşı taraftan gelen ve okunmamış mesajlar varsa işaretle
                          final unreadMessages = messages.where((msg) => msg.senderId == widget.otherUserId && !msg.isRead).toList();

                          if (unreadMessages.isNotEmpty) {
                            vm.markMessagesAsRead();
                          }
                        });

                        if (messages.isEmpty) {
                          return Center(
                            child: Text(
                              context.tr('no_messages'),
                              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                            ),
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
