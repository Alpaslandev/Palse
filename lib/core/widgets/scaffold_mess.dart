import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/routes/app_router.dart';
import 'package:palseapp/core/keys/global_keys.dart';

/// ScaffoldMess, uygulama genelinde kullanılabilecek mesaj gösterimi için
/// tasarlanmış özel bir widget.
///
/// Bu sınıf, global bir ScaffoldMessengerKey kullanarak context bağımlılığını
/// ortadan kaldırır ve uygulama genelinde daha kolay kullanım sağlar.
///
/// Örnek kullanım:
/// ```dart
/// // Context olmadan kullanım (global key ile)
/// ScaffoldMess.showSnackBar('Merhaba Dünya!');
///
/// // Context ile kullanım (güvenlik için)
/// ScaffoldMess.showSnackBar('Merhaba Dünya!', context: context);
///
/// // Navigasyon ile kullanım (context gerekli değil, route name kullanılır)
/// ScaffoldMess.showNavigationSnackBar(
///   'Profiliniz güncellendi',
///   'Görüntüle',
///   'profile',
/// );
/// ```
class ScaffoldMess {
  /// Yardımcı metod - Scaffold Messenger'a güvenli erişim
  static ScaffoldMessengerState? _getMessengerStateWithLog({bool showWarnings = true}) {
    final messenger = GlobalKeys.instance.scaffoldMessengerKey.currentState;
    if (messenger == null && showWarnings) {
      debugPrint('❌ UYARI: ScaffoldMessengerKey henüz hazır değil!');
      debugPrint('❌ Bu sadece MaterialApp oluşturulduktan sonra kullanılabilir.');
    }
    return messenger;
  }

  /// Mesaj bildirimi için MaterialBanner gösterir (üstte)
  ///
  /// [title] - Bildirimin başlığı
  /// [message] - Gösterilecek mesaj
  /// [onViewPressed] - Görüntüle düğmesine basıldığında çalışacak fonksiyon
  /// [duration] - Banner'ın ekranda kalma süresi
  /// [backgroundColor] - Arkaplan rengi
  /// [context] - Opsiyonel build context (GlobalKey çalışmazsa kullanılır)
  static void showMessageBanner({
    required String title,
    required String message,
    required VoidCallback onViewPressed,
    Duration duration = const Duration(seconds: 5),
    Color backgroundColor = Colors.blue,
  }) {
    try {
      debugPrint('🔔 showMessageBanner çağrıldı | ${DateTime.now()}');
      debugPrint('🔔 Başlık: $title');
      debugPrint('🔔 Mesaj: $message');

      final messenger = _getMessengerStateWithLog();
      if (messenger == null) {
        debugPrint('❌ HATA: ScaffoldMessengerKey henüz hazır değil!');
        debugPrint('❌ MaterialApp oluşturulduktan sonra çağrılmalı');
        return; // Exception fırlatmak yerine sadece log atıp çıkalım
      }

      debugPrint('🔔 ScaffoldMessengerKey hazır, banner hazırlanıyor...');

      final MaterialBanner materialBanner = MaterialBanner(
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.all(16),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        leading: const CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(Icons.message, color: Colors.blue),
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('🔔 Banner "Görüntüle" butonuna tıklandı');
              _hideCurrentMaterialBanner();
              onViewPressed();
            },
            child: const Text('Görüntüle', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              debugPrint('🔔 Banner "Kapat" butonuna tıklandı');
              _hideCurrentMaterialBanner();
            },
            child: const Text('Kapat', style: TextStyle(color: Colors.white)),
          ),
        ],
      );

      // Önce tüm bannerları temizle
      try {
        messenger.clearMaterialBanners();
        debugPrint('🔔 Önceki banner\'lar temizlendi');
      } catch (e) {
        debugPrint('❌ Banner temizleme hatası: $e');
      }

      try {
        messenger.showMaterialBanner(materialBanner);
        debugPrint('🔔 Banner başarıyla gösterildi!');
      } catch (e) {
        debugPrint('❌ Banner gösterme hatası: $e');
      }

      // Otomatik kapanma süresi
      if (duration != Duration.zero) {
        Future.delayed(duration, () {
          debugPrint('🔔 Otomatik kapanma süresi doldu, banner kapatılıyor...');
          _hideCurrentMaterialBanner();
        });
      }
    } catch (e) {
      debugPrint('❌ showMessageBanner genel hata: $e');
    }
  }

  /// MaterialBanner gösterir
  static void _showMaterialBannerWithState(MaterialBanner banner, [BuildContext? context]) {
    debugPrint('📬 _showMaterialBannerWithState çağrıldı');

    if (_getMessengerStateWithLog() != null) {
      try {
        _getMessengerStateWithLog()!.showMaterialBanner(banner);
        debugPrint('📬 Banner global key ile gösterildi');
      } catch (e) {
        debugPrint('📬 Banner global key ile gösterilemedi: $e');
        // Fallback olarak context'i deneyelim
        if (context != null) {
          try {
            ScaffoldMessenger.of(context).showMaterialBanner(banner);
            debugPrint('📬 Banner context ile gösterildi');
          } catch (e) {
            debugPrint('📬 Banner context ile de gösterilemedi: $e');
          }
        }
      }
    } else if (context != null) {
      try {
        ScaffoldMessenger.of(context).showMaterialBanner(banner);
        debugPrint('📬 Banner context ile gösterildi (key null idi)');
      } catch (e) {
        debugPrint('📬 Banner context ile gösterilemedi: $e');
      }
    } else {
      debugPrint('📬 Banner gösterilemedi: Key ve context her ikisi de null');
      throw Exception('ScaffoldMess: MaterialBanner göstermek için GlobalKey veya Context gerekli');
    }
  }

  /// Mevcut MaterialBanner'ı gizler
  static void _hideCurrentMaterialBanner() {
    try {
      final messenger = _getMessengerStateWithLog();
      if (messenger != null) {
        messenger.hideCurrentMaterialBanner();
      }
    } catch (e) {
      debugPrint('MaterialBanner gizleme hatası: $e');
    }
  }

  /// Tüm MaterialBanner'ları temizler
  static void clearMaterialBanners() {
    try {
      final messenger = _getMessengerStateWithLog();
      if (messenger != null) {
        messenger.clearMaterialBanners();
      }
    } catch (e) {
      debugPrint('MaterialBanner temizleme hatası: $e');
    }
  }

  /// Test amaçlı uygulama genelinde mesaj gösterir
  ///
  /// Bu metod, ScaffoldMess'in nasıl kullanılacağını göstermek için eklenmiştir.
  /// GlobalKey kullanarak context olmadan çalışır.
  static void showTestMessage() {
    if (_getMessengerStateWithLog() != null) {
      showSnackBar('Global Key ile çalışıyor! 🎉');
    } else {
      debugPrint('ScaffoldMess: GlobalKey henüz hazır değil. Context kullanın.');
    }
  }

  /// Basit bir Snackbar gösterir
  ///
  /// [message] - Gösterilecek mesaj
  /// [duration] - Snackbar'ın ekranda kalma süresi
  /// [actionLabel] - Aksiyon butonu etiketi
  /// [onActionPressed] - Aksiyon butonuna basıldığında çalışacak fonksiyon
  /// [context] - Opsiyonel build context (GlobalKey çalışmazsa kullanılır)
  static void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onActionPressed,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    double? width,
  }) {
    try {
      final SnackBar snackBar = SnackBar(
        content: Text(message),
        duration: duration,
        behavior: behavior,
        width: width,
        action: actionLabel != null && onActionPressed != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onActionPressed,
              )
            : null,
      );

      _getMessengerStateWithLog()!.showSnackBar(snackBar);
    } catch (e) {
      debugPrint('SnackBar gösterme hatası: $e');
    }
  }

  /// Hata mesajı içeren Snackbar gösterir
  ///
  /// [message] - Gösterilecek hata mesajı
  /// [duration] - Snackbar'ın ekranda kalma süresi
  /// [actionLabel] - Aksiyon butonu etiketi
  /// [onActionPressed] - Aksiyon butonuna basıldığında çalışacak fonksiyon
  /// [context] - Opsiyonel build context (GlobalKey çalışmazsa kullanılır)
  static void showErrorSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onActionPressed,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    double? width,
  }) {
    try {
      final SnackBar snackBar = SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: duration,
        behavior: behavior,
        width: width,
        action: actionLabel != null && onActionPressed != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onActionPressed,
              )
            : null,
      );

      _getMessengerStateWithLog()!.showSnackBar(snackBar);
    } catch (e) {
      debugPrint('Hata SnackBar gösterme hatası: $e');
    }
  }

  /// Başarı mesajı içeren Snackbar gösterir
  ///
  /// [message] - Gösterilecek başarı mesajı
  /// [duration] - Snackbar'ın ekranda kalma süresi
  /// [actionLabel] - Aksiyon butonu etiketi
  /// [onActionPressed] - Aksiyon butonuna basıldığında çalışacak fonksiyon
  /// [context] - Opsiyonel build context (GlobalKey çalışmazsa kullanılır)
  static void showSuccessSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 5),
    String? actionLabel,
    VoidCallback? onActionPressed,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    double? width,
  }) {
    try {
      final SnackBar snackBar = SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: duration,
        behavior: behavior,
        width: width,
        action: actionLabel != null && onActionPressed != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onActionPressed,
              )
            : null,
      );

      _getMessengerStateWithLog()!.showSnackBar(snackBar);
    } catch (e) {
      debugPrint('Başarı SnackBar gösterme hatası: $e');
    }
  }

  static void showSuccessTaskSnackBar(
    String message, {
    String? eventName,
    Duration duration = const Duration(seconds: 5),
    String? actionLabel,
    VoidCallback? onActionPressed,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    double? width,
  }) {
    try {
      final SnackBar snackBar = SnackBar(
        content: eventName != null ? Text(eventName) : Text(message),
        backgroundColor: Colors.green,
        duration: duration,
        behavior: behavior,
        width: width,
        action: actionLabel != null && onActionPressed != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onActionPressed,
              )
            : null,
      );

      _getMessengerStateWithLog()!.showSnackBar(snackBar);
    } catch (e) {
      debugPrint('Görev SnackBar gösterme hatası: $e');
    }
  }

  /// Uyarı mesajı içeren Snackbar gösterir
  ///
  /// [message] - Gösterilecek uyarı mesajı
  /// [duration] - Snackbar'ın ekranda kalma süresi
  /// [actionLabel] - Aksiyon butonu etiketi
  /// [onActionPressed] - Aksiyon butonuna basıldığında çalışacak fonksiyon
  /// [context] - Opsiyonel build context (GlobalKey çalışmazsa kullanılır)
  static void showWarningSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onActionPressed,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    double? width,
  }) {
    try {
      final SnackBar snackBar = SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: duration,
        behavior: behavior,
        width: width,
        action: actionLabel != null && onActionPressed != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onActionPressed,
              )
            : null,
      );

      _getMessengerStateWithLog()!.showSnackBar(snackBar);
    } catch (e) {
      debugPrint('Uyarı SnackBar gösterme hatası: $e');
    }
  }

  /// Özelleştirilmiş bir Snackbar gösterir
  ///
  /// [message] - Gösterilecek mesaj
  /// [backgroundColor] - Arkaplan rengi
  /// [textColor] - Metin rengi
  /// [duration] - Snackbar'ın ekranda kalma süresi
  /// [actionLabel] - Aksiyon butonu etiketi
  /// [onActionPressed] - Aksiyon butonuna basıldığında çalışacak fonksiyon
  /// [context] - Opsiyonel build context (GlobalKey çalışmazsa kullanılır)
  static void showCustomSnackBar(
    String message, {
    Color backgroundColor = Colors.black,
    Color textColor = Colors.white,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    Color? actionTextColor,
    VoidCallback? onActionPressed,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    double? width,
  }) {
    try {
      final SnackBar snackBar = SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: behavior,
        width: width,
        action: actionLabel != null && onActionPressed != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: actionTextColor ?? textColor,
                onPressed: onActionPressed,
              )
            : null,
      );

      _getMessengerStateWithLog()!.showSnackBar(snackBar);
    } catch (e) {
      debugPrint('Özel SnackBar gösterme hatası: $e');
    }
  }

  /// Go router kullanarak navigasyon yapar (önceki sayfayı tamamen değiştirir)
  ///
  /// [message] - Gösterilecek mesaj
  /// [actionLabel] - Aksiyon butonu etiketi
  /// [route] - Yönlendirilecek sayfa rotası (route name)
  /// [arguments] - Rota parametreleri
  /// [backgroundColor] - Opsiyonel arkaplan rengi
  /// [context] - Opsiyonel build context (GlobalKey çalışmazsa kullanılır)
  /// [shouldReplaceCurrentScreen] - Geçerli ekranı değiştirip değiştirmeyeceği (varsayılan: false)
  static void showGotoSnackBar(
    String message,
    String actionLabel,
    String route, {
    Object? arguments,
    Color backgroundColor = Colors.blue,
    Duration duration = const Duration(seconds: 4),
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    double? width,
    bool shouldReplaceCurrentScreen = false,
  }) {
    try {
      final SnackBar snackBar = SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: behavior,
        width: width,
        action: SnackBarAction(
          label: actionLabel,
          textColor: Colors.white,
          onPressed: () {
            // Önceki Snackbar'ı kapat
            _hideCurrentMaterialBanner();

            // Yeni sayfaya yönlendir
            try {
              final navContext = GlobalKeys.instance.navigatorKey.currentState!.context;

              if (shouldReplaceCurrentScreen) {
                // Sayfayı değiştir (stack'i temizle)
                GoRouter.of(navContext).goNamed(route, extra: arguments);
              } else {
                // Yeni sayfa ekle (stack'e ekler)
                GoRouter.of(navContext).pushNamed(route, extra: arguments);
              }
            } catch (e) {
              debugPrint('Navigasyon hatası: $e');
            }
          },
        ),
      );

      _getMessengerStateWithLog()!.showSnackBar(snackBar);
    } catch (e) {
      debugPrint('Goto SnackBar gösterme hatası: $e');
    }
  }

  /// Navigasyon işlemi gerçekleştiren bir Snackbar gösterir
  ///
  /// [message] - Gösterilecek mesaj
  /// [actionLabel] - Aksiyon butonu etiketi
  /// [route] - Yönlendirilecek sayfa rotası (route name)
  /// [arguments] - Rota parametreleri
  /// [backgroundColor] - Opsiyonel arkaplan rengi
  /// [duration] - Snackbar'ın ekranda kalma süresi
  static void showNavigationSnackBar(
    String message,
    String actionLabel,
    String route, {
    Object? arguments,
    Color backgroundColor = Colors.blue,
    Duration duration = const Duration(seconds: 4),
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    double? width,
  }) {
    try {
      final SnackBar snackBar = SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: behavior,
        width: width,
        action: SnackBarAction(
          label: actionLabel,
          textColor: Colors.white,
          onPressed: () {
            // Önceki Snackbar'ı kapat
            _hideCurrentMaterialBanner();

            // Yeni sayfaya yönlendir
            try {
              final navigatorKey = GlobalKeys.instance.navigatorKey;
              if (navigatorKey.currentState != null) {
                final context = navigatorKey.currentState!.context;
                GoRouter.of(context).pushNamed(route, extra: arguments);
              }
            } catch (e) {
              debugPrint('Navigasyon hatası: $e');
            }
          },
        ),
      );

      _getMessengerStateWithLog()!.showSnackBar(snackBar);
    } catch (e) {
      debugPrint('Navigasyon SnackBar gösterme hatası: $e');
    }
  }

  /// Mevcut Snackbar'ı kapatır
  ///
  /// [context] - Opsiyonel build context (GlobalKey çalışmazsa kullanılır)
  static void hideSnackBar() {
    try {
      final messenger = _getMessengerStateWithLog();
      if (messenger != null) {
        messenger.hideCurrentSnackBar();
      }
    } catch (e) {
      debugPrint('SnackBar kapatma hatası: $e');
    }
  }

  /// Tüm Snackbar'ları kapatır
  ///
  /// [context] - Opsiyonel build context (GlobalKey çalışmazsa kullanılır)
  static void clearSnackBars() {
    try {
      final messenger = _getMessengerStateWithLog();
      if (messenger != null) {
        messenger.clearSnackBars();
      }
    } catch (e) {
      debugPrint('SnackBar temizleme hatası: $e');
    }
  }

  /// Test amaçlı uygulama genelinde mesaj gösterir
  static void testMessages() {
    try {
      debugPrint('🧪 TEST: ScaffoldMess.testMessages çağrıldı');

      // Önce SnackBar test et
      showSnackBar('Test SnackBar: ScaffoldMess test ediliyor');

      // 2 saniye sonra başarı mesajı göster
      Future.delayed(const Duration(seconds: 2), () {
        showSuccessSnackBar('Test başarılı!');
      });

      // 4 saniye sonra banner göster
      Future.delayed(const Duration(seconds: 4), () {
        showMessageBanner(
          title: 'Test Banner',
          message: 'Bu bir test banner mesajıdır.',
          onViewPressed: () {
            showSnackBar('Banner tıklandı!');
          },
        );
      });

      debugPrint('🧪 TEST: ScaffoldMess test mesajları planlandı');
    } catch (e) {
      debugPrint('🧪 TEST HATASI: $e');
    }
  }
}
