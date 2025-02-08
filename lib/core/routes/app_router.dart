import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/provider/auth_provider.dart';

// Router sınıfını oluştur
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  // Tek bir AuthProvider instance'ı tutacağız
  static late final AuthProvider _authProvider;

  // Router instance'ı oluştur
  static late final GoRouter router;

  // Router'ı initialize et
  static void initialize(AuthProvider authProvider) {
    _authProvider = authProvider;

    router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: splash,
      debugLogDiagnostics: true,
      refreshListenable: _authProvider,
      redirect: _handleRedirect,
      routes: routes,
    );
  }

  static String? _handleRedirect(BuildContext context, GoRouterState state) {
    debugPrint('Redirect Check:');
    debugPrint('Current Location: ${state.matchedLocation}');
    debugPrint('Is Loading: ${_authProvider.isLoading}');
    debugPrint('Is Authenticated: ${_authProvider.isAuthenticated}');
    debugPrint('Is Profile Setup Completed: ${_authProvider.isProfileSetupCompleted}');

    // Loading durumunda redirect yok
    if (_authProvider.isLoading) {
      return null;
    }
    // Splash ekranı kontrolü
    if (state.matchedLocation == splash) {
      if (_authProvider.isAuthenticated) {
        return _authProvider.isProfileSetupCompleted ? navigationBar : profileSetup;
      }
      return login;
    }
    // Auth olmayan kullanıcı için
    if (!_authProvider.isAuthenticated) {
      // Sadece login ve splash'e izin ver
      return (state.matchedLocation == login || state.matchedLocation == splash) ? null : login;
    }

    // Auth olan kullanıcı için
    if (_authProvider.isAuthenticated) {
      // Profile setup tamamlanmamışsa
      if (!_authProvider.isProfileSetupCompleted) {
        return state.matchedLocation == profileSetup ? null : profileSetup;
      }

      // Profile setup tamamlanmışsa
      if (_authProvider.isProfileSetupCompleted) {
        // Login veya setup sayfalarında kalmasına izin verme
        if (state.matchedLocation == login || state.matchedLocation == profileSetup || state.matchedLocation == splash) {
          return navigationBar;
        }
      }
    }

    return null;
  }

  // Private constructor ile instance oluşturmayı engelle
  AppRouter._();
}
