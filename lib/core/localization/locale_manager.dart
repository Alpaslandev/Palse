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

  /// Geçerli locale'yi döndürür. Eğer henüz ayarlanmamışsa varsayılan olarak Türkçe döner.
  static Locale get currentLocale {
    return _currentLocale ?? const Locale('tr', 'TR'); // Varsayılan olarak Türkçe
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
