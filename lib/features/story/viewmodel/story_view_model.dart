import 'dart:io';
import 'package:flutter/material.dart';
import 'package:palseapp/features/story/service/story_service.dart';
import 'package:palseapp/features/story/model/story_model.dart';

// Hikaye işlemleri için UI mantığını yöneten ViewModel.
class StoryViewModel extends ChangeNotifier {
  final StoryService _storyService = StoryService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Yükleme durumunu günceller ve dinleyicileri bilgilendirir.
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Yeni bir hikaye yükler.
  Future<bool> uploadStory({
    required File imageFile,
    required String userId,
    required bool isPublic,
  }) async {
    _setLoading(true);
    try {
      await _storyService.createStory(
        imageFile: imageFile,
        userId: userId,
        isPublic: isPublic,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      print('ViewModelde hikaye yüklenirken hata: $e');
      return false;
    }
  }

  // Sunucudan hikayeleri çeker.
  Future<List<StoryModel>> fetchStories({
    required String currentUserId,
    required List<String> followingIds,
  }) async {
    // Bu metod doğrudan FutureBuilder tarafından kullanılacağı için
    // kendi içinde bir loading state yönetmesine gerek yok.
    return await _storyService.fetchStories(
      currentUserId: currentUserId,
      followingIds: followingIds,
    );
  }
}
