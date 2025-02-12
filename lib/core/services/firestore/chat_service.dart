import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:palseapp/core/models/chat_model.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:flutter/foundation.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Var olan sohbeti bul
  Future<String?> findExistingChat(String userId1, String userId2) async {
    try {
      final snapshot = await _db.collection('chats').where('participants', arrayContainsAny: [userId1]).get();

      for (var doc in snapshot.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(userId2)) {
          return doc.id;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Sohbet arama hatası: $e');
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

  // Yeni sohbet başlat ve chatId döndür
  Future<String> startNewChat(String userId1, String userId2) async {
    try {
      // Yeni chat belgesi oluştur
      final chatRef = _db.collection('chats').doc();

      final batch = _db.batch();

      // Chat belgesini oluştur
      batch.set(chatRef, {
        'participants': [userId1, userId2],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': ''
      });

      // Her iki kullanıcının chatInfos'unu güncelle
      final chatInfo = {
        'chatId': chatRef.id,
        'lastMessageTime': FieldValue.serverTimestamp(),
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

      return chatRef.id;
    } catch (e) {
      debugPrint('Sohbet başlatma hatası: $e');
      rethrow;
    }
  }

  // Kullanıcının chat bilgilerini güncelleme
  Future<void> updateUserChatInfo(String userId, String otherUserId, Map<String, dynamic> chatInfo) async {
    await _db.collection('customers').doc(userId).set({
      'chatInfos': {
        otherUserId: {
          ...chatInfo,
          'otherUserId': otherUserId,
        }
      }
    }, SetOptions(merge: true));
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
      // 1. Mesajları okundu olarak işaretle
      final messagesQuery = await db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isEqualTo: otherUserId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in messagesQuery.docs) {
        transaction.update(doc.reference, {'isRead': true});
      }

      // 2. unreadCount'u sıfırla
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
  Future<void> sendMessage(String chatId, Message message) async {
    try {
      debugPrint('ChatService - Mesaj gönderiliyor... ChatId: $chatId');
      debugPrint('ChatService - Mesaj içeriği: ${message.toMap()}');

      final batch = _db.batch();

      // Mesajı ekle
      final messageRef = _db.collection('chats').doc(chatId).collection('messages').doc();
      batch.set(messageRef, message.toMap());
      debugPrint('ChatService - Mesaj Firestore\'a ekleniyor...');

      // Son mesajı güncelle
      batch.update(_db.collection('chats').doc(chatId), {
        'lastMessage': message.type == 'image' ? '📷 Fotoğraf' : message.content,
        'lastMessageTime': message.timestamp,
        'lastMessageSenderId': message.senderId,
      });
      debugPrint('ChatService - Son mesaj bilgileri güncelleniyor...');

      await batch.commit();
      debugPrint('ChatService - Batch işlemi tamamlandı');

      // Okunmamış mesaj sayısını artır
      final chat = await _db.collection('chats').doc(chatId).get();
      final participants = List<String>.from(chat.data()?['participants'] ?? []);
      final receiverId = participants.firstWhere((id) => id != message.senderId);

      await incrementUnreadCount(chatId, message.senderId, receiverId);
      debugPrint('ChatService - Okunmamış mesaj sayısı güncellendi');
    } catch (e) {
      debugPrint('ChatService - Mesaj gönderme hatası: $e');
      rethrow;
    }
  }

  // Mesajları dinle
  Stream<List<Message>> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList());
  }

  // Sohbetleri dinle
  Stream<List<Chat>> getChats(String userId) {
    debugPrint('Getting chats for user: $userId');

    // Kullanıcının chatInfos bilgilerini ve sohbetlerini aynı anda dinle
    return _db.collection('customers').doc(userId).snapshots().asyncMap((userDoc) async {
      final chatInfos = (userDoc.data()?['chatInfos'] as Map<String, dynamic>?) ?? {};

      // Sohbetleri dinle
      final chatsSnapshot = await _db
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .first; // Son durumu al

      final chats = chatsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        // Diğer kullanıcının ID'sini bul
        final otherUserId = (data['participants'] as List<dynamic>).firstWhere((id) => id != userId, orElse: () => '');

        // ChatInfos'dan unreadCount bilgisini al
        final unreadCount = (chatInfos[otherUserId]?['unreadCount'] as int?) ?? 0;
        data['unreadCount'] = unreadCount;

        debugPrint('Chat data for ${doc.id}: $data');
        debugPrint('Unread count for chat ${doc.id}: $unreadCount');
        return Chat.fromMap(data);
      }).toList();

      return chats;
    });
  }
}
