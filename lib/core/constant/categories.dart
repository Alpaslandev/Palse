import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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

  // Eski kullanımlar için geçici olarak doğrudan metni döndüren getter
  // Bu geçiş sürecinde kullanılır, sonra kaldırılabilir
  String get text {
    // Burada geçici olarak sabit metinleri döndürüyoruz
    // Bu kısmı geçiş sürecinde kullanabiliriz
    switch (this) {
      case Categories.kahveSohbet:
        return 'Kahve ve Sohbet';
      case Categories.kitapBulusma:
        return 'Kitap Buluşmaları';
      case Categories.dilKultur:
        return 'Dil ve Kültür Değişimi';
      case Categories.spor:
        return 'Spor Faaliyetleri';
      case Categories.halisaha:
        return 'Halısaha Aktiviteleri';
      case Categories.doga:
        return 'Doğa Faaliyetleri';
      case Categories.fitness:
        return 'Fitness ve Egzersiz';
      case Categories.sanatTarih:
        return 'Sanat ve Tarihi Geziler';
      case Categories.filmDizi:
        return 'Film ve Dizi Buluşmaları';
      case Categories.dans:
        return 'Dans Buluşmaları';
      case Categories.muzik:
        return 'Müzik Faaliyetleri';
      case Categories.konser:
        return 'Konser Buluşmaları';
      case Categories.parti:
        return 'Parti ve Eğlence';
      case Categories.mutfak:
        return 'Mutfak Sanatları';
      case Categories.egitim:
        return 'Eğitim Faaliyetleri';
      case Categories.arastirma:
        return 'Araştırma Grupları';
      case Categories.videoOyun:
        return 'Video Oyunu Buluşmaları';
      case Categories.elSanatlari:
        return 'El Sanatları';
      case Categories.yazilim:
        return 'Yazılımcı Buluşmaları';
      case Categories.yoga:
        return 'Yoga ve Meditasyon';
      case Categories.fotograf:
        return 'Fotoğrafçılık Faaliyetleri';
      case Categories.evcilHayvan:
        return 'Evcil Hayvan Buluşmaları';
      case Categories.motosiklet:
        return 'Motosiklet Grupları';
      case Categories.araba:
        return 'Araba Grupları';
      case Categories.moda:
        return 'Moda ve Giyim';
      case Categories.cevrimici:
        return 'Çevrimiçi Etkinlikler';
      case Categories.oyunTurnuva:
        return 'Çevrimiçi Oyun Turnuvaları';
      case Categories.seyahat:
        return 'Seyahat Etkinlikleri';
      case Categories.odaPaylas:
        return 'Oda Paylaşımı ve Emlak';
      case Categories.arabaKiralama:
        return 'Araba Kiralama, Alım/Satım';
      case Categories.esyaAlimSatim:
        return 'Eşya Alım/Satım';
      case Categories.diger:
        return 'Diğer';
    }
  }

  // Tüm kategori metinlerini liste olarak döndürür
  static List<String> getAllCategoryTexts() {
    return Categories.values.map((e) => e.text).toList();
  }

  // Bir context içinde tüm çevrilmiş kategori metinlerini döndürür
  static List<String> getAllLocalizedTexts(BuildContext context) {
    return Categories.values.map((e) => e.getText(context)).toList();
  }

  // Metin değerine göre kategori enum'ını döndürür
  static Categories fromText(String text) {
    return Categories.values.firstWhere(
      (e) => e.text == text,
      orElse: () => Categories.diger,
    );
  }
}
