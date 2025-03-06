import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/lang/en.dart';
import 'package:palseapp/core/localization/lang/tr.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // Desteklenen diller
  static const List<Locale> supportedLocales = [
    Locale('tr', 'TR'),
    Locale('en', 'US'),
  ];

  // Dil dosyaları
  static const Map<String, Map<String, String>> _localizedValues = {
    'tr': tr,
    'en': en,
  };

  // Geçerli dil için çeviri değerlerini al
  Map<String, String> get _values {
    return _localizedValues[locale.languageCode] ?? tr; // Varsayılan olarak Türkçe
  }

  // Belirli bir anahtar için çeviri değerini döndür
  String translate(String key) {
    return _values[key] ?? key; // Anahtar bulunamazsa anahtarın kendisini döndür
  }

  // Geçerli dil için çeviri değerlerini al (statik yardımcı metod)
  static Map<String, String> getValues(Locale locale) {
    return _localizedValues[locale.languageCode] ?? tr; // Varsayılan olarak Türkçe
  }

  // Belirli bir anahtar için çeviri değerini döndür (statik yardımcı metod)
  static String translateKey(String key, Locale locale) {
    final values = getValues(locale);
    return values[key] ?? key; // Anahtar bulunamazsa anahtarın kendisini döndür
  }

  // Localization delegesi
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // BuildContext üzerinden erişim için yardımcı metod
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
}

// Localization delegesi
class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['tr', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// Kolay erişim için extension
extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String tr(String key) => l10n.translate(key);
}
