// Mesaj yazma alanı widget'ı - Alıntı gösterimi ile birlikte
import 'package:flutter/material.dart';
import 'package:palseapp/core/models/chat_model.dart';
import 'package:palseapp/features/messages/viewmodel/messages_view_model.dart';
import 'package:provider/provider.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController _messageController = TextEditingController();
  final String chatId;
  final String currentUserId;
  final String otherUserId;

  MessageInput({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MessagesViewModel>(
      builder: (context, viewModel, child) {
        return Column(
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
                            'Alıntı',
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
              padding: const EdgeInsets.symmetric(horizontal: 8),
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
                        onPressed: viewModel.isUploadingImage ? null : () => viewModel.handleAttachment(context),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Mesaj yazın...',
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          if (_messageController.text.trim().isNotEmpty) {
                            viewModel.sendMessage(
                              chatId,
                              currentUserId,
                              otherUserId,
                              _messageController.text,
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
        );
      },
    );
  }
}
