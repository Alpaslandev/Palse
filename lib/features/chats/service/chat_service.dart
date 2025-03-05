import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:palseapp/core/models/chat_model.dart';
import 'package:flutter/foundation.dart';
import 'package:palseapp/core/services/notification_service.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService notificationService;

  ChatService({NotificationService? notificationService}) : notificationService = notificationService ?? NotificationService();

  // Var olan sohbeti bul
  Future<String?> findExistingChat(String userId1, String userId2) async {
    try {
      // participants array'inde her iki kullanıcının da olduğu chat'i ara
      final snapshot = await _db.collection('chats').where('participants', arrayContainsAny: [userId1]).get();

      for (var doc in snapshot.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(userId1) && participants.contains(userId2)) {
          return doc.id;
        }
      }
      return null;
    } catch (e) {
      _logError('findExistingChat', e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  // Sohbet başlat veya var olanı getir - String ID döndürür
  Future<String> startOrGetChat(String otherUserId, String currentUserId) async {
    try {
      // 1. İki kullanıcı arasında mevcut bir sohbet var mı kontrol et
      final existingChatId = await findExistingChat(currentUserId, otherUserId);

      if (existingChatId != null) {
        // Var olan sohbetin ID'sini döndür
        return existingChatId;
      }

      // 2. Yeni sohbet oluştur
      final chatId = _db.collection('chats').doc().id;

      final newChat = Chat.create(
        chatId: chatId,
        participants: [currentUserId, otherUserId],
      );

      // 3. Sadece Firestore'daki "chats" koleksiyonuna kaydet
      await _db.collection('chats').doc(chatId).set(newChat.toFirestoreJson());

      // Chat ID'sini döndür
      return chatId;
    } catch (e) {
      _logError('startOrGetChat', e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  // Mesajları okundu olarak işaretle
  Future<void> markMessagesAsRead(String chatId, String currentUserId, String otherUserId) async {
    try {
      // Parametreleri kontrol et
      if (chatId.isEmpty) {
        debugPrint("HATA: markMessagesAsRead - chatId boş string!");
        return;
      }
      if (currentUserId.isEmpty || otherUserId.isEmpty) {
        debugPrint("HATA: markMessagesAsRead - userID'lerden biri boş: currentUserId=$currentUserId, otherUserId=$otherUserId");
        return;
      }

      // 1. Son sohbet durumunu al
      final chatDoc = await _db.collection('chats').doc(chatId).get();
      final chatData = chatDoc.data();

      if (chatData == null) {
        debugPrint("HATA: markMessagesAsRead - Chat belgesi bulunamadı: $chatId");
        return;
      }

      final chat = Chat.fromFirestore(chatData, chatId);

      // 2. Karşı taraftan gelen ve okunmamış mesajları işaretle
      final messagesQuery = await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isEqualTo: otherUserId)
          .where('isRead', isEqualTo: false)
          .get();

      // 3. Mesajları işaretle (batch işlemi)
      if (messagesQuery.docs.isNotEmpty) {
        final batch = _db.batch();

        for (var doc in messagesQuery.docs) {
          batch.update(doc.reference, {'isRead': true});
        }

        // 4. Kullanıcı belgesindeki chatMap'i güncelle
        // NOT: Chat koleksiyonunda unreadCount tutmuyoruz, sadece kullanıcı belgesini güncelliyoruz
        if (chat.lastMessageSenderId == otherUserId) {
          batch.update(_db.collection('customers').doc(currentUserId),
              {'chatMap.$otherUserId.unreadCount': 0, 'chatMap.$otherUserId.isLastMessageRead': true});
        }

        await batch.commit();
      }
    } catch (e) {
      _logError('markMessagesAsRead', e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  // Mesaj gönderme
  Future<void> sendMessage(String chatId, Message message, String currentUserId) async {
    try {
      // chatId kontrolü
      if (chatId.isEmpty) {
        debugPrint("HATA: chatId boş string!");
        return;
      }

      // 1. Chat belgesini kontrol et
      final chatDoc = await _db.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        debugPrint("HATA: Chat belgesi bulunamadı: $chatId");
        return;
      }

      final chatData = chatDoc.data();
      if (chatData == null) {
        debugPrint("HATA: Chat belgesi bulunamadı: $chatId");
        return;
      }

      // 2. Chat nesnesini oluştur
      final chat = Chat.fromFirestore(chatData, chatId);
      final otherUserId = chat.getOtherUserId(currentUserId);

      if (otherUserId.isEmpty) {
        debugPrint("HATA: Diğer kullanıcı ID'si bulunamadı");
        return;
      }

      // 3. Mesajı Firestore'a ekle
      await _db.collection('chats').doc(chatId).collection('messages').add(message.toMap());

      // 4. İlk mesaj olup olmadığını kontrol et (lastMessage boşsa ilk mesaj)
      bool isFirstMessage = chat.lastMessage.isEmpty;

      // 5. Son mesaj bilgilerini güncelle
      final updatedChat = chat.copyWith(
        lastMessage: message.content,
        lastMessageTime: message.timestamp,
        lastMessageSenderId: message.senderId,
        lastMessageType: message.type.value,
        lastMessageQuoted: message.quotedMessage != null,
        isTemporary: false,
        // Chat koleksiyonunda unreadCount tutmuyoruz - her kullanıcı kendi belgelerinde tutar
      );

      // 6. Batch işlemi başlat
      final batch = _db.batch();

      // 7. Chat belgesini güncelle
      batch.update(_db.collection('chats').doc(chatId), updatedChat.toFirestoreJson());

      // 8. Kullanıcı belgesini güncelle (her iki kullanıcı için)
      try {
        // Kullanıcı belgelerini al
        final currentUserDoc = await _db.collection('customers').doc(currentUserId).get();
        final otherUserDoc = await _db.collection('customers').doc(otherUserId).get();

        // Mesajı gönderen ve alan için farklı unreadCount değerleri
        // Mesajı gönderen: unreadCount = 0 (kendi mesajını okumuş sayılır)
        // Mesajı alan: unreadCount + 1 veya isFirstMessage ise 1
        final senderUnreadCount = 0;
        final receiverUnreadCount = isFirstMessage
            ? 1
            : (otherUserDoc.exists && otherUserDoc.data()?['chatMap']?[currentUserId]?['unreadCount'] != null
                ? otherUserDoc.data()!['chatMap'][currentUserId]['unreadCount'] + 1
                : 1);

        // Gönderen için ChatMap güncellemesi (unreadCount = 0)
        final senderChat = updatedChat.copyWith(unreadCount: senderUnreadCount, isLastMessageRead: false);

        // Alıcı için ChatMap güncellemesi (unreadCount artar)
        final receiverChat = updatedChat.copyWith(unreadCount: receiverUnreadCount, isLastMessageRead: false);

        // Gönderen için chatMap - kendi mesajını okumuş sayılır
        final senderChatMap = {'chatMap.$otherUserId': senderChat.toUserDocumentJson(currentUserId)};

        // Alıcı için chatMap - okunmamış mesajı var
        final receiverChatMap = {'chatMap.$currentUserId': receiverChat.toUserDocumentJson(otherUserId)};

        // İlk mesaj ise veya chatMap güncellenecekse
        if (isFirstMessage || currentUserDoc.exists) {
          // Gönderenin belgesini güncelle
          if (currentUserDoc.exists) {
            batch.update(_db.collection('customers').doc(currentUserId), senderChatMap);
          } else {
            batch.set(
                _db.collection('customers').doc(currentUserId),
                {
                  'chatMap': {otherUserId: senderChatMap['chatMap.$otherUserId']}
                },
                SetOptions(merge: true));
          }
        }

        // İlk mesaj ise veya diğer kullanıcının belgesi varsa
        if (isFirstMessage || otherUserDoc.exists) {
          // Alıcının belgesini güncelle
          if (otherUserDoc.exists) {
            batch.update(_db.collection('customers').doc(otherUserId), receiverChatMap);
          } else {
            batch.set(
                _db.collection('customers').doc(otherUserId),
                {
                  'chatMap': {currentUserId: receiverChatMap['chatMap.$currentUserId']}
                },
                SetOptions(merge: true));
          }
        }
      } catch (e) {
        debugPrint("HATA: chatMap güncelleme hatası: $e. Belge oluşturuluyor...");

        // Gönderen ve alıcı için farklı unreadCount değerleri hazırla
        int senderUnreadCount = 0;
        int receiverUnreadCount = 0;

        if (message.senderId == currentUserId) {
          // Ben gönderdim
          receiverUnreadCount = chat.unreadCount + 1;
        } else {
          // Karşı taraf gönderdi
          senderUnreadCount = chat.unreadCount + 1;
        }

        // Kullanıcı belgeleri için chatMap oluştur
        final userChatMap = {
          'chatMap': {otherUserId: updatedChat.copyWith(unreadCount: senderUnreadCount).toUserDocumentJson(currentUserId)}
        };

        final otherUserChatMap = {
          'chatMap': {currentUserId: updatedChat.copyWith(unreadCount: receiverUnreadCount).toUserDocumentJson(otherUserId)}
        };

        // Verileri set et (merge: true ile mevcut verileri korur)
        batch.set(_db.collection('customers').doc(currentUserId), userChatMap, SetOptions(merge: true));
        batch.set(_db.collection('customers').doc(otherUserId), otherUserChatMap, SetOptions(merge: true));
      }

      // 9. Değişiklikleri kaydet
      await batch.commit();

      // 10. Bildirimi gönder
      if (otherUserId.isNotEmpty) {
        await notificationService.sendNotification(
          receiverId: otherUserId,
          senderName: '',
          message: message.type == 'image' ? '📷 Fotoğraf gönderdi' : message.content,
          chatId: chatId,
          senderId: message.senderId,
        );
      }
    } catch (e) {
      _logError('sendMessage', e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  // Mesajları dinle
  Stream<List<Message>> getMessages(String chatId, {int limit = 20, DocumentSnapshot? startAfter}) {
    var query = _db.collection('chats/$chatId/messages').orderBy('timestamp', descending: true).limit(limit);

    if (startAfter != null) query = query.startAfterDocument(startAfter);

    return query.snapshots().map((snapshot) => snapshot.docs.map((doc) => Message.fromMap(doc.data(), doc.id)).toList());
  }

  // Sohbeti okundu olarak işaretle (tüm mesajlar)
  Future<void> markChatAsRead(String chatId, String currentUserId) async {
    try {
      // Parametreleri kontrol et
      if (chatId.isEmpty) {
        debugPrint("HATA: markChatAsRead - chatId boş string!");
        return;
      }
      if (currentUserId.isEmpty) {
        debugPrint("HATA: markChatAsRead - currentUserId boş!");
        return;
      }

      // 1. Chat belgesini al
      final chatDoc = await _db.collection('chats').doc(chatId).get();
      final chatData = chatDoc.data();

      if (chatData == null) {
        debugPrint("HATA: markChatAsRead - Chat belgesi bulunamadı: $chatId");
        return;
      }

      final chat = Chat.fromFirestore(chatData, chatId);
      final otherUserId = chat.getOtherUserId(currentUserId);

      if (otherUserId.isEmpty) {
        debugPrint("HATA: markChatAsRead - Diğer kullanıcı ID'si bulunamadı");
        return;
      }

      // Son mesaj benden ise işlem yapmaya gerek yok
      if (chat.lastMessageSenderId == currentUserId) return;

      // 2. Tüm okunmamış mesajları bul
      final messagesRef = _db.collection('chats').doc(chatId).collection('messages');
      final unreadMessages = await messagesRef.where('senderId', isEqualTo: otherUserId).where('isRead', isEqualTo: false).get();

      if (unreadMessages.docs.isEmpty) return;

      // 3. Batch işlemi başlat
      final batch = _db.batch();

      // Tüm mesajları okundu olarak işaretle
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      // Chat belgesini güncelle
      batch.update(_db.collection('chats').doc(chatId), {'unreadCount': 0, 'isLastMessageRead': true});

      // Kullanıcı belgesini güncelle
      batch.update(
          _db.collection('customers').doc(currentUserId), {'chatMap.$otherUserId.unreadCount': 0, 'chatMap.$otherUserId.isLastMessageRead': true});

      await batch.commit();
    } catch (e) {
      _logError('markChatAsRead', e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  void _logError(String method, Object error, {StackTrace? stackTrace}) {
    debugPrint('''[ChatService] $method hatası: 
    Hata: $error
    StackTrace: ${stackTrace ?? 'Yok'}
    ''');
  }
}
