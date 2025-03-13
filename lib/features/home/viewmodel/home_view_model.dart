import 'package:flutter/material.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/firestore/advert_service.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeViewModel extends ChangeNotifier {
  final AdvertService _advertService = AdvertService();
  final CustomerService _customerService = CustomerService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Advert> _adverts = [];
  bool _isLoading = false;
  bool _hasMore = true; // Daha fazla ilan var mı?
  bool _shouldShowOtherTab = false; // Diğer sekmesine yönlendirme yapılmalı mı?
  static const int _pageSize = 25; // Sayfa başına ilan sayısı

  final Map<String, Customer> _customers = {}; // Kullanıcı önbelleği

  int? _filterDistance;
  String? _filterGender;

  DocumentSnapshot? _lastDocument; // Son dökümanı tut

  // Getter'lar
  List<Advert> get adverts => _adverts;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  bool get shouldShowOtherTab => _shouldShowOtherTab;
  int? get filterDistance => _filterDistance;
  String? get filterGender => _filterGender;

  // Tab değiştiğinde ilanları getir (ilk yükleme)
  Future<void> fetchAdvertsForTab(Customer? user, int tabIndex) async {
    if (user == null) return;

    // Yeni tab'e geçildiğinde listeyi ve son dökümanı sıfırla
    _adverts = [];
    _lastDocument = null;
    _hasMore = true;
    _shouldShowOtherTab = false; // Flag'i sıfırla

    await _loadMoreAdverts(user, tabIndex);
  }

  // Daha fazla ilan yükle
  Future<void> loadMore(Customer? user, int tabIndex) async {
    if (user == null || _isLoading || !_hasMore) return;
    await _loadMoreAdverts(user, tabIndex);
  }

  // İlanları yükle
  Future<void> _loadMoreAdverts(Customer? user, int tabIndex) async {
    if (_isLoading || !_hasMore) return;

    _setLoading(true);
    try {
      List<Advert> newAdverts = [];

      switch (tabIndex) {
        case 0:
          newAdverts = await _advertService.fetchAdvertsByCity(
            user?.location?.city ?? '',
            lastDocument: _lastDocument,
            limit: _pageSize,
            userLocation: user?.location,
          );
          break;
        case 1:
          if (user?.favoriteCategories != null && user?.favoriteCategories?.isNotEmpty == true) {
            newAdverts = await _advertService.fetchAdvertsByInterests(
              user?.favoriteCategories ?? [],
              lastDocument: _lastDocument,
              limit: _pageSize,
              userLocation: user?.location,
            );
          }
          break;
        case 2: // Other sekmesi
          newAdverts = await _advertService.fetchOtherAdverts(
            userCity: user?.location?.city,
            userInterests: user?.favoriteCategories,
            lastDocument: _lastDocument,
            limit: _pageSize,
            userLocation: user?.location,
          );
          break;
        default:
          newAdverts = await _advertService.fetchAdverts(
            lastDocument: _lastDocument,
            limit: _pageSize,
            userLocation: user?.location,
          );
      }

      // Kullanıcının kendi ilanlarını ve engellediği kişilerin ilanlarını filtrele
      if (user != null) {
        newAdverts = newAdverts.where((advert) {
          // Kullanıcının kendi ilanlarını filtrele
          if (advert.creatorUserID == user.userID) {
            return false;
          }

          // Kullanıcının engellediği kişilerin ilanlarını filtrele
          if (user.blockUsers != null && user.blockUsers!.contains(advert.creatorUserID)) {
            return false;
          }

          return true;
        }).toList();
      }

      if (newAdverts.isNotEmpty) {
        // Son dökümanı güncelle - DÜZELTME BURADA
        _lastDocument = await _firestore
            .collection('events')
            .where('advertID', isEqualTo: newAdverts.last.advertID)
            .get()
            .then((value) => value.docs.isNotEmpty ? value.docs.first : null);

        // Yeni ilanları ekle
        _adverts.addAll(newAdverts);

        // İlanlar bulundu, flag'i false yap
        _shouldShowOtherTab = false;
      } else {
        // Eğer şehre göre veya ilgi alanlarına göre ilan bulunamadıysa ve bu ilk yüklemeyse
        if (_adverts.isEmpty && (tabIndex == 0 || tabIndex == 1)) {
          debugPrint('${tabIndex == 0 ? "Şehre" : "İlgi alanlarına"} göre ilan bulunamadı, diğer sekmesine yönlendirme yapılacak.');

          // Flag'i true yap - Diğer sekmesine yönlendirme yapılacak
          _shouldShowOtherTab = true;
        }
      }

      // Sayfa kontrolü
      _hasMore = newAdverts.length >= _pageSize;
      notifyListeners();

      debugPrint('Yeni ilanlar yüklendi. Toplam: ${_adverts.length}, Yeni: ${newAdverts.length}');
    } catch (e) {
      debugPrint('İlanlar yüklenirken hata: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> likeAdvert(String advertId, String userId) async {
    try {
      // Önce yerel olarak güncelle
      final index = adverts.indexWhere((advert) => advert.advertID == advertId);
      final advert = adverts[index];
      if (index != -1) {
        // Yerel listeyi güncelle
        final updatedLikers = [...adverts[index].likers, userId];
        adverts[index] = adverts[index].copyWith(likers: updatedLikers);

        // Sadece UI'ı bilgilendir

        await _advertService.likeAdvert(advertId, userId, advert.creatorUserID);

        // Kullanıcının belgesini de güncelle
        await _customerService.likeAdvert(advertId, userId);
      }
    } catch (e) {
      debugPrint('İlan beğenme hatası: $e');
      // Hata durumunda yerel değişikliği geri al
      final index = adverts.indexWhere((advert) => advert.advertID == advertId);
      if (index != -1) {
        final updatedLikers = [...adverts[index].likers];
        updatedLikers.remove(userId);
        adverts[index] = adverts[index].copyWith(likers: updatedLikers);
        notifyListeners();
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> unlikeAdvert(String advertId, String userId) async {
    try {
      // Önce yerel olarak güncelle
      final index = adverts.indexWhere((advert) => advert.advertID == advertId);
      if (index != -1) {
        // Yerel listeyi güncelle
        final updatedLikers = [...adverts[index].likers];
        updatedLikers.remove(userId);
        adverts[index] = adverts[index].copyWith(likers: updatedLikers);

        // Ardından Firestore'u güncelle (arka planda)
        await _advertService.unlikeAdvert(advertId, userId);

        // Kullanıcının belgesini de güncelle
        await _customerService.unlikeAdvert(advertId, userId);
      }
    } catch (e) {
      debugPrint('İlan beğenmeme hatası: $e');
      // Hata durumunda yerel değişikliği geri al
      final index = adverts.indexWhere((advert) => advert.advertID == advertId);
      if (index != -1) {
        final updatedLikers = [...adverts[index].likers, userId];
        adverts[index] = adverts[index].copyWith(likers: updatedLikers);
        notifyListeners();
      }
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _adverts.clear();
    _customers.clear();
    super.dispose();
  }
}
