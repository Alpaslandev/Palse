import 'package:cloud_firestore/cloud_firestore.dart';

class Message2 {
  final String senderId;
  final String text;
  final Timestamp timestamp;
  final bool isNewMessage;

  Message2({required this.senderId, required this.text, required this.timestamp, required this.isNewMessage});

  Map<String, dynamic> toMap() {
    return {'senderId': senderId, 'text': text, 'timestamp': timestamp, 'isNewMessage': true};
  }

  factory Message2.fromMap(Map<String, dynamic> map) {
    return Message2(senderId: map['senderId'], text: map['text'], timestamp: map['timestamp'], isNewMessage: map['isNewMessage'] ?? true);
  }

  factory Message2.empty() {
    return Message2(senderId: '', text: '', timestamp: Timestamp.now(), isNewMessage: false);
  }
}
