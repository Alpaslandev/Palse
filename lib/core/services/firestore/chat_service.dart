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
  Future<void> sendMessage(String chatId, String senderId, String receiverId, String content) async {
    await _db.runTransaction((transaction) async {
      final messageRef = _db.collection('chats').doc(chatId).collection('messages').doc();

      transaction
          .set(messageRef, {'content': content, 'senderId': senderId, 'timestamp': FieldValue.serverTimestamp(), 'isRead': false, 'type': 'text'});

      transaction.update(_db.collection('chats').doc(chatId),
          {'lastMessage': content, 'lastMessageTime': FieldValue.serverTimestamp(), 'lastMessageSenderId': senderId});

      await incrementUnreadCount(chatId, senderId, receiverId);
    });
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

    return _db.collection('chats').where('participants', arrayContains: userId).snapshots().map((snapshot) {
      debugPrint('Chat documents: ${snapshot.docs.length}');
      debugPrint('Raw data: ${snapshot.docs.map((doc) => doc.data())}');

      return snapshot.docs.map((doc) {
        final data = doc.data();
        // ID'yi ekleyelim
        data['id'] = doc.id;
        return Chat.fromMap(data);
      }).toList();
    });
  }
}
