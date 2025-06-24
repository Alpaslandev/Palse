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
      //  await _advertService.checkDatabaseConsistencyForQueries();

      switch (tabIndex) {
        case 0:
          newAdverts = await _advertService.fetchAdvertsByCity(
            user?.location?.city ?? '',
            lastDocument: _lastDocument,
            limit: _pageSize,
          );
          break;
        case 1:
          newAdverts = await _advertService.fetchAdvertsByInterests(
            user?.favoriteCategories ?? [],
            lastDocument: _lastDocument,
            limit: _pageSize,
          );
          break;
        case 2: // Other sekmesi
          newAdverts = await _advertService.fetchOtherAdverts(
            user: user,
            lastDocument: _lastDocument,
            limit: _pageSize,
          );
          break;
        default:
          newAdverts = await _advertService.fetchAdvertsByFiltering(
            lastDocument: _lastDocument,
            limit: _pageSize,
          );
      }

      if (newAdverts.isNotEmpty) {
        // Son dökümanı güncelle (filtrelenmemiş listeden alıyoruz)
        _lastDocument = await _firestore
            .collection('events')
            .doc(newAdverts.last.advertID)
            .get();

        // Yeni ilanları ekle
        _adverts.addAll(newAdverts);

        // İlanlar bulundu, flag'i false yap
        _shouldShowOtherTab = false;
      } else {
        // Eğer şehre göre veya ilgi alanlarına göre ilan bulunamadıysa ve bu ilk yüklemeyse
        if (_adverts.isEmpty && (tabIndex == 0 || tabIndex == 1)) {
          debugPrint(
              '${tabIndex == 0 ? "Şehre" : "İlgi alanlarına"} göre ilan bulunamadı, diğer sekmesine yönlendirme yapılacak.');

          // Flag'i true yap - Diğer sekmesine yönlendirme yapılacak
          _shouldShowOtherTab = true;
        }
      }

      // Sayfa kontrolü - Filtreleme öncesi duruma göre hasMore değerini ayarla
      _hasMore = newAdverts.length >= _pageSize;

      debugPrint(
          'Yeni ilanlar yüklendi. Toplam: ${_adverts.length}, Yeni: ${newAdverts.length}, Daha fazla var mı: $_hasMore');
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
      if (index != -1) {
        // Yerel listeyi güncelle
        final updatedLikers = [...adverts[index].likers, userId];
        adverts[index] = adverts[index].copyWith(likers: updatedLikers);

        // Sadece UI'ı bilgilendir

        await _advertService.likeAdvert(
          advertId: advertId,
          userId: userId,
        );
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
        await _advertService.unlikeAdvert(
          advertId: advertId,
          userId: userId,
        );
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

  Future<void> sendJoinRequest(String advertId, String userId) async {
    try {
      final index = adverts.indexWhere((a) => a.advertID == advertId);
      if (index == -1) return;

      // 1. Optimistik olarak UI'yı güncelle
      final updatedJoiners = [...adverts[index].joinRequestIds, userId];
      adverts[index] = adverts[index].copyWith(joinRequestIds: updatedJoiners);

      debugPrint('Katılım isteği gönderildi: $updatedJoiners');

      // 3. (Opsiyonel) Kullanıcının belgesini de güncelle
      await _advertService.sendJoinRequest(advertId, userId);
    } catch (e) {
      debugPrint('Katılım isteği gönderme hatası: $e');

      // 4. Hata olursa yerel değişikliği geri al
      final index = adverts.indexWhere((a) => a.advertID == advertId);
      if (index != -1) {
        final updatedJoiners = [...adverts[index].joinRequestIds]
          ..remove(userId);
        adverts[index] =
            adverts[index].copyWith(joinRequestIds: updatedJoiners);
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cancelJoinRequest(String advertId, String userId) async {
    try {
      final index = adverts.indexWhere((a) => a.advertID == advertId);
      if (index == -1) return;

      // 1. UI'da optimistik olarak userId'yi listeden çıkar
      final updatedJoiners = [...adverts[index].joinRequestIds];
      updatedJoiners.remove(userId);

      adverts[index] = adverts[index].copyWith(joinRequestIds: updatedJoiners);
      debugPrint('Katılım isteği iptal edildi: $updatedJoiners');

      await _advertService.rejectJoinRequest(advertId, userId);
    } catch (e) {
      debugPrint('Katılım isteği iptal hatası: $e');

      // 4. Hata varsa rollback (geri alma)
      final index = adverts.indexWhere((a) => a.advertID == advertId);
      if (index != -1 && !adverts[index].joinRequestIds.contains(userId)) {
        final revertedList = [...adverts[index].joinRequestIds, userId];
        adverts[index] = adverts[index].copyWith(joinRequestIds: revertedList);
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
