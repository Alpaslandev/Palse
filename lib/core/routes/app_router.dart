import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/widgets/landing_view.dart';
import 'package:palseapp/core/widgets/notification_view.dart';
import 'package:palseapp/features/auth/views/login_view.dart';
import 'package:palseapp/features/chats/view/chats_view.dart';
import 'package:palseapp/features/create_advert/view/create_advert_view.dart';
import 'package:palseapp/features/home/view/home_view.dart';
import 'package:palseapp/features/messages/view/messages_view.dart';
import 'package:palseapp/features/my_advert/view/my_advert_view.dart';
import 'package:palseapp/features/profile/view/profile_view.dart';
import 'package:palseapp/features/profile_setup_steps/view/profile_setup_view.dart';
import 'package:palseapp/features/settings/view/settings_view.dart';
import 'package:palseapp/features/splash/splash_view.dart';

// Router sınıfını oluştur
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

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
      routes: [
        // Splash screen'i ekleyelim
        GoRoute(
          path: splash,
          parentNavigatorKey: _rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => const SplashView(),
        ),
        GoRoute(
          path: login,
          name: 'login',
          parentNavigatorKey: _rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => const LoginView(),
        ),
        GoRoute(
          path: profileSetup,
          name: 'profileSetup',
          parentNavigatorKey: _rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => const ProfileSetupView(),
        ),
        GoRoute(
          path: chats,
          name: 'chats',
          parentNavigatorKey: _rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => ChatsView(),
          routes: [
            GoRoute(
              path: 'messages',
              name: 'messages',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) {
                final params = state.extra as Map<String, dynamic>;
                return MessagesView(
                  chatId: params['chatId']!,
                  otherUserId: params['otherUserId']!,
                  currentUserId: _authProvider.user?.userID ?? '',
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: notification,
          name: 'notification',
          parentNavigatorKey: _rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => const NotificationView(),
        ),
        GoRoute(
          path: createAdvert,
          name: 'createAdvert',
          parentNavigatorKey: _rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => const CreateAdvertView(),
        ),
        GoRoute(
          path: settings,
          name: 'settings',
          parentNavigatorKey: _rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => const SettingsView(),
        ),
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) => LandingView(child: child),
          routes: [
            GoRoute(
              path: home,
              name: 'home',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const HomeView(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
                    child: child,
                  );
                },
              ),
            ),
            GoRoute(
              path: myAdverts,
              name: 'myAdverts',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const MyAdvertView(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
                    child: child,
                  );
                },
              ),
            ),
            GoRoute(
              path: profile,
              name: 'profile',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const ProfileView(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
                    child: child,
                  );
                },
              ),
            ),
          ],
        ),
      ],
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

    // Eğer zaten navigationBar'daysa ve koşullar doğruysa redirect yapma
    if (state.matchedLocation == landing && _authProvider.isAuthenticated && _authProvider.isProfileSetupCompleted) {
      return null;
    }

    // Auth olan kullanıcı için
    if (_authProvider.isAuthenticated) {
      // Profile setup tamamsa ve root veya restricted route'daysa
      if (_authProvider.isProfileSetupCompleted &&
          (state.matchedLocation == splash ||
              state.matchedLocation == login ||
              state.matchedLocation == profileSetup ||
              state.matchedLocation == '/')) {
        return home;
      }

      // Profile setup tamamlanmamışsa
      if (!_authProvider.isProfileSetupCompleted && state.matchedLocation != profileSetup) {
        return profileSetup;
      }

      return null;
    }

    // Auth olmayan kullanıcı için
    if (state.matchedLocation == splash || state.matchedLocation == '/') {
      return login;
    }

    return (state.matchedLocation == login) ? null : login;
  }

  // Private constructor ile instance oluşturmayı engelle
  AppRouter._();
}
