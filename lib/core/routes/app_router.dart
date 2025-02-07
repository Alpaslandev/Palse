import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:palseapp/features/auth/views/login_view.dart';
import 'package:palseapp/features/home/view/home_view.dart';
import 'package:palseapp/features/profile/view/profile_view.dart';
import 'package:palseapp/core/provider/auth_provider.dart';

// Route isimleri için sabitler
class AppRoutes {
  static const String home = '/home';
  static const String login = '/login';
  static const String profile = '/profile';

  // Route'ları private constructor ile gizle
  AppRoutes._();
}

// Router yapılandırması
final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  redirect: (BuildContext context, GoRouterState state) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Auth gerektiren sayfalar için kontrol
    final isAuthRoute = state.matchedLocation.startsWith('/home') || state.matchedLocation.startsWith('/profile');

    // Kullanıcı giriş yapmamışsa ve auth gerektiren bir sayfaya erişmeye çalışıyorsa
    if (isAuthRoute && !authProvider.isAuthenticated) {
      return AppRoutes.login;
    }

    // Kullanıcı giriş yapmışsa ve login sayfasına erişmeye çalışıyorsa
    if (state.matchedLocation == AppRoutes.login && authProvider.isAuthenticated) {
      return AppRoutes.home;
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginView(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeView(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfileView(),
    ),
  ],
);
