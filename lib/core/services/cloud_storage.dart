import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class CloudStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> uploadFile(String path, String fileName, File file) async {
    await _storage.ref(path).child(fileName).putFile(file);
  }
}
