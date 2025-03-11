import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore koleksiyonlarını yedeklemek için singleton servis
/// Kankam için özel olarak hazırladım 😎
class FirestoreBackupService {
  // Singleton instance
  static final FirestoreBackupService _instance = FirestoreBackupService._internal();

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Factory constructor
  factory FirestoreBackupService() {
    return _instance;
  }

  // Private constructor
  FirestoreBackupService._internal();

  /// Bir koleksiyonu yedekler
  /// [sourceCollection]: Yedeklenecek koleksiyon adı
  /// [targetCollection]: Hedef koleksiyon adı
  /// [onProgress]: İlerleme durumunu bildiren callback (opsiyonel)
  /// [onComplete]: İşlem tamamlandığında çağrılacak callback (opsiyonel)
  /// [onError]: Hata durumunda çağrılacak callback (opsiyonel)
  Future<void> backupCollection({
    required String sourceCollection,
    required String targetCollection,
    Function(int processed, int total)? onProgress,
    Function(int total)? onComplete,
    Function(String error)? onError,
  }) async {
    try {
      // Kaynak koleksiyondan tüm dökümanları al
      final QuerySnapshot sourceSnapshot = await _firestore.collection(sourceCollection).get();
      final int totalDocuments = sourceSnapshot.docs.length;
      int processedDocuments = 0;

      // Her dökümanı hedef koleksiyona kopyala
      for (final DocumentSnapshot doc in sourceSnapshot.docs) {
        // Döküman verilerini al
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Hedef koleksiyona aynı ID ile kopyala
        await _firestore.collection(targetCollection).doc(doc.id).set(data);

        // İlerleme durumunu bildir
        processedDocuments++;
        if (onProgress != null) {
          onProgress(processedDocuments, totalDocuments);
        }
      }

      // İşlem tamamlandı
      if (onComplete != null) {
        onComplete(totalDocuments);
      }
    } catch (e) {
      // Hata durumunu bildir
      if (onError != null) {
        onError(e.toString());
      }
      rethrow;
    }
  }

  /// Belirli bir dökümanı yedekler
  /// [sourceCollection]: Kaynak koleksiyon adı
  /// [documentId]: Yedeklenecek döküman ID'si
  /// [targetCollection]: Hedef koleksiyon adı
  Future<void> backupDocument({
    required String sourceCollection,
    required String documentId,
    required String targetCollection,
  }) async {
    try {
      // Dökümanı al
      final DocumentSnapshot doc = await _firestore.collection(sourceCollection).doc(documentId).get();

      if (doc.exists) {
        // Döküman verilerini al
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Hedef koleksiyona aynı ID ile kopyala
        await _firestore.collection(targetCollection).doc(documentId).set(data);
      }
    } catch (e) {
      print('Döküman yedekleme hatası: $e');
      rethrow;
    }
  }
}

// Kullanım kolaylığı için global erişim noktası
final firestoreBackup = FirestoreBackupService();
