import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:palseapp/core/constant/notifications_enum.dart';
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

  // Mesaj gönderme
  Future<void> sendMessage(String chatId, Message message, String senderId, String receiverId, String senderName) async {
    try {
      // 1. Batch işlemi başlat
      final batch = _db.batch();

      // 2. Mesajı Firestore'a ekle
      final messageRef = _db.collection('chats').doc(chatId).collection('messages').doc();
      batch.set(messageRef, message.toMap());

      // 3. Chat belgesini güncelle (son mesaj bilgileri)
      final chatUpdate = {
        'lastMessage': message.content,
        'lastMessageTime': message.timestamp,
        'lastMessageSenderId': message.senderId,
        'lastMessageType': message.type.value,
        'lastMessageQuoted': message.quotedMessage != null,
        'isTemporary': false
      };
      batch.update(_db.collection('chats').doc(chatId), chatUpdate);

      // 4. Kullanıcı belgelerini güncelle
      // Gönderen için (kendi gönderdiği mesajın okunmadığını gösterir, unreadCount değişmez)
      batch.set(
          _db.collection('customers').doc(senderId),
          {
            'chatMap': {
              receiverId: {
                'otherUserId': receiverId,
                'chatId': chatId,
                'lastMessage': message.content,
                'lastMessageTime': message.timestamp,
                'lastMessageSenderId': message.senderId,
                'lastMessageType': message.type.value,
                'isLastMessageRead': false, // Karşı taraf henüz okumadı
                // unreadCount değişmez
              }
            }
          },
          SetOptions(merge: true));

      // Alıcı için (yeni mesaj okunmamış, unreadCount artar)
      // FieldValue.increment kullanarak mevcut değeri okumadan artırabiliriz
      batch.set(
          _db.collection('customers').doc(receiverId),
          {
            'chatMap': {
              senderId: {
                'otherUserId': senderId,
                'chatId': chatId,
                'senderName': senderName,
                'lastMessage': message.content,
                'lastMessageTime': message.timestamp,
                'lastMessageSenderId': message.senderId,
                'lastMessageType': message.type.value,
                'isLastMessageRead': false, // Yeni mesajı henüz okumadı
                'unreadCount': FieldValue.increment(1) // Mevcut değeri 1 artır
              }
            }
          },
          SetOptions(merge: true));

      // 5. Değişiklikleri kaydet
      await batch.commit();

      // 6. Bildirimi gönder
      await notificationService.sendNotification(
        receiverId: receiverId,
        chatId: chatId,
        notificationType: NotificationsEnum.message,
      );
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
  Future<void> markChatAsRead(String chatId, String currentUserId, String otherUserId) async {
    try {
      // 1. Chat belgesinden son mesajı kimin gönderdiğini al
      final chatDoc = await _db.collection('chats').doc(chatId).get();
      final lastMessageSenderId = chatDoc.data()?['lastMessageSenderId'];

      // 2. Batch işlemi başlat
      final batch = _db.batch();

      // 3. Tüm okunmamış mesajları bul ve işaretle
      final messagesRef = _db.collection('chats').doc(chatId).collection('messages');
      final unreadMessages = await messagesRef.where('senderId', isEqualTo: otherUserId).where('isRead', isEqualTo: false).get();

      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      // 4. Kendi belgemdeki unreadCount ve isLastMessageRead'i güncelle
      batch.update(
          _db.collection('customers').doc(currentUserId), {'chatMap.$otherUserId.unreadCount': 0, 'chatMap.$otherUserId.isLastMessageRead': true});

      // 5. SADECE son mesajı karşı taraf gönderdiyse, karşı tarafın belgesindeki isLastMessageRead'i güncelle
      if (lastMessageSenderId == otherUserId) {
        batch.update(_db.collection('customers').doc(otherUserId), {'chatMap.$currentUserId.isLastMessageRead': true});
      }

      // 6. Değişiklikleri kaydet
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
