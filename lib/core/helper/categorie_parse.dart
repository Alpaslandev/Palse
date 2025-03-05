import 'package:flutter/material.dart';
import 'package:palseapp/core/constant/categories.dart';

Categories? parseCategoryType(dynamic value) {
  if (value == null) return null;

  // Eğer değer zaten bir CategoryType ise direkt döndür
  if (value is Categories) return value;

  // String değer için kontrol
  if (value is String) {
    // Önce enum.name olarak eşleşme kontrolü yap
    try {
      return Categories.values.firstWhere(
        (e) => e.name == value,
        orElse: () {
          return Categories.values.firstWhere(
            (e) => e.text == value,
            orElse: () => Categories.diger, // Eşleşme bulunamazsa varsayılan değer
          );
        },
      );
    } catch (e) {
      debugPrint('Kategori dönüştürme hatası: $e');
      return Categories.diger;
    }
  }

  // Desteklenmeyen değer tipi
  return Categories.diger;
}
