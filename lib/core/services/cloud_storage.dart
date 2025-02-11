import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

enum FileType {
  profile,
  adverts,
  documents,
  messages,
}

class CloudStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadUserFile({
    required String userId,
    required FileType fileType,
    required String fileName,
    required File file,
  }) async {
    try {
      // Dosya yolu oluştur
      final path = 'users/$userId/${fileType.name}/$fileName.jpg';
      // Dosya yükleme
      final task = _storage.ref(path).putFile(file);

      // Yükleme ilerlemesini dinleme (opsiyonel)
      task.snapshotEvents.listen((TaskSnapshot snapshot) {
        debugPrint('Yükleme ilerlemesi: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
      });

      // Yüklemenin tamamlanmasını bekleme
      final snapshot = await task;

      // URL alma
      final url = await snapshot.ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      throw Exception('Dosya yükleme hatası: ${e.message}');
    } catch (e) {
      throw Exception('Beklenmeyen hata: $e');
    }
  }

  Future<void> deleteUserFolder(String userId) async {
    try {
      // Kullanıcı klasörünü sil
      final folderRef = _storage.ref('users/$userId');
      await folderRef.listAll().then((result) async {
        for (var item in result.items) {
          await item.delete();
        }
        for (var prefix in result.prefixes) {
          await prefix.delete();
        }
      });
    } on FirebaseException catch (e) {
      throw Exception('Klasör silme hatası: ${e.message}');
    }
  }
}
