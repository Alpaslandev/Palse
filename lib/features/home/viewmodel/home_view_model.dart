import 'package:flutter/material.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/firestore/advert_service.dart';

// Ana sayfa view model'i - IndexedStack mantığı ile her tab ayrı state tutar
class HomeViewModel extends ChangeNotifier {
  final AdvertService _advertService = AdvertService();

  // Her tab için ayrı liste ve durum tutma
  final List<List<Advert>> _tabAdverts = [[], [], []]; // 3 tab için
  final List<bool> _tabLoadingStates = [false, false, false];
  final List<bool> _tabInitialized = [false, false, false];

  // Getter'lar - aktif tab'a göre veri döndür
  List<Advert> getAdvertsForTab(int tabIndex) {
    if (tabIndex < 0 || tabIndex >= _tabAdverts.length) return [];
    return _tabAdverts[tabIndex];
  }

  bool isTabLoading(int tabIndex) {
    if (tabIndex < 0 || tabIndex >= _tabLoadingStates.length) return false;
    return _tabLoadingStates[tabIndex];
  }

  bool isTabInitialized(int tabIndex) {
    if (tabIndex < 0 || tabIndex >= _tabInitialized.length) return false;
    return _tabInitialized[tabIndex];
  }

  // Belirli bir tab'ı ilk kez yükle
  Future<void> initializeTab(Customer? user, int tabIndex) async {
    if (user == null || isTabInitialized(tabIndex)) return;

    await _loadTabData(user, tabIndex);
    _tabInitialized[tabIndex] = true;
  }

  // Tab verilerini yenile (refresh)
  Future<void> refreshTab(Customer? user, int tabIndex) async {
    if (user == null) return;

    // Tab'ı sıfırla ve yeniden yükle
    _tabAdverts[tabIndex].clear();
    _tabInitialized[tabIndex] = false;

    await _loadTabData(user, tabIndex);
    _tabInitialized[tabIndex] = true;
  }

  // Tüm tab'ları yenile
  Future<void> refreshAllTabs(Customer? user) async {
    if (user == null) return;

    // Tüm tab'ları sıfırla
    for (int i = 0; i < _tabAdverts.length; i++) {
      _tabAdverts[i].clear();
      _tabInitialized[i] = false;
    }

    // Paralel olarak tüm tab'ları yükle
    await Future.wait([
      _loadTabData(user, 0),
      _loadTabData(user, 1),
      _loadTabData(user, 2),
    ]);

    // Tüm tab'ları initialized olarak işaretle
    for (int i = 0; i < _tabInitialized.length; i++) {
      _tabInitialized[i] = true;
    }
  }

  // Tab verilerini yükle
  Future<void> _loadTabData(Customer user, int tabIndex) async {
    if (_tabLoadingStates[tabIndex]) return;

    _setTabLoading(tabIndex, true);

    try {
      List<Advert> newAdverts = [];

      switch (tabIndex) {
        case 0: // Şehir bazlı ilanlar
          newAdverts = await _advertService.fetchAdvertsByCity(
            user.location?.city ?? '',
          );
          break;
        case 1: // İlgi alanlarına göre ilanlar
          newAdverts = await _advertService.fetchAdvertsByInterests(
            user.favoriteCategories ?? [],
          );
          break;
        case 2: // Diğer ilanlar
          newAdverts = await _advertService.fetchOtherAdverts(user: user);
          break;
      }

      _tabAdverts[tabIndex] = newAdverts;
      debugPrint('Tab $tabIndex yüklendi: ${newAdverts.length} ilan');
    } catch (e) {
      debugPrint('Tab $tabIndex yüklenirken hata: $e');
    } finally {
      _setTabLoading(tabIndex, false);
    }
  }

  // Takip edilen kişilerin ilanlarını yükle
  Future<List<Advert>> loadFollowingsAdverts(Customer user) async {
    try {
      // Takip edilen kişilerin ID'lerini al
      final followingIds = user.followings;

      // Takip edilen kişilerin ilanlarını getir
      final adverts =
          await _advertService.fetchFollowingUserAdverts(followingIds);

      return adverts;
    } catch (e) {
      debugPrint('Takip edilen kişilerin ilanları yüklenirken hata: $e');
      return [];
    }
  }

  // Tab loading durumunu güncelle
  void _setTabLoading(int tabIndex, bool isLoading) {
    _tabLoadingStates[tabIndex] = isLoading;
    notifyListeners();
  }

  @override
  void dispose() {
    // Tüm tab verilerini temizle
    for (var tabList in _tabAdverts) {
      tabList.clear();
    }
    super.dispose();
  }
}
