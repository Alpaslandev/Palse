import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/keys/global_keys.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/routes/navigation_observer.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/provider/ads_provider.dart';
import 'package:palseapp/core/widgets/faq_page.dart';
import 'package:palseapp/core/widgets/landing_view.dart';
import 'package:palseapp/core/widgets/notification_view.dart';
import 'package:palseapp/core/widgets/advert/widgets/user_list_view.dart';
import 'package:palseapp/features/achievement/achievement_test_page.dart';
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
import 'package:palseapp/features/profile/view/widgets/xp_events_view.dart';
import 'package:palseapp/features/profile_setup_steps/view/profile_setup_view.dart';
import 'package:palseapp/features/settings/view/edit_profile.dart';
import 'package:palseapp/features/settings/view/language_settings_view.dart';
import 'package:palseapp/features/settings/view/settings_view.dart';
import 'package:palseapp/features/settings/view/widgets/verified_screen.dart';
import 'package:palseapp/features/splash/splash_view.dart';
import 'package:palseapp/features/story/model/story_model.dart';
import 'package:palseapp/features/story/view/add_story_view.dart';
import 'package:palseapp/features/story/view/story_display_view.dart';
import 'package:palseapp/features/story/viewmodel/story_view_model.dart';
import 'package:palseapp/features/subscription/view/paywall_screen.dart';
import 'package:provider/provider.dart';

// Router sınıfını oluştur
class AppRouter {
  // NavigatorKey'i public yapalım
  static final _rootNavigatorKey = GlobalKeys.instance.navigatorKey;
  // Tek bir AuthProvider instance'ı tutacağız
  static late final AuthProvider _authProvider;
  static late final AdsProvider _adsProvider;
  // Router instance'ı oluştur
  static late final GoRouter router;

  // Router'ı initialize et
  static void initialize(AuthProvider authProvider, AdsProvider adsProvider) {
    _authProvider = authProvider;
    _adsProvider = adsProvider;

    router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: "/$splash",
      debugLogDiagnostics: false,
      refreshListenable: _authProvider,
      redirect: _handleRedirect,
      extraCodec: CustomGoRouterCodec(),
      observers: [
        NavigationObserver(_adsProvider),
      ],
      errorBuilder: (context, state) {
        debugPrint('❌ ROUTER HATASI: ${state.error}');
        debugPrint('❌ ROUTER HATASI URI: ${state.uri}');

        Future.delayed(const Duration(milliseconds: 100), () {
          if (context.mounted) {
            GoRouter.of(context).go('/$home');
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Sayfa Bulunamadı'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Sayfa bulunamadı',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('İstenen sayfa: ${state.uri.path}'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => GoRouter.of(context).go('/$home'),
                  child: const Text('Ana Sayfaya Dön'),
                ),
              ],
            ),
          ),
        );
      },
      routes: [
        GoRoute(
          path: "/$splash",
          name: splash,
          parentNavigatorKey: _rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => const SplashView(),
        ),
        GoRoute(
          path: "/$login",
          name: login,
          parentNavigatorKey: _rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => const LoginView(),
        ),
        GoRoute(
          path: "/$profileSetup",
          name: profileSetup,
          parentNavigatorKey: _rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => const ProfileSetupView(),
        ),
        GoRoute(
          path: "/$storyDisplay",
          name: storyDisplay,
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final Map<String, dynamic> data =
                state.extra as Map<String, dynamic>;

            // JSON'dan StoryModel'lere çevir
            final List<dynamic> storiesJson = data['stories'] as List<dynamic>;
            final List<StoryModel> stories = storiesJson
                .map((json) =>
                    StoryModel.fromRouterJson(json as Map<String, dynamic>))
                .toList();

            return ChangeNotifierProvider(
              create: (_) => StoryViewModel(),
              child: StoryDisplayView(
                stories: stories,
                initialIndex: data['initialIndex'],
                isCurrentUserStory: data['isCurrentUserStory'] ?? false,
              ),
            );
          },
        ),
        GoRoute(
          path: "/$chats",
          name: chats,
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => ChatsView(),
          routes: [
            GoRoute(
              path: ':chatId', // URL parametresi olarak chatId
              name: messages,
              parentNavigatorKey: _rootNavigatorKey,
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
          path: "/$addStory",
          name: addStory,
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const AddStoryView(),
        ),
        GoRoute(
          name: xpEvents,
          path: "/$xpEvents",
          parentNavigatorKey: _rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => const XpEventsView(),
        ),
        GoRoute(
          name: filter,
          path: "/$filter",
          parentNavigatorKey: _rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => const FilterView(),
        ),
        GoRoute(
          path: "/$friendProfile",
          name: friendProfile,
          parentNavigatorKey: _rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) {
            final customerID = state.extra! as String; // Null check eklendi
            return FriendProfileView(customerID: customerID);
          },
        ),
        GoRoute(
          path: "/$comment",
          name: comment,
          parentNavigatorKey: _rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) {
            // Extra parametresi opsiyonel hale getirildi
            Customer customer;
            if (state.extra != null) {
              customer = state.extra! as Customer;
            } else {
              // Extra yoksa mevcut kullanıcıyı kullan
              customer = _authProvider.user!;
            }
            return CommentView(customer: customer);
          },
        ),
        GoRoute(
          path: "/$notification",
          name: notification,
          parentNavigatorKey: _rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => const NotificationView(),
        ),
        GoRoute(
          path: "/$createAdvert",
          name: createAdvert,
          parentNavigatorKey: _rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => const CreateAdvertView(),
        ),
        GoRoute(
          path: "/$settings",
          name: settings,
          builder: (context, state) => const SettingsView(),
          routes: [
            GoRoute(
              path: "editProfile", // relative path
              name: editProfile,
              builder: (context, state) {
                final user = state.extra! as Customer;
                return EditProfileView(user: user);
              },
            ),
            GoRoute(
              path: "faq", // relative path
              name: faq,
              builder: (context, state) => const FAQPage(),
            ),
            GoRoute(
              path: "languageSettings", // relative path
              name: languageSettings,
              builder: (context, state) => const LanguageSettingsView(),
            ),
          ],
        ),
        GoRoute(
          path: "/$verified",
          name: verified,
          builder: (context, state) => const VerifiedScreen(),
        ),
        GoRoute(
          path: "/$paywall",
          name: paywall,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const PaywallScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(0, 1);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          ),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return LandingView(navigationShell: navigationShell);
          },
          branches: [
            // Branch 1: Home
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: "/$home",
                  name: home,
                  pageBuilder: (context, state) => NoTransitionPage(
                    child: HomeView(key: GlobalKeys.instance.homeViewKey),
                  ),
                ),
                GoRoute(
                  path: "/$byInterest",
                  name: byInterest,
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: HomeView(initialTabIndex: 1),
                  ),
                ),
              ],
            ),
            // Branch 2: Categories
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: "/$categories",
                  name: categories,
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: CategoriesView(),
                  ),
                ),
              ],
            ),
            // Branch 3: My Adverts
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: "/$myAdverts",
                  name: myAdverts,
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: MyAdvertView(),
                  ),
                  routes: [
                    GoRoute(
                      path: "userList", // relative path
                      name: userList,
                      builder: (context, state) {
                        final extra = state.extra as Map<String, dynamic>;
                        return UserListView(
                          users: extra['users'] as List<String>,
                          isLikers: extra['isLikers'] as bool,
                          advertId: extra['advertId'] as String?,
                        );
                      },
                    ),
                  ],
                ),
                GoRoute(
                  path: "/$recentlyViewers",
                  name: recentlyViewers,
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: MyAdvertView(initialTabIndex: 2),
                  ),
                ),
              ],
            ),
            // Branch 4: Profile
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: "/$profile",
                  name: profile,
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: ProfileView(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static String? _handleRedirect(BuildContext context, GoRouterState state) {
    try {
      /*
      debugPrint('🔄 YÖNLENDİRME KONTROLÜ:');
      debugPrint('📍 Mevcut Konum: ${state.matchedLocation}');
      debugPrint('📍 URI: ${state.uri}');
      debugPrint('📍 Tam URI: ${state.uri.toString()}');
      debugPrint('📍 Path Parametreleri: ${state.pathParameters}');
      debugPrint('📍 Query Parametreleri: ${state.uri.queryParameters}');
      debugPrint('📍 Extra: ${state.extra != null ? 'Var' : 'Yok'}');

      debugPrint('👤 Kullanıcı Durumu:');
      debugPrint('👤 Yükleniyor: ${_authProvider.isLoading}');
      debugPrint('👤 Giriş Yapılmış: ${_authProvider.isAuthenticated}');
      debugPrint('👤 Firebase User: ${_authProvider.firebaseUser?.email}');
      debugPrint('👤 User: ${_authProvider.user?.userID}');
      debugPrint(
          '👤 Profil Kurulumu Tamamlanmış: ${_authProvider.isProfileSetupCompleted}');
      debugPrint(
          '👤 Firestore Verileri Yüklenmiş: ${_authProvider.isFirestoreDataLoaded}');
      */
      final isSplashScreen = state.matchedLocation == '/$splash';
      final isAuthRoute = state.matchedLocation.startsWith('/$login');
      final isUserSetupRoute =
          state.matchedLocation.startsWith('/$profileSetup');

      // Loading durumunda redirect yok - Firestore verilerinin yüklenmesini bekle
      if (_authProvider.isLoading) {
        debugPrint('⏳ Hala yükleniyor, yönlendirme yapılmıyor');
        return null;
      }

      final isAuthenticated = _authProvider.isAuthenticated;
      final isProfileSetup = _authProvider.isProfileSetupCompleted;

      // Splash screen özel durumu
      if (isSplashScreen) {
        if (!isAuthenticated) {
          debugPrint('🔀 Splash -> Login yönlendirmesi');
          return '/$login';
        }
        if (isAuthenticated && !isProfileSetup) {
          debugPrint('🔀 Splash -> Profile Setup yönlendirmesi');
          return '/$profileSetup';
        }
        debugPrint('🔀 Splash -> Home yönlendirmesi');
        return '/$home';
      }

      // 1. Kullanıcı giriş yapmamışsa
      if (!isAuthenticated) {
        // Eğer zaten auth route'daysa, orada kal
        if (isAuthRoute) {
          debugPrint('🔒 Kullanıcı zaten login sayfasında, yönlendirme yok');
          return null;
        }
        // Değilse login'e yönlendir
        debugPrint('🔒 Kullanıcı giriş yapmamış -> Login yönlendirmesi');
        return '/$login';
      }

      // 2. Kullanıcı giriş yapmış ama profil kurulumu tamamlanmamışsa
      if (isAuthenticated && !isProfileSetup) {
        // Eğer zaten profil kurulum sayfasındaysa, orada kal
        if (isUserSetupRoute) {
          debugPrint(
              '👤 Kullanıcı zaten profil kurulum sayfasında, yönlendirme yok');
          return null;
        }
        // Değilse profil kurulum sayfasına yönlendir
        debugPrint(
            '👤 Kullanıcı giriş yapmış ama profil kurulumu tamamlanmamış -> Profile Setup yönlendirmesi');
        return '/$profileSetup';
      }

      // 3. Kullanıcı giriş yapmış ve profil kurulumu tamamlanmışsa
      if (isAuthenticated && isProfileSetup) {
        // Eğer auth route veya profil kurulum veya splash screen sayfasındaysa, ana sayfaya yönlendir
        if (isAuthRoute || isUserSetupRoute || isSplashScreen) {
          debugPrint(
              '🏠 Kullanıcı giriş yapmış ve profil kurulumu tamamlanmış -> Home yönlendirmesi');
          return '/$home';
        }
      }

      debugPrint('✅ Yönlendirme yok, normal navigasyona devam ediliyor');
      return null;
    } catch (e) {
      debugPrint('❌ YÖNLENDİRME HATASI: $e');
      // Hata durumunda yönlendirme yapma
      return null;
    }
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
