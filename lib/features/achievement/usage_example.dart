import 'package:palseapp/features/achievement/achievements.dart';
import 'package:palseapp/features/achievement/achievement_manager.dart';

/// Bu dosya, XP sistemini nasıl kullanacağınızı gösteren bir örnek içerir.
/// Kullanım örnekleri ve notlar burada bulunmaktadır.

/* ÖRNEK KULLANIM:

// Herhangi bir sınıfta XP kazandırmak için:
class SomeService with XpInterface {
  void createListing() {
    // İş mantığı...
    
    // XP kazandır
    earnXp(XpEvent.createListing);
  }
  
  void sendMessage() {
    // İş mantığı...
    
    // XP kazandır
    earnXp(XpEvent.sendMessage);
  }
  
  void checkDailyTask() {
    // Günlük görev tamamlandı mı kontrol et
    if (!isDailyTaskCompletedToday()) {
      // Henüz tamamlanmamış, kullanıcıya göster
    }
  }
}

// Uygulama başlatılırken:
void initializeAchievements() {
  // Veritabanından kullanıcının mevcut başarılarını yükle
  UserAchievements userAchievements = loadUserAchievementsFromDb();
  
  // Achievement Manager'ı başlat
  AchievementManager().initialize(userAchievements);
  
  // Günlük görev zamanlayıcısını başlat
  DailyTaskScheduler().startScheduler();
}

// Kullanıcının XP kazanımlarını dinlemek için:
void listenToXpChanges() {
  AchievementManager().addListener((achievements) {
    // Kullanıcı arayüzünü güncelle
    updateUI(achievements);
    
    // Veritabanını güncelle
    saveUserAchievementsToDb(achievements);
  });
}

// Kullanıcı profil ekranında seviye ve XP bilgilerini göstermek için:
Widget buildProfileXpInfo(BuildContext context) {
  final achievements = AchievementManager().userAchievements;
  
  return Column(
    children: [
      Text('Unvan: ${achievements.rank.getLocalizedTitle(context)}'),
      Text('XP: ${achievements.totalXp}'),
      Text('Bir sonraki seviyeye: ${achievements.xpToNextRank} XP'),
      LinearProgressIndicator(
        value: achievements.progressPercentage,
      ),
    ],
  );
}

*/

/// Not:
/// 1. XP kazandırmak için XpInterface mixin'ini kullanın
/// 2. XP kazandırmak istediğinizde earnXp(XpEvent.eventName) metodunu çağırın
/// 3. Kullanıcı durumunu izlemek için AchievementManager().addListener kullanın
/// 4. Günlük görevlerin sıfırlanması için DailyTaskScheduler().startScheduler() çağırın

/// ÖRNEK UYGULAMA - AŞAĞIDAKİ KOD GERÇEK KULLANIM İÇİN BİR ŞABLONDUR

/// Kullanım örneği - Bu sınıf mixin kullanarak XP kazanma yeteneğine sahip olur
class ProfileService with XpInterface {
  /// Kullanıcı yeni bir ilan oluşturduğunda
  void createNewListing() {
    // Uygulamanın ilan oluşturma işlemleri...

    // İlk ilan mı kontrol et
    if (!isTaskCompleted(XpEvent.firstListing)) {
      // İlk ilan ise, ilk ilan ödülü ver
      earnXp(XpEvent.firstListing);
    }

    // Her ilan oluşturma için XP ver
    earnXp(XpEvent.createListing);

    // Günlük görev için kontrol et
    checkDailyListingTask();
  }

  /// Kullanıcı bir mesaj gönderdiğinde
  void sendMessageToUser(String userId) {
    // Uygulamanın mesaj gönderme işlemleri...

    // İlk mesaj mı kontrol et
    if (!isTaskCompleted(XpEvent.firstMessage)) {
      // İlk mesaj ise, ilk mesaj ödülü ver
      earnXp(XpEvent.firstMessage);
    }

    // Mesaj gönderme ödülü ver
    earnXp(XpEvent.sendMessage);
  }

  /// Kullanıcı bir yorum yazdığında
  void writeCommentToUser(String userId) {
    // Uygulamanın yorum yazma işlemleri...

    // Yorum yazma ödülü ver
    earnXp(XpEvent.writeComment);
  }

  /// Kullanıcı uygulamaya giriş yaptığında
  void userLoggedIn() {
    // Günlük giriş için XP ver
    earnXp(XpEvent.dailyLogin);
  }

  /// Günlük görev için ilan oluşturma ve mesaj gönderme kontrolü
  void checkDailyListingTask() {
    // Günlük görev tamamlanmamışsa kontrol et
    if (!isDailyTaskCompletedToday()) {
      // Kullanıcı hem ilan oluşturdu hem de mesaj gönderdi mi?
      // Burada daha karmaşık bir kontrol yapılabilir
      earnXp(XpEvent.dailyTaskCreateListingAndMessage);
    }
  }
}
