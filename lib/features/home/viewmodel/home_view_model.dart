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
  static const int _pageSize = 25; // Sayfa başına ilan sayısı

  final Map<String, Customer> _customers = {}; // Kullanıcı önbelleği

  int? _filterDistance;
  String? _filterGender;

  DocumentSnapshot? _lastDocument; // Son dökümanı tut

  // Getter'lar
  List<Advert> get adverts => _adverts;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  int? get filterDistance => _filterDistance;
  String? get filterGender => _filterGender;

  // Tab değiştiğinde ilanları getir (ilk yükleme)
  Future<void> fetchAdvertsForTab(Customer? user, int tabIndex) async {
    if (user == null) return;

    // Yeni tab'e geçildiğinde listeyi ve son dökümanı sıfırla
    _adverts = [];
    _lastDocument = null;
    _hasMore = true;

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
          );
          break;
        case 1:
          if (user?.favoriteCategories != null && user?.favoriteCategories?.isNotEmpty == true) {
            newAdverts = await _advertService.fetchAdvertsByInterests(
              user?.favoriteCategories ?? [],
              lastDocument: _lastDocument,
              limit: _pageSize,
            );
          } else {
            newAdverts = await _advertService.fetchAdverts(
              lastDocument: _lastDocument,
              limit: _pageSize,
            );
          }
          break;
        default:
          newAdverts = await _advertService.fetchAdverts(
            lastDocument: _lastDocument,
            limit: _pageSize,
          );
      }

      if (newAdverts.isNotEmpty) {
        // Son dökümanı güncelle - DÜZELTME BURADA
        _lastDocument =
            await _firestore.collection('adverts').where('advertID', isEqualTo: newAdverts.last.advertID).get().then((value) => value.docs.first);

        // Yeni ilanları ekle
        _adverts.addAll(newAdverts);

        // Kullanıcı bilgilerini getir
        //    await _fetchCustomersForAdverts();
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

  // İlanların kullanıcı bilgilerini getir
  Future<void> _fetchCustomersForAdverts() async {
    try {
      final userIds = _adverts.map((a) => a.creatorUserID).toSet();
      debugPrint('Toplam ${userIds.length} kullanıcı bilgisi çekilecek');

      for (final userId in userIds) {
        try {
          if (!_customers.containsKey(userId)) {
            final customer = await _customerService.fetchUserFromFirestore(userId);
            if (customer != null) {
              _customers[userId] = customer;
            } else {
              debugPrint('Kullanıcı bulunamadı: $userId');
            }
          }
        } catch (e) {
          debugPrint('Kullanıcı bilgisi çekilirken hata ($userId): $e');
        }
      }
    } catch (e) {
      debugPrint('Kullanıcı bilgileri toplu çekilirken hata: $e');
    }
  }

  // Kullanıcı bilgisini al (null dönebilir)
  // Customer? getCustomerForAdvert(String userId) => _customers[userId];

  Future<void> likeAdvert(String advertId, String userId) async {
    try {
      await _advertService.likeAdvert(advertId, userId);
      notifyListeners();
    } catch (e) {
      debugPrint('İlan beğenilirken hata: $e');
    }
  }

  Future<void> unlikeAdvert(String advertId, String userId) async {
    try {
      await _advertService.unlikeAdvert(advertId, userId);
      notifyListeners();
    } catch (e) {
      debugPrint('İlan beğenilirken hata: $e');
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
