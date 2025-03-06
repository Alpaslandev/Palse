import 'package:flutter/material.dart';
import 'package:palseapp/core/models/chat_model.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/features/chats/service/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatsViewModel extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final Customer _customer;
  bool isLoading = true;

  ChatsViewModel(this._customer);

  String? get currentUserId => _customer.userID;
  Customer? get currentUser => _customer;

  // Sohbet başlat veya var olan sohbeti bul (String chatId döndürür)
  Future<String> startOrGetChat(String otherUserId) async {
    final currentUserId = _customer.userID;
    if (currentUserId == null || currentUserId.isEmpty) {
      throw Exception("Geçerli kullanıcı kimliği bulunamadı");
    }

    try {
      // ChatService'ten chatId al
      return await _chatService.startOrGetChat(otherUserId, currentUserId);
    } catch (e) {
      debugPrint('Sohbet başlatma hatası: $e');
      rethrow;
    }
  }

  // Chat nesnesi getir
  Future<Chat> getChat(String chatId) async {
    try {
      final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) {
        throw Exception("Chat belgesi bulunamadı: $chatId");
      }
      return Chat.fromFirestore(chatDoc.data() ?? {}, chatId);
    } catch (e) {
      debugPrint('Chat getirme hatası: $e');
      rethrow;
    }
  }
}

/*

// Chat listesi view için
Widget buildChatList(Customer customer) {
  // Sıralanmış sohbet özetlerini al
  final sortedChats = customer.getSortedChatSummaries();
  
  return ListView.builder(
    itemCount: sortedChats.length,
    itemBuilder: (context, index) {
      final chat = sortedChats[index];
      return ListTile(
        title: Text(chat.otherUserName),
        subtitle: Text(chat.lastMessage),
        onTap: () => navigateToChatScreen(chat.chatId, chat.otherUserId),
      );
    }
  );
}

// Mesaj gönder butonu için
void onMessageButtonPressed(String otherUserId) {
  final customer = Provider.of<AuthProvider>(context, listen: false).user;
  
  // Mevcut sohbeti hızlıca bul (O(1) erişim)
  final existingChat = customer?.findChatWithUser(otherUserId);
  
  if (existingChat != null) {
    // Mevcut sohbeti aç
    navigateToChatScreen(existingChat.chatId, otherUserId);
  } else {
    // Yeni sohbet başlat
    chatService.startOrGetChat(customer!.userID!, otherUserId).then((chatId) {
      navigateToChatScreen(chatId, otherUserId);
    });
  }
}



*/
