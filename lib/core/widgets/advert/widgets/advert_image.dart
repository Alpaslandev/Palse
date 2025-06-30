import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

// İlan görselini gösteren widget
class AdvertImage extends StatelessWidget {
  const AdvertImage({
    super.key,
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    // Debug için URL'yi logla
    //  debugPrint('🖼️ AdvertImage yükleniyor: $imageUrl');

    if (!imageUrl.contains('assets/images/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
          // Memory cache boyutunu sınırla - büyük görseller için
          memCacheHeight: 500,
          memCacheWidth: 500,
          // Cache manager ile daha iyi kontrol
          cacheManager: CacheManager(
            Config(
              'customCacheKey',
              stalePeriod: const Duration(days: 7),
              maxNrOfCacheObjects: 100,
            ),
          ),
          placeholder: (context, url) {
            //  debugPrint('🔄 CachedNetworkImage placeholder: $url');
            return Container(
              width: double.infinity,
              height: 250,
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
          errorWidget: (context, url, error) {
            // Hata durumunda detaylı log
            // debugPrint('❌ CachedNetworkImage HATA!');
            //  debugPrint('   URL: $url');
            //  debugPrint('   Hata: $error');
            //  debugPrint('   Hata Tipi: ${error.runtimeType}');

            // Decompress hatası ise direkt hata ikonu göster
            if (error.toString().contains('Could not decompress image')) {
              //  debugPrint('🚫 Decompress hatası - Image.network denenmeyecek');
              return Container(
                width: double.infinity,
                height: 250,
                color: Colors.grey[300],
                child: Icon(
                  Icons.image_not_supported,
                  size: 50,
                  color: Colors.grey[600],
                ),
              );
            }

            //  debugPrint('🔄 Image.network ile tekrar deneniyor...');

            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    //    debugPrint('✅ Image.network başarılı: $imageUrl');
                    return child;
                  }
                  //  debugPrint(
                  //      '🔄 Image.network yükleniyor: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
                  return Container(
                    width: double.infinity,
                    height: 250,
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  //  debugPrint('💥 Image.network da BAŞARISIZ!');
                  //  debugPrint('   URL: $imageUrl');
                  //  debugPrint('   Hata: $error');
                  //  debugPrint('   Stack: $stackTrace');
                  return Container(
                    width: double.infinity,
                    height: 250,
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
    }

    //   debugPrint('🖼️ Asset image yükleniyor: $imageUrl');
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        imageUrl,
        width: double.infinity,
        height: 250,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          //  debugPrint('❌ Asset image hatası: $imageUrl - $error');
          return Container(
            width: double.infinity,
            height: 250,
            color: Colors.grey[300],
            child: Icon(
              Icons.image_not_supported,
              size: 50,
              color: Colors.grey[600],
            ),
          );
        },
      ),
    );
  }
}
