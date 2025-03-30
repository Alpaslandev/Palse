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
      var query = _firestore.collection('events').limit(1000);

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
      // Kullanıcı null ise veya favoriteCategories null/boş ise doğrudan tüm ilanları getir
      if (user == null || user.favoriteCategories == null || user.favoriteCategories!.isEmpty) {
        // Temel sorgu: Tüm ilanları getir
        var query = _firestore.collection('events').orderBy('isCreatorPremium', descending: true).orderBy('createdAt', descending: true).limit(limit);

        // Pagination için
        if (lastDocument != null) {
          query = query.startAfterDocument(lastDocument);
        }

        final querySnapshot = await query.get();
        final adverts = querySnapshot.docs.map((doc) => Advert.fromJson(doc.data(), doc.id)).toList();
        debugPrint('Kategori olmadan çekilen ilan sayısı: ${adverts.length}');
        return adverts;
      }

      // İlgi alanları dışındaki ilanları filtrele
      // Firestore whereNotIn sorgusu en fazla 10 değer alabilir
      var categoryValues = user.favoriteCategories!.map((interest) => interest.name).take(10).toList();

      // Kategori listesi boş olmamalı, en az bir kategori içermeli
      if (categoryValues.isEmpty) {
        // Boş liste durumunda yine normal sorgu yap
        var query = _firestore.collection('events').orderBy('isCreatorPremium', descending: true).orderBy('createdAt', descending: true).limit(limit);

        // Pagination için
        if (lastDocument != null) {
          query = query.startAfterDocument(lastDocument);
        }

        final querySnapshot = await query.get();
        final adverts = querySnapshot.docs.map((doc) => Advert.fromJson(doc.data(), doc.id)).toList();
        debugPrint('Boş kategori listesi için çekilen ilan sayısı: ${adverts.length}');
        return adverts;
      }

      // Temel sorgu: İlgi alanları dışındaki ilanları çek
      var query = _firestore
          .collection('events')
          .where('advertType', whereNotIn: categoryValues)
          .orderBy('advertType') // whereNotIn ile kullanılan alan için önce orderBy gerekli
          .orderBy('isCreatorPremium', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      // Pagination için
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      // Sorguyu çalıştır
      final querySnapshot = await query.get();
      final adverts = querySnapshot.docs.map((doc) => Advert.fromJson(doc.data(), doc.id)).toList();

      debugPrint('whereNotIn ile çekilen ilan sayısı: ${adverts.length}');
      return adverts;
    } catch (e) {
      debugPrint('Other ilanlar çekilirken hata: $e');
      // Hata durumunda hatanın tam detayını logla
      debugPrint('Hata detayı: $e');

      // Hata durumunda boş liste döndür
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

  // Events koleksiyonundaki tüm belgelerin field tutarlılığını kontrol eden metod
  Future<void> checkFieldConsistencyInEvents() async {
    try {
      // İşlem başlangıcını logla
      debugPrint('Events koleksiyonundaki field tutarlılığı kontrolü başlatıldı');

      // Tüm belgeleri getir
      final eventsSnapshot = await _firestore.collection('events').get();
      debugPrint('Toplam belge sayısı: ${eventsSnapshot.size}');

      // İlk belgenin field'larını referans al
      final firstDoc = eventsSnapshot.docs.last;
      final referenceFields = firstDoc.data().keys.toSet();
      debugPrint('Referans field\'lar: ${referenceFields.join(', ')}');

      // İstatistikler için sayaçlar
      int totalProcessed = 0;
      int inconsistentDocs = 0;

      // Tüm belgeleri kontrol et
      for (var doc in eventsSnapshot.docs) {
        totalProcessed++;

        // Mevcut belgenin field'larını al
        final currentFields = doc.data().keys.toSet();

        // Eksik veya fazla field'ları bul
        final missingFields = referenceFields.difference(currentFields);
        final extraFields = currentFields.difference(referenceFields);

        // Eksik veya fazla field varsa logla
        if (missingFields.isNotEmpty || extraFields.isNotEmpty) {
          inconsistentDocs++;
          debugPrint('Tutarsız belge ID: ${doc.id}');
          if (missingFields.isNotEmpty) {
            debugPrint('Eksik field\'lar: ${missingFields.join(', ')}');
          }
          if (extraFields.isNotEmpty) {
            debugPrint('Fazla field\'lar: ${extraFields.join(', ')}');
          }
        }

        // Her 100 belgede bir ilerleme bildirimi
        if (totalProcessed % 100 == 0) {
          debugPrint('İşlenen belge: $totalProcessed / ${eventsSnapshot.size}, Tutarsız belge sayısı: $inconsistentDocs');
        }
      }

      // Sonuçları logla
      debugPrint('Field tutarlılığı kontrolü tamamlandı. Toplam tutarsız belge sayısı: $inconsistentDocs / ${eventsSnapshot.size}');
    } catch (e) {
      debugPrint('Field tutarlılığı kontrolü sırasında hata oluştu: $e');
      throw Exception('Field tutarlılığı kontrolü sırasında hata oluştu: $e');
    }
  }

  // isCreatorPremium, createdAt ve advertType alanlarının varlığını kontrol eden metod
  Future<void> checkRequiredFieldsInEvents() async {
    try {
      // İşlem başlangıcını logla
      debugPrint('İlan belgelerinde zorunlu alanların kontrolü başlatıldı');

      // Kontrol edilecek alanlar
      final requiredFields = ['isCreatorPremium', 'createdAt', 'advertType'];

      // İstatistikler için sayaçlar
      int totalProcessed = 0;
      int documentsWithMissingFields = 0;

      // Eksik alanlara sahip belgelerin ID'lerini saklayan map
      final Map<String, List<String>> missingFieldsMap = {};

      // Tüm ilanları getir
      final eventsSnapshot = await _firestore.collection('events').get();
      debugPrint('Toplam ilan sayısı: ${eventsSnapshot.size}');

      // Tüm belgeleri kontrol et
      for (var doc in eventsSnapshot.docs) {
        totalProcessed++;
        final data = doc.data();

        // Belgedeki eksik alanları bul
        final List<String> missingFields = [];
        for (var field in requiredFields) {
          if (!data.containsKey(field)) {
            missingFields.add(field);
          }
        }

        // Eksik alan varsa kaydet
        if (missingFields.isNotEmpty) {
          documentsWithMissingFields++;
          missingFieldsMap[doc.id] = missingFields;

          debugPrint('Belge ID: ${doc.id}, Eksik alanlar: ${missingFields.join(', ')}');
        }

        // Her 100 belgede bir ilerleme bildirimi
        if (totalProcessed % 100 == 0) {
          debugPrint('İşlenen ilan: $totalProcessed / ${eventsSnapshot.size}, Sorunlu belge sayısı: $documentsWithMissingFields');
        }
      }

      // Sonuçları logla
      debugPrint('Zorunlu alan kontrolü tamamlandı.');
      debugPrint('Toplam işlenen belge: $totalProcessed');
      debugPrint(
          'Eksik alanlara sahip belge sayısı: $documentsWithMissingFields (${(documentsWithMissingFields / totalProcessed * 100).toStringAsFixed(2)}%)');

      // Özet istatistikler
      final fieldStats = <String, int>{};
      for (var field in requiredFields) {
        int missingCount = 0;
        missingFieldsMap.forEach((_, fields) {
          if (fields.contains(field)) {
            missingCount++;
          }
        });
        fieldStats[field] = missingCount;
      }

      // Alan bazlı istatistikleri logla
      debugPrint('Alan bazlı eksik belge sayısı:');
      fieldStats.forEach((field, count) {
        debugPrint('- $field: $count belge (${(count / totalProcessed * 100).toStringAsFixed(2)}%)');
      });
    } catch (e) {
      debugPrint('Zorunlu alan kontrolü sırasında hata oluştu: $e');
      throw Exception('Zorunlu alan kontrolü sırasında hata oluştu: $e');
    }
  }

  // Belirli ilan ID'leri için creatorUserID kontrolü ve customer varlığı kontrolü
  Future<void> checkAdvertCreatorExistence() async {
    try {
      // Kontrol edilecek ilan ID'leri
      final List<String> advertIds = ['3OgPxKdkfVQayOEJb3q6', 'ABNqUY7sV33orG6I2ack', 'UJ7dkpq4QOJ0HYfJjv1H'];

      debugPrint('Belirtilen ilanların creatorUserID kontrolü başlatıldı');

      for (var advertId in advertIds) {
        // İlan belgesini getir
        final advertDoc = await _firestore.collection('events').doc(advertId).get();

        if (!advertDoc.exists) {
          debugPrint('İlan bulunamadı: $advertId');
          continue;
        }

        final advertData = advertDoc.data();
        if (advertData == null) {
          debugPrint('İlan verisi boş: $advertId');
          continue;
        }

        // creatorUserID alanını kontrol et
        final creatorUserID = advertData['creatorUserID'];

        if (creatorUserID == null || creatorUserID.toString().isEmpty) {
          debugPrint('İlan: $advertId - creatorUserID alanı yok veya boş!');
          continue;
        }

        debugPrint('İlan: $advertId - creatorUserID: $creatorUserID');

        // Customer koleksiyonunda bu kullanıcının varlığını kontrol et
        final customerDoc = await _firestore.collection('customers').doc(creatorUserID.toString()).get();

        if (!customerDoc.exists) {
          debugPrint('İlan: $advertId - SORUN: Kullanıcı bulunamadı: $creatorUserID');
        } else {
          // Kullanıcı premium durumunu al
          final isPremium = customerDoc.data()?['isPremium'] ?? false;
          debugPrint('İlan: $advertId - Kullanıcı bulundu: $creatorUserID (Premium: $isPremium)');

          // İlana isCreatorPremium alanını ekle/güncelle
          await _firestore.collection('events').doc(advertId).update({'isCreatorPremium': isPremium});

          debugPrint('İlan: $advertId - isCreatorPremium alanı güncellendi: $isPremium');
        }
      }

      debugPrint('Kontrol işlemi tamamlandı.');
    } catch (e) {
      debugPrint('İlan yaratıcısı kontrolü sırasında hata oluştu: $e');
    }
  }

  // Veritabanındaki sıralama ve filtreleme için kullanılan alanlarda tutarsızlık kontrolü
  Future<void> checkDatabaseConsistencyForQueries() async {
    try {
      debugPrint('Veritabanı tutarsızlık kontrolü başlatıldı: Sorgu alanları için detaylı kontrol');

      // Kontrol edilecek kritik sorgu alanları
      final List<String> queryFields = ['advertType', 'isCreatorPremium', 'createdAt'];

      // İstatistikler için sayaçlar
      int totalProcessed = 0;
      int inconsistentDocs = 0;

      // Her bir alan için tip tutarsızlığı olan belgeleri sakla
      Map<String, List<String>> fieldTypeErrors = {};
      // Her alan için belge sayısı
      Map<String, int> fieldCounts = {};
      // advertType değerlerinin dağılımı
      Map<String, int> advertTypeDistribution = {};

      queryFields.forEach((field) {
        fieldTypeErrors[field] = [];
        fieldCounts[field] = 0;
      });

      // Tüm ilanları getir
      final eventsSnapshot = await _firestore.collection('events').get();
      int totalDocs = eventsSnapshot.size;
      debugPrint('Toplam belge sayısı: $totalDocs');

      // Tüm belgeleri kontrol et
      for (var doc in eventsSnapshot.docs) {
        totalProcessed++;
        final data = doc.data();
        final docId = doc.id;

        // Her bir kritik alanı kontrol et
        for (var field in queryFields) {
          // 1. Alan var mı?
          if (!data.containsKey(field)) {
            inconsistentDocs++;
            debugPrint('HATA: Belge $docId - $field alanı eksik!');
            continue;
          }

          fieldCounts[field] = (fieldCounts[field] ?? 0) + 1;

          // 2. Alan için tip kontrolü
          final value = data[field];

          switch (field) {
            case 'advertType':
              // advertType bir string olmalı
              if (value is! String) {
                fieldTypeErrors[field]!.add(docId);
                debugPrint('HATA: Belge $docId - advertType alan tipi yanlış: ${value.runtimeType}');
              } else {
                // advertType dağılımını topla
                advertTypeDistribution[value] = (advertTypeDistribution[value] ?? 0) + 1;
              }
              break;

            case 'isCreatorPremium':
              // isCreatorPremium bir boolean olmalı
              if (value is! bool) {
                fieldTypeErrors[field]!.add(docId);
                debugPrint('HATA: Belge $docId - isCreatorPremium alan tipi yanlış: ${value.runtimeType}');
              }
              break;

            case 'createdAt':
              // createdAt bir Timestamp olmalı
              if (value is! Timestamp) {
                fieldTypeErrors[field]!.add(docId);
                debugPrint('HATA: Belge $docId - createdAt alan tipi yanlış: ${value.runtimeType}');
              }
              break;
          }
        }

        // Ayrıca sorgu sırasında sorun çıkarabilecek diğer tutarsızlıkları kontrol et
        if (data.containsKey('advertType') && data.containsKey('isCreatorPremium') && data.containsKey('createdAt')) {
          // whereNotIn sorgusu için advertType kontrolü
          final advertType = data['advertType'];
          if (advertType is String && advertType.isEmpty) {
            debugPrint('UYARI: Belge $docId - advertType boş string, bu sorgu sırasında sorun yaratabilir');
          }
        }

        // Her 100 belgede bir ilerleme bildirimi
        if (totalProcessed % 100 == 0) {
          debugPrint('İşlenen belge: $totalProcessed / $totalDocs');
        }
      }

      // Sonuçları logla
      debugPrint('\n===== KONTROL SONUÇLARI =====');

      // Alan varlığı istatistikleri
      debugPrint('\nAlan Varlığı İstatistikleri:');
      fieldCounts.forEach((field, count) {
        double percentage = (count / totalDocs) * 100;
        debugPrint('- $field: $count / $totalDocs belge (${percentage.toStringAsFixed(2)}%)');
      });

      // Tip hatası olan belgeler
      debugPrint('\nTip Hatası Olan Belgeler:');
      bool hasTypeErrors = false;
      fieldTypeErrors.forEach((field, docs) {
        if (docs.isNotEmpty) {
          hasTypeErrors = true;
          debugPrint('- $field: ${docs.length} belgede tip hatası var');
          if (docs.length <= 5) {
            debugPrint('  Belge ID\'leri: ${docs.join(', ')}');
          } else {
            debugPrint('  İlk 5 belge ID: ${docs.take(5).join(', ')}...');
          }
        }
      });

      if (!hasTypeErrors) {
        debugPrint('Hiçbir belgede tip hatası bulunamadı.');
      }

      // advertType dağılımı
      debugPrint('\nadvertType Dağılımı:');
      advertTypeDistribution.forEach((type, count) {
        double percentage = (count / totalDocs) * 100;
        debugPrint('- $type: $count belge (${percentage.toStringAsFixed(2)}%)');
      });

      // Sorgu testi: whereNotIn kullanılabilir mi?
      debugPrint('\nSorgu Uyumluluk Kontrolü:');
      if (advertTypeDistribution.length > 10) {
        debugPrint('UYARI: ${advertTypeDistribution.length} farklı advertType değeri var. whereNotIn sorgusu maksimum 10 değer alabilir!');
      } else {
        debugPrint('OK: ${advertTypeDistribution.length} farklı advertType değeri var, whereNotIn sorgusu için uygundur.');
      }

      // Tespit edilen sorunlar var mı?
      if (inconsistentDocs > 0) {
        debugPrint('\nTOPLAM SORUNLU BELGE: $inconsistentDocs / $totalDocs (${(inconsistentDocs / totalDocs * 100).toStringAsFixed(2)}%)');
        debugPrint('\nÖNERİLER:');
        debugPrint('1. Eksik alanları olan belgeleri güncelleyin veya silin.');
        debugPrint('2. Tip hataları olan belgeleri düzeltin.');
        debugPrint('3. Özellikle advertType alanı için veritabanı tutarlılığını sağlayın.');
      } else {
        debugPrint('\nHiçbir tutarsızlık tespit edilmedi. Veritabanı sorgu alanları için tutarlı görünüyor.');
      }

      debugPrint('\nVeritabanı tutarlılık kontrolü tamamlandı.');
    } catch (e) {
      debugPrint('Veritabanı tutarlılık kontrolünde hata oluştu: $e');
    }
  }
}
