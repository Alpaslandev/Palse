// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AppTheme {
  // Temel renkler - Her iki temada da kullanılacak
  static const Color primaryColor = Color(0xFF3A5ACB); // Ana mavi
  static const Color accentColor = Color(0xFF007AFF); // Vurgu rengi
  static const Color successColor = Color(0xFF4CAF50); // Başarı yeşili
  static const Color warningColor = Color(0xFFFFC107); // Uyarı sarısı
  static const Color errorColor = Color(0xFFE53935); // Hata kırmızısı

  // Açık tema renkleri
  static const Color lightTextColor = Color(0xFF212121); // Metin rengi
  static const Color lightBackgroundColor = Color(0xFFFFFFFF); // Arka plan rengi
  static const Color lightSurfaceColor = Color(0xFFF5F5F5); // Yüzey rengi
  static const Color lightCardColor = Color(0xFFFFFFFF); // Kart rengi
  static const Color lightDividerColor = Color(0xFFE0E0E0); // Ayırıcı rengi
  static const Color lightIconColor = Color(0xFF616161); // İkon rengi

  // Koyu tema renkleri
  static const Color darkTextColor = Color(0xFFEEEEEE); // Metin rengi
  static const Color darkBackgroundColor = Color(0xFF121212); // Arka plan rengi
  static const Color darkSurfaceColor = Color(0xFF1E1E1E); // Yüzey rengi
  static const Color darkCardColor = Color(0xFF252525); // Kart rengi
  static const Color darkDividerColor = Color(0xFF424242); // Ayırıcı rengi
  static const Color darkIconColor = Color(0xFFBDBDBD); // İkon rengi
  static const Color darkChipColor = Color(0xFF252525); // Chip rengi

  // Açık tema
  static ThemeData get theme => _createTheme(
        brightness: Brightness.light,
        textColor: lightTextColor,
        backgroundColor: lightBackgroundColor,
        surfaceColor: lightSurfaceColor,
        cardColor: lightCardColor,
        dividerColor: lightDividerColor,
        iconColor: lightIconColor,
      );

  // Koyu tema
  static ThemeData get darkTheme => _createTheme(
        brightness: Brightness.dark,
        textColor: darkTextColor,
        backgroundColor: darkBackgroundColor,
        surfaceColor: darkSurfaceColor,
        cardColor: darkCardColor,
        dividerColor: darkDividerColor,
        iconColor: darkIconColor,
      );

  // Ortak tema oluşturma fonksiyonu
  static ThemeData _createTheme({
    required Brightness brightness,
    required Color textColor,
    required Color backgroundColor,
    required Color surfaceColor,
    required Color cardColor,
    required Color dividerColor,
    required Color iconColor,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primaryColor,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: isDark ? darkTextColor : Colors.white,
        secondary: accentColor,
        onSecondary: isDark ? darkTextColor : Colors.white,
        error: errorColor,
        onError: Colors.white,
        surface: surfaceColor,
        onSurface: textColor,
      ),

      // Temel renkler
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      dividerColor: dividerColor,
      iconTheme: IconThemeData(color: iconColor),

      cardTheme: CardTheme(
        color: backgroundColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // AppBar teması
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),

      // Yazı renkleri
      textTheme: TextTheme(
        titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        titleSmall: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: textColor),
        bodySmall: TextStyle(color: textColor.withOpacity(0.8)),
      ),

      // Form elemanları
      inputDecorationTheme: InputDecorationTheme(
        fillColor: cardColor,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: isDark ? dividerColor : primaryColor.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: primaryColor, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: errorColor),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
        floatingLabelStyle: TextStyle(color: primaryColor),
        hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
      ),

      // Butonlar
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: isDark ? darkTextColor : Colors.white,
            shape: StadiumBorder(),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            disabledBackgroundColor: primaryColor.withOpacity(0.5),
            disabledForegroundColor: darkTextColor),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: backgroundColor,
        labelStyle: TextStyle(color: darkTextColor),
        iconTheme: IconThemeData(color: darkTextColor),
        shape: StadiumBorder(),
      ),

      // SwitchList'ler için tema
      switchTheme: SwitchThemeData(
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return isDark ? Colors.grey.shade700 : Colors.grey.shade300;
        }),
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return isDark ? Colors.grey.shade400 : Colors.grey.shade50;
        }),
      ),

      // TabBar teması
      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
        indicatorColor: primaryColor,
      ),
    );
  }
}
