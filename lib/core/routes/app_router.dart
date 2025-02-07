import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:palseapp/features/auth/views/login_view.dart';
import 'package:palseapp/features/home/view/home_view.dart';
import 'package:palseapp/features/profile/view/profile_view.dart';
import 'package:palseapp/core/provider/auth_provider.dart';

// Router sınıfını oluştur
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  // Route isimleri için sabitler
  static const String home = '/home';
  static const String login = '/login';
  static const String profile = '/profile';

  // Router instance'ı oluştur
  static GoRouter get router => _router;

  // Private constructor ile instance oluşturmayı engelle
  AppRouter._();

  // Router yapılandırması
  static final _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: home,
    debugLogDiagnostics: true,
    refreshListenable: _getAuthProvider(),
    redirect: _handleRedirect,
    routes: _routes,
  );

  // Auth provider'a erişim için yardımcı metod
  static ChangeNotifier _getAuthProvider() {
    if (_rootNavigatorKey.currentContext != null) {
      return Provider.of<AuthProvider>(
        _rootNavigatorKey.currentContext!,
        listen: false,
      );
    }
    return AuthProvider();
  }

  // Yönlendirme mantığı
  static String? _handleRedirect(BuildContext context, GoRouterState state) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    debugPrint('Current Location: ${state.matchedLocation}');
    debugPrint('Is Authenticated: ${authProvider.isAuthenticated}');
    debugPrint('Is Loading: ${authProvider.isLoading}');

    // Loading durumunda bekle
    if (authProvider.isLoading) return null;

    // Auth gerektiren route'ları kontrol et
    final isAuthRoute = authProvider.isAuthenticated || authProvider.isLoading == false;

    // Auth kontrolü
    if (isAuthRoute && state.matchedLocation != login) {
      return login;
    }

    // Giriş yapılmışsa login sayfasından yönlendir
    if (state.matchedLocation == login && authProvider.isAuthenticated) {
      return home;
    }

    return null;
  }

  // Route tanımlamaları
  static final List<RouteBase> _routes = [
    GoRoute(
      path: login,
      name: 'login',
      builder: (context, state) => const LoadingWrapper(
        child: LoginView(),
      ),
    ),
    GoRoute(
      path: home,
      name: 'home',
      builder: (context, state) => const LoadingWrapper(
        child: HomeView(),
      ),
    ),
    GoRoute(
      path: profile,
      name: 'profile',
      builder: (context, state) => const LoadingWrapper(
        child: ProfileView(),
      ),
    ),
  ];
}

// Loading durumu için wrapper widget
class LoadingWrapper extends StatelessWidget {
  final Widget child;

  const LoadingWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return child;
      },
    );
  }
}
