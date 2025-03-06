import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';

// Uygulama kategorilerini ve ikonlarını tutan enum
enum Categories {
  kahveSohbet(icon: Icons.coffee, textKey: 'category_coffee_chat'),
  kitapBulusma(icon: Icons.book, textKey: 'category_book_meetings'),
  dilKultur(icon: Icons.language, textKey: 'category_language_culture'),
  spor(icon: Icons.sports, textKey: 'category_sports'),
  halisaha(icon: Icons.sports_soccer, textKey: 'category_football'),
  doga(icon: Icons.nature_people, textKey: 'category_nature'),
  fitness(icon: Icons.fitness_center, textKey: 'category_fitness'),
  sanatTarih(icon: Icons.museum, textKey: 'category_art_history'),
  filmDizi(icon: Icons.movie, textKey: 'category_movies_series'),
  dans(icon: Icons.music_note, textKey: 'category_dance'),
  muzik(icon: Icons.audiotrack, textKey: 'category_music'),
  konser(icon: Icons.queue_music, textKey: 'category_concerts'),
  parti(icon: Icons.celebration, textKey: 'category_party'),
  mutfak(icon: Icons.restaurant, textKey: 'category_culinary'),
  egitim(icon: Icons.school, textKey: 'category_education'),
  arastirma(icon: Icons.search, textKey: 'category_research'),
  videoOyun(icon: Icons.sports_esports, textKey: 'category_video_games'),
  elSanatlari(icon: Icons.brush, textKey: 'category_crafts'),
  yazilim(icon: Icons.code, textKey: 'category_coding'),
  yoga(icon: Icons.self_improvement, textKey: 'category_yoga'),
  fotograf(icon: Icons.camera_alt, textKey: 'category_photography'),
  evcilHayvan(icon: Icons.pets, textKey: 'category_pets'),
  motosiklet(icon: Icons.two_wheeler, textKey: 'category_motorcycle'),
  araba(icon: Icons.directions_car, textKey: 'category_cars'),
  moda(icon: Icons.shopping_bag, textKey: 'category_fashion'),
  cevrimici(icon: Icons.computer, textKey: 'category_online'),
  oyunTurnuva(icon: Icons.gamepad, textKey: 'category_game_tournaments'),
  seyahat(icon: Icons.flight, textKey: 'category_travel'),
  odaPaylas(icon: Icons.house, textKey: 'category_room_sharing'),
  arabaKiralama(icon: Icons.car_rental, textKey: 'category_car_rental'),
  esyaAlimSatim(icon: Icons.shopping_cart, textKey: 'category_items_trade'),
  diger(icon: Icons.more_horiz, textKey: 'category_other');

  final IconData icon;
  final String textKey;

  const Categories({required this.icon, required this.textKey});

  // Çevirilmiş metni döndüren getter
  String getText(BuildContext context) {
    return context.tr(textKey);
  }

  // Tüm kategori metinlerini liste olarak döndürür
  static List<String> getAllCategoryTexts(BuildContext context) {
    return Categories.values.map((e) => e.getText(context)).toList();
  }

  // Bir context içinde tüm çevrilmiş kategori metinlerini döndürür
  static List<String> getAllLocalizedTexts(BuildContext context) {
    return Categories.values.map((e) => e.getText(context)).toList();
  }

  // Çevrilmiş metin değerine göre kategori enum'ını döndürür
  static Categories fromLocalizedText(BuildContext context, String text) {
    return Categories.values.firstWhere(
      (e) => e.getText(context) == text,
      orElse: () => Categories.diger,
    );
  }
}

// Türkçe metin değerleri ile enum karşılıkları - Eski kayıtları parse etmek için
// String (Türkçe metin) -> Categories (enum) map
final Map<String, Categories> legacyTurkishTextMap = {
  'Kahve ve Sohbet': Categories.kahveSohbet,
  'Kitap Buluşmaları': Categories.kitapBulusma,
  'Dil ve Kültür Değişimi': Categories.dilKultur,
  'Spor Faaliyetleri': Categories.spor,
  'Halısaha Aktiviteleri': Categories.halisaha,
  'Doğa Faaliyetleri': Categories.doga,
  'Fitness ve Egzersiz': Categories.fitness,
  'Sanat ve Tarihi Geziler': Categories.sanatTarih,
  'Film ve Dizi Buluşmaları': Categories.filmDizi,
  'Dans Buluşmaları': Categories.dans,
  'Müzik Faaliyetleri': Categories.muzik,
  'Konser Buluşmaları': Categories.konser,
  'Parti ve Eğlence': Categories.parti,
  'Mutfak Sanatları': Categories.mutfak,
  'Eğitim Faaliyetleri': Categories.egitim,
  'Araştırma Grupları': Categories.arastirma,
  'Video Oyunu Buluşmaları': Categories.videoOyun,
  'El Sanatları': Categories.elSanatlari,
  'Yazılımcı Buluşmaları': Categories.yazilim,
  'Yoga ve Meditasyon': Categories.yoga,
  'Fotoğrafçılık Faaliyetleri': Categories.fotograf,
  'Evcil Hayvan Buluşmaları': Categories.evcilHayvan,
  'Motosiklet Grupları': Categories.motosiklet,
  'Araba Grupları': Categories.araba,
  'Moda ve Giyim': Categories.moda,
  'Çevrimiçi Etkinlikler': Categories.cevrimici,
  'Çevrimiçi Oyun Turnuvaları': Categories.oyunTurnuva,
  'Seyahat Etkinlikleri': Categories.seyahat,
  'Oda Paylaşımı ve Emlak': Categories.odaPaylas,
  'Araba Kiralama, Alım/Satım': Categories.arabaKiralama,
  'Eşya Alım/Satım': Categories.esyaAlimSatim,
  'Diğer': Categories.diger,
};

// Categories (enum) -> String (Türkçe metin) map - Search sorgularında kullanmak için
final Map<Categories, String> legacyTurkishTextMapReverse = {
  Categories.kahveSohbet: 'Kahve ve Sohbet',
  Categories.kitapBulusma: 'Kitap Buluşmaları',
  Categories.dilKultur: 'Dil ve Kültür Değişimi',
  Categories.spor: 'Spor Faaliyetleri',
  Categories.halisaha: 'Halısaha Aktiviteleri',
  Categories.doga: 'Doğa Faaliyetleri',
  Categories.fitness: 'Fitness ve Egzersiz',
  Categories.sanatTarih: 'Sanat ve Tarihi Geziler',
  Categories.filmDizi: 'Film ve Dizi Buluşmaları',
  Categories.dans: 'Dans Buluşmaları',
  Categories.muzik: 'Müzik Faaliyetleri',
  Categories.konser: 'Konser Buluşmaları',
  Categories.parti: 'Parti ve Eğlence',
  Categories.mutfak: 'Mutfak Sanatları',
  Categories.egitim: 'Eğitim Faaliyetleri',
  Categories.arastirma: 'Araştırma Grupları',
  Categories.videoOyun: 'Video Oyunu Buluşmaları',
  Categories.elSanatlari: 'El Sanatları',
  Categories.yazilim: 'Yazılımcı Buluşmaları',
  Categories.yoga: 'Yoga ve Meditasyon',
  Categories.fotograf: 'Fotoğrafçılık Faaliyetleri',
  Categories.evcilHayvan: 'Evcil Hayvan Buluşmaları',
  Categories.motosiklet: 'Motosiklet Grupları',
  Categories.araba: 'Araba Grupları',
  Categories.moda: 'Moda ve Giyim',
  Categories.cevrimici: 'Çevrimiçi Etkinlikler',
  Categories.oyunTurnuva: 'Çevrimiçi Oyun Turnuvaları',
  Categories.seyahat: 'Seyahat Etkinlikleri',
  Categories.odaPaylas: 'Oda Paylaşımı ve Emlak',
  Categories.arabaKiralama: 'Araba Kiralama, Alım/Satım',
  Categories.esyaAlimSatim: 'Eşya Alım/Satım',
  Categories.diger: 'Diğer',
};
