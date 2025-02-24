import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:palseapp/features/chats/model/chat_model.dart';
import 'package:palseapp/core/models/customer.dart';
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

  Stream<Customer?> getUserInfo(String userId) {
    return _db
        .collection('customers')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.data() != null ? Customer.fromJson(snapshot.data()!, userId) : null);
  }

  // Sohbet başlat veya var olanı getir
  Future<String> startOrGetChat(String userId1, String userId2) async {
    try {
      // Önce var olan chat'i kontrol et
      final existingChatId = await findExistingChat(userId1, userId2);
      if (existingChatId != null) {
        return existingChatId;
      }

      // Yeni chat oluştur
      final chatRef = _db.collection('chats').doc();

      // 5 dakika sonra silinecek bir flag ekle
      final tempFlag = true;
      final creationTime = FieldValue.serverTimestamp();

      final batch = _db.batch();

      // Chat belgesini oluştur
      batch.set(chatRef, {
        'participants': [userId1, userId2],
        'lastMessage': '',
        'lastMessageTime': creationTime,
        'lastMessageSenderId': '',
        'isTemporary': tempFlag,
        'createdAt': creationTime,
      });

      // Her iki kullanıcının chatInfos'unu güncelle
      final chatInfo = {
        'chatId': chatRef.id,
        'lastMessageTime': creationTime,
        'unreadCount': 0,
      };

      batch.set(
        _db.collection('customers').doc(userId1),
        {
          'chatInfos': {
            userId2: {
              ...chatInfo,
              'otherUserId': userId2,
            }
          }
        },
        SetOptions(merge: true),
      );

      batch.set(
        _db.collection('customers').doc(userId2),
        {
          'chatInfos': {
            userId1: {
              ...chatInfo,
              'otherUserId': userId1,
            }
          }
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      // 5 dakika sonra mesaj yoksa chat'i sil
      Future.delayed(const Duration(minutes: 5), () async {
        final chatDoc = await chatRef.get();
        if (chatDoc.exists) {
          final data = chatDoc.data();
          if (data != null && data['isTemporary'] == true && data['lastMessage'] == '') {
            // Chat'i ve ilgili referansları sil
            final batch = _db.batch();

            // Chat'i sil
            batch.delete(chatRef);

            // Kullanıcıların chatInfos'undan sil
            batch.set(
              _db.collection('customers').doc(userId1),
              {
                'chatInfos': {userId2: FieldValue.delete()}
              },
              SetOptions(merge: true),
            );

            batch.set(
              _db.collection('customers').doc(userId2),
              {
                'chatInfos': {userId1: FieldValue.delete()}
              },
              SetOptions(merge: true),
            );

            await batch.commit();
          }
        }
      });

      return chatRef.id;
    } catch (e) {
      _logError('startOrGetChat', e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  // Transaction ile unreadCount güncelleme
  Future<void> incrementUnreadCount(String chatId, String senderId, String receiverId) async {
    final db = FirebaseFirestore.instance;

    await db.runTransaction((transaction) async {
      // Alıcının dökümanını al
      final receiverDoc = await transaction.get(db.collection('customers').doc(receiverId));

      // Mevcut chatInfos map'ini al
      final chatInfos = receiverDoc.data()?['chatInfos'] as Map<String, dynamic>? ?? {};

      // Mevcut unreadCount'u al ve 1 artır
      final currentUnreadCount = (chatInfos[senderId]?['unreadCount'] ?? 0) + 1;

      // Transaction ile güncelle
      transaction.set(
          db.collection('customers').doc(receiverId),
          {
            'chatInfos': {
              senderId: {'unreadCount': currentUnreadCount}
            }
          },
          SetOptions(merge: true));
    });
  }

  // Mesajları okundu olarak işaretle
  Future<void> markMessagesAsRead(String chatId, String currentUserId, String otherUserId) async {
    final db = FirebaseFirestore.instance;

    // Transaction başlat
    await db.runTransaction((transaction) async {
      // 1. Önce tüm okumaları yapalım
      final messagesQuery = await db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isEqualTo: otherUserId)
          .where('isRead', isEqualTo: false)
          .get();

      final chatDoc = await transaction.get(db.collection('chats').doc(chatId));
      final lastMessageSenderId = chatDoc.data()?['lastMessageSenderId'];

      // 2. Şimdi yazma işlemlerini yapalım
      // Mesajları okundu olarak işaretle
      for (var doc in messagesQuery.docs) {
        transaction.update(doc.reference, {'isRead': true});
      }

      // Son mesajın göndereni karşı tarafsa, son mesajı okundu olarak işaretle
      if (lastMessageSenderId == otherUserId) {
        transaction.update(db.collection('chats').doc(chatId), {'lastMessageIsRead': true});
      }

      // unreadCount'u sıfırla
      transaction.set(
          db.collection('customers').doc(currentUserId),
          {
            'chatInfos': {
              otherUserId: {'unreadCount': 0}
            }
          },
          SetOptions(merge: true));
    });
  }

  // Mesaj gönderme
  Future<void> sendMessage(String chatId, Message message, String senderName) async {
    try {
      String receiverId = '';

      await _db.runTransaction((transaction) async {
        // Chat dokümanını oku
        final chatDoc = await transaction.get(_db.collection('chats').doc(chatId));
        final participants = List<String>.from(chatDoc.data()?['participants'] ?? []);
        receiverId = participants.firstWhere((id) => id != message.senderId);

        // Alıcının dokümanını oku
        final receiverDoc = await transaction.get(_db.collection('customers').doc(receiverId));
        final chatInfos = receiverDoc.data()?['chatInfos'] as Map<String, dynamic>? ?? {};
        final currentUnreadCount = (chatInfos[message.senderId]?['unreadCount'] ?? 0) + 1;

        // Mesajı ekle
        final messageRef = _db.collection('chats').doc(chatId).collection('messages').doc();

        // ServerTimestamp kullan
        final messageData = message.toMap();
        messageData['timestamp'] = FieldValue.serverTimestamp();
        transaction.set(messageRef, messageData);

        // Son mesaj bilgisini güncelle
        final lastMessageData = {
          'lastMessage': message.type == 'image' ? '📷 Fotoğraf' : message.content,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSenderId': message.senderId,
          'lastMessageIsRead': false,
          'lastMessageType': message.type,
          'lastMessageQuoted': message.quotedMessage != null,
        };

        // Chat dokümanını güncelle - öncelikli olarak bunu yap
        transaction.update(_db.collection('chats').doc(chatId), lastMessageData);

        // Her iki kullanıcının chatInfos'unu güncelle
        transaction.set(
          _db.collection('customers').doc(receiverId),
          {
            'chatInfos': {
              message.senderId: {
                'chatId': chatId,
                'lastMessageTime': FieldValue.serverTimestamp(),
                'unreadCount': currentUnreadCount,
                'otherUserId': message.senderId
              }
            }
          },
          SetOptions(merge: true),
        );

        transaction.set(
          _db.collection('customers').doc(message.senderId),
          {
            'chatInfos': {
              receiverId: {'chatId': chatId, 'lastMessageTime': FieldValue.serverTimestamp(), 'otherUserId': receiverId}
            }
          },
          SetOptions(merge: true),
        );

        // isTemporary flag'ini kaldır
        transaction.update(_db.collection('chats').doc(chatId), {
          ...lastMessageData,
          'isTemporary': false,
        });
      });

      // Bildirimi gönder
      if (receiverId.isNotEmpty) {
        await notificationService.sendNotification(
          receiverId: receiverId,
          senderName: senderName,
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

    return query.snapshots().map((snapshot) => snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList());
  }

  // Sohbetleri dinle
  Stream<List<Chat>> getChats(String userId) {
    debugPrint('Getting chats for user: $userId');

    // Direkt chats koleksiyonunu dinleyelim
    return _db.collection('chats').where('participants', arrayContains: userId).snapshots().asyncMap((chatsSnapshot) async {
      // Kullanıcının dokümanını bir kez alalım (unreadCount için)
      final userDoc = await _db.collection('customers').doc(userId).get();
      final chatInfos = (userDoc.data()?['chatInfos'] as Map<String, dynamic>?) ?? {};

      final chats = chatsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        // Diğer kullanıcının ID'sini bul
        final otherUserId = (data['participants'] as List<dynamic>).firstWhere((id) => id != userId, orElse: () => '');

        // Sadece unreadCount için chatInfos'u kullanalım
        final unreadCount = (chatInfos[otherUserId]?['unreadCount'] as int?) ?? 0;
        data['unreadCount'] = unreadCount;

        return Chat.fromMap(data);
      }).toList();

      // Son mesaj zamanına göre sırala
      chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

      return chats;
    });
  }

  void _logError(String method, Object error, {StackTrace? stackTrace}) {
    debugPrint('''[ChatService] $method hatası: 
    Hata: $error
    StackTrace: ${stackTrace ?? 'Yok'}
    ''');
  }
}
