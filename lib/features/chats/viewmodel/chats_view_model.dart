import 'package:flutter/material.dart';
import 'package:palseapp/core/models/chat_model.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/firestore/chat_service.dart';
import 'package:palseapp/core/provider/auth_provider.dart';

class ChatsViewModel extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final AuthProvider _authProvider;

  ChatsViewModel(this._authProvider);

  String? get currentUserId => _authProvider.user?.userID;

  // Sohbetleri dinle
  Stream<List<Chat>> getChats(String userId) {
    return _chatService.getChats(userId);
  }

  // Kullanıcı bilgilerini al
  Stream<Customer?> getUserInfo(String userId) {
    return _chatService.getUserInfo(userId);
  }

  // Sohbet başlat veya var olan sohbeti bul
  Future<String> startOrGetChat(String userId1, String userId2) async {
    try {
      // Önce var olan sohbeti kontrol et
      final existingChat = await _chatService.findExistingChat(userId1, userId2);

      if (existingChat != null) {
        return existingChat;
      }

      // Yoksa yeni sohbet başlat
      return await _chatService.startNewChat(userId1, userId2);
    } catch (e) {
      debugPrint('Sohbet başlatma hatası: $e');
      rethrow;
    }
  }
}
