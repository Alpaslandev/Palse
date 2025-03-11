import 'package:flutter/material.dart';
import 'package:palseapp/core/constant/notifications_enum.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/firestore/advert_service.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:palseapp/core/services/notification_service.dart';

class HomeViewModel extends ChangeNotifier {
  final AdvertService _advertService = AdvertService();
  final CustomerService _customerService = CustomerService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

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
          } else {
            newAdverts = await _advertService.fetchAdverts(
              lastDocument: _lastDocument,
              limit: _pageSize,
              userLocation: user?.location,
            );
          }
          break;
        default:
          newAdverts = await _advertService.fetchAdverts(
            lastDocument: _lastDocument,
            limit: _pageSize,
            userLocation: user?.location,
          );
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

  /// Events koleksiyonundaki tüm belgelerin creatorUserID'lerini kullanarak
  /// customer koleksiyonundan profil resimlerini alıp events belgelerini günceller
  Future<void> updateEventsWithCreatorProfilePictures() async {
    // Firestore instance'ını al
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Tüm events belgelerini al
      final QuerySnapshot eventsSnapshot = await firestore.collection('events').get();

      // Batch işlemi başlat
      WriteBatch batch = firestore.batch();
      int operationCount = 0;
      const int BATCH_LIMIT = 500; // Firestore batch işlemi limiti

      // Her bir event belgesi için işlem yap
      for (final DocumentSnapshot eventDoc in eventsSnapshot.docs) {
        // Event belgesinden creatorUserID'yi al
        final Map<String, dynamic>? eventData = eventDoc.data() as Map<String, dynamic>?;

        if (eventData == null || !eventData.containsKey('creatorUserID')) {
          print('Event ${eventDoc.id} için creatorUserID bulunamadı, atlanıyor.');
          continue;
        }

        final String? creatorUserID = eventData['creatorUserID'] as String?;

        // Eğer creatorUserID null ise, bu belgeyi atla
        if (creatorUserID == null || creatorUserID.isEmpty) {
          print('Event ${eventDoc.id} için geçerli bir creatorUserID bulunamadı, atlanıyor.');
          continue;
        }

        // Customer koleksiyonundan ilgili kullanıcıyı bul
        final DocumentSnapshot customerDoc = await firestore.collection('customers').doc(creatorUserID).get();

        // Eğer customer belgesi yoksa veya profilePictureUrl yoksa, atla
        if (!customerDoc.exists) {
          print('Customer $creatorUserID bulunamadı, atlanıyor.');
          continue;
        }

        final Map<String, dynamic>? customerData = customerDoc.data() as Map<String, dynamic>?;

        if (customerData == null || !customerData.containsKey('profilePictureUrl')) {
          print('Customer $creatorUserID için profilePictureUrl bulunamadı, atlanıyor.');
          continue;
        }

        final String? profilePictureUrl = customerData['profilePictureUrl'] as String?;

        if (profilePictureUrl == null || profilePictureUrl.isEmpty) {
          print('Customer $creatorUserID için geçerli bir profilePictureUrl bulunamadı, atlanıyor.');
          continue;
        }

        // Event belgesini güncelle
        batch.update(eventDoc.reference, {'creatorProfilePicture': profilePictureUrl});

        // İşlem sayacını artır
        operationCount++;

        // Eğer batch limiti doluysa, commit yap ve yeni batch başlat
        if (operationCount >= BATCH_LIMIT) {
          await batch.commit();
          print('$operationCount belge güncellendi, yeni batch başlatılıyor...');
          batch = firestore.batch();
          operationCount = 0;
        }
      }

      // Kalan işlemleri commit et
      if (operationCount > 0) {
        await batch.commit();
        print('Son $operationCount belge güncellendi.');
      }

      print('Tüm events belgeleri başarıyla güncellendi! 🎉');
    } catch (error) {
      print('Güncelleme işlemi sırasında hata oluştu: $error');
      rethrow; // Hatayı yukarı ilet
    }
  }

  @override
  void dispose() {
    _adverts.clear();
    _customers.clear();
    super.dispose();
  }
}
