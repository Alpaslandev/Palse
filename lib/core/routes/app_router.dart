import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/provider/ads_provider.dart';
import 'package:palseapp/core/widgets/faq_page.dart';
import 'package:palseapp/core/widgets/landing_view.dart';
import 'package:palseapp/core/widgets/notification_view.dart';
import 'package:palseapp/core/widgets/recently_viewer.dart';
import 'package:palseapp/core/widgets/see_likers.dart';
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
import 'package:palseapp/features/profile/widgets/xp_events_view.dart';
import 'package:palseapp/features/profile_setup_steps/view/profile_setup_view.dart';
import 'package:palseapp/features/settings/view/edit_profile.dart';
import 'package:palseapp/features/settings/view/language_settings_view.dart';
import 'package:palseapp/features/settings/view/settings_view.dart';
import 'package:palseapp/features/settings/view/widgets/verified_screen.dart';
import 'package:palseapp/features/splash/splash_view.dart';
import 'package:palseapp/features/subscription/view/paywall_screen.dart';

// Navigasyon gözlemcisi sınıfı
class _NavigationObserver extends NavigatorObserver {
  final AdsProvider adsProvider;
  final String splashPath;
  final String loginPath;
  final String profileSetupPath;

  // Reklam gösterilmeyecek sayfalar
  final List<String> _excludedRoutes = [
    splash,
    login,
    profileSetup,
    paywall, // Ödeme sayfasında reklam gösterme
    settings, // Ayarlar sayfasında reklam gösterme
    notification, // Bildirim sayfasında reklam gösterme
    messages, // Mesajlar sayfasında reklam gösterme
    chats, // Sohbetler sayfasında reklam gösterme
  ];

  // Her zaman reklam gösterilecek sayfalar (önemli içerik sayfaları)
  final List<String> _priorityRoutes = [
    friendProfile, // Arkadaş profili sayfasında her zaman reklam göster
    myAdverts, // İlanlarım sayfasında her zaman reklam göster
    categories, // Kategoriler sayfasında her zaman reklam göster
  ];

  _NavigationObserver(this.adsProvider, this.splashPath, this.loginPath, this.profileSetupPath);

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

      debugPrint('🔍 Rota adı: $routeName');

      // Chat ve mesaj sayfaları için özel kontrol
      if (_isChatOrMessageRoute(routeName)) {
        debugPrint('🚫 Reklam gösterilmedi: Chat veya mesaj sayfası');
        return;
      }

      // Derin URL yolları için kontrol (örn: "/chats/abc123?otherId=xyz")
      final bool isDeepUrl = routeName.contains('?') || (routeName.contains('/') && routeName.lastIndexOf('/') > 0);
      if (isDeepUrl) {
        debugPrint('🔍 Derin URL yolu tespit edildi: $routeName');

        // Derin URL yollarında reklam göstermeyi atla
        // Bu, chat gibi alt sayfalarda sorun yaşamamak için
        if (routeName.contains('/chats/') || routeName.contains('/messages/')) {
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

      // Öncelikli sayfalarda her zaman reklam göster
      if (_priorityRoutes.contains(pageName)) {
        debugPrint('🎯 Reklam gösteriliyor: "$pageName" öncelikli sayfa');
        _safeShowAd();
        return;
      }

      // Diğer sayfalarda normal reklam gösterme mantığı ile devam et
      debugPrint('🔄 Reklam gösterme denemesi: "$pageName" sayfası için normal reklam mantığı');
      _safeShowAd();
    } catch (e) {
      debugPrint('❌ Reklam gösterme hatası: $e');
    }
  }

  // Chat veya mesaj sayfası olup olmadığını kontrol eden yardımcı metod
  bool _isChatOrMessageRoute(String routeName) {
    // Tam eşleşme kontrolü
    if (routeName == "/$chats" || routeName == "/$messages") {
      return true;
    }

    // Alt sayfa kontrolü
    if (routeName.startsWith("/$chats/") || routeName.contains("/$messages/") || routeName.contains("?otherId=")) {
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

// Router sınıfını oluştur
class AppRouter {
  // NavigatorKey'i public yapalım
  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

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
      navigatorKey: rootNavigatorKey,
      initialLocation: "/$splash",
      debugLogDiagnostics: true,
      refreshListenable: _authProvider,
      redirect: _handleRedirect,
      extraCodec: CustomGoRouterCodec(),
      observers: [
        _NavigationObserver(_adsProvider, "/$splash", "/$login", "/$profileSetup"),
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
          path: "/$chats",
          name: chats,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => ChatsView(),
          routes: [
            GoRoute(
              path: ':chatId', // URL parametresi olarak chatId
              name: messages,
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
          name: xpEvents,
          path: "/$xpEvents",
          parentNavigatorKey: rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => const XpEventsView(),
        ),
        GoRoute(
          name: filter,
          path: "/$filter",
          parentNavigatorKey: rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => const FilterView(),
        ),
        GoRoute(
          path: "/$friendProfile",
          name: friendProfile,
          parentNavigatorKey: rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) {
            final customerID = state.extra! as String; // Null check eklendi
            return FriendProfileView(customerID: customerID);
          },
          routes: [
            GoRoute(
              path: '/$comment',
              name: comment,
              builder: (context, state) {
                final customer = state.extra! as Customer; // Null check eklendi
                return CommentView(customer: customer);
              },
            ),
          ],
        ),
        GoRoute(
          path: "/$notification",
          name: notification,
          parentNavigatorKey: rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => const NotificationView(),
        ),
        GoRoute(
          path: "/$createAdvert",
          name: createAdvert,
          parentNavigatorKey: rootNavigatorKey, // Ana navigator'ı kullan
          builder: (context, state) => const CreateAdvertView(),
        ),
        GoRoute(
          path: "/$settings",
          name: settings,
          builder: (context, state) => const SettingsView(),
          routes: [
            GoRoute(
              path: "/$editProfile",
              name: editProfile,
              builder: (context, state) {
                final user = state.extra! as Customer;
                return EditProfileView(user: user);
              },
            ),
            GoRoute(
              path: "/$faq",
              name: faq,
              builder: (context, state) => const FAQPage(),
            ),
            GoRoute(
              path: "/$languageSettings",
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
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // Alttan yukarı doğru kaydırma animasyonu
              const begin = Offset(0, 1); // Başlangıç pozisyonu (alt)
              const end = Offset.zero; // Bitiş pozisyonu (üst)
              const curve = Curves.easeInOut;

              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          ),
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
              path: "/$myAdverts",
              name: myAdverts,
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
                  path: "/$seeViewers",
                  name: seeViewers,
                  builder: (context, state) => SeeLikersView(viewers: state.extra as List<String>? ?? []),
                ),
                GoRoute(
                  path: "/$recentlyViewers",
                  name: recentlyViewers,
                  builder: (context, state) => RecentlyViewer(customer: state.extra as Customer, onProfileTap: () {}),
                ),
              ],
            ),
            GoRoute(
              path: "/$categories",
              name: categories,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const CategoriesView(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: CurveTween(curve: Curves.easeInOut).animate(animation), child: child);
                },
              ),
            ),
            GoRoute(
              path: "/$profile",
              name: profile,
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

            // XP ve Görev Test Sayfası
            GoRoute(
              path: "/$achievementTest",
              name: achievementTest,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const AchievementTestPage(),
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
    try {
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
      debugPrint('👤 Profil Kurulumu Tamamlanmış: ${_authProvider.isProfileSetupCompleted}');
      debugPrint('👤 Firestore Verileri Yüklenmiş: ${_authProvider.isFirestoreDataLoaded}');

      final isSplashScreen = state.matchedLocation == '/$splash';
      final isAuthRoute = state.matchedLocation.startsWith('/$login');
      final isUserSetupRoute = state.matchedLocation.startsWith('/$profileSetup');

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
          debugPrint('👤 Kullanıcı zaten profil kurulum sayfasında, yönlendirme yok');
          return null;
        }
        // Değilse profil kurulum sayfasına yönlendir
        debugPrint('👤 Kullanıcı giriş yapmış ama profil kurulumu tamamlanmamış -> Profile Setup yönlendirmesi');
        return '/$profileSetup';
      }

      // 3. Kullanıcı giriş yapmış ve profil kurulumu tamamlanmışsa
      if (isAuthenticated && isProfileSetup) {
        // Eğer auth route veya profil kurulum sayfasındaysa, ana sayfaya yönlendir
        if (isAuthRoute || isUserSetupRoute || isSplashScreen) {
          debugPrint('🏠 Kullanıcı giriş yapmış ve profil kurulumu tamamlanmış -> Home yönlendirmesi');
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
