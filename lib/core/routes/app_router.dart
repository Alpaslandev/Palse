import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/widgets/faq_page.dart';
import 'package:palseapp/core/widgets/landing_view.dart';
import 'package:palseapp/core/widgets/notification_view.dart';
import 'package:palseapp/core/widgets/see_likers.dart';
import 'package:palseapp/features/auth/views/login_view.dart';
import 'package:palseapp/features/categories/view/categories_view.dart';
import 'package:palseapp/features/chats/view/chats_view.dart';
import 'package:palseapp/features/create_advert/view/create_advert_view.dart';
import 'package:palseapp/features/comment/view/comment_view.dart';
import 'package:palseapp/features/friend_profile/friend_profile_view.dart';
import 'package:palseapp/features/home/view/home_view.dart';
import 'package:palseapp/features/home/widgets/filter_view.dart';
import 'package:palseapp/features/messages/view/messages_view.dart';
import 'package:palseapp/features/my_advert/view/my_advert_view.dart';
import 'package:palseapp/features/profile/view/profile_view.dart';
import 'package:palseapp/features/profile/widgets/xp_events_view.dart';
import 'package:palseapp/features/profile_setup_steps/view/profile_setup_view.dart';
import 'package:palseapp/features/settings/view/edit_profile.dart';
import 'package:palseapp/features/settings/view/settings_view.dart';
import 'package:palseapp/features/splash/splash_view.dart';
import 'package:palseapp/features/subscription/view/subscription_view.dart';

// Router sınıfını oluştur
class AppRouter {
  // NavigatorKey'i public yapalım
  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  // Tek bir AuthProvider instance'ı tutacağız
  static late final AuthProvider _authProvider;

  // Router instance'ı oluştur
  static late final GoRouter router;

  // Router'ı initialize et
  static void initialize(AuthProvider authProvider) {
    _authProvider = authProvider;

    router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: "/$splash",
      debugLogDiagnostics: true,
      refreshListenable: _authProvider,
      redirect: _handleRedirect,
      extraCodec: CustomGoRouterCodec(),
      routes: [
        GoRoute(
          path: "/$splash",
          name: splash,
          parentNavigatorKey: rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => const SplashView(),
        ),
        GoRoute(
          path: "/$login",
          name: login,
          parentNavigatorKey: rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => const LoginView(),
        ),
        GoRoute(
          path: "/$profileSetup",
          name: profileSetup,
          parentNavigatorKey: rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => const ProfileSetupView(),
        ),
        GoRoute(
          path: chats,
          name: 'chats',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => ChatsView(),
          routes: [
            GoRoute(
              path: ':chatId', // URL parametresi olarak chatId
              name: 'messages',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) {
                final chatId = state.pathParameters['chatId']!;
                final otherUserId = state.uri.queryParameters['otherId']!;

                return MessagesView(
                  chatId: chatId,
                  otherUserId: otherUserId,
                  currentUserId: _authProvider.user?.userID ?? '',
                );
              },
            ),
          ],
        ),
        GoRoute(
          name: 'subscription',
          path: subscription,
          parentNavigatorKey: rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => const SubscriptionView(),
        ),
        GoRoute(
          name: 'xpEvents',
          path: xpEvents,
          parentNavigatorKey: rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => const XpEventsView(),
        ),
        GoRoute(
          name: 'filter',
          path: filter,
          parentNavigatorKey: rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => const FilterView(),
        ),
        GoRoute(
          path: friendProfile,
          parentNavigatorKey: rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) {
            final customerID = state.extra! as String; // Null check eklendi
            return FriendProfileView(customerID: customerID);
          },
          routes: [
            GoRoute(
              path: '/comment',
              name: comment,
              builder: (context, state) {
                final customer = state.extra! as Customer; // Null check eklendi
                return CommentView(customer: customer);
              },
            ),
          ],
        ),
        GoRoute(
          path: notification,
          parentNavigatorKey: rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => const NotificationView(),
        ),
        GoRoute(
          path: createAdvert,
          parentNavigatorKey: rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => const CreateAdvertView(),
        ),
        GoRoute(
          path: settings,
          builder: (context, state) => const SettingsView(),
          routes: [
            GoRoute(
              path: editProfile,
              name: editProfile,
              builder: (context, state) {
                final user = state.extra! as Customer;
                return EditProfileView(user: user);
              },
            ),
            GoRoute(
              path: faq,
              name: faq,
              builder: (context, state) => const FAQPage(),
            ),
          ],
        ),
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) => LandingView(child: child),
          routes: [
            GoRoute(
              path: "/$home",
              name: home,
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
              routes: [
                GoRoute(
                  path: seeViewers,
                  name: seeViewers,
                  builder: (context, state) => SeeLikersView(viewers: state.extra as List<String>? ?? []),
                ),
              ],
            ),
            GoRoute(
              path: categories,
              name: 'categories',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const CategoriesView(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: CurveTween(curve: Curves.easeInOut).animate(animation), child: child);
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

    final isSplashScreen = state.matchedLocation == '/$splash';
    final isAuthRoute = state.matchedLocation.startsWith('/$login');
    final isUserSetupRoute = state.matchedLocation.startsWith('/$profileSetup');

    // Loading durumunda redirect yok
    if (_authProvider.isLoading) return null;

    final isAuthenticated = _authProvider.isAuthenticated;
    final isProfileSetup = _authProvider.isProfileSetupCompleted;

    // Splash screen özel durumu
    if (isSplashScreen) {
      if (!isAuthenticated) return '/$login';
      if (isAuthenticated && !isProfileSetup) return '/$profileSetup';
      return '/$home';
    }

    // 1. Kullanıcı giriş yapmamışsa
    if (!isAuthenticated) {
      // Eğer zaten auth route'daysa, orada kal
      if (isAuthRoute) return null;
      // Değilse login'e yönlendir
      return '/$login';
    }

    // 2. Kullanıcı giriş yapmış ama profil kurulumu tamamlanmamışsa
    if (isAuthenticated && !isProfileSetup) {
      // Eğer zaten profil kurulum sayfasındaysa, orada kal
      if (isUserSetupRoute) return null;
      // Değilse profil kurulum sayfasına yönlendir
      return '/$profileSetup';
    }

    // 3. Kullanıcı giriş yapmış ve profil kurulumu tamamlanmışsa
    if (isAuthenticated && isProfileSetup) {
      // Eğer auth route veya profil kurulum sayfasındaysa, ana sayfaya yönlendir
      if (isAuthRoute || isUserSetupRoute || isSplashScreen) return '/$home';
    }

    return null;
  }

  // Private constructor ile instance oluşturmayı engelle
  AppRouter._();
}

// Codec sınıfı düzeltildi
class CustomGoRouterCodec extends Codec<Object?, Object?> {
  @override
  Converter<Object?, Object?> get encoder => _CustomEncoder();

  @override
  Converter<Object?, Object?> get decoder => _CustomDecoder();
}

class _CustomEncoder extends Converter<Object?, Object?> {
  @override
  Object? convert(Object? input) {
    if (input is Customer) {
      return {
        'type': 'Customer',
        'data': {
          'userID': input.userID,
          'firstName': input.firstName,
          'lastName': input.lastName,
          'email': input.email,
          'profilePictureUrl': input.profilePictureUrl,
          // Diğer gerekli alanları ekleyin
        }
      };
    }
    return input;
  }
}

class _CustomDecoder extends Converter<Object?, Object?> {
  @override
  Object? convert(Object? input) {
    if (input is Map && input['type'] == 'Customer') {
      final data = input['data'] as Map<String, dynamic>;
      return Customer(
        userID: data['userID'],
        firstName: data['firstName'],
        lastName: data['lastName'],
        email: data['email'],
        profilePictureUrl: data['profilePictureUrl'],
        // Diğer alanları ekleyin
      );
    }
    return input;
  }
}
