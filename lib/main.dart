import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:palseapp/core/keys/global_keys.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/localization/locale_manager.dart';
import 'package:palseapp/core/provider/ads_provider.dart';
import 'package:palseapp/core/provider/locale_provider.dart';
import 'package:palseapp/core/provider/theme_provider.dart';
import 'package:palseapp/core/routes/app_router.dart';
import 'package:palseapp/core/services/update_service.dart';
import 'package:palseapp/features/achievement/achievement_service.dart';
import 'package:palseapp/core/services/notification_service.dart';
import 'package:palseapp/core/services/shared_pref_service.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:palseapp/core/provider/subscription_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint('Firebase already initialized');
    } else {
      rethrow;
    }
  }

  await MobileAds.instance.initialize();

  await Purchases.setLogLevel(LogLevel.error);
  // RevenueCat ayarlarını platform bazlı ayarlama
  if (Platform.isIOS) {
    await Purchases.configure(
        PurchasesConfiguration('appl_nqgFBnNbiUeCvilAmLqKsvbZNal'));
  } else if (Platform.isAndroid) {
    await Purchases.configure(
        PurchasesConfiguration('goog_PEygpHUWqHBCeYbZdjULShUAQfz'));
    debugPrint('RevenueCat gecikmeli başlatıldı');
  }
  await Future.delayed(const Duration(milliseconds: 200));

  // Kritik işlemleri önce başlat
  final authProvider = AuthProvider();
  await authProvider.initializeAuth();

  final adsProvider = AdsProvider();
  AppRouter.initialize(authProvider, adsProvider);

  // Sonra NotificationService'i başlat
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Diğer provider'ları hazırla
  final localeProvider = LocaleProvider();
  await localeProvider.initialize();
  LocaleManager.setLocale(localeProvider.locale);

  await initializeDateFormatting(localeProvider.locale.toString(), null);
  Intl.defaultLocale = localeProvider.locale.toString();
  debugPrint('Intl.defaultLocale: ${Intl.defaultLocale}');

  final subscriptionProvider = SubscriptionProvider();
  final themeProvider = ThemeProvider();
  await SharedPrefService.init();

  await AchievementService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: subscriptionProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: adsProvider),
        Provider(create: (_) => AchievementService()),
        Provider(create: (_) => NotificationService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    debugPrint('Locale: ${localeProvider.locale.languageCode}');

    // Locale değiştiğinde LocaleManager'ı güncelle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocaleManager.setLocale(localeProvider.locale);
    });

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Palse',
      theme: AppTheme.theme, // Aydınlık tema
      darkTheme: AppTheme.darkTheme, // Koyu tema
      themeMode: themeProvider.themeMode, // Tema modunu provider'dan al
      routerConfig: AppRouter.router,
      scaffoldMessengerKey: GlobalKeys.instance
          .scaffoldMessengerKey, // Burada router'ın navigatorKey'ini kullanıyoruz
      locale: localeProvider.locale, // Dil ayarını provider'dan al
      localizationsDelegates: const [
        AppLocalizations.delegate, // Kendi localization delegemiz
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        return UpdateWrapper(child: child!);
      },
    );
  }
}

class UpdateWrapper extends StatefulWidget {
  final Widget child;
  const UpdateWrapper({super.key, required this.child});

  @override
  State<UpdateWrapper> createState() => _UpdateWrapperState();
}

class _UpdateWrapperState extends State<UpdateWrapper> {
  final UpdateService _updateService = UpdateService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateService.checkForUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
