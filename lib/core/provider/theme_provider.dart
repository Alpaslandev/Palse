import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // Tema tercihi için anahtar
  static const String _themePreferenceKey = 'theme_preference';

  // Varsayılan tema durumu (aydınlık tema)
  bool _isDarkMode = false;

  // Tema durumunu okuma özelliği
  bool get isDarkMode => _isDarkMode;

  // ThemeMode özelliği
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // Provider başlatıldığında kayıtlı tema tercihini yükle
  ThemeProvider() {
    _loadThemePreference();
  }

  // Kayıtlı tema tercihini yükle
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themePreferenceKey) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Tema tercihi yüklenirken hata: $e');
    }
  }

  // Tema tercihini değiştir ve kaydet
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themePreferenceKey, _isDarkMode);
    } catch (e) {
      debugPrint('Tema tercihi kaydedilirken hata: $e');
    }
  }
}
