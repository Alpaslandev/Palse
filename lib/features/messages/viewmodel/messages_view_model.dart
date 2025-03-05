import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:palseapp/core/models/chat_model.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/features/chats/service/chat_service.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';

class MessagesViewModel extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final CustomerService _customerService = CustomerService();
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final String chatId;
  final String currentUserId;
  final String otherUserId;
  List<Message> messages = [];
  bool isLoading = false;
  bool isUploadingImage = false;
  double uploadProgress = 0.0;
  Message? _quotedMessage;

  Message? get quotedMessage => _quotedMessage;

  MessagesViewModel(this.chatId, this.currentUserId, this.otherUserId);

  // Mesajları dinle
  Stream<List<Message>> getMessages(String chatId) {
    return _chatService.getMessages(chatId).map((msgs) {
      // messages listesini güncelle
      messages = msgs;
      return msgs;
    });
  }

  // Müşteri bilgilerini al
  Stream<Customer?> getUserInfo(String userId) {
    return _customerService.getUserStream(userId);
  }

  // Alıntı mesajını ayarla
  void setQuotedMessage(Message? message) {
    _quotedMessage = message;
    notifyListeners();
  }

  // Alıntı mesajını temizle
  void clearQuotedMessage() {
    _quotedMessage = null;
    notifyListeners();
  }

  // Mesaj gönder
  Future<void> sendMessage(String chatId, String senderId, String receiverId, String content) async {
    if (content.trim().isEmpty) return;

    try {
      isLoading = true;
      notifyListeners();

      // Alıntı mesajı varsa, mesajı alıntıyla birlikte gönder
      final messageToSend = Message(
        senderId: senderId,
        content: content,
        timestamp: DateTime.now(),
        type: MessageType.text,
        quotedMessage: _quotedMessage?.content,
        quotedMessageId: _quotedMessage?.messageId,
      );

      await _chatService.sendMessage(
        chatId,
        messageToSend,
        senderId,
        receiverId,
      );

      // Mesaj gönderildikten sonra alıntıyı temizle
      setQuotedMessage(null);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Mesajları okundu olarak işaretle
  Future<void> markMessagesAsRead() async {
    try {
      // Tüm sohbeti okundu olarak işaretle
      await _chatService.markChatAsRead(chatId, currentUserId, otherUserId);

      notifyListeners();
    } catch (e) {
      debugPrint('Mesajları okundu işaretleme hatası: $e');
    }
  }

  // Dosya ekleme işlemini yönet
  Future<void> handleAttachment(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Kamera'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Galeri'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  // Görsel seç
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (image != null) {
        isUploadingImage = true;
        uploadProgress = 0.0;
        notifyListeners();

        final String imageUrl = await _uploadImage(File(image.path));
        debugPrint('Yüklenen görsel URL: $imageUrl'); // Debug için URL'i yazdır
        await sendImageMessage(imageUrl);
      }
    } catch (e) {
      debugPrint('Görsel seçme hatası: $e');
    } finally {
      isUploadingImage = false;
      uploadProgress = 0.0;
      notifyListeners();
    }
  }

  // Görseli yükle
  Future<String> _uploadImage(File imageFile) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child('chat_images').child(fileName);

      final UploadTask uploadTask = ref.putFile(imageFile);

      // İlerleme durumunu dinle
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        notifyListeners();
      });

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('Storage URL: $downloadUrl'); // Debug için URL'i yazdır
      return downloadUrl;
    } catch (e) {
      debugPrint('Görsel yükleme hatası: $e');
      rethrow;
    }
  }

  // Görsel mesajı gönder
  Future<void> sendImageMessage(String imageUrl) async {
    try {
      debugPrint('Görsel mesaj gönderiliyor... URL: $imageUrl'); // Debug için URL'i yazdır
      final messageToSend = Message(
        senderId: currentUserId,
        content: imageUrl,
        timestamp: DateTime.now(),
        type: MessageType.image,
        quotedMessage: _quotedMessage?.content,
        quotedMessageId: _quotedMessage?.senderId,
      );

      debugPrint('Message objesi oluşturuldu: ${messageToSend.toMap()}'); // Debug için mesaj objesini yazdır

      await _chatService.sendMessage(
        chatId,
        messageToSend,
        currentUserId,
        otherUserId,
      );

      debugPrint('Görsel mesaj başarıyla gönderildi!'); // Debug için başarı mesajı
      setQuotedMessage(null);
    } catch (e) {
      debugPrint('Görsel mesaj gönderme hatası: $e');
    }
  }
}
