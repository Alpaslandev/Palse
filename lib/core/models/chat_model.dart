import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Chat {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastMessageSenderId;
  final int unreadCount;
  final bool isLastMessageRead;
  final String lastMessageType;
  final bool lastMessageQuoted;
  final bool isTemporary;
  final DateTime createdAt;

  // Kullanıcı belgesinde saklanacak ek bilgiler
  final String? otherUserId; // Sadece kullanıcı belgesinde kullanılır

  Chat({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageSenderId,
    this.unreadCount = 0,
    this.isLastMessageRead = false,
    this.lastMessageType = 'text',
    this.lastMessageQuoted = false,
    this.isTemporary = false,
    required this.createdAt,
    this.otherUserId,
  });

  // Diğer kullanıcının ID'sini al
  String getOtherUserId(String currentUserId) {
    return otherUserId ?? participants.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  // Son mesajı ben mi gönderdim?
  bool isMe(String currentUserId) {
    return lastMessageSenderId == currentUserId;
  }

  // Okunmamış mesaj var mı?
  bool get hasUnreadMessages => unreadCount > 0;

  // toString metodu ekle - hata ayıklamayı kolaylaştırmak için
  @override
  String toString() {
    return 'Chat(id: $id)';
  }

  // Chats koleksiyonu için JSON
  Map<String, dynamic> toFirestoreJson() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageType': lastMessageType,
      'lastMessageQuoted': lastMessageQuoted,
      'isTemporary': isTemporary,
      'createdAt': Timestamp.fromDate(createdAt),
      // NOT: unreadCount ve isLastMessageRead kullanıcı belgelerinde saklanır, chat koleksiyonunda değil
    };
  }

  // Kullanıcı belgesi için JSON
  Map<String, dynamic> toUserDocumentJson(String currentUserId) {
    final otherUserId = getOtherUserId(currentUserId);

    return {
      'chatId': id,
      'otherUserId': otherUserId,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount, // Kullanıcıya özel okunmamış mesaj sayısı
      'isLastMessageRead': isLastMessageRead, // Kullanıcıya özel son mesaj okunma durumu
      'lastMessageType': lastMessageType,
      'lastMessageQuoted': lastMessageQuoted,
      'isTemporary': isTemporary,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Chats koleksiyonundan oluşturma
  factory Chat.fromFirestore(Map<String, dynamic> json, String chatId) {
    return Chat(
      id: chatId,
      participants: List<String>.from(json['participants'] ?? []),
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: json['lastMessageTime'] != null ? (json['lastMessageTime'] as Timestamp).toDate() : DateTime.now(),
      lastMessageSenderId: json['lastMessageSenderId'] ?? '',
      // Chat koleksiyonunda unreadCount ve isLastMessageRead tutulmaz, varsayılan değerleri kullan
      lastMessageType: json['lastMessageType'] ?? 'text',
      lastMessageQuoted: json['lastMessageQuoted'] ?? false,
      isTemporary: json['isTemporary'] ?? false,
      createdAt: json['createdAt'] != null ? (json['createdAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  // Kullanıcı belgesinden oluşturma
  factory Chat.fromUserDocument(Map<String, dynamic> json) {
    return Chat(
      id: json['chatId'] ?? '',
      participants: [], // Kullanıcı belgesinde participants tutulmaz
      otherUserId: json['otherUserId'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: json['lastMessageTime'] != null ? (json['lastMessageTime'] as Timestamp).toDate() : DateTime.now(),
      lastMessageSenderId: json['lastMessageSenderId'] ?? '',
      unreadCount: json['unreadCount'] ?? 0,
      isLastMessageRead: json['isLastMessageRead'] ?? false,
      lastMessageType: json['lastMessageType'] ?? 'text',
      lastMessageQuoted: json['lastMessageQuoted'] ?? false,
      isTemporary: json['isTemporary'] ?? false,
      createdAt: json['createdAt'] != null ? (json['createdAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  // Yeni sohbet oluşturma
  factory Chat.create({
    required String chatId,
    required List<String> participants,
    String initialMessage = '',
    String? initialMessageSenderId,
  }) {
    final now = DateTime.now();
    return Chat(
      id: chatId,
      participants: participants,
      lastMessage: initialMessage,
      lastMessageTime: now,
      lastMessageSenderId: initialMessageSenderId ?? participants[0],
      isTemporary: initialMessage.isEmpty, // Mesaj yoksa geçici olarak işaretle
      createdAt: now,
    );
  }

  // Kopya oluşturma
  Chat copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    int? unreadCount,
    bool? isLastMessageRead,
    String? lastMessageType,
    bool? lastMessageQuoted,
    bool? isTemporary,
    DateTime? createdAt,
    String? otherUserId,
  }) {
    return Chat(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      isLastMessageRead: isLastMessageRead ?? this.isLastMessageRead,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageQuoted: lastMessageQuoted ?? this.lastMessageQuoted,
      isTemporary: isTemporary ?? this.isTemporary,
      createdAt: createdAt ?? this.createdAt,
      otherUserId: otherUserId ?? this.otherUserId,
    );
  }
}

enum MessageType {
  text('text', Icons.text_fields, '💬'),
  image('image', Icons.image, '📷'),
  url('url', Icons.link, '🔗');

  const MessageType(this.value, this.icon, this.emoji);

  final IconData icon;
  final String emoji;
  final String value;
}

// Mesaj modeli (sadeleştirilmiş)
class Message {
  final String senderId;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final String? quotedMessage;
  final String? quotedMessageId;
  final bool isRead; // Mesajın okunup okunmadığı bilgisi
  final String? messageId;
  Message({
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.type,
    this.quotedMessage,
    this.quotedMessageId,
    this.isRead = false, // Varsayılan olarak okunmamış
    this.messageId,
  });

  // Firestore'dan veri okuma
  factory Message.fromMap(Map<String, dynamic> map, String messageId) {
    return Message(
      senderId: map['senderId'] as String? ?? '',
      content: map['content'] as String? ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: map['type'] != null ? MessageType.values.byName(map['type']) : MessageType.text,
      quotedMessage: map['quotedMessage'] as String?,
      quotedMessageId: map['quotedMessageId'] as String?,
      isRead: map['isRead'] as bool? ?? false, // Firestore'dan isRead değerini al
      messageId: messageId,
    );
  }

  // Firestore'a veri yazma
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.value,
      'quotedMessage': quotedMessage,
      'quotedMessageId': quotedMessageId,
      'isRead': isRead, // isRead bilgisini ekle
    };
  }

  // Kopya oluşturma
  Message copyWith({
    String? senderId,
    String? content,
    DateTime? timestamp,
    MessageType? type,
    String? quotedMessage,
    String? quotedMessageId,
    bool? isRead,
  }) {
    return Message(
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      quotedMessage: quotedMessage ?? this.quotedMessage,
      quotedMessageId: quotedMessageId ?? this.quotedMessageId,
      isRead: isRead ?? this.isRead,
    );
  }
}
