import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
}
