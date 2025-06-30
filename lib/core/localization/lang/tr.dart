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
  'privacy_terms_agreement':
      'Giriş yaparak Gizlilik Politikasını ve Kullanım Koşullarını kabul etmiş sayılırsınız.',
  'create_account': 'Hesap Oluştur',
  'login_subtitle': 'Hesabınıza giriş yapın veya sosyal medya ile devam edin',
  'signup_subtitle': 'Yeni bir hesap oluşturun ve etkinliklere katılın',
  'email_hint': 'E-posta adresinizi girin',
  'password_hint': 'Şifrenizi girin',
  'confirm_password_hint': 'Şifrenizi tekrar girin',
  'login_with_email': 'E-posta ile Giriş Yap',
  'signup_with_email': 'E-posta ile Kayıt Ol',
  'social_login_title': 'Sosyal Medya ile Giriş Yap',
  'google_login': 'Google',
  'apple_login': 'Apple',
  'already_have_account': 'Zaten hesabınız var mı?',
  'dont_have_account': 'Hesabınız yok mu?',
  'passwords_dont_match': 'Şifreler eşleşmiyor',
  'by_continuing': 'Devam ederek',
  'and': 've',

  // Profil Kurulumu
  'profile_setup': 'Profil Oluştur',
  'profile_setup_step': 'Adım {step}/6',
  'profile_setup_back': 'Geri',
  'profile_setup_next': 'İleri',
  'profile_setup_finish': 'Tamamla',
  'profile_setup_error_name':
      'Lütfen ad ve soyadınızı doğru şekilde girin (en az 3 karakter)',
  'profile_setup_error_birthday_gender':
      'Lütfen doğum tarihinizi ve cinsiyetinizi seçin',
  'profile_setup_error_location':
      'Lütfen bir konum seçin veya mevcut konumunuzu kullanın',
  'profile_setup_error_nickname':
      'Lütfen geçerli bir takma ad girin (en az 3 karakter)',
  'profile_setup_error_categories': 'Lütfen en az 3 kategori seçin',

  // Profil Kurulum Adımları
  // 1. Adım: Kullanıcı Bilgileri
  'user_info_welcome': 'Hoşgeldin!',
  'user_info_description':
      'Deneyimini hazırlamak için birkaç bilgi girmeni rica ediyoruz.',
  'user_info_first_name': 'Ad',
  'user_info_last_name': 'Soyad',
  'user_info_first_name_hint': 'Adınızı girin',
  'user_info_last_name_hint': 'Soyadınızı girin',
  'user_info_perfect': 'Mükemmel!',
  'user_info_hello':
      'Merhaba {firstName} {lastName}, şimdi diğer adımlara geçebilirsin.',
  'user_info_info': 'Bilgi',
  'user_info_please_enter':
      'Lütfen adınızı ve soyadınızı girin. Bu bilgiler profilinizde görünecektir.',

  // 2. Adım: Doğum Tarihi ve Cinsiyet
  'birthday_gender_title': 'Sizi tanıyalım',
  'birthday_gender_birthday': 'Doğum Tarihi',
  'birthday_gender_select_date': 'Tarih Seçin',
  'birthday_gender_age_restriction':
      'Bu uygulamayı kullanmak için en az 18 yaşında olmalısınız',
  'birthday_gender_gender': 'Cinsiyet',
  'birthday_gender_male': 'Erkek',
  'birthday_gender_female': 'Kadın',
  'birthday_gender_other': 'Diğer',
  'birthday_gender_required': 'Zorunlu',
  'birthday_gender_optional': 'Opsiyonel',
  'birthday_gender_optional_info':
      'Doğum tarihi ve cinsiyet bilgileriniz opsiyoneldir. Dilerseniz daha sonra profil ayarlarından güncelleyebilirsiniz.',
  'birthday_gender_select_birth_date': 'Lütfen doğum tarihinizi seçin',
  'birthday_gender_select_gender': 'Lütfen cinsiyetinizi seçin',
  'birthday_gender_awesome': 'Harika!',
  'birthday_gender_basics_completed':
      'Temel bilgileriniz tamamlandı, şimdi diğer adımlara geçebilirsiniz.',
  'birthday_gender_info': 'Bilgi',
  'birthday_gender_info_text':
      'Doğum tarihiniz ve cinsiyetiniz size uygun etkinlikleri önerirken kullanılacaktır.',

  // 3. Adım: Konum
  'location_title': 'Konumunuz',
  'location_description': 'Size yakın etkinlik ve aktiviteleri göstereceğiz',
  'location_current': 'Mevcut Konumu Kullan',
  'location_search': 'Ara',
  'location_search_hint': 'Şehir, ilçe vs. ara',
  'location_permission_text':
      'Size yakın etkinlikleri bulmak için konum izni verin',
  'location_permission_button': 'Konum İzni Ver',
  'location_required': 'Zorunlu',
  'location_optional': 'Opsiyonel',
  'location_optional_info':
      'Konum bilgisi opsiyoneldir. Dilerseniz daha sonra profil ayarlarından güncelleyebilirsiniz.',
  'location_please_select': 'Lütfen bir konum seçin',
  'location_search_label': 'Konum Ara',
  'location_search_hint_detailed': 'Şehir veya ilçe adı girin',
  'location_selected': 'Seçilen Konum:',
  'location_coordinates': 'Koordinatlar: {lat}, {lng}',
  'location_error_getting': 'Konum alınamadı: {error}',
  'location_error_general': 'Hata: {error}',

  // 4. Adım: Takma Ad
  'nickname_title': 'Bir Takma Ad Seçin',
  'nickname_description': 'Diğer kullanıcılar sizi böyle görecek',
  'nickname_hint': 'Bir takma ad girin (en az 3 karakter)',
  'nickname_availability_checking': 'Kullanılabilirlik kontrol ediliyor...',
  'nickname_available': 'Bu takma ad kullanılabilir',
  'nickname_unavailable': 'Bu takma ad zaten alınmış',
  'nickname_almost_done': 'Çok az kaldı...',
  'nickname_choose_cool': 'Havalı bir kullanıcı adına ne dersin?',
  'nickname_required': 'Zorunlu',
  'nickname_profile_info': 'Bu isim profilinizde görünecektir',
  'nickname_label': 'Takma Ad',
  'nickname_min_length_error': 'Takma ad en az 3 karakter olmalıdır',
  'nickname_please_enter': 'Lütfen bir takma ad girin',
  'nickname_great_choice': 'Harika bir seçim!',
  'nickname_tip': 'Eğlenceli ve özgün bir isim seçin!',

  // 5. Adım: Profil Fotoğrafı
  'profile_picture_title': 'Profil Resmi Ekleyin',
  'profile_picture_description':
      'Bu, başkalarının sizi tanımasına yardımcı olur',
  'profile_picture_upload': 'Fotoğraf Yükle',
  'profile_picture_take': 'Fotoğraf Çek',
  'profile_picture_skip': 'Şimdilik Geç',
  'profile_picture_almost_done': 'Neredeyse Bitti!',
  'profile_picture_add_photo':
      'Seni tanımak için bir fotoğraf eklemek ister misin?',
  'profile_picture_tip':
      'Profil fotoğrafı olan kullanıcılar %70 daha fazla etkileşim alıyor!',
  'profile_picture_add': 'Fotoğraf Ekle',
  'profile_picture_looks_great':
      'Harika görünüyor! Fotoğrafını değiştirmek istersen tekrar dokunabilirsin.',
  'profile_picture_skip_info':
      'Bu adımı atlayabilirsin, daha sonra profil ayarlarından ekleyebilirsin',

  // 6. Adım: Kategoriler
  'categories_title': 'İlgi Alanlarınızı Seçin',
  'categories_description': 'İlgilendiğiniz en az 3 kategori seçin',
  'categories_min_selection': 'En az {count} kategori daha seçin',
  'categories_selected': '{count} kategori seçildi',
  'categories_finally': 'Son olarak',
  'categories_select_interests': 'ilgi alanlarınızı seçiniz',
  'categories_great': 'Harika! Yeterli kategori seçtiniz',
  'categories_min_required': 'En az 3 kategori seçmeniz gerekiyor',
  'categories_list_title': 'Kategoriler',

  // Ana Sayfa
  'home': 'Ana Sayfa',
  'explore': 'Keşfet',
  'messages': 'Mesajlar',
  'profile': 'Profil',
  'city_based': 'Şehrimdekiler',
  'interest_based': 'İlgine Göre',
  'other': 'Diğer',
  'favorites': 'Favoriler',
  'no_listings_yet': 'Henüz ilan bulunmuyor',
  'no_listings_in_your_city': 'Şehrinizde ilan bulunamadı',
  'no_listings_in_your_interests': 'İlgi alanlarınızda ilan bulunamadı',
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
  'join': 'Katıl',
  'waiting': 'Bekliyor',
  'joined': 'Katıldı',
  'joined_events': 'Katıldığım Etkinlikler',
  'join_request': 'Katılım İstekleri',
  'message': 'Mesaj',
  'report_listing': 'İlanı Şikayet Et',
  'report_sent': 'Şikayet işlemi başlatıldı',
  'block_user': 'Bu Kullanıcıyı Engelle',
  'user_blocked': 'Kullanıcı engellendi',
  'unblock_user': 'Engeli Kaldır',
  'user_unblocked': 'Kullanıcının engeli kaldırıldı',
  'user_blocked_message':
      'Bu kullanıcıyı engellediniz. Mesaj göndermek için engeli kaldırmanız gerekiyor.',
  'listings': 'İlanlar',
  'send_message': 'Mesaj Gönder',
  'report_abuse': 'Kötüye Kullanım Bildir',

  // Takip İşlemleri
  'follow': 'Takip Et',
  'unfollow': 'Takibi Bırak',
  'send_request': 'İstek Gönder',
  'request_sent': 'İstek Gönderildi',
  'request_cancelled': 'İstek iptal edildi',
  'follow_request_sent': 'Takip isteği gönderildi',
  'user_followed': 'Kullanıcı takip edildi',
  'unfollowed_user': 'Kullanıcı takipten çıkarıldı',
  'leave': 'Ayrıl',
  'comments': 'Yorumlar',
  'add_comment': 'Yorum Ekle',
  'advert_deleted_successfully': 'İlan başarıyla silindi',

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
  'only_premium_users_can_select_photo':
      'Yalnızca premium üyeler fotoğraf seçebilir.',
  'premium_subscription': 'Premium Abonelik',
  'finish': 'Tamamla',
  'back': 'Geri',
  'advert_created_successfully_non_premium':
      'Bundan sonraki ilanlarınızda reklam izlememek için premium üye olabilirsiniz.',
  'advert_created_successfully_premium': 'İlanınız başarıyla oluşturuldu.',
  'please_select_photo': 'Lütfen bir fotoğraf seçin',
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
  'verify_profile_text':
      'Gerçek bir profil olduğunu doğrula ve\nekstra görünürlük kazan!',

  // XP Sistemi
  'xp_system': 'XP Sistemi ve Ünvanlar',
  'ranks': 'Unvanlar',
  'ranks_description': 'Kazandığınız XP puanlarına göre unvanınız yükselir:',

  // Premium
  'get_premium': 'Premium Ol',
  'premium_required': 'Premium Üyelik Gerekiyor',
  'premium_photo_message': 'Premium üyelik alarak fotoğraf gönderebilirsiniz.',
  'ok': 'Tamam',

  // Hata Mesajları
  'error': 'Hata',
  'try_again': 'Tekrar Dene',
  'connection_error': 'Bağlantı hatası',
  'min_categories_warning': 'En az 3 kategori seçilmelidir.',

  // XP Event Grupları
  'welcome_rewards': 'Hoş Geldin Ödülleri (Tek Seferlik)',
  'listing': 'İlan Verme',
  'messaging': 'Mesajlaşma',
  'commenting': 'Yorumlama ve Yorum Almak',
  'daily_tasks': 'Günlük Görevler',

  // XP Event Açıklamaları
  'first_listing_description': 'İlk ilanını oluşturma',
  'first_message_description': 'İlk mesajını gönderme',
  'create_listing_description': 'Yeni ilan oluştur',
  'receive_first_message_description': 'İlanınıza gelen her ilk mesaj',
  'send_first_message_description':
      'İlk defa mesaj gönderilen kullanıcı başına',
  'write_comment_description': 'Birine yorum yazma',
  'receive_comment_description': 'Profiline yorum alma',
  'daily_task_listing_and_message_description':
      'Bir ilan oluştur ve bir mesaj gönder',
  'daily_login_description': 'Uygulamaya günlük giriş',
  'daily_create_listing_description': 'Bir ilan oluştur',
  'daily_send_message_description': 'Bir mesaj gönder',
  'no_daily_task_yet': 'Henüz günlük görevin yok',
  'daily_task_completed': 'Günlük görev tamamlandı! +100 XP kazandın',
  'task_completed': 'Görev Tamamlandı',
  'next_reset': 'Bir sonraki yenileme',
  'completed_tasks': 'Tamamlanan görevler',
  'daily_task_login': 'Uygulamaya giriş yap',
  'daily_task_create_listing': 'Bir ilan oluştur',
  'daily_task_send_message': 'Bir mesaj gönder',
  'notification_daily_tasks_reset_title': 'Günlük Görevler Yenilendi',
  'notification_daily_tasks_reset_body':
      'Yeni günlük görevler hazır! Hemen tamamla ve XP kazan.',

  // Ödül Bildirimleri
  'comment_reward_earned': 'Yorum yazdığın için +{xp} XP kazandın!',
  'comment_error': 'Yorum eklenirken bir hata oluştu',
  'comment_received_title': 'Yeni Yorum Aldın!',
  'comment_received_body':
      '{commenter} profiline yorum yazdı ve +{xp} XP kazandın!',

  // Dil Ayarları
  'language_settings': 'Dil Ayarları',
  'language_change_info':
      'Dil değişikliği anında uygulanır ve otomatik olarak kaydedilir.',
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
  'delete_account': 'Hesabımı Sil',
  'delete_account_confirmation':
      'Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
  // Başarı Bildirimleri
  'notification_task_completed_title': 'Yeni Görev Tamamlandı!',
  'notification_task_completed_body':
      '{task} görevini tamamladınız ve {xp} XP kazandınız.',
  'notification_xp_earned_title': 'XP Kazandınız!',
  'notification_xp_earned_body': '{task} görevinden {xp} XP kazandınız.',
  'notification_rank_up_title': 'Yeni Seviye!',
  'notification_rank_up_body':
      'Tebrikler! {xp} XP\'ye ulaştın ve artık bir {rank} {icon} oldun! Daha fazla keşfet ve liderliğe bir adım daha yaklaş!',
  'notification_premium_reward_title': 'Premium Ödül Kazandınız!',
  'notification_premium_reward_body':
      'Tebrikler! {xp} XP\'ye ulaştın ve 1 Haftalık Premium Üyelik kazandın! Keyfini çıkar! 🎉',
  'notification_next_premium_title': 'Durmak Yok!',
  'notification_next_premium_body':
      'Bir sonraki premium ödül için sadece {xp} XP kaldı! Hemen bir ilan oluştur ve mesaj gönder!',
  'notification_daily_task_reset_title': 'Günlük Görevler Sıfırlandı',
  'notification_daily_task_reset_body':
      'Günlük görevler sıfırlandı, yeni görevleri tamamlayarak XP kazanabilirsiniz.',
  'notification_xp_reset_title': 'XP Sıfırlandı',
  'notification_xp_reset_body':
      'XP\'niz sıfırlandı. Yeniden XP kazanmaya başlayabilirsiniz.',

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
  'total_xp': 'Toplam XP',
  'premium_rewards': 'Premium Ödülleri',
  'next_reward': 'Bir sonraki ödül',
  'max_level_reached': 'Maksimum seviyeye ulaştınız',
  'next_level': 'Bir sonraki seviye',

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
  'category_theater': 'Sinema ve Tiyatro',
  'category_other': 'Diğer',

  // Gender
  'gender_male': 'Erkek',
  'gender_female': 'Kadın',
  'gender_others': 'Diğer',

  // Rütbe/Ünvan çevirileri
  'rank_beginner': 'Keşfe Başlayan',
  'rank_explorer': 'Sosyal Keşifçi',
  'rank_connector': 'Bağlantı Ustası',
  'rank_leader': ' Etkinlik Lideri',
  'rank_master': 'Sosyal Usta',

  // Konum Sayfası
  'location_search_city_district': 'Şehir, İlçe Ara',
  'location_use_current': 'Mevcut Konumumu Kullan',

  // Profil - Günlük Görev
  'daily_task_next_reset_time': '24 saat',
  'daily_tasks_reset_success':
      'Günlük görevler sıfırlandı! Yeni görevleri tamamlayabilirsiniz.',

  // Rapor Etme
  'please_explain_reason': 'Lütfen şikayet nedeninizi açıklayın',
  'report_reason_hint': 'Şikayet nedeninizi buraya yazın...',
  'submit': 'Gönder',
  'cancel': 'İptal',

  // Sohbet
  'chats': 'Sohbetler',
  'no_chats_yet': 'Henüz sohbet bulunmuyor',
  'delete_chat': 'Sohbeti Sil',
  'delete_chat_confirmation': 'Bu sohbeti silmek istediğinize emin misiniz?',
  'chat_deleted': 'Sohbet başarıyla silindi',
  'user_not_found': 'Kullanıcı bulunamadı',

  // Yorum Şikayet
  'comment_reported_success': 'Yorum başarıyla şikayet edildi',
  'comment_report_error': 'Yorum şikayet edilirken bir hata oluştu',

  // Telefon Doğrulama
  'phone_verification': 'Telefon Doğrulama',
  'login_required': 'Önce oturum açmanız gerekiyor',
  'verify_your_phone': 'Telefon Numaranızı Doğrulayın',
  'verify_phone_subtitle':
      'Hesabınızı güvence altına almak için telefon numaranızı doğrulayın',
  'phone_number': 'Telefon Numarası',
  'phone_number_hint': '5XX XXX XX XX',
  'phone_number_info': 'Lütfen başında 0 olmadan girin (örn: 5XX XXX XX XX)',
  'send_verification_code': 'Doğrulama Kodu Gönder',
  'sending': 'Gönderiliyor...',
  'info': 'Bilgi',
  'sms_delay_info':
      'SMS kodunun gelmesi biraz zaman alabilir. Lütfen en az 2 dakika bekleyin.',
  'check_number_retry':
      'Kod gelmediyse numaranızı kontrol edip tekrar deneyin.',
  'enter_verification_code': 'Doğrulama Kodunu Girin',
  'enter_6_digit_code': 'Telefonunuza gönderilen 6 haneli kodu girin',
  'code_sent_to': 'Kod {phoneNumber} numarasına gönderildi',
  'verification_code': 'Doğrulama Kodu',
  'verification_code_hint': '6 haneli kod',
  'verify': 'Doğrula',
  'verifying': 'Doğrulanıyor...',
  'resend_code': 'Kodu Tekrar Gönder',
  'important': 'Önemli',
  'verification_in_progress':
      'Doğrulama işlemi devam ederken lütfen uygulamadan çıkmayın.',
  'resend_code_info':
      'Kod gelmediyse "Kodu Tekrar Gönder" butonuna tıklayabilirsiniz.',
  'verification_error': 'Doğrulama hatası oluştu',
  'invalid_phone_format': 'Geçersiz telefon numarası formatı',
  'too_many_requests':
      'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin',
  'quota_exceeded': 'SMS kotası aşıldı. Lütfen daha sonra tekrar deneyin',
  'captcha_failed': 'Captcha doğrulaması başarısız oldu. Tekrar deneyin',
  'app_not_authorized':
      'Uygulama Firebase Authentication kullanmaya yetkili değil',
  'understood': 'ANLADIM',
  'code_sent': 'Doğrulama kodu gönderildi',
  'please_enter_code': 'Lütfen doğrulama kodunu girin',
  'verification_id_not_found':
      'Doğrulama ID\'si bulunamadı. Lütfen tekrar deneyin.',
  'user_session_not_found': 'Kullanıcı oturumu bulunamadı',
  'phone_verified_success': 'Telefon numarası başarıyla doğrulandı',
  'phone_already_verified': 'Telefon numarası zaten doğrulanmış',
  'error_prefix': 'Hata: ',
  'please_enter_phone': 'Lütfen telefon numaranızı girin',
  'invalid_characters':
      'Geçersiz karakterler içeriyor (sadece rakam, + ve boşluk kullanın)',
  'phone_too_short': 'Telefon numarası çok kısa',
  'verification_in_progress_enter_code':
      'Doğrulama işlemi devam ediyor. Lütfen kodu girin veya işlemi tamamlayın.',

  // Yorum Sistemi
  'please_select_rating': 'Lütfen bir puan seçin',
  'please_write_comment': 'Lütfen bir yorum yazın',
  'profile_evaluation': 'Profil Değerlendirmesi',
  'max_50_characters': 'En fazla 50 karakter girebilirsiniz!',
  'write_your_comment': 'Yorumunuzu yazın...',
  'share': 'Paylaş',
  'no_comments_yet': 'Henüz yorum yapılmamış',
  'viewmodel_comments_debug': 'Yorumlar',
  'received_comment_debug': 'Alınan yorum',
  'comment_not_added_debug': 'Yorum eklenmedi',

  // XP Kartı
  'rank': 'Unvan',
  'level_progress': 'Seviye İlerlemesi',
  'to_next_level': 'Bir sonraki seviyeye',
  'earned_premium_rewards': 'Kazanılan Premium Ödüller',
  'to_next_premium': 'Bir sonraki premium ödüle',
  'premium_thresholds': 'Premium Eşikler',
  'total': 'Toplam',
};
