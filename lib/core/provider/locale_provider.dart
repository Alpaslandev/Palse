import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('tr', 'TR'); // Varsayılan olarak Türkçe
  static const String _localeKey = 'locale';

  Locale get locale => _locale;

  // Provider'ı başlat ve kaydedilmiş dil ayarını yükle
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_localeKey);

    if (savedLocale != null) {
      final parts = savedLocale.split('_');
      if (parts.length == 2) {
        _locale = Locale(parts[0], parts[1]);
      }
    }

    notifyListeners();
  }

  // Dili değiştir
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;

    // Dil ayarını kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, '${locale.languageCode}_${locale.countryCode}');

    notifyListeners();
  }

  // Türkçe'ye geç
  Future<void> setTurkish() async {
    await setLocale(const Locale('tr', 'TR'));
  }

  // İngilizce'ye geç
  Future<void> setEnglish() async {
    await setLocale(const Locale('en', 'US'));
  }

  // Dili değiştir (dil kodu ile)
  Future<void> toggleLocale() async {
    if (_locale.languageCode == 'tr') {
      await setEnglish();
    } else {
      await setTurkish();
    }
  }
}
