import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';

/// Uygulama genelinde locale yönetimi için kullanılan sınıf.
/// Context gerektirmeden çeviri işlemleri yapabilmek için kullanılır.
class LocaleManager {
  static Locale? _currentLocale;

  /// Geçerli locale'yi ayarlar. Uygulama başlangıcında veya dil değişikliğinde çağrılmalıdır.
  static void setLocale(Locale locale) {
    _currentLocale = locale;
  }

  /// Geçerli locale'yi döndürür. Eğer henüz ayarlanmamışsa varsayılan olarak cihaz dilini veya İngilizce döner.
  static Locale get currentLocale {
    if (_currentLocale != null) {
      return _currentLocale!;
    }

    // Cihaz dilini al
    final deviceLocale = WidgetsBinding.instance.window.locale;

    // Desteklenen diller listesi (LocaleProvider ile senkronize tutulmalı)
    const supportedLocales = [
      Locale('tr', 'TR'),
      Locale('en', 'US'),
    ];

    // Cihaz dili destekleniyorsa onu kullan
    if (supportedLocales.any((locale) => locale.languageCode == deviceLocale.languageCode)) {
      return deviceLocale;
    }

    // Desteklenmiyorsa İngilizce kullan
    return const Locale('en', 'US');
  }

  /// Verilen anahtar için çeviriyi döndürür.
  static String translate(String key) {
    return AppLocalizations.translateKey(key, currentLocale);
  }

  /// Verilen anahtar için çeviriyi döndürür ve parametre değiştirmelerini uygular.
  /// Örnek: translateWithParams('notification_body', {'name': 'Ahmet', 'count': '5'})
  static String translateWithParams(String key, Map<String, String> params) {
    String text = translate(key);
    params.forEach((key, value) {
      text = text.replaceAll('{$key}', value);
    });
    return text;
  }
}
