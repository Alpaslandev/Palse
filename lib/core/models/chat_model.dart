import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastMessageSenderId;
  final int unreadCount;
  final bool lastMessageIsRead;

  Chat({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageSenderId,
    this.unreadCount = 0,
    this.lastMessageIsRead = false,
  });

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: map['lastMessageTime'] != null ? (map['lastMessageTime'] as Timestamp).toDate() : DateTime.now(),
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      unreadCount: map['unreadCount'] ?? 0,
      lastMessageIsRead: map['lastMessageIsRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'lastMessageIsRead': lastMessageIsRead,
    };
  }

  factory Chat.fromChatInfo(Map<String, dynamic> json, String chatId, String otherUserId) {
    return Chat(
      id: chatId,
      participants: [otherUserId],
      lastMessage: '',
      lastMessageTime: json['lastMessageTime'] != null ? (json['lastMessageTime'] as Timestamp).toDate() : DateTime.now(),
      lastMessageSenderId: '',
      unreadCount: json['unreadCount'] as int? ?? 0,
      lastMessageIsRead: json['lastMessageIsRead'] ?? false,
    );
  }

  factory Chat.empty() {
    return Chat(
      id: '',
      participants: [],
      lastMessage: '',
      lastMessageTime: DateTime.now(),
      lastMessageSenderId: '',
      unreadCount: 0,
      lastMessageIsRead: false,
    );
  }
}

// Mesaj modeli
class Message {
  final String senderId; // Gönderen kullanıcının ID'si
  final String content; // Mesaj içeriği
  final Timestamp timestamp; // Gönderilme zamanı
  final bool isRead; // Okundu durumu
  final String type; // Mesaj tipi (text, image, vs)
  final String? quotedMessage; // Alıntı mesajı
  final String? quotedMessageId; // Yeni alan

  Message({
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.isRead,
    required this.type,
    this.quotedMessage,
    this.quotedMessageId, // Yeni parametre
  });

  // Firestore'dan veri okuma
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderId: map['senderId'] ?? '',
      content: map['content'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      isRead: map['isRead'] ?? false,
      type: map['type'] ?? 'text',
      quotedMessage: map['quotedMessage'],
      quotedMessageId: map['quotedMessageId'], // Yeni alan
    );
  }

  // Firestore'a veri yazma
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp,
      'isRead': isRead,
      'type': type,
      'quotedMessage': quotedMessage,
      'quotedMessageId': quotedMessageId,
    };
  }

  // Debug için toString metodunu ekleyelim
  @override
  String toString() {
    return 'Message{senderId: $senderId, content: $content, type: $type, isRead: $isRead}';
  }

  // Boş mesaj oluşturma
  factory Message.empty() {
    return Message(
      senderId: '',
      content: '',
      timestamp: Timestamp.now(),
      isRead: false,
      type: 'text',
      quotedMessage: null,
      quotedMessageId: null,
    );
  }

  // Kopya oluşturma
  Message copyWith({
    String? senderId,
    String? content,
    Timestamp? timestamp,
    bool? isRead,
    String? type,
    String? quotedMessage,
    String? quotedMessageId,
  }) {
    return Message(
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      quotedMessage: quotedMessage ?? this.quotedMessage,
      quotedMessageId: quotedMessageId ?? this.quotedMessageId,
    );
  }
}
