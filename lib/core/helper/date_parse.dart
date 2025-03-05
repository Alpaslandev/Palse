// Tarih ve saat parse etme fonksiyonu güncellendi
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

DateTime? parseDateTime(dynamic dateData, dynamic timeData) {
  if (dateData == null) return null;

  // Eğer zaten DateTime ise
  if (dateData is DateTime) return dateData;

  // Eğer Timestamp ise
  if (dateData is Timestamp) return dateData.toDate();

  // Eğer String ise
  if (dateData is String) {
    try {
      // Önce "dd/MM/yyyy" formatını dene (eski format)
      if (dateData.contains('/')) {
        final dateParts = dateData.split('/');
        if (dateParts.length == 3) {
          // Saat bilgisini kontrol et
          if (timeData is String && timeData.contains(':')) {
            final timeParts = timeData.split(':');
            if (timeParts.length == 2) {
              return DateTime(
                int.parse(dateParts[2]), // yıl
                int.parse(dateParts[1]), // ay
                int.parse(dateParts[0]), // gün
                int.parse(timeParts[0]), // saat
                int.parse(timeParts[1]), // dakika
              );
            }
          }
          // Saat bilgisi yoksa sadece tarih oluştur
          return DateTime(
            int.parse(dateParts[2]), // yıl
            int.parse(dateParts[1]), // ay
            int.parse(dateParts[0]), // gün
          );
        }
      }
      // Eğer başarısız olursa ISO formatını dene
      return DateTime.parse(dateData);
    } catch (e) {
      debugPrint('Tarih parse hatası: $e');
      return null;
    }
  }
  return null;
}

// Tarih ve saat parse etme fonksiyonu güncellendi
DateTime? parseDateTimee(dynamic dateData) {
  if (dateData == null) return null;

  // Eğer zaten DateTime ise
  if (dateData is DateTime) return dateData;

  // Eğer Timestamp ise
  if (dateData is Timestamp) return dateData.toDate();

  // Eğer String ise
  if (dateData is String) {
    try {
      // Önce "dd/MM/yyyy" formatını dene (eski format)
      if (dateData.contains('/')) {
        final dateParts = dateData.split('/');
        // tarih oluştur
        return DateTime(
          int.parse(dateParts[2]), // yıl
          int.parse(dateParts[1]), // ay
          int.parse(dateParts[0]), // gün
        );
      }
      // Eğer başarısız olursa ISO formatını dene
      return DateTime.parse(dateData);
    } catch (e) {
      debugPrint('Tarih parse hatası: $e');
      return null;
    }
  }
  return null;
}
