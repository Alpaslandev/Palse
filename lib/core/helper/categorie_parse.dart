import 'package:flutter/material.dart';
import 'package:palseapp/core/constant/categories.dart';

Categories? parseCategoryType(dynamic value, [BuildContext? context]) {
  if (value == null) return null;

  // Eğer değer zaten bir CategoryType ise direkt döndür
  if (value is Categories) return value;

  // String değer için kontrol
  if (value is String) {
    // 1. Önce enum.name olarak eşleşme kontrolü yap
    try {
      final enumNameMatch = Categories.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => Categories.diger,
      );

      // Eğer bir eşleşme bulduysa ve bu "diger" değilse, döndür
      if (enumNameMatch != Categories.diger) {
        return enumNameMatch;
      }

      // 2. Eski Türkçe metin karşılığı ile eşleşme kontrolü yap
      final legacyTextMatch = legacyTurkishTextMap[value];
      if (legacyTextMatch != null) {
        return legacyTextMatch;
      }

      // 3. Context varsa localized text ile eşleşme kontrolü yap
      if (context != null) {
        return Categories.fromLocalizedText(context, value);
      }

      // Eşleşme bulunamadı, diger döndür
      return Categories.diger;
    } catch (e) {
      debugPrint('Kategori dönüştürme hatası: $e');
      return Categories.diger;
    }
  }

  // Desteklenmeyen değer tipi
  return Categories.diger;
}
