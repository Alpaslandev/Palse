import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tasakliyiz_gucluyuz_ankaragucluyuz.dart';
import 'package:palseapp/core/helper/date_parse.dart';
import 'package:palseapp/core/helper/categorie_parse.dart';
import 'package:palseapp/core/helper/location_parse.dart';
import 'package:palseapp/core/constant/categories.dart';

/// Firestore yedekleme örneği
/// Kankam için özel olarak hazırladım 🤜🤛
class FirestoreBackupExample extends StatefulWidget {
  const FirestoreBackupExample({Key? key}) : super(key: key);

  @override
  State<FirestoreBackupExample> createState() => _FirestoreBackupExampleState();
}

class _FirestoreBackupExampleState extends State<FirestoreBackupExample> {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();

  bool _isLoading = false;
  String _statusMessage = '';
  double _progress = 0.0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _sourceController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _backupCollection() async {
    final String source = _sourceController.text.trim();
    final String target = _targetController.text.trim();

    if (source.isEmpty || target.isEmpty) {
      setState(() {
        _statusMessage = 'Kaynak ve hedef koleksiyon adlarını girmelisin kankam!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _progress = 0.0;
      _statusMessage = 'Yedekleme başlıyor...';
    });

    try {
      await firestoreBackup.backupCollection(
        sourceCollection: source,
        targetCollection: target,
        onProgress: (processed, total) {
          setState(() {
            _progress = processed / total;
            _statusMessage = 'İşleniyor: $processed / $total döküman';
          });
        },
        onComplete: (total) {
          setState(() {
            _isLoading = false;
            _progress = 1.0;
            _statusMessage = 'Yedekleme tamamlandı! $total döküman kopyalandı.';
          });
        },
        onError: (error) {
          setState(() {
            _isLoading = false;
            _statusMessage = 'Hata: $error';
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Beklenmeyen hata: $e';
      });
    }
  }

  // Tarih düzeltme fonksiyonu
  Future<void> _fixDates() async {
    final String collectionName = _sourceController.text.trim();

    if (collectionName.isEmpty) {
      setState(() {
        _statusMessage = 'Koleksiyon adını girmelisin kankam!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _progress = 0.0;
      _statusMessage = 'Tarih düzeltme başlıyor...';
    });

    try {
      // Koleksiyondaki tüm dökümanları al
      final QuerySnapshot snapshot = await _firestore.collection(collectionName).get();
      final int totalDocuments = snapshot.docs.length;
      int processedDocuments = 0;
      int updatedDocuments = 0;

      // Her dökümanı kontrol et ve güncelle
      for (final DocumentSnapshot doc in snapshot.docs) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Tarih alanlarını kontrol et
        if (data['advertDate'] != null || data['advertTime'] != null) {
          // Tarihi dönüştür
          final DateTime? newDate = parseDateTime(data['advertDate'], data['advertTime']);

          if (newDate != null) {
            // Güncelleme işlemi için map oluştur
            final Map<String, dynamic> updateData = {
              'startEventDate': Timestamp.fromDate(newDate),
              // Eski alanları silmek için FieldValue.delete() kullan
              'advertDate': FieldValue.delete(),
              'advertTime': FieldValue.delete(),
              'advertLastUsage': FieldValue.delete(), // Bu alan da artık kullanılmıyor
            };

            // Dökümanı güncelle
            await _firestore.collection(collectionName).doc(doc.id).update(updateData);
            updatedDocuments++;
          }
        }

        // İlerleme durumunu güncelle
        processedDocuments++;
        setState(() {
          _progress = processedDocuments / totalDocuments;
          _statusMessage = 'Tarih düzeltiliyor: $processedDocuments / $totalDocuments döküman';
        });
      }

      setState(() {
        _isLoading = false;
        _progress = 1.0;
        _statusMessage = 'Tarih düzeltme tamamlandı! $updatedDocuments döküman güncellendi ve eski alanlar silindi.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Tarih düzeltme hatası: $e';
      });
    }
  }

  // Kategori düzeltme fonksiyonu
  Future<void> _fixCategories() async {
    final String collectionName = _sourceController.text.trim();

    if (collectionName.isEmpty) {
      setState(() {
        _statusMessage = 'Koleksiyon adını girmelisin kankam!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _progress = 0.0;
      _statusMessage = 'Kategori düzeltme başlıyor...';
    });

    try {
      // Koleksiyondaki tüm dökümanları al
      final QuerySnapshot snapshot = await _firestore.collection(collectionName).get();
      final int totalDocuments = snapshot.docs.length;
      int processedDocuments = 0;
      int updatedDocuments = 0;

      // Her dökümanı kontrol et ve güncelle
      for (final DocumentSnapshot doc in snapshot.docs) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Kategori alanını kontrol et
        if (data['advertType'] != null) {
          // Kategoriyi dönüştür
          final Categories? newCategory = parseCategoryType(data['advertType']);

          if (newCategory != null) {
            // Güncelleme işlemi için map oluştur - eski advertType'ı yeni formata dönüştür
            // Eski advertType alanını silmiyoruz, sadece değerini güncelliyoruz
            final Map<String, dynamic> updateData = {
              'advertType': newCategory.name,
            };

            // Dökümanı güncelle
            await _firestore.collection(collectionName).doc(doc.id).update(updateData);
            updatedDocuments++;
          }
        }

        // İlerleme durumunu güncelle
        processedDocuments++;
        setState(() {
          _progress = processedDocuments / totalDocuments;
          _statusMessage = 'Kategori düzeltiliyor: $processedDocuments / $totalDocuments döküman';
        });
      }

      setState(() {
        _isLoading = false;
        _progress = 1.0;
        _statusMessage = 'Kategori düzeltme tamamlandı! $updatedDocuments döküman güncellendi.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Kategori düzeltme hatası: $e';
      });
    }
  }

  // Konum düzeltme fonksiyonu
  Future<void> _fixLocations() async {
    final String collectionName = _sourceController.text.trim();

    if (collectionName.isEmpty) {
      setState(() {
        _statusMessage = 'Koleksiyon adını girmelisin kankam!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _progress = 0.0;
      _statusMessage = 'Konum düzeltme başlıyor...';
    });

    try {
      // Koleksiyondaki tüm dökümanları al
      final QuerySnapshot snapshot = await _firestore.collection(collectionName).get();
      final int totalDocuments = snapshot.docs.length;
      int processedDocuments = 0;
      int updatedDocuments = 0;

      // Her dökümanı kontrol et ve güncelle
      for (final DocumentSnapshot doc in snapshot.docs) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Konum alanlarını kontrol et
        if (data['city'] != null || data['district'] != null || data['geoPoint'] != null) {
          // Konumu dönüştür
          final locationModel = parseAdvertLocation(data);

          if (locationModel != null) {
            // Güncelleme işlemi için map oluştur
            final Map<String, dynamic> updateData = {
              'location': locationModel.toJson(),
              // Eski alanları silmek için FieldValue.delete() kullan
              'city': FieldValue.delete(),
              'district': FieldValue.delete(),
              'geoPoint': FieldValue.delete(),
            };

            // Dökümanı güncelle
            await _firestore.collection(collectionName).doc(doc.id).update(updateData);
            updatedDocuments++;
          }
        }

        // İlerleme durumunu güncelle
        processedDocuments++;
        setState(() {
          _progress = processedDocuments / totalDocuments;
          _statusMessage = 'Konum düzeltiliyor: $processedDocuments / $totalDocuments döküman';
        });
      }

      setState(() {
        _isLoading = false;
        _progress = 1.0;
        _statusMessage = 'Konum düzeltme tamamlandı! $updatedDocuments döküman güncellendi ve eski alanlar silindi.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Konum düzeltme hatası: $e';
      });
    }
  }

  // advertName alanını title olarak değiştiren fonksiyon
  Future<void> _renameAdvertNameToTitle() async {
    final String collectionName = _sourceController.text.trim();

    if (collectionName.isEmpty) {
      setState(() {
        _statusMessage = 'Koleksiyon adını girmelisin kankam!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _progress = 0.0;
      _statusMessage = 'Alan yeniden adlandırma başlıyor...';
    });

    try {
      // Koleksiyondaki tüm dökümanları al
      final QuerySnapshot snapshot = await _firestore.collection(collectionName).get();
      final int totalDocuments = snapshot.docs.length;
      int processedDocuments = 0;
      int updatedDocuments = 0;

      // Her dökümanı kontrol et ve güncelle
      for (final DocumentSnapshot doc in snapshot.docs) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // advertName alanını kontrol et
        if (data.containsKey('advertName')) {
          // Güncelleme işlemi için map oluştur
          final Map<String, dynamic> updateData = {
            'title': data['advertName'], // advertName değerini title'a kopyala
            'advertName': FieldValue.delete(), // advertName alanını sil
          };

          // Dökümanı güncelle
          await _firestore.collection(collectionName).doc(doc.id).update(updateData);
          updatedDocuments++;
        }

        // İlerleme durumunu güncelle
        processedDocuments++;
        setState(() {
          _progress = processedDocuments / totalDocuments;
          _statusMessage = 'Alan yeniden adlandırılıyor: $processedDocuments / $totalDocuments döküman';
        });
      }

      setState(() {
        _isLoading = false;
        _progress = 1.0;
        _statusMessage = 'Alan yeniden adlandırma tamamlandı! $updatedDocuments döküman güncellendi.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Alan yeniden adlandırma hatası: $e';
      });
    }
  }

  // İlanların creatorGender alanını güncelleme fonksiyonu
  Future<void> _updateCreatorGenders() async {
    final String collectionName = _sourceController.text.trim();

    if (collectionName.isEmpty) {
      setState(() {
        _statusMessage = 'Koleksiyon adını girmelisin kankam!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _progress = 0.0;
      _statusMessage = 'CreatorGender güncelleme başlıyor...';
    });

    try {
      // Koleksiyondaki tüm dökümanları al
      final QuerySnapshot snapshot = await _firestore.collection(collectionName).get();
      final int totalDocuments = snapshot.docs.length;
      int processedDocuments = 0;
      int updatedDocuments = 0;

      // Kullanıcı önbelleği - Aynı kullanıcıyı tekrar tekrar sorgulamayı önlemek için
      final Map<String, String> userGenderCache = {};

      // Her dökümanı kontrol et ve güncelle
      for (final DocumentSnapshot doc in snapshot.docs) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // creatorUserID alanını kontrol et
        if (data['creatorUserID'] != null) {
          final String creatorUserID = data['creatorUserID'] as String;
          String? gender;

          // Önbellekte bu kullanıcı var mı kontrol et
          if (userGenderCache.containsKey(creatorUserID)) {
            gender = userGenderCache[creatorUserID];
          } else {
            // Kullanıcı bilgilerini al
            final DocumentSnapshot userDoc = await _firestore.collection('customers').doc(creatorUserID).get();

            if (userDoc.exists) {
              final Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

              // Gender bilgisini al
              if (userData['gender'] != null) {
                // Gender değerini normalize et
                final String rawGender = userData['gender'].toString().toLowerCase();

                // Gender enum'a dönüştür
                if (rawGender == 'male' || rawGender == 'erkek' || rawGender == 'm') {
                  gender = 'male';
                } else if (rawGender == 'female' || rawGender == 'kadın' || rawGender == 'kadin' || rawGender == 'f') {
                  gender = 'female';
                } else {
                  gender = 'others';
                }

                // Önbelleğe ekle
                userGenderCache[creatorUserID] = gender;
              }
            }
          }

          // Gender bilgisi varsa, ilanı güncelle
          if (gender != null) {
            await _firestore.collection(collectionName).doc(doc.id).update({
              'creatorGender': gender,
            });
            updatedDocuments++;
          }
        }

        // İlerleme durumunu güncelle
        processedDocuments++;
        setState(() {
          _progress = processedDocuments / totalDocuments;
          _statusMessage = 'CreatorGender güncelleniyor: $processedDocuments / $totalDocuments döküman';
        });
      }

      setState(() {
        _isLoading = false;
        _progress = 1.0;
        _statusMessage = 'CreatorGender güncelleme tamamlandı! $updatedDocuments döküman güncellendi.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'CreatorGender güncelleme hatası: $e';
      });
    }
  }

  // Belirli alanları silme ve belge yapısını analiz etme fonksiyonu
  Future<void> _cleanAndAnalyzeFields() async {
    final String collectionName = _sourceController.text.trim();

    if (collectionName.isEmpty) {
      setState(() {
        _statusMessage = 'Koleksiyon adını girmelisin kankam!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _progress = 0.0;
      _statusMessage = 'Analiz ve temizleme başlıyor...';
    });

    try {
      // Koleksiyondaki tüm dökümanları al
      final QuerySnapshot snapshot = await _firestore.collection(collectionName).get();
      final int totalDocuments = snapshot.docs.length;
      int processedDocuments = 0;
      int updatedDocuments = 0;

      // Tüm belgelerdeki alanları toplamak için bir set
      final Set<String> allFields = {};

      // Her belgedeki alanları saklamak için bir map
      final Map<String, Set<String>> documentFields = {};

      // Nadir bulunan alanları tespit etmek için sayaç
      final Map<String, int> fieldCounts = {};

      // Her dökümanı kontrol et ve güncelle
      for (final DocumentSnapshot doc in snapshot.docs) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Bu belgenin alanlarını kaydet
        final Set<String> currentDocFields = data.keys.toSet();
        documentFields[doc.id] = currentDocFields;

        // Tüm alanları topla
        allFields.addAll(currentDocFields);

        // Alan sayaçlarını güncelle
        for (final field in currentDocFields) {
          fieldCounts[field] = (fieldCounts[field] ?? 0) + 1;
        }

        // creatorName ve creatorLastName alanlarını sil
        if (data.containsKey('creatorName') || data.containsKey('creatorLastName')) {
          final Map<String, dynamic> updateData = {
            'creatorName': FieldValue.delete(),
            'creatorLastName': FieldValue.delete(),
          };

          await _firestore.collection(collectionName).doc(doc.id).update(updateData);
          updatedDocuments++;
        }

        // İlerleme durumunu güncelle
        processedDocuments++;
        setState(() {
          _progress = processedDocuments / totalDocuments;
          _statusMessage = 'Analiz ve temizleme: $processedDocuments / $totalDocuments döküman';
        });
      }

      // Nadir bulunan alanları tespit et (toplam belgelerin %20'sinden azında bulunan)
      final double threshold = totalDocuments * 0.2;
      final List<String> rareFields =
          fieldCounts.entries.where((entry) => entry.value < threshold).map((entry) => '${entry.key} (${entry.value} belgede)').toList();

      // Tüm belgelerde ortak olan alanları bul
      final Set<String> commonFields = allFields.where((field) => fieldCounts[field] == totalDocuments).toSet();

      // Bazı belgelerde eksik olan alanları bul
      final Set<String> inconsistentFields = allFields.difference(commonFields);

      // Sonuçları göster
      final String analysisResult = '''
Analiz Sonuçları:
- Toplam belge sayısı: $totalDocuments
- Toplam alan sayısı: ${allFields.length}
- Tüm belgelerde ortak olan alanlar (${commonFields.length}): ${commonFields.join(', ')}
- Tutarsız alanlar (${inconsistentFields.length}): ${inconsistentFields.join(', ')}
- Nadir bulunan alanlar: ${rareFields.join(', ')}
- Temizlenen belge sayısı: $updatedDocuments
''';

      setState(() {
        _isLoading = false;
        _progress = 1.0;
        _statusMessage = analysisResult;
      });

      // Sonuçları konsola da yazdır (daha detaylı görüntülemek için)
      debugPrint(analysisResult);

      // Belge bazında alan farklılıklarını konsola yazdır
      documentFields.forEach((docId, fields) {
        final missingFields = allFields.difference(fields);
        if (missingFields.isNotEmpty) {
          debugPrint('Belge $docId\'de eksik alanlar: ${missingFields.join(', ')}');
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Analiz ve temizleme hatası: $e';
      });
    }
  }

  // Tüm dönüşümleri yapan fonksiyon güncellendi
  Future<void> _fixAll() async {
    final String collectionName = _sourceController.text.trim();

    if (collectionName.isEmpty) {
      setState(() {
        _statusMessage = 'Koleksiyon adını girmelisin kankam!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _progress = 0.0;
      _statusMessage = 'Tüm dönüşümler başlıyor...';
    });

    try {
      // Koleksiyondaki tüm dökümanları al
      final QuerySnapshot snapshot = await _firestore.collection(collectionName).get();
      final int totalDocuments = snapshot.docs.length;
      int processedDocuments = 0;
      int updatedDocuments = 0;

      // Kullanıcı önbelleği - Gender bilgisi için
      final Map<String, String> userGenderCache = {};

      // Her dökümanı kontrol et ve güncelle
      for (final DocumentSnapshot doc in snapshot.docs) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        bool updated = false;

        // Güncelleme işlemi için map oluştur
        final Map<String, dynamic> updateData = {};

        // 1. Tarih dönüşümü
        if (data['advertDate'] != null || data['advertTime'] != null) {
          final DateTime? newDate = parseDateTime(data['advertDate'], data['advertTime']);

          if (newDate != null) {
            updateData['startEventDate'] = Timestamp.fromDate(newDate);
            updateData['advertDate'] = FieldValue.delete();
            updateData['advertTime'] = FieldValue.delete();
            updateData['advertLastUsage'] = FieldValue.delete();
            updated = true;
          }
        }

        // 2. Kategori dönüşümü
        if (data['advertType'] != null) {
          final Categories? newCategory = parseCategoryType(data['advertType']);

          if (newCategory != null) {
            updateData['advertType'] = newCategory.name;
            updated = true;
          }
        }

        // 3. Konum dönüşümü
        if (data['city'] != null || data['district'] != null || data['geoPoint'] != null) {
          final locationModel = parseAdvertLocation(data);

          if (locationModel != null) {
            updateData['location'] = locationModel.toJson();
            updateData['city'] = FieldValue.delete();
            updateData['district'] = FieldValue.delete();
            updateData['geoPoint'] = FieldValue.delete();
            updated = true;
          }
        }

        // 4. Diğer eski alanları temizle
        if (data['advertContext'] != null) {
          updateData['description'] = data['advertContext'];
          updateData['advertContext'] = FieldValue.delete();
          updated = true;
        }

        // 5. advertName'i title olarak değiştir
        if (data['advertName'] != null) {
          updateData['title'] = data['advertName'];
          updateData['advertName'] = FieldValue.delete();
          updated = true;
        }

        if (data['count'] != null) {
          updateData['count'] = FieldValue.delete();
          updated = true;
        }

        if (data['phoneNumber'] != null) {
          updateData['phoneNumber'] = FieldValue.delete();
          updated = true;
        }

        // 6. creatorName ve creatorLastName alanlarını sil
        if (data['creatorName'] != null) {
          updateData['creatorName'] = FieldValue.delete();
          updated = true;
        }

        if (data['creatorLastName'] != null) {
          updateData['creatorLastName'] = FieldValue.delete();
          updated = true;
        }

        // 7. countUUIDs'i likers'a dönüştür
        if (data['countUUIDs'] != null && (data['likers'] == null || (data['likers'] as List).isEmpty)) {
          updateData['likers'] = data['countUUIDs'];
          updateData['countUUIDs'] = FieldValue.delete();
          updated = true;
        }

        // 8. creatorGender alanını güncelle
        if (data['creatorUserID'] != null && (data['creatorGender'] == null || data['creatorGender'].toString().isEmpty)) {
          final String creatorUserID = data['creatorUserID'] as String;
          String? gender;

          // Önbellekte bu kullanıcı var mı kontrol et
          if (userGenderCache.containsKey(creatorUserID)) {
            gender = userGenderCache[creatorUserID];
          } else {
            // Kullanıcı bilgilerini al
            final DocumentSnapshot userDoc = await _firestore.collection('customers').doc(creatorUserID).get();

            if (userDoc.exists) {
              final Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

              // Gender bilgisini al
              if (userData['gender'] != null) {
                // Gender değerini normalize et
                final String rawGender = userData['gender'].toString().toLowerCase();

                // Gender enum'a dönüştür
                if (rawGender == 'male' || rawGender == 'erkek' || rawGender == 'm') {
                  gender = 'male';
                } else if (rawGender == 'female' || rawGender == 'kadın' || rawGender == 'kadin' || rawGender == 'f') {
                  gender = 'female';
                } else {
                  gender = 'others';
                }

                // Önbelleğe ekle
                userGenderCache[creatorUserID] = gender;
              }
            }
          }

          // Gender bilgisi varsa, güncelleme verisine ekle
          if (gender != null) {
            updateData['creatorGender'] = gender;
            updated = true;
          }
        }

        // Eğer güncelleme yapılacaksa
        if (updated && updateData.isNotEmpty) {
          await _firestore.collection(collectionName).doc(doc.id).update(updateData);
          updatedDocuments++;
        }

        // İlerleme durumunu güncelle
        processedDocuments++;
        setState(() {
          _progress = processedDocuments / totalDocuments;
          _statusMessage = 'Dönüşüm yapılıyor: $processedDocuments / $totalDocuments döküman';
        });
      }

      setState(() {
        _isLoading = false;
        _progress = 1.0;
        _statusMessage = 'Tüm dönüşümler tamamlandı! $updatedDocuments döküman güncellendi.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Dönüşüm hatası: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Yedekleme 🔥'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _sourceController,
              decoration: const InputDecoration(
                labelText: 'Kaynak Koleksiyon',
                hintText: 'Örn: users',
                prefixIcon: Icon(Icons.folder_open),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _targetController,
              decoration: const InputDecoration(
                labelText: 'Hedef Koleksiyon',
                hintText: 'Örn: users_backup',
                prefixIcon: Icon(Icons.folder_copy),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _backupCollection,
              child: _isLoading && _statusMessage.contains('Yedekleme')
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Yedekle 💾'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Veri Dönüşüm İşlemleri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _fixDates,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Tarihleri Düzelt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _fixCategories,
                    icon: const Icon(Icons.category),
                    label: const Text('Kategorileri Düzelt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _fixLocations,
                    icon: const Icon(Icons.location_on),
                    label: const Text('Konumları Düzelt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _renameAdvertNameToTitle,
                    icon: const Icon(Icons.title),
                    label: const Text('advertName → title'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _updateCreatorGenders,
                    icon: const Icon(Icons.people),
                    label: const Text('Gender Güncelle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _cleanAndAnalyzeFields,
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('Analiz Et ve Temizle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _fixAll,
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('Tümünü Düzelt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading || _progress > 0) LinearProgressIndicator(value: _progress),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const Text(
              'Kankam için özel olarak hazırladım 🤜🤛',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
