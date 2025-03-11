// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AppTheme {
  // Temel renkler - Her iki temada da kullanılacak
  static const Color primaryColor = Color(0xFF3A5ACB); // Ana mavi
  static const Color accentColor = Color(0xFF007AFF); // Vurgu rengi
  static const Color successColor = Color(0xFF4CAF50); // Başarı yeşili
  static const Color warningColor = Color(0xFFFFC107); // Uyarı sarısı
  static const Color errorColor = Color(0xFFE53935); // Hata kırmızısı

  // Uygulama özgü semantik renkler
  static const Color chatBubbleSentColor = Color(0xFFE3F2FD); // Gönderilen mesaj balonu
  static const Color chatBubbleReceivedColor = Color(0xFFEEEEEE); // Alınan mesaj balonu
  static const Color unreadIndicatorColor = Color(0xFF1976D2); // Okunmamış mesaj/bildirim göstergesi
  static const Color verifiedBadgeColor = Color(0xFF4CAF50); // Doğrulanmış rozet rengi
  static const Color unverifiedBadgeColor = Color(0xFFE53935); // Doğrulanmamış rozet rengi
  static const Color premiumFeatureColor = Color(0xFFFFD700); // Premium özellik rengi
  static const Color notificationBadgeColor = Color(0xFFE53935); // Bildirim rozeti rengi
  static const Color activeChatColor = Color(0xFF4CAF50); // Aktif kullanıcı göstergesi

  // Mesajlaşma özel renkleri - Açık tema
  static const Color lightQuoteBackgroundColor = Color(0xFFF5F5F5); // Alıntı arkaplanı
  static const Color lightUrlBackgroundColor = Color(0xFFF5F5F5); // URL arkaplanı
  static const Color lightQuotedMessageBackgroundColor = Color(0xFFF0F0F0); // Alıntılanmış mesaj arkaplanı

  // Mesajlaşma özel renkleri - Koyu tema
  static const Color darkQuoteBackgroundColor = Color(0xFF2A2A2A); // Alıntı arkaplanı
  static const Color darkUrlBackgroundColor = Color(0xFF2A2A2A); // URL arkaplanı
  static const Color darkQuotedMessageBackgroundColor = Color(0xFF303030); // Alıntılanmış mesaj arkaplanı

  // Bilgi kartları için renkler
  static const Color infoColor = Color(0xFF2196F3); // Bilgi mavi

  // Açık tema için bilgi kartı renkleri
  static const Color lightInfoBackgroundColor = Color(0xFFE3F2FD); // Mavi bilgi arkaplan
  static const Color lightInfoBorderColor = Color(0xFFBBDEFB); // Mavi bilgi kenarlık
  static const Color lightWarningBackgroundColor = Color(0xFFFFF8E1); // Turuncu uyarı arkaplan
  static const Color lightWarningBorderColor = Color(0xFFFFE0B2); // Turuncu uyarı kenarlık

  // Koyu tema için bilgi kartı renkleri
  static const Color darkInfoBackgroundColor = Color(0xFF0D47A1); // Koyu mavi bilgi arkaplan
  static const Color darkInfoBorderColor = Color(0xFF1565C0); // Koyu mavi bilgi kenarlık
  static const Color darkWarningBackgroundColor = Color(0xFF4E342E); // Koyu kahverengi uyarı arkaplan
  static const Color darkWarningBorderColor = Color(0xFF6D4C41); // Koyu kahverengi uyarı kenarlık

  // Form renkler - Açık tema
  static const Color lightInputFillColor = Color(0xFFF5F5F5); // Form dolgu rengi
  static const Color lightHintTextColor = Color(0xFF9E9E9E); // İpucu metin rengi
  static const Color lightBorderColor = Color(0xFFE0E0E0); // Kenarlık rengi

  // Form renkler - Koyu tema
  static const Color darkInputFillColor = Color(0xFF2C2C2C); // Form dolgu rengi
  static const Color darkHintTextColor = Color(0xFF757575); // İpucu metin rengi
  static const Color darkBorderColor = Color(0xFF424242); // Kenarlık rengi

  // Açık tema renkleri
  static const Color lightTextColor = Color(0xFF212121); // Metin rengi
  static const Color lightBackgroundColor = Color(0xFFFFFFFF); // Arka plan rengi
  static const Color lightSurfaceColor = Color(0xFFF5F5F5); // Yüzey rengi
  static const Color lightCardColor = Color(0xFFFFFFFF); // Kart rengi
  static const Color lightDividerColor = Color(0xFFE0E0E0); // Ayırıcı rengi
  static const Color lightIconColor = Color(0xFF616161); // İkon rengi
  static const Color lightSubtitleColor = Color(0xFF757575); // Alt başlık rengi

  // Koyu tema renkleri - Kontrast iyileştirildi
  static const Color darkTextColor = Color(0xFFFAFAFA); // Metin rengi (daha parlak beyaz)
  static const Color darkBackgroundColor = Color(0xFF121212); // Arka plan rengi
  static const Color darkSurfaceColor = Color(0xFF1E1E1E); // Yüzey rengi
  static const Color darkCardColor = Color(0xFF252525); // Kart rengi
  static const Color darkDividerColor = Color(0xFF424242); // Ayırıcı rengi
  static const Color darkIconColor = Color(0xFFE0E0E0); // İkon rengi (daha parlak)
  static const Color darkChipColor = Color(0xFF252525); // Chip rengi
  static const Color darkSubtitleColor = Color(0xFFBDBDBD); // Alt başlık rengi (daha parlak)

  // Mesajlaşma ekranı renkleri - Açık tema
  static const Color lightChatBubbleSentColor = Color(0xFFE3F2FD); // Gönderilen mesaj arka planı
  static const Color lightChatBubbleSentTextColor = Color(0xFF212121); // Gönderilen mesaj metni
  static const Color lightChatBubbleReceivedColor = Color(0xFFEEEEEE); // Alınan mesaj arka planı
  static const Color lightChatBubbleReceivedTextColor = Color(0xFF212121); // Alınan mesaj metni

  // Mesajlaşma ekranı renkleri - Koyu tema
  static const Color darkChatBubbleSentColor = Color(0xFF1E3A5F); // Gönderilen mesaj arka planı
  static const Color darkChatBubbleSentTextColor = Color(0xFFFAFAFA); // Gönderilen mesaj metni
  static const Color darkChatBubbleReceivedColor = Color(0xFF2A2A2A); // Alınan mesaj arka planı
  static const Color darkChatBubbleReceivedTextColor = Color(0xFFFAFAFA); // Alınan mesaj metni

  // Açık tema
  static ThemeData get theme => _createTheme(
        brightness: Brightness.light,
        textColor: lightTextColor,
        backgroundColor: lightBackgroundColor,
        surfaceColor: lightSurfaceColor,
        cardColor: lightCardColor,
        dividerColor: lightDividerColor,
        iconColor: lightIconColor,
        subtitleColor: lightSubtitleColor,
        inputFillColor: lightInputFillColor,
        hintTextColor: lightHintTextColor,
        borderColor: lightBorderColor,
        infoBackgroundColor: lightInfoBackgroundColor,
        infoBorderColor: lightInfoBorderColor,
        warningBackgroundColor: lightWarningBackgroundColor,
        warningBorderColor: lightWarningBorderColor,
        chatBubbleSentColor: lightChatBubbleSentColor,
        chatBubbleSentTextColor: lightChatBubbleSentTextColor,
        chatBubbleReceivedColor: lightChatBubbleReceivedColor,
        chatBubbleReceivedTextColor: lightChatBubbleReceivedTextColor,
        quoteBackgroundColor: lightQuoteBackgroundColor,
        urlBackgroundColor: lightUrlBackgroundColor,
        quotedMessageBackgroundColor: lightQuotedMessageBackgroundColor,
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
        subtitleColor: darkSubtitleColor,
        inputFillColor: darkInputFillColor,
        hintTextColor: darkHintTextColor,
        borderColor: darkBorderColor,
        infoBackgroundColor: darkInfoBackgroundColor,
        infoBorderColor: darkInfoBorderColor,
        warningBackgroundColor: darkWarningBackgroundColor,
        warningBorderColor: darkWarningBorderColor,
        chatBubbleSentColor: darkChatBubbleSentColor,
        chatBubbleSentTextColor: darkChatBubbleSentTextColor,
        chatBubbleReceivedColor: darkChatBubbleReceivedColor,
        chatBubbleReceivedTextColor: darkChatBubbleReceivedTextColor,
        quoteBackgroundColor: darkQuoteBackgroundColor,
        urlBackgroundColor: darkUrlBackgroundColor,
        quotedMessageBackgroundColor: darkQuotedMessageBackgroundColor,
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
    required Color subtitleColor,
    required Color inputFillColor,
    required Color hintTextColor,
    required Color borderColor,
    required Color infoBackgroundColor,
    required Color infoBorderColor,
    required Color warningBackgroundColor,
    required Color warningBorderColor,
    required Color chatBubbleSentColor,
    required Color chatBubbleSentTextColor,
    required Color chatBubbleReceivedColor,
    required Color chatBubbleReceivedTextColor,
    required Color quoteBackgroundColor,
    required Color urlBackgroundColor,
    required Color quotedMessageBackgroundColor,
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
        background: backgroundColor,
        onBackground: textColor,
        surface: surfaceColor,
        onSurface: textColor,
        tertiary: infoColor,
        tertiaryContainer: infoBackgroundColor,
        errorContainer: warningBackgroundColor,
        // Yeni eklenen semantik renkler için extensions kullanılacak
      ),

      // Temel renkler
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      dividerColor: dividerColor,
      iconTheme: IconThemeData(color: iconColor),

      cardTheme: CardTheme(
        color: cardColor,
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
        bodySmall: TextStyle(color: subtitleColor),
        labelSmall: TextStyle(color: subtitleColor),
      ),

      // Form elemanları
      inputDecorationTheme: InputDecorationTheme(
        fillColor: inputFillColor,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: isDark ? borderColor : primaryColor.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: borderColor),
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
        hintStyle: TextStyle(color: hintTextColor),
      ),

      // Butonlar
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white, // Her zaman beyaz olsun (daha iyi kontrast için)
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            disabledBackgroundColor: primaryColor.withOpacity(0.5),
            disabledForegroundColor: isDark ? darkTextColor : Colors.white.withOpacity(0.7)),
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
        backgroundColor: isDark ? darkChipColor : backgroundColor,
        labelStyle: TextStyle(color: textColor),
        iconTheme: IconThemeData(color: iconColor),
        shape: const StadiumBorder(),
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

// Tema renkleri için extension
extension CustomColorScheme on ColorScheme {
  // Mesajlaşma renkleri
  Color get chatBubbleSent => brightness == Brightness.light ? AppTheme.lightChatBubbleSentColor : AppTheme.darkChatBubbleSentColor;

  Color get chatBubbleSentText => brightness == Brightness.light ? AppTheme.lightChatBubbleSentTextColor : AppTheme.darkChatBubbleSentTextColor;

  Color get chatBubbleReceived => brightness == Brightness.light ? AppTheme.lightChatBubbleReceivedColor : AppTheme.darkChatBubbleReceivedColor;

  Color get chatBubbleReceivedText =>
      brightness == Brightness.light ? AppTheme.lightChatBubbleReceivedTextColor : AppTheme.darkChatBubbleReceivedTextColor;

  // Mesajlaşma özel renkleri
  Color get quoteBackground => brightness == Brightness.light ? AppTheme.lightQuoteBackgroundColor : AppTheme.darkQuoteBackgroundColor;

  Color get urlBackground => brightness == Brightness.light ? AppTheme.lightUrlBackgroundColor : AppTheme.darkUrlBackgroundColor;

  Color get quotedMessageBackground =>
      brightness == Brightness.light ? AppTheme.lightQuotedMessageBackgroundColor : AppTheme.darkQuotedMessageBackgroundColor;

  // Uygulama özgü renkler
  Color get verified => AppTheme.verifiedBadgeColor;
  Color get unverified => AppTheme.unverifiedBadgeColor;
  Color get premium => AppTheme.premiumFeatureColor;
  Color get notification => AppTheme.notificationBadgeColor;
  Color get activeChat => AppTheme.activeChatColor;
  Color get unreadIndicator => AppTheme.unreadIndicatorColor;
}
