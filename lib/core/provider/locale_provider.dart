import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  // Varsayılan olarak cihaz dili, desteklenmiyorsa İngilizce
  Locale _locale = const Locale('en', 'US');
  static const String _localeKey = 'locale';

  // Desteklenen diller listesi
  static const List<Locale> supportedLocales = [
    Locale('tr', 'TR'),
    Locale('en', 'US'),
  ];

  Locale get locale => _locale;

  // Provider'ı başlat ve kaydedilmiş dil ayarını yükle
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_localeKey);

    if (savedLocale != null) {
      // Kaydedilmiş dil varsa onu kullan
      final parts = savedLocale.split('_');
      if (parts.length == 2) {
        _locale = Locale(parts[0], parts[1]);
      }
    } else {
      // Kaydedilmiş dil yoksa cihaz dilini kontrol et
      final deviceLocale = WidgetsBinding.instance.window.locale;

      // Cihaz dili destekleniyorsa onu kullan
      if (isLocaleSupported(deviceLocale)) {
        _locale = deviceLocale;
      } else {
        // Desteklenmiyorsa İngilizce kullan
        _locale = const Locale('en', 'US');
      }

      // Seçilen dili kaydet
      await prefs.setString(_localeKey, '${_locale.languageCode}_${_locale.countryCode}');
    }

    notifyListeners();
  }

  // Verilen dilin desteklenip desteklenmediğini kontrol et
  bool isLocaleSupported(Locale locale) {
    return supportedLocales.any((supportedLocale) => supportedLocale.languageCode == locale.languageCode);
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
