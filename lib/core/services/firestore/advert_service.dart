import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/constant/categories.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/notification_service.dart';

class AdvertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService notificationService = NotificationService();

  // Şehre göre ilanları getir (index gerekmeden)
  Future<List<Advert>> fetchAdvertsByCity(
    String? city, {
    DocumentSnapshot? lastDocument,
    int limit = 25,
  }) async {
    try {
      final upperCity = city;
      debugPrint('Aranan şehir: $upperCity, limit: $limit');

      // Temel sorgu - isCreatorPremium alanına göre önce sırala sonra createdAt
      var query = _firestore
          .collection('events')
          .where('location.city', isEqualTo: upperCity)
          .orderBy('isCreatorPremium', descending: true) // Premium ilanlar önce
          .orderBy('createdAt', descending: true) // Aynı premium durumunda yeni ilanlar önce
          .limit(limit);

      // Eğer son döküman varsa, ondan sonrasını getir
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();
      final adverts = querySnapshot.docs.map((doc) => Advert.fromJson(doc.data(), doc.id)).toList();

      debugPrint('Bulunan ilan sayısı: ${adverts.length}');
      return adverts;
    } catch (e) {
      debugPrint('Şehre göre ilanlar çekilirken hata: $e');
      return [];
    }
  }

  // İlgi alanlarına göre ilanları getir
  Future<List<Advert>> fetchAdvertsByInterests(List<Categories>? interests, {DocumentSnapshot? lastDocument, int limit = 25}) async {
    try {
      // İlgi alanı yoksa boş liste döndür
      if (interests == null || interests.isEmpty) {
        return [];
      }

      // Kategorileri string olarak al
      final categoryValues = interests.map((interest) => interest.name).toList();
      debugPrint('Aranan kategoriler: $categoryValues');

      // GERÇEK ÇÖZÜM: Firestore'un kısıtlamalarından dolayı tek sorguda tüm kategorileri alamayız
      // En fazla whereIn ile 10 kategori alabiliriz
      List<String> categoriesToQuery = categoryValues.length > 10 ? categoryValues.sublist(0, 10) : categoryValues;

      // Tek sorgu oluştur - 10'dan fazla kategori varsa ilk 10'unu al
      var query = _firestore
          .collection('events')
          .where('advertType', whereIn: categoriesToQuery)
          .orderBy('isCreatorPremium', descending: true) // Premium ilanlar önce
          .orderBy('createdAt', descending: true) // Aynı premium durumunda yeni ilanlar önce
          .limit(limit);

      // Pagination için
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      // Sorguyu çalıştır
      final querySnapshot = await query.get();
      final adverts = querySnapshot.docs.map((doc) => Advert.fromJson(doc.data(), doc.id)).toList();

      debugPrint('Bulunan ilan sayısı: ${adverts.length}');
      return adverts;
    } catch (e) {
      debugPrint('İlgi alanlarına göre ilanlar çekilirken hata: $e');
      debugPrint('Hata detayı: $e');
      return [];
    }
  }

  // Cinsiyet ve kategoriye göre esnek filtreleme ile ilanları getir
  Future<List<Advert>> fetchAdvertsByFiltering({
    DocumentSnapshot? lastDocument,
    int limit = 25,
    String? gender,
    String? category,
  }) async {
    try {
      // Temel sorgu
      var query = _firestore.collection('events').limit(limit);

      // Cinsiyet filtresi ekle (eğer belirtilmişse)
      if (gender != null && gender.isNotEmpty) {
        query = query.where('creatorGender', isEqualTo: gender);
      }

      // Kategori filtresi ekle (eğer belirtilmişse)
      if (category != null && category.isNotEmpty) {
        query = query.where('advertType', isEqualTo: category);
      }

      // Sıralama ve pagination - Premium ilanlar önce
      query = query.orderBy('isCreatorPremium', descending: true).orderBy('createdAt', descending: true);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      // Sorguyu çalıştır
      final querySnapshot = await query.get();
      final adverts = querySnapshot.docs.map((doc) => Advert.fromJson(doc.data(), doc.id)).toList();

      debugPrint('Filtrelenmiş ilan sayısı: ${adverts.length}');
      return adverts;
    } catch (e) {
      debugPrint('Filtrelenmiş ilanlar çekilirken hata: $e');
      return [];
    }
  }

  // Other sekmesi için ilanları getir - Kullanıcının şehrinde ve ilgi alanlarında olmayan ilanlar
  Future<List<Advert>> fetchOtherAdverts({
    DocumentSnapshot? lastDocument,
    int limit = 25,
    Customer? user,
  }) async {
    try {
      // Temel sorgu: İlgi alanları dışındaki ilanları çek
      var query = _firestore.collection('events').limit(limit);

      // İlgi alanları dışındaki ilanları filtrele
      var categoryValues = user!.favoriteCategories!.map((interest) => interest.name).take(10).toList();
      query = query
          .where('advertType', whereNotIn: categoryValues)
          .orderBy('isCreatorPremium', descending: true) // Premium ilanlar önce
          .orderBy('createdAt', descending: true);

      // Pagination için
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      // Sorguyu çalıştır
      final querySnapshot = await query.get();
      final adverts = querySnapshot.docs.map((doc) => Advert.fromJson(doc.data(), doc.id)).toList();

      debugPrint('Firestore\'dan çekilen ilan sayısı: ${adverts.length}');

      return adverts;
    } catch (e) {
      debugPrint('Other ilanlar çekilirken hata: $e');
      return [];
    }
  }

// İlan adverts koleksiyonlarında arar
  Future<Advert?> fetchAdvertById(String advertID) async {
    try {
      // Önce events koleksiyonunda ara
      DocumentSnapshot eventSnapshot = await _firestore.collection('events').doc(advertID).get();
      if (eventSnapshot.exists) {
        return Advert.fromJson(eventSnapshot.data() as Map<String, dynamic>, advertID);
      }

      return null;
    } catch (e) {
      debugPrint('İlan arama hatası: $e');
      return null;
    }
  }

  Future<void> likeAdvert(String advertId, String userId, String creatorUserID) async {
    try {
      final docSnapshot = await _firestore.collection('events').doc(advertId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data.containsKey('likers')) {
          await _firestore.collection('events').doc(advertId).update({
            'likers': FieldValue.arrayUnion([userId])
          });
        } else {
          await _firestore.collection('events').doc(advertId).update({
            'likers': [userId]
          });
        }
      }
    } catch (e) {
      debugPrint('İlan beğenme hatası: $e');
    }
  }

  Future<void> unlikeAdvert(String advertId, String userId) async {
    try {
      await _firestore.collection('events').doc(advertId).update({
        'likers': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      debugPrint('İlan beğenme hatası: $e');
    }
  }

  Future<void> deleteAdvert(String advertId) async {
    try {
      await _firestore.collection('events').doc(advertId).delete();
      debugPrint('İlan başarıyla silindi');
    } catch (e) {
      debugPrint('İlan silme hatası: $e');
    }
  }

  // Tüm ilanlara kullanıcıların premium durumunu ekleyen toplu işlem
  Future<void> updateAllAdvertsWithCreatorPremiumStatus() async {
    try {
      // İşlem başlangıcını logla
      debugPrint('Tüm ilanlara premium durumu ekleme işlemi başlatıldı');

      // Batch işlemi için counter
      int batchCount = 0;
      int totalProcessed = 0;

      // Tüm ilanları getir
      final eventsSnapshot = await _firestore.collection('events').get();

      // Kullanıcı ID ve premium durumlarını saklayacak map (önbellek)
      final Map<String, bool> userPremiumStatus = {};

      // Batch oluştur
      var batch = _firestore.batch();

      // İlanları işle
      for (var doc in eventsSnapshot.docs) {
        // İlan verisini al
        final advertData = doc.data();
        final creatorUserID = advertData['creatorUserID'] as String?;

        if (creatorUserID == null || creatorUserID.isEmpty) {
          debugPrint('İlan için creatorUserID bulunamadı: ${doc.id}');
          continue;
        }

        // Kullanıcı premium durumunu al, cache'de yoksa Firestore'dan getir
        bool isPremium;
        if (userPremiumStatus.containsKey(creatorUserID)) {
          isPremium = userPremiumStatus[creatorUserID]!;
        } else {
          // Kullanıcı belgesini getir
          final customerDoc = await _firestore.collection('customers').doc(creatorUserID).get();

          if (!customerDoc.exists) {
            debugPrint('Kullanıcı bulunamadı: $creatorUserID');
            continue;
          }

          // Premium durumunu al
          isPremium = customerDoc.data()?['isPremium'] ?? false;

          // Cache'e ekle
          userPremiumStatus[creatorUserID] = isPremium;
        }

        // İlanı güncelle - isCreatorPremium alanını ekle
        batch.update(doc.reference, {'isCreatorPremium': isPremium});

        // Batch limitini kontrol et (500 işlem)
        batchCount++;
        totalProcessed++;

        if (batchCount >= 499) {
          // Batch'i commit et
          await batch.commit();
          debugPrint('Batch commit edildi: $batchCount ilan işlendi, toplam: $totalProcessed / ${eventsSnapshot.size}');

          // Yeni batch oluştur
          batch = _firestore.batch();
          batchCount = 0;
        }
      }

      // Kalan işlemleri commit et
      if (batchCount > 0) {
        await batch.commit();
        debugPrint('Son batch commit edildi: $batchCount ilan işlendi, toplam: $totalProcessed / ${eventsSnapshot.size}');
      }

      debugPrint('Tüm ilanlar güncellendi. Toplam ilan sayısı: ${eventsSnapshot.size}');
    } catch (e) {
      debugPrint('İlanlar güncellenirken hata oluştu: $e');
      throw Exception('İlanlar güncellenirken hata oluştu: $e');
    }
  }

  // Silinmiş kullanıcıların ilanlarını temizleyen metod
  Future<void> cleanupDeletedUsersAdverts() async {
    try {
      // İşlem başlangıcını logla
      debugPrint('Silinmiş kullanıcıların ilanlarını temizleme işlemi başlatıldı');

      // İstatistikler için sayaçlar
      int totalProcessed = 0;
      int totalDeleted = 0;

      // Batch işlemi için counter ve batch
      int batchCount = 0;
      var batch = _firestore.batch();

      // Tüm ilanları getir
      final eventsSnapshot = await _firestore.collection('events').get();
      debugPrint('Toplam ilan sayısı: ${eventsSnapshot.size}');

      // Silinecek ilanların referanslarını tutacak liste
      final List<DocumentReference> advertsToDelete = [];

      // İlanları işle
      for (var doc in eventsSnapshot.docs) {
        totalProcessed++;

        // İlan verisini al
        final advertData = doc.data();
        final creatorUserID = advertData['creatorUserID'] as String?;

        if (creatorUserID == null || creatorUserID.isEmpty) {
          // CreatorUserID bilgisi eksikse doğrudan sil
          advertsToDelete.add(doc.reference);
          totalDeleted++;
          continue;
        }

        // Kullanıcı belgesinin var olup olmadığını kontrol et
        try {
          final customerDoc = await _firestore.collection('customers').doc(creatorUserID).get();

          // Kullanıcı bulunamadıysa ilanı silme listesine ekle
          if (!customerDoc.exists) {
            advertsToDelete.add(doc.reference);
            totalDeleted++;

            debugPrint('Silinecek ilan: ${doc.id}, Sahibi bulunamadı: $creatorUserID');
          }
        } catch (e) {
          // Kullanıcı kontrolünde hata olursa güvenli tarafa geç, silme
          debugPrint('Kullanıcı kontrolünde hata: $e');
          continue;
        }

        // Her 100 ilanda bir ilerleme bildirimi
        if (totalProcessed % 100 == 0) {
          debugPrint('İşlenen ilan: $totalProcessed / ${eventsSnapshot.size}, Silinecek: $totalDeleted');
        }
      }

      // Silinecek ilanları batch işlemi ile sil
      debugPrint('Toplam silinecek ilan sayısı: ${advertsToDelete.length}');

      for (var advertRef in advertsToDelete) {
        batch.delete(advertRef);
        batchCount++;

        // Batch limitini kontrol et (500 işlem)
        if (batchCount >= 499) {
          // Batch'i commit et
          await batch.commit();
          debugPrint('Batch commit edildi: $batchCount ilan silindi');

          // Yeni batch oluştur
          batch = _firestore.batch();
          batchCount = 0;
        }
      }

      // Kalan işlemleri commit et
      if (batchCount > 0) {
        await batch.commit();
        debugPrint('Son batch commit edildi: $batchCount ilan silindi');
      }

      debugPrint('Temizleme işlemi tamamlandı. Toplam silinen ilan sayısı: $totalDeleted / ${eventsSnapshot.size}');

      return;
    } catch (e) {
      debugPrint('İlanlar temizlenirken hata oluştu: $e');
      throw Exception('İlanlar temizlenirken hata oluştu: $e');
    }
  }

  // Kategorisi yetersiz olan kullanıcıların kategorilerini 3'e tamamlayan metod
  Future<void> completeUserCategoriesToMinimumThree() async {
    try {
      // İşlem başlangıcını logla
      debugPrint('Kategori sayısı yetersiz olan kullanıcıların kategorilerini tamamlama işlemi başlatıldı');

      // Kullanılabilecek tüm varsayılan kategoriler
      final List<String> availableCategories = [
        'kahveSohbet',
        'kitapBulusma',
        'dilKultur',
        'halisaha',
        'doga',
        'fitness',
        'sanatTarih',
        'filmDizi',
        'spor'
      ];

      // İstatistikler için sayaçlar
      int totalProcessed = 0;
      int totalUpdated = 0;

      // Batch işlemi için counter ve batch
      int batchCount = 0;
      var batch = _firestore.batch();

      // Tüm kullanıcıları getir ve manuel olarak kategorileri kontrol et
      final customersSnapshot = await _firestore.collection('customers').get();

      debugPrint('Toplam kullanıcı sayısı: ${customersSnapshot.size}');

      // Kullanıcıları işle
      for (var doc in customersSnapshot.docs) {
        totalProcessed++;

        // Kullanıcı verisini al
        final userData = doc.data();

        // Mevcut kategorileri al
        List<String> currentCategories = [];
        final favoriteCategories = userData['favoriteCategories'];

        if (favoriteCategories != null && favoriteCategories is List) {
          currentCategories = List<String>.from(favoriteCategories.map((cat) => cat.toString()));
        }

        // Kategori sayısı 3'ten az mı kontrol et
        if (currentCategories.length < 3) {
          // Eklenmesi gereken kategori sayısı
          int neededCategories = 3 - currentCategories.length;
          List<String> categoriesToAdd = [];

          // Kullanıcının henüz sahip olmadığı kategorilerden ekle
          for (String category in availableCategories) {
            if (!currentCategories.contains(category)) {
              categoriesToAdd.add(category);
              neededCategories--;

              // Yeterli sayıda kategori eklendiyse döngüden çık
              if (neededCategories <= 0) break;
            }
          }

          // Yeni kategori listesi oluştur (mevcut + eklenecek)
          List<String> updatedCategories = [...currentCategories, ...categoriesToAdd];

          // Firestore'u güncelle
          batch.update(doc.reference, {'favoriteCategories': updatedCategories});

          batchCount++;
          totalUpdated++;

          // Batch limitini kontrol et (500 işlem)
          if (batchCount >= 499) {
            // Batch'i commit et
            await batch.commit();
            debugPrint('Batch commit edildi: $batchCount kullanıcı güncellendi, toplam: $totalUpdated / $totalProcessed');

            // Yeni batch oluştur
            batch = _firestore.batch();
            batchCount = 0;
          }
        }

        // Her 100 kullanıcıda bir ilerleme bildirimi
        if (totalProcessed % 100 == 0) {
          debugPrint('İşlenen kullanıcı: $totalProcessed / ${customersSnapshot.size}, Güncellenen: $totalUpdated');
        }
      }

      // Kalan işlemleri commit et
      if (batchCount > 0) {
        await batch.commit();
        debugPrint('Son batch commit edildi: $batchCount kullanıcı güncellendi');
      }

      debugPrint('Kategori tamamlama işlemi tamamlandı. Toplam güncellenen kullanıcı sayısı: $totalUpdated / $totalProcessed');
    } catch (e) {
      debugPrint('Kullanıcı kategorileri tamamlanırken hata oluştu: $e');
      throw Exception('Kullanıcı kategorileri tamamlanırken hata oluştu: $e');
    }
  }

  // Kullanıcıların kategori durumlarını kontrol eden metod
  Future<void> checkUserCategoriesStatus() async {
    try {
      // İşlem başlangıcını logla
      debugPrint('Kullanıcı kategori durumu kontrol işlemi başlatıldı');

      // İstatistikler için sayaçlar
      int totalUsers = 0;
      int usersWithNoCategories = 0;
      int usersWithFewCategories = 0; // 3'ten az kategorisi olanlar

      // Tüm kullanıcıları getir
      final customersSnapshot = await _firestore.collection('customers').get();
      totalUsers = customersSnapshot.size;

      debugPrint('Toplam kullanıcı sayısı: $totalUsers');

      // Kategori sayısına göre kullanıcı dağılımı
      Map<int, int> categoryCountDistribution = {};
      List<String> usersWithoutCategories = [];

      // Kullanıcıları işle
      for (var doc in customersSnapshot.docs) {
        final userData = doc.data();
        final userId = doc.id;

        // Kategori listesini al
        final List<dynamic>? categories = userData['favoriteCategories'] as List<dynamic>?;

        int categoryCount = 0;
        if (categories != null) {
          categoryCount = categories.length;
        }

        // Kategori sayısına göre istatistik tut
        categoryCountDistribution[categoryCount] = (categoryCountDistribution[categoryCount] ?? 0) + 1;

        // Hiç kategorisi yoksa
        if (categoryCount == 0) {
          usersWithNoCategories++;
          usersWithoutCategories.add(userId);
        }

        // 3'ten az kategorisi varsa
        if (categoryCount < 3) {
          usersWithFewCategories++;
        }

        // Her 500 kullanıcıda bir ilerleme bildirimi
        if (usersWithoutCategories.length % 500 == 0 && usersWithoutCategories.isNotEmpty) {
          debugPrint('İşlenen kullanıcı: ${usersWithoutCategories.length}');
        }
      }

      // Sonuçları logla
      debugPrint('Kategori sayısına göre kullanıcı dağılımı:');
      categoryCountDistribution.forEach((categoryCount, userCount) {
        debugPrint('$categoryCount kategori: $userCount kullanıcı (${(userCount / totalUsers * 100).toStringAsFixed(2)}%)');
      });

      debugPrint(
          'Hiç kategorisi olmayan kullanıcı sayısı: $usersWithNoCategories (${(usersWithNoCategories / totalUsers * 100).toStringAsFixed(2)}%)');
      debugPrint(
          '3\'ten az kategorisi olan kullanıcı sayısı: $usersWithFewCategories (${(usersWithFewCategories / totalUsers * 100).toStringAsFixed(2)}%)');

      // Hiç kategorisi olmayan kullanıcıları listele (ilk 20)
      if (usersWithoutCategories.isNotEmpty) {
        final displayCount = usersWithoutCategories.length > 20 ? 20 : usersWithoutCategories.length;
        debugPrint('Hiç kategorisi olmayan ilk $displayCount kullanıcı:');
        for (int i = 0; i < displayCount; i++) {
          debugPrint('- ${usersWithoutCategories[i]}');
        }
      }

      debugPrint('Kategori kontrolü tamamlandı.');
    } catch (e) {
      debugPrint('Kullanıcı kategori kontrolünde hata oluştu: $e');
    }
  }

  // Kategorisi olmayan kullanıcılara varsayılan kategoriler ekleyen metod
  Future<void> addDefaultCategoriesToUsers() async {
    try {
      // İşlem başlangıcını logla
      debugPrint('Kategorisi olmayan kullanıcılara varsayılan kategoriler ekleme işlemi başlatıldı');

      // Varsayılan kategoriler
      final List<String> defaultCategories = ['kahveSohbet', 'kitapBulusma', 'dilKultur'];

      // İstatistikler için sayaçlar
      int totalProcessed = 0;
      int totalUpdated = 0;

      // Batch işlemi için counter ve batch
      int batchCount = 0;
      var batch = _firestore.batch();

      // Tüm kullanıcıları getir ve manuel olarak kategorileri kontrol et
      final customersSnapshot = await _firestore.collection('customers').get();

      debugPrint('Toplam kullanıcı sayısı: ${customersSnapshot.size}');

      // Kullanıcıları işle
      for (var doc in customersSnapshot.docs) {
        totalProcessed++;

        // Kullanıcı verisini al
        final userData = doc.data();

        // Kategorileri kontrol et (null veya boş ise güncelle)
        final favoriteCategories = userData['favoriteCategories'];
        bool shouldUpdate = false;

        // Kategoriler null ise veya boş bir liste ise güncelle
        if (favoriteCategories == null) {
          shouldUpdate = true;
        } else if (favoriteCategories is List && favoriteCategories.isEmpty) {
          shouldUpdate = true;
        }

        if (shouldUpdate) {
          // Varsayılan kategorileri ekle
          batch.update(doc.reference, {'favoriteCategories': defaultCategories});

          batchCount++;
          totalUpdated++;

          // Batch limitini kontrol et (500 işlem)
          if (batchCount >= 499) {
            // Batch'i commit et
            await batch.commit();
            debugPrint('Batch commit edildi: $batchCount kullanıcı güncellendi, toplam: $totalUpdated / $totalProcessed');

            // Yeni batch oluştur
            batch = _firestore.batch();
            batchCount = 0;
          }
        }

        // Her 100 kullanıcıda bir ilerleme bildirimi
        if (totalProcessed % 100 == 0) {
          debugPrint('İşlenen kullanıcı: $totalProcessed / ${customersSnapshot.size}, Güncellenen: $totalUpdated');
        }
      }

      // Kalan işlemleri commit et
      if (batchCount > 0) {
        await batch.commit();
        debugPrint('Son batch commit edildi: $batchCount kullanıcı güncellendi');
      }

      debugPrint('Güncelleme işlemi tamamlandı. Toplam güncellenen kullanıcı sayısı: $totalUpdated / $totalProcessed');
    } catch (e) {
      debugPrint('Kullanıcı kategori güncellemesinde hata oluştu: $e');
      throw Exception('Kullanıcı kategori güncellemesinde hata oluştu: $e');
    }
  }
}
