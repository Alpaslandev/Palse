// Navigasyon gözlemcisi sınıfı
import 'package:flutter/material.dart';
import 'package:palseapp/core/provider/ads_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:provider/provider.dart';
import 'package:palseapp/core/provider/auth_provider.dart';

class NavigationObserver extends NavigatorObserver {
  final AdsProvider adsProvider;

  // Reklam gösterilmeyecek sayfalar
  final List<String> _excludedRoutes = [
    splash,
    login,
    profileSetup,
    paywall, // Ödeme sayfasında reklam gösterme
    messages, // Mesajlar sayfasında reklam gösterme
  ];

  NavigationObserver(this.adsProvider);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    try {
      debugPrint('🔍 NAVIGASYON: didPush - ${_getRouteInfo(route)}');
      if (previousRoute != null) {
        debugPrint('🔍 NAVIGASYON: önceki sayfa - ${_getRouteInfo(previousRoute)}');
      }
      _maybeShowAd(route, previousRoute);
    } catch (e) {
      debugPrint('❌ NAVIGASYON HATASI (didPush): $e');
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    try {
      debugPrint('🔍 NAVIGASYON: didPop - ${_getRouteInfo(route)}');
      if (previousRoute != null) {
        debugPrint('🔍 NAVIGASYON: geri dönülen sayfa - ${_getRouteInfo(previousRoute)}');
        // Geri dönüşlerde reklam göstermeyi devre dışı bırakıyoruz
        // Eğer geri dönüşlerde de reklam göstermek isterseniz, aşağıdaki satırı aktif edebilirsiniz
        // _maybeShowAd(previousRoute, route);
      }
    } catch (e) {
      debugPrint('❌ NAVIGASYON HATASI (didPop): $e');
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    try {
      debugPrint('🔍 NAVIGASYON: didRemove - ${_getRouteInfo(route)}');
      if (previousRoute != null) {
        debugPrint('🔍 NAVIGASYON: aktif sayfa - ${_getRouteInfo(previousRoute)}');
      }
    } catch (e) {
      debugPrint('❌ NAVIGASYON HATASI (didRemove): $e');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    try {
      if (newRoute != null) {
        debugPrint('🔍 NAVIGASYON: didReplace - ${_getRouteInfo(newRoute)}');
        if (oldRoute != null) {
          debugPrint('🔍 NAVIGASYON: eski sayfa - ${_getRouteInfo(oldRoute)}');
        }
        _maybeShowAd(newRoute, oldRoute);
      }
    } catch (e) {
      debugPrint('❌ NAVIGASYON HATASI (didReplace): $e');
    }
  }

  // Rota bilgilerini string olarak döndüren yardımcı metod
  String _getRouteInfo(Route<dynamic> route) {
    final name = route.settings.name ?? 'isimsiz';
    final arguments = route.settings.arguments != null ? '(argümanlar var)' : '(argüman yok)';
    return '$name $arguments';
  }

  // Reklam gösterme mantığı
  void _maybeShowAd(Route<dynamic> route, Route<dynamic>? previousRoute) {
    try {
      // Rota adını al (eğer varsa)
      final String? routeName = route.settings.name;
      if (routeName == null) {
        debugPrint('🚫 Reklam gösterilmedi: Rota adı bulunamadı');
        return;
      }

      // Önce kullanıcı premium mi kontrol et
      final context = navigator?.context;
      if (context != null) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.user;

        // Premium kullanıcılara reklam gösterme
        if (user != null && user.isPremium == true) {
          debugPrint('🚫 Reklam gösterilmedi: Kullanıcı premium üye');
          return;
        }

        // Kullanıcı giriş yapmamışsa reklam gösterme
        if (user == null) {
          debugPrint('🚫 Reklam gösterilmedi: Kullanıcı giriş yapmamış');
          return;
        }
      }

      debugPrint('🔍 Rota adı: $routeName');

      // mesaj sayfası için özel kontrol
      if (_isMessageRoute(routeName)) {
        debugPrint('🚫 Reklam gösterilmedi: mesaj sayfası');
        return;
      }

      // Derin URL yolları için kontrol (örn: "/chats/abc123?otherId=xyz")
      final bool isDeepUrl = routeName.contains('?') || (routeName.contains('/') && routeName.lastIndexOf('/') > 0);
      if (isDeepUrl) {
        debugPrint('🔍 Derin URL yolu tespit edildi: $routeName');

        // Derin URL yollarında reklam göstermeyi atla
        // Bu, chat gibi alt sayfalarda sorun yaşamamak için
        if (routeName.contains('/messages/')) {
          debugPrint('🚫 Reklam gösterilmedi: Derin chat/mesaj URL yolu');
          return;
        }
      }

      // Rota adından sayfa adını çıkar (örn: "/home" -> "home")
      final String pageName = _extractPageName(routeName);
      debugPrint('🔍 Sayfa adı: $pageName');

      // Hariç tutulan sayfalarda reklam gösterme
      if (_excludedRoutes.contains(pageName)) {
        debugPrint('🚫 Reklam gösterilmedi: "$pageName" sayfası hariç tutulan sayfalar listesinde');
        return;
      }

      // Önceki sayfadan aynı sayfaya geçişlerde reklam gösterme
      if (previousRoute != null && previousRoute.settings.name != null) {
        final previousPageName = _extractPageName(previousRoute.settings.name!);
        debugPrint('🔍 Önceki sayfa adı: $previousPageName');

        if (previousPageName == pageName) {
          debugPrint('🚫 Reklam gösterilmedi: Aynı sayfaya geçiş yapıldı ($pageName)');
          return;
        }

        // Chat sayfasından mesaj sayfasına geçişlerde reklam gösterme
        if (_isChatRelatedTransition(previousPageName, pageName)) {
          debugPrint('🚫 Reklam gösterilmedi: Chat ile ilgili geçiş ($previousPageName -> $pageName)');
          return;
        }
      }

      // Diğer sayfalarda normal reklam gösterme mantığı ile devam et
      debugPrint('🔄 Reklam gösterme denemesi: "$pageName" sayfası için normal reklam mantığı');
      _safeShowAd();
    } catch (e) {
      debugPrint('❌ Reklam gösterme hatası: $e');
    }
  }

  // Chat veya mesaj sayfası olup olmadığını kontrol eden yardımcı metod
  bool _isMessageRoute(String routeName) {
    // Tam eşleşme kontrolü
    if (routeName == "/$messages") {
      return true;
    }

    // Alt sayfa kontrolü
    if (routeName.startsWith("/$messages/") || routeName.contains("?otherId=")) {
      return true;
    }

    return false;
  }

  // Chat ile ilgili geçiş olup olmadığını kontrol eden yardımcı metod
  bool _isChatRelatedTransition(String previousPage, String currentPage) {
    // Chat sayfasından mesaj sayfasına veya tersi
    if ((previousPage == chats && currentPage == messages) || (previousPage == messages && currentPage == chats)) {
      return true;
    }

    return false;
  }

  // Güvenli reklam gösterme metodu
  void _safeShowAd() {
    try {
      final result = adsProvider.showInterstitialAd();
      result.then((shown) {
        if (shown) {
          debugPrint('✅ Reklam gösterildi');
        } else {
          debugPrint('❌ Reklam gösterilemedi: Muhtemelen zaman aralığı dolmadı veya reklam hazır değil');
        }
      }).catchError((error) {
        debugPrint('❌ Reklam gösterme hatası: $error');
      });
    } catch (e) {
      debugPrint('❌ Reklam gösterme hatası: $e');
    }
  }

  // URL'den sayfa adını çıkaran yardımcı metod
  String _extractPageName(String routeName) {
    try {
      // Başındaki "/" karakterini kaldır
      if (routeName.startsWith('/')) {
        routeName = routeName.substring(1);
      }

      // Parametreleri kaldır (örn: "messages/123?otherId=456" -> "messages")
      int paramIndex = routeName.indexOf('/');
      if (paramIndex > 0) {
        routeName = routeName.substring(0, paramIndex);
      }

      // Query parametrelerini kaldır (örn: "messages?otherId=456" -> "messages")
      paramIndex = routeName.indexOf('?');
      if (paramIndex > 0) {
        routeName = routeName.substring(0, paramIndex);
      }

      return routeName;
    } catch (e) {
      debugPrint('❌ Sayfa adı çıkarma hatası: $e, orijinal rota: $routeName');
      // Hata durumunda orijinal rotayı döndür
      return routeName;
    }
  }
}
