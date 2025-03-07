// Türkçe dil dosyası
const Map<String, String> tr = {
  // Genel
  'app_name': 'Palse App',

  // Giriş/Kayıt
  'login': 'Giriş Yap',
  'register': 'Kayıt Ol',
  'email': 'E-posta',
  'password': 'Şifre',
  'confirm_password': 'Şifre Tekrar',
  'forgot_password': 'Şifremi Unuttum',
  'continue': 'Devam Et',
  'welcome_message': 'Hoş geldin 👋',
  'or': 'Veya',
  'login_successful': 'Giriş başarılı',
  'login_failed': 'Giriş başarısız',
  'privacy_terms_agreement': 'Giriş yaparak Gizlilik Politikasını ve Kullanım Koşullarını kabul etmiş sayılırsınız.',

  // Ana Sayfa
  'home': 'Ana Sayfa',
  'explore': 'Keşfet',
  'messages': 'Mesajlar',
  'profile': 'Profil',
  'city_based': 'Şehrine Göre',
  'interest_based': 'İlgine Göre',
  'other': 'Diğer',
  'favorites': 'Favoriler',
  'no_listings_yet': 'Henüz ilan bulunmuyor',
  'no_more_listings_in_category': 'Bu kategoride başka ilan bulunmamaktadır.',
  'click_to_see_other_listings': 'Diğer ilanları görmek için tıklayın',
  'create_listing': 'İlan Ver',

  // İlanlar ve Profil
  'my_listings': 'İlanlarım',
  'my_likes': 'Beğendiklerim',
  'profile_viewers': 'Profilime Bakanlar',
  'no_listing_found': 'İlan bulunamadı',
  'show_less': 'Daha az göster',
  'show_more': 'Devamını gör...',
  'likers': 'Beğenenler',
  'delete': 'Sil',
  'like': 'Beğen',
  'message': 'Mesaj',
  'report_listing': 'İlanı Şikayet Et',
  'report_sent': 'Şikayet işlemi başlatıldı',
  'block_user': 'Bu Kullanıcıyı Engelle',
  'user_blocked': 'Kullanıcı engellendi',
  'listings': 'İlanlar',
  'send_message': 'Mesaj Gönder',
  'report_abuse': 'Kötüye Kullanım Bildir',
  'comments': 'Yorumlar',

  // Etkinlik Oluşturma
  'create_advert': 'Etkinlik Oluştur',
  'event_type': 'Etkinlik Tipi',
  'event_description': 'İlan Açıklaması',
  'event_date': 'Etkinlik Tarihi',
  'event_location': 'Etkinlik Konumu',
  'please_select_event_date': 'Lütfen etkinlik tarihini seçin',
  'please_select_event_location': 'Lütfen etkinlik konumunu seçin',
  'event_title': 'Etkinlik Başlığı',
  'event_title_required': 'Etkinlik başlığı gerekli',
  'event_title_min_length': 'Etkinlik başlığı en az 15 karakter olmalı',
  'event_description_required': 'İlan açıklaması gerekli',
  'event_description_min_length': 'İlan açıklaması en az 15 karakter olmalı',
  'event_type_required': 'Etkinlik tipi seçiniz',
  'select_photo': 'Fotoğraf Seç',
  'use_ready_photo': 'Hazır Fotoğraf Kullan',
  'only_premium_users_can_select_photo': 'Yalnızca premium üyeler fotoğraf seçebilir.',
  'premium_subscription': 'Premium Abonelik',
  'finish': 'Tamamla',
  'back': 'Geri',

  // Mesajlar
  'no_messages': 'Henüz mesaj yok',
  'type_message': 'Mesaj yazın...',
  'send': 'Gönder',
  'quote': 'Alıntı',
  'error_occurred': 'Bir hata oluştu',
  'no_notifications': 'Bildirim bulunamadı',
  'camera': 'Kamera',
  'gallery': 'Galeri',

  // Profil
  'edit_profile': 'Profili Düzenle',
  'settings': 'Ayarlar',
  'logout': 'Çıkış Yap',
  'daily_task': 'Bugünkü Görev',
  'daily_task_step1': 'Bir ilan oluştur ve bir mesaj gönder!',
  'daily_task_step2': 'Görevi tamamla, toplamda +100 XP kazan!',
  'complete_task': 'Görevi Tamamla',
  'verify_profile_text': 'Gerçek bir profil olduğunu doğrula ve\nekstra görünürlük kazan!',
  'get_premium': 'Premium Ol',

  // XP Sistemi
  'xp_system': 'XP Sistemi ve Ünvanlar',
  'ranks': 'Unvanlar',
  'ranks_description': 'Kazandığınız XP puanlarına göre unvanınız yükselir:',

  // Premium
  'premium_required': 'Premium Üyelik Gerekiyor',
  'premium_photo_message': 'Premium üyelik alarak fotoğraf gönderebilirsiniz.',
  'ok': 'Tamam',

  // Hata Mesajları
  'error': 'Hata',
  'try_again': 'Tekrar Dene',
  'connection_error': 'Bağlantı hatası',

  // XP Event Grupları
  'welcome_rewards': 'Hoş Geldin Ödülleri (Tek Seferlik)',
  'listing': 'İlan Verme',
  'messaging': 'Mesajlaşma',
  'commenting': 'Yorumlama ve Yorum Almak',
  'daily_tasks': 'Günlük Görev',

  // XP Event Açıklamaları
  'first_listing_description': 'İlk ilanını oluşturma',
  'first_message_description': 'İlk mesajını gönderme',
  'create_listing_description': 'Yeni ilan oluştur',
  'receive_first_message_description': 'İlanınıza gelen her ilk mesaj',
  'send_first_message_description': 'İlk defa mesaj gönderilen kullanıcı başına',
  'write_comment_description': 'Birine yorum yazma',
  'receive_comment_description': 'Profiline yorum alma',
  'daily_task_listing_and_message_description': 'Bir ilan oluştur ve bir mesaj gönder',
  'daily_login_description': 'Uygulamaya günlük giriş',

  // Dil Ayarları
  'language_settings': 'Dil Ayarları',
  'language_change_info': 'Dil değişikliği anında uygulanır ve otomatik olarak kaydedilir.',
  'app_language': 'Uygulama Dili',

  // Ayarlar Sayfası
  'user': 'Kullanıcı',
  'application': 'Uygulama',
  'general': 'Genel',
  'dark_theme': 'Koyu Tema',
  'notifications': 'Bildirimler',
  'account_verified': 'Hesabın Onaylı',
  'account_not_verified': 'Hesabın Onaylı Değil',
  'faq': 'Sıkça Sorulan Sorular',
  'terms_of_use': 'Kullanım Şartları',
  'privacy_policy': 'Gizlilik Politikası',
  'about_us': 'Hakkımızda',
  'app_version': 'Uygulama Versiyonu',

  // Kategoriler
  'categories': 'Kategoriler',
  'save': 'Kaydet',
  'my_interests': 'İlgi Alanlarım',
  'all_categories': 'Tüm Kategoriler',
  'interests_saved': 'İlgi alanlarınız kaydedildi',

  // Premium Overlay
  'premium_feature_only': 'Bu özellik sadece premium aboneler için',

  // Profil Düzenleme
  'change_photo': 'Fotoğrafı Değiştir',
  'username': 'Kullanıcı Adı',
  'first_name': 'Ad',
  'last_name': 'Soyad',
  'phone': 'Telefon',
  'location': 'Konum',
  'birth_date': 'Doğum Tarihi',
  'gender': 'Cinsiyet',
  'phone_verified': 'Telefon Doğrulanmıştır.',
  'phone_not_verified': 'Telefon Doğrulanmamıştır.',
  'phone_verification_success': 'Telefon numarası başarıyla doğrulandı',
  'photo_upload_error': 'Fotoğraf yükleme hatası',
  'profile_updated_successfully': 'Profil başarıyla güncellendi',

  // Liderlik Tablosu
  'leaderboard': 'Liderlik Tablosu',
  'your_rank': 'Sizin Sıralamanız',

  // XP İlerleme
  'to_next_level_part1': 'Bir sonraki seviyeye ',
  'to_next_level_part2': ' kaldı!',
  'to_next_premium_part1': 'Bir sonraki premium ödülüne ',
  'to_next_premium_part2': ' kaldı!',

  // Filtreleme
  'filtering': 'Filtreleme',
  'distance': 'Mesafe',
  'male': 'Erkek',
  'female': 'Kadın',
  'all': 'Hepsi',
  'category': 'Kategori',
  'apply': 'Uygula',

  // Kategoriler - Enum çevirileri
  'category_coffee_chat': 'Kahve ve Sohbet',
  'category_book_meetings': 'Kitap Buluşmaları',
  'category_language_culture': 'Dil ve Kültür Değişimi',
  'category_sports': 'Spor Faaliyetleri',
  'category_football': 'Halısaha Aktiviteleri',
  'category_nature': 'Doğa Faaliyetleri',
  'category_fitness': 'Fitness ve Egzersiz',
  'category_art_history': 'Sanat ve Tarihi Geziler',
  'category_movies_series': 'Film ve Dizi Buluşmaları',
  'category_dance': 'Dans Buluşmaları',
  'category_music': 'Müzik Faaliyetleri',
  'category_concerts': 'Konser Buluşmaları',
  'category_party': 'Parti ve Eğlence',
  'category_culinary': 'Mutfak Sanatları',
  'category_education': 'Eğitim Faaliyetleri',
  'category_research': 'Araştırma Grupları',
  'category_video_games': 'Video Oyunu Buluşmaları',
  'category_crafts': 'El Sanatları',
  'category_coding': 'Yazılımcı Buluşmaları',
  'category_yoga': 'Yoga ve Meditasyon',
  'category_photography': 'Fotoğrafçılık Faaliyetleri',
  'category_pets': 'Evcil Hayvan Buluşmaları',
  'category_motorcycle': 'Motosiklet Grupları',
  'category_cars': 'Araba Grupları',
  'category_fashion': 'Moda ve Giyim',
  'category_online': 'Çevrimiçi Etkinlikler',
  'category_game_tournaments': 'Çevrimiçi Oyun Turnuvaları',
  'category_travel': 'Seyahat Etkinlikleri',
  'category_room_sharing': 'Oda Paylaşımı ve Emlak',
  'category_car_rental': 'Araba Kiralama, Alım/Satım',
  'category_items_trade': 'Eşya Alım/Satım',
  'category_other': 'Diğer',

  // Gender
  'gender_male': 'Erkek',
  'gender_female': 'Kadın',
  'gender_others': 'Diğer',

  // Rütbe/Ünvan çevirileri
  'rank_beginner': '🌟 Keşfe Başlayan',
  'rank_explorer': '🔍 Sosyal Keşifçi',
  'rank_connector': '🧩 Bağlantı Ustası',
  'rank_leader': '🎯 Etkinlik Lideri',
  'rank_master': '👑 Sosyal Usta',
};
