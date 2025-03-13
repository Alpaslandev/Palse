import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/localization/locale_manager.dart';
import 'package:palseapp/core/provider/ads_provider.dart';
import 'package:palseapp/core/provider/locale_provider.dart';
import 'package:palseapp/core/provider/theme_provider.dart';
import 'package:palseapp/core/routes/app_router.dart';
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
import 'package:palseapp/core/widgets/scaffold_mess.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i güvenli şekilde başlat
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      // Zaten başlatılmış, görmezden gel
      debugPrint('Firebase already initialized');
    } else {
      // Başka bir hata varsa fırlat
      rethrow;
    }
  }

  MobileAds.instance.initialize();

  // RevenueCat'i başlat
  if (Platform.isIOS) {
    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration('appl_nqgFBnNbiUeCvilAmLqKsvbZNal'));
  } else if (Platform.isAndroid) {
    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration('goog_PEygpHUWqHBCeYbZdjULShUAQfz'));
  }

  final authProvider = AuthProvider();
  await authProvider.initializeAuth();

  final notificationService = NotificationService();
  await notificationService.initialize();

  AppRouter.initialize(authProvider);

  // Locale provider'ı başlat
  final localeProvider = LocaleProvider();
  await localeProvider.initialize();

  // Cihazın diline uygun tarih formatlamasını başlat
  final locale = localeProvider.locale;
  debugPrint('Locale: $locale');

  // LocaleManager'ı ayarla
  LocaleManager.setLocale(locale);

  await initializeDateFormatting(locale.toString(), null);
  Intl.defaultLocale = locale.toString();
  debugPrint('Intl.defaultLocale: ${Intl.defaultLocale}');

  final subscriptionProvider = SubscriptionProvider();
  final themeProvider = ThemeProvider();
  final adsProvider = AdsProvider();
  await SharedPrefService.init();

  // Achievement servisini başlat (günlük görevleri kontrol et)
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
      ],
      child: MyApp(notificationService: notificationService),
    ),
  );
}

class MyApp extends StatelessWidget {
  final NotificationService notificationService;

  const MyApp({super.key, required this.notificationService});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    // Locale değiştiğinde LocaleManager'ı güncelle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocaleManager.setLocale(localeProvider.locale);
    });

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Palse App',
      theme: AppTheme.theme, // Aydınlık tema
      darkTheme: AppTheme.darkTheme, // Koyu tema
      themeMode: themeProvider.themeMode, // Tema modunu provider'dan al
      routerConfig: AppRouter.router,
      scaffoldMessengerKey: ScaffoldMess.rootScaffoldMessengerKey, // ScaffoldMess için GlobalKey kullan
      locale: localeProvider.locale, // Dil ayarını provider'dan al
      localizationsDelegates: const [
        AppLocalizations.delegate, // Kendi localization delegemiz
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notificationService.setContext(context);
        });
        return child!;
      },
    );
  }
}
