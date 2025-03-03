import 'package:flutter/material.dart';

// Uygulama kategorilerini ve ikonlarını tutan enum
enum Categories {
  kahveSohbet(icon: Icons.coffee, text: 'Kahve ve Sohbet'),
  kitapBulusma(icon: Icons.book, text: 'Kitap Buluşmaları'),
  dilKultur(icon: Icons.language, text: 'Dil ve Kültür Değişimi'),
  spor(icon: Icons.sports, text: 'Spor Faaliyetleri'),
  halisaha(icon: Icons.sports_soccer, text: 'Halısaha Aktiviteleri'),
  doga(icon: Icons.nature_people, text: 'Doğa Faaliyetleri'),
  fitness(icon: Icons.fitness_center, text: 'Fitness ve Egzersiz'),
  sanatTarih(icon: Icons.museum, text: 'Sanat ve Tarihi Geziler'),
  filmDizi(icon: Icons.movie, text: 'Film ve Dizi Buluşmaları'),
  dans(icon: Icons.music_note, text: 'Dans Buluşmaları'),
  muzik(icon: Icons.audiotrack, text: 'Müzik Faaliyetleri'),
  konser(icon: Icons.queue_music, text: 'Konser Buluşmaları'),
  parti(icon: Icons.celebration, text: 'Parti ve Eğlence'),
  mutfak(icon: Icons.restaurant, text: 'Mutfak Sanatları'),
  egitim(icon: Icons.school, text: 'Eğitim Faaliyetleri'),
  arastirma(icon: Icons.search, text: 'Araştırma Grupları'),
  videoOyun(icon: Icons.sports_esports, text: 'Video Oyunu Buluşmaları'),
  elSanatlari(icon: Icons.brush, text: 'El Sanatları'),
  yazilim(icon: Icons.code, text: 'Yazılımcı Buluşmaları'),
  yoga(icon: Icons.self_improvement, text: 'Yoga ve Meditasyon'),
  fotograf(icon: Icons.camera_alt, text: 'Fotoğrafçılık Faaliyetleri'),
  evcilHayvan(icon: Icons.pets, text: 'Evcil Hayvan Buluşmaları'),
  motosiklet(icon: Icons.two_wheeler, text: 'Motosiklet Grupları'),
  araba(icon: Icons.directions_car, text: 'Araba Grupları'),
  moda(icon: Icons.shopping_bag, text: 'Moda ve Giyim'),
  cevrimici(icon: Icons.computer, text: 'Çevrimiçi Etkinlikler'),
  oyunTurnuva(icon: Icons.gamepad, text: 'Çevrimiçi Oyun Turnuvaları'),
  seyahat(icon: Icons.flight, text: 'Seyahat Etkinlikleri'),
  odaPaylas(icon: Icons.house, text: 'Oda Paylaşımı ve Emlak'),
  arabaKiralama(icon: Icons.car_rental, text: 'Araba Kiralama, Alım/Satım'),
  esyaAlimSatim(icon: Icons.shopping_cart, text: 'Eşya Alım/Satım'),
  diger(icon: Icons.more_horiz, text: 'Diğer');

  final IconData icon;
  final String text;

  const Categories({required this.icon, required this.text});

  // Tüm kategori metinlerini liste olarak döndürür
  static List<String> getAllCategoryTexts() {
    return Categories.values.map((e) => e.text).toList();
  }

  // Metin değerine göre kategori enum'ını döndürür
  static Categories fromText(String text) {
    return Categories.values.firstWhere(
      (e) => e.text == text,
      orElse: () => Categories.diger,
    );
  }
}
