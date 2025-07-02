import 'dart:io';
import 'package:flutter/material.dart';
import 'package:palseapp/features/story/service/story_service.dart';
import 'package:palseapp/features/story/model/story_model.dart';

// Hikaye işlemleri için UI mantığını yöneten ViewModel.
class StoryViewModel extends ChangeNotifier {
  final StoryService _storyService = StoryService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<StoryModel>? _cachedStories;
  String? _lastUserId;
  List<String>? _lastFollowingIds;

  // Yükleme durumunu günceller ve dinleyicileri bilgilendirir.
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Cache'i temizler ve hikayeleri yeniden yükler
  Future<void> refreshStories({
    required String currentUserId,
    required List<String> followingIds,
  }) async {
    _cachedStories = null;
    _lastUserId = null;
    _lastFollowingIds = null;
    await fetchStories(
      currentUserId: currentUserId,
      followingIds: followingIds,
      forceRefresh: true,
    );
  }

  // Yeni bir hikaye yükler.
  Future<bool> uploadStory({
    required File imageFile,
    required String userId,
    required String username,
    required String profilePictureUrl,
    required bool isPublic,
  }) async {
    _setLoading(true);
    try {
      await _storyService.createStory(
        imageFile: imageFile,
        userId: userId,
        username: username,
        profilePictureUrl: profilePictureUrl,
        isPublic: isPublic,
      );
      // Hikaye eklendikten sonra cache'i temizle
      _cachedStories = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      debugPrint('ViewModelde hikaye yüklenirken hata: $e');
      return false;
    }
  }

  // Sunucudan hikayeleri çeker.
  Future<List<StoryModel>> fetchStories({
    required String currentUserId,
    required List<String> followingIds,
    bool forceRefresh = false,
  }) async {
    // Cache kontrolü - eğer aynı kullanıcı ve takip listesi ise cached veriyi döndür
    if (!forceRefresh &&
        _cachedStories != null &&
        _lastUserId == currentUserId &&
        _listEquals(_lastFollowingIds, followingIds)) {
      return _cachedStories!;
    }

    final stories = await _storyService.fetchStories(
      currentUserId: currentUserId,
      followingIds: followingIds,
    );

    // Cache'e kaydet
    _cachedStories = stories;
    _lastUserId = currentUserId;
    _lastFollowingIds = List.from(followingIds);

    return stories;
  }

  // İki listenin eşit olup olmadığını kontrol eder
  bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // Bir hikayeyi "görüldü" olarak işaretler.
  Future<void> markStoryAsViewed({
    required String storyId,
    required String viewerId,
  }) async {
    // Bu işlem arka planda sessizce yapılabilir, UI'ı bloklamaya gerek yok.
    await _storyService.addViewToStory(storyId, viewerId);
  }

  Future<void> deleteStory({
    required String storyId,
    required String userId,
  }) async {
    await _storyService.deleteStory(storyId: storyId, userId: userId);
    // Hikaye silindikten sonra cache'i temizle
    _cachedStories = null;
  }
}
