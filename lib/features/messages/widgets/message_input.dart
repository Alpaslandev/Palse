// Mesaj yazma alanı widget'ı - Alıntı gösterimi ile birlikte
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/models/chat_model.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/features/messages/viewmodel/messages_view_model.dart';
import 'package:provider/provider.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController _messageController = TextEditingController();
  final String chatId;
  final String currentUserId;
  final String otherUserId;
  final bool isPremium;
  final String senderName;

  MessageInput({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
    required this.isPremium,
    required this.senderName,
  });

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

  @override
  Widget build(BuildContext context) {
    return Consumer<MessagesViewModel>(
      builder: (context, viewModel, child) {
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
                      color: Colors.grey.shade200,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 40,
                          color: Colors.blue,
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
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                viewModel.quotedMessage?.content ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
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
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
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
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      Row(
                        children: [
                          IconButton(
                            icon: viewModel.isUploadingImage
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.attach_file),
                            onPressed: isPremium
                                ? viewModel.isUploadingImage
                                    ? null
                                    : () => viewModel.handleAttachment(context, senderName)
                                : () => _showPremiumDialog(context),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: context.tr('type_message'),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                ),
                                maxLines: null,
                                textCapitalization: TextCapitalization.sentences,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
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
                                  chatId,
                                  currentUserId,
                                  otherUserId,
                                  messageText,
                                  senderName,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('premium_required')),
        content: Text(context.tr('premium_photo_message')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pushNamed(paywall);
            },
            child: Text(context.tr('ok')),
          ),
        ],
      ),
    );
  }
}
