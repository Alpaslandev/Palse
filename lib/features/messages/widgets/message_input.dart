// Mesaj yazma alanı widget'ı - Alıntı gösterimi ile birlikte
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/models/chat_model.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/services/firestore/report_service.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/core/widgets/scaffold_mess.dart';
import 'package:palseapp/features/messages/viewmodel/messages_view_model.dart';
import 'package:provider/provider.dart';

class MessageInput extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserId;
  final bool isPremium;
  final String senderName;

  const MessageInput({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
    required this.isPremium,
    required this.senderName,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  // Controller'ı state içinde tut ve dispose etmeyi unutma
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // URL tespiti yapan yardımcı fonksiyon
  bool isUrl(String text) {
    // Basit bir URL regex kontrolü
    final urlRegExp = RegExp(
      r'^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-zA-Z0-9]+([\-\.]{1}[a-zA-Z0-9]+)*\.[a-zA-Z]{2,5}(:[0-9]{1,5})?(\/.*)?$',
      caseSensitive: false,
    );
    return urlRegExp.hasMatch(text.trim());
  }

  // Görsel URL'si olup olmadığını kontrol eden fonksiyon
  bool isImageUrl(String text) {
    // Görsel uzantılarını kontrol et
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.svg'];
    final lowerText = text.toLowerCase();

    // Hem URL olmalı hem de görsel uzantısına sahip olmalı
    return isUrl(text) && imageExtensions.any((ext) => lowerText.endsWith(ext));
  }

  // Kullanıcının engellenip engellenmediğini kontrol et
  bool isUserBlocked(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    if (currentUser == null || currentUser.blockUsers == null) {
      return false;
    }

    return currentUser.blockUsers!.contains(widget.otherUserId);
  }

  // Kullanıcının engelini kaldır
  Future<void> unblockUser(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    if (currentUser == null || currentUser.userID == null) return;

    try {
      final reportService = ReportService();
      await reportService.unblockUser(widget.otherUserId, currentUserId: currentUser.userID!);

      // Kullanıcı modelini güncelle
      if (currentUser.blockUsers != null) {
        final updatedBlockList = List<String>.from(currentUser.blockUsers!);
        updatedBlockList.remove(widget.otherUserId);

        final updatedUser = currentUser.copyWith(
          blockUsers: updatedBlockList,
        );

        authProvider.updateUser(updatedUser);

        ScaffoldMess.showSuccessSnackBar(context.tr('user_unblocked'));
      }
    } catch (e) {
      debugPrint('Kullanıcı engeli kaldırılırken hata: ${e.toString()}');
      ScaffoldMess.showErrorSnackBar(context.tr('error_occurred'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isBlocked = isUserBlocked(context);

    return Consumer<MessagesViewModel>(
      builder: (context, viewModel, child) {
        // Kullanıcı engellenmişse engel bilgisi göster
        if (isBlocked) {
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.block, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.tr('user_blocked_message'),
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => unblockUser(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: Text(context.tr('unblock_user')),
                  ),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          child: GestureDetector(
            // Mesaj giriş alanına dokunulduğunda olayın üst widget'lara yayılmasını engelle
            onTap: () {}, // Boş onTap olayı, olayın üst widget'lara yayılmasını engeller
            behavior: HitTestBehavior.opaque, // Tüm alanı kapsayacak şekilde dokunma olaylarını yakala
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Alıntılanan mesaj varsa göster
                if (viewModel.quotedMessage != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.quoteBackground,
                      border: Border(
                        top: BorderSide(color: theme.dividerColor),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 40,
                          color: theme.colorScheme.primary,
                          margin: const EdgeInsets.only(right: 8),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context.tr('quote'),
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                viewModel.quotedMessage?.content ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: theme.colorScheme.onSurface),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                          onPressed: () => viewModel.clearQuotedMessage(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ),
                // Mesaj yazma alanı
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (viewModel.isUploadingImage)
                        LinearProgressIndicator(
                          value: viewModel.uploadProgress,
                          backgroundColor: theme.colorScheme.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                        ),
                      Row(
                        children: [
                          IconButton(
                            icon: viewModel.isUploadingImage
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                : Icon(Icons.attach_file, color: theme.colorScheme.onSurface),
                            onPressed: widget.isPremium
                                ? viewModel.isUploadingImage
                                    ? null
                                    : () => viewModel.handleAttachment(context, widget.senderName)
                                : () => _showPremiumDialog(context),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: context.tr('type_message'),
                                  hintStyle: TextStyle(color: theme.hintColor),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                ),
                                style: TextStyle(color: theme.colorScheme.onSurface),
                                maxLines: null,
                                textCapitalization: TextCapitalization.sentences,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.send, color: theme.colorScheme.primary),
                            onPressed: () {
                              if (_messageController.text.trim().isNotEmpty) {
                                // Mesajın URL olup olmadığını kontrol et
                                final messageText = _messageController.text.trim();

                                // Mesaj tipini belirle: görsel URL mi, normal URL mi, normal mesaj mı?
                                MessageType messageType;
                                if (isImageUrl(messageText)) {
                                  // Görsel URL ise image tipi olarak işaretle
                                  messageType = MessageType.image;
                                } else if (isUrl(messageText)) {
                                  // Normal URL ise url tipi olarak işaretle
                                  messageType = MessageType.url;
                                } else {
                                  // Normal metin mesajı
                                  messageType = MessageType.text;
                                }

                                viewModel.sendMessage(
                                  widget.chatId,
                                  widget.currentUserId,
                                  widget.otherUserId,
                                  messageText,
                                  widget.senderName,
                                  messageType,
                                );
                                _messageController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPremiumDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          context.tr('premium_required'),
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Text(
          context.tr('premium_photo_message'),
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pushNamed(paywall);
            },
            child: Text(
              context.tr('ok'),
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
