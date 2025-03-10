import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/routes/app_router.dart';

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
class ScaffoldMess extends StatelessWidget {
  const ScaffoldMess({super.key, required this.child});
  final Widget child;

  /// ScaffoldMessenger için global anahtar
  static final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: rootScaffoldMessengerKey,
      child: Scaffold(
        body: child,
      ),
    );
  }

  /// ScaffoldMessengerState'e erişim sağlar
  static ScaffoldMessengerState? get _messenger => rootScaffoldMessengerKey.currentState;

  /// BuildContext'i kontrol eder, eğer messengerKey kullanılamıyorsa context'i kullanır
  static void _showSnackBarWithState(SnackBar snackBar, [BuildContext? context]) {
    if (_messenger != null) {
      _messenger!.showSnackBar(snackBar);
    } else if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      throw Exception('ScaffoldMess: Snackbar göstermek için GlobalKey veya Context gerekli');
    }
  }

  /// Test amaçlı uygulama genelinde mesaj gösterir
  ///
  /// Bu metod, ScaffoldMess'in nasıl kullanılacağını göstermek için eklenmiştir.
  /// GlobalKey kullanarak context olmadan çalışır.
  static void showTestMessage() {
    if (_messenger != null) {
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
    Duration? duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    double? width,
    BuildContext? context,
  }) {
    final SnackBar snackBar = SnackBar(
      content: Text(message),
      duration: duration ?? const Duration(seconds: 4),
      behavior: behavior,
      width: width,
      action: actionLabel != null && onActionPressed != null
          ? SnackBarAction(
              label: actionLabel,
              onPressed: onActionPressed,
            )
          : null,
    );

    _showSnackBarWithState(snackBar, context);
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
    Duration? duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    double? width,
    BuildContext? context,
  }) {
    final SnackBar snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: duration ?? const Duration(seconds: 4),
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

    _showSnackBarWithState(snackBar, context);
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
    Duration? duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    double? width,
    BuildContext? context,
  }) {
    final SnackBar snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      duration: duration ?? const Duration(seconds: 5),
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

    _showSnackBarWithState(snackBar, context);
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
    Duration? duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    double? width,
    BuildContext? context,
  }) {
    final SnackBar snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.orange,
      duration: duration ?? const Duration(seconds: 4),
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

    _showSnackBarWithState(snackBar, context);
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
    Duration? duration,
    String? actionLabel,
    Color? actionTextColor,
    VoidCallback? onActionPressed,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    double? width,
    BuildContext? context,
  }) {
    final SnackBar snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(color: textColor),
      ),
      backgroundColor: backgroundColor,
      duration: duration ?? const Duration(seconds: 4),
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

    _showSnackBarWithState(snackBar, context);
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
    Duration? duration,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    double? width,
    BuildContext? context,
    bool shouldReplaceCurrentScreen = false,
  }) {
    final SnackBar snackBar = SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      duration: duration ?? const Duration(seconds: 4),
      behavior: behavior,
      width: width,
      action: SnackBarAction(
        label: actionLabel,
        textColor: Colors.white,
        onPressed: () {
          // Önceki Snackbar'ı kapat
          if (_messenger != null) {
            _messenger!.hideCurrentSnackBar();
          } else if (context != null) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }

          // Yeni sayfaya yönlendir
          try {
            if (AppRouter.rootNavigatorKey.currentState != null) {
              final BuildContext navContext = AppRouter.rootNavigatorKey.currentState!.context;

              if (shouldReplaceCurrentScreen) {
                // Sayfayı değiştir (stack'i temizle)
                GoRouter.of(navContext).goNamed(route, extra: arguments);
              } else {
                // Yeni sayfa ekle (stack'e ekler)
                GoRouter.of(navContext).pushNamed(route, extra: arguments);
              }
            } else if (context != null) {
              if (shouldReplaceCurrentScreen) {
                context.goNamed(route, extra: arguments);
              } else {
                context.pushNamed(route, extra: arguments);
              }
            } else {
              debugPrint('ScaffoldMess: Navigasyon yapılamadı. Navigator key veya context gerekli.');
            }
          } catch (e) {
            debugPrint('ScaffoldMess: Navigasyon hatası: $e');
          }
        },
      ),
    );

    _showSnackBarWithState(snackBar, context);
  }

  /// Navigasyon işlemi gerçekleştiren bir Snackbar gösterir
  ///
  /// [message] - Gösterilecek mesaj
  /// [actionLabel] - Aksiyon butonu etiketi
  /// [route] - Yönlendirilecek sayfa rotası (route name)
  /// [arguments] - Rota parametreleri
  /// [backgroundColor] - Opsiyonel arkaplan rengi
  /// [context] - Opsiyonel build context (GlobalKey çalışmazsa kullanılır)
  static void showNavigationSnackBar(
    String message,
    String actionLabel,
    String route, {
    Object? arguments,
    Color backgroundColor = Colors.blue,
    Duration? duration,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    double? width,
    BuildContext? context,
  }) {
    final SnackBar snackBar = SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      duration: duration ?? const Duration(seconds: 4),
      behavior: behavior,
      width: width,
      action: SnackBarAction(
        label: actionLabel,
        textColor: Colors.white,
        onPressed: () {
          // Önceki Snackbar'ı kapat
          if (_messenger != null) {
            _messenger!.hideCurrentSnackBar();
          } else if (context != null) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }

          // Yeni sayfaya yönlendir - GoRouter'ın rootNavigatorKey'i üzerinden
          // Bu, context'e bağımlı olmadan çalışır
          try {
            if (AppRouter.rootNavigatorKey.currentState != null) {
              final BuildContext navContext = AppRouter.rootNavigatorKey.currentState!.context;
              GoRouter.of(navContext).pushNamed(route, extra: arguments);
            } else if (context != null) {
              context.pushNamed(route, extra: arguments);
            } else {
              debugPrint('ScaffoldMess: Navigasyon yapılamadı. Navigator key veya context gerekli.');
            }
          } catch (e) {
            debugPrint('ScaffoldMess: Navigasyon hatası: $e');
          }
        },
      ),
    );

    _showSnackBarWithState(snackBar, context);
  }

  /// Mevcut Snackbar'ı kapatır
  ///
  /// [context] - Opsiyonel build context (GlobalKey çalışmazsa kullanılır)
  static void hideSnackBar({BuildContext? context}) {
    if (_messenger != null) {
      _messenger!.hideCurrentSnackBar();
    } else if (context != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } else {
      throw Exception('ScaffoldMess: Snackbar kapatmak için GlobalKey veya Context gerekli');
    }
  }

  /// Tüm Snackbar'ları kapatır
  ///
  /// [context] - Opsiyonel build context (GlobalKey çalışmazsa kullanılır)
  static void clearSnackBars({BuildContext? context}) {
    if (_messenger != null) {
      _messenger!.clearSnackBars();
    } else if (context != null) {
      ScaffoldMessenger.of(context).clearSnackBars();
    } else {
      throw Exception('ScaffoldMess: Snackbar\'ları temizlemek için GlobalKey veya Context gerekli');
    }
  }
}
