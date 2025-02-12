import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/models/chat_model.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/firestore/chat_service.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';

class MessagesViewModel extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final CustomerService _customerService = CustomerService();

  Customer? otherUser;
  List<Message> messages = [];
  bool isLoading = false;
  Message? _quotedMessage;

  Message? get quotedMessage => _quotedMessage;

  MessagesViewModel(String otherUserId) {
    getUserInfo(otherUserId);
  }

  // Mesajları dinle
  Stream<List<Message>> getMessages(String chatId) {
    return _chatService.getMessages(chatId);
  }

  // Müşteri bilgilerini al
  Future<Customer?> getUserInfo(String userId) async {
    isLoading = true;
    notifyListeners();
    try {
      otherUser = await _customerService.fetchUserFromFirestore(userId);
      return otherUser;
    } catch (e) {
      debugPrint('Müşteri bilgileri alınamadı: $e');
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Alıntı mesajını ayarla
  void setQuotedMessage(Message? message) {
    _quotedMessage = message;
    notifyListeners();
  }

  // Alıntı mesajını temizle
  void clearQuotedMessage() {
    _quotedMessage = null;
    notifyListeners();
  }

  // Yeni sohbet başlat
  Future<void> startNewChat(String userId1, String userId2) async {
    try {
      isLoading = true;
      notifyListeners();
      await _chatService.startNewChat(userId1, userId2);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Mesaj gönder
  Future<void> sendMessage(String chatId, String senderId, String receiverId, String content) async {
    if (content.trim().isEmpty) return;

    try {
      isLoading = true;
      notifyListeners();

      // Alıntı mesajı varsa, mesajı alıntıyla birlikte gönder
      final messageToSend = Message(
        senderId: senderId,
        content: content,
        timestamp: Timestamp.now(),
        isRead: false,
        type: 'text',
        quotedMessage: _quotedMessage?.content,
        quotedMessageId: _quotedMessage?.senderId,
      );

      await _chatService.sendMessage(
        chatId,
        messageToSend,
      );

      // Mesaj gönderildikten sonra alıntıyı temizle
      setQuotedMessage(null);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Mesajları okundu olarak işaretle
  Future<void> markMessagesAsRead(String chatId, String currentUserId, String otherUserId) async {
    try {
      await _chatService.markMessagesAsRead(chatId, currentUserId, otherUserId);
      notifyListeners();
    } catch (e) {
      debugPrint('Mesajları okundu işaretleme hatası: $e');
    }
  }

  // Dosya ekleme işlemini yönet
  Future<void> handleAttachment(BuildContext context) async {
    // TODO: Dosya ekleme işlemi için gerekli kodlar eklenecek
    debugPrint('Dosya ekleme özelliği yakında eklenecek');
  }
}
