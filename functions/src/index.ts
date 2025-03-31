import * as admin from "firebase-admin";
import {onDocumentCreated, onDocumentUpdated} from "firebase-functions/v2/firestore";
import {getNotificationContent} from "./notifications";
import {logger} from "firebase-functions/v2";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {onCall, HttpsError} from "firebase-functions/v2/https";

// Firebase'i başlat
admin.initializeApp();

// Yeni bildirim eklendiğinde tetiklenecek fonksiyon
export const sendNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    try {
      const notification = event.data?.data();

      if (!notification) {
        console.log("Bildirim verisi bulunamadı");
        return;
      }

      // Gerekli verileri al
      const receiverId = notification.receiverId;
      const notificationType = notification.type;
      const chatId = notification.chatId || "";
      const customerCollection = admin.firestore().collection("customers");
      const chatCollection = admin.firestore().collection("chats");


      console.log(`İşleniyor: ${notificationType} | Alıcı: ${receiverId}`);

      // Alıcının kullanıcı bilgilerini al
      const userDoc = await customerCollection.doc(receiverId).get();

      if (!userDoc.exists) {
        console.log("Alıcı kullanıcı bulunamadı:", receiverId);
        return;
      }

      const userData = userDoc.data();
      const userLang = userData?.languagePreference || "tr";
      const isPremium = userData?.isPremium === true;
      const token = userData?.fcmToken;

      // KULLANICI BİLGİLERİNİ LOGLAMA EKLEYELİM
      console.log("=== KULLANICI BİLGİLERİ ===");
      console.log(`ID: ${receiverId}`);
      console.log(`Dil: ${userLang}`);
      console.log(`Premium: ${isPremium}`);
      console.log(`FCM Token: ${token ? "Var" : "Yok"}`);
      console.log(`Tam Veri: ${JSON.stringify(userData, null, 2)}`);

      if (!token) {
        console.log("Kullanıcı FCM tokeni bulunamadı:", receiverId);
        return;
      }

      // Bildirim içeriğini belirle
      let title = "";
      let body = "";
      const data: Record<string, string> = {
        type: notificationType,
        receiverId: receiverId,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      };

      // Bildirim tipini loglayalım
      console.log("=== BİLDİRİM BİLGİLERİ ===");
      console.log(`Bildirim Tipi: ${notificationType}`);
      console.log(`Tüm Bildirim Verisi: ${JSON.stringify(notification, null, 2)}`);

      // Bildirime göre özel işlemler
      if (notificationType === "message" && chatId) {
        // Sohbet için özel işlemler
        try {
          // Sohbet bilgilerini al
          const chatDoc = await chatCollection.doc(chatId).get();

          const chatData = chatDoc.data();
          const lastMessage = chatData?.lastMessage || "";

          // Gönderici bilgilerini al
          const senderId = chatData?.lastMessageSenderId || "";
          const senderDoc = await customerCollection.doc(senderId).get();

          const senderData = senderDoc.data();
          const senderName = senderData?.firstName || "Kullanıcı";

          // Mesaj içeriğini düzenle (çok uzunsa kısalt)
          let messageText = lastMessage || "";
          if (lastMessage.length > 50) {
            messageText = messageText.substring(0, 47) + "...";
          }

          // Standart mesaj içeriğini al
          const {title: baseTitle} = getNotificationContent("message", userLang, isPremium);

          // Değişkenleri yerine koy
          title = baseTitle;
          body = senderName + ": " + messageText;

          // Ek veriler
          data.chatId = chatId;
          data.senderId = senderId;
          data.receiverId = receiverId;
        } catch (error) {
          console.log("Mesaj bilgisi alınamadı:", error);
          // Hata durumunda varsayılan mesaj kullan
          const fallbackContent = getNotificationContent("message", userLang, isPremium);
          title = fallbackContent.title;
          body = fallbackContent.body;
        }
      } else {
        // Bildirim içeriğini al
        try {
          // notifications.ts modülünden içeriği al
          const {title: contentTitle, body: contentBody} = getNotificationContent(notificationType, userLang, isPremium);
          title = contentTitle;
          body = contentBody;

          // Elde edilen içeriği logla
          console.log("=== OLUŞTURULAN BİLDİRİM İÇERİĞİ ===");
          console.log(`Başlık: "${title}"`);
          console.log(`İçerik: "${body}"`);
        } catch (error) {
          console.error("Bildirim içeriği oluşturulurken hata:", error);
          title = "Yeni Bildirim";
          body = "Bildiriminiz var";
        }
      }

      // FCM mesajını oluştur
      const message = {
        token: token,
        notification: {
          title: title,
          body: body,
        },
        data: data,
        android: {
          priority: "high" as const,
          notification: {
            sound: "default",
            priority: "high" as const,
            channelId: "messages",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
              contentAvailable: true,
            },
          },
        },
      };

      // Bildirimi gönder
      const response = await admin.messaging().send(message);
      console.log("Bildirim başarıyla gönderildi:", response);

      // Bildirim belgesini sil (opsiyonel)
      await event.data?.ref.delete();
    } catch (error) {
      console.error("Bildirim gönderme hatası:", error);
    }
  }
);

/**
 * Customers koleksiyonundaki profileViewers array'i veya comments map'i değiştiğinde
 * direkt bildirim gönderen fonksiyon
 */
export const onCustomerProfileViewed = onDocumentUpdated("customers/{userId}", async (event) => {
  try {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();
    const userId = event.params.userId;

    if (!beforeData || !afterData) {
      logger.info(`Belge bulunamadı veya silindi: ${userId}`);
      return null;
    }

    // Kullanıcı bilgilerini al
    const userDoc = await admin.firestore().collection("customers").doc(userId).get();
    if (!userDoc.exists) {
      logger.error("Kullanıcı bulunamadı:", userId);
      return null;
    }

    const userData = userDoc.data();
    const token = userData?.fcmToken;
    const userLang = userData?.languagePreference || "tr";
    const isPremium = userData?.isPremium === true;

    if (!token) {
      logger.error("Kullanıcı FCM tokeni bulunamadı:", userId);
      return null;
    }

    // 1. profileViewers array'ini kontrol et
    const beforeViewers = beforeData.profileViewers || [];
    const afterViewers = afterData.profileViewers || [];

    // Yeni görüntüleyenler varsa
    if (afterViewers.length > beforeViewers.length) {
      // Yeni görüntüleyenleri bul
      const newViewers = afterViewers.filter((viewer: string) => !beforeViewers.includes(viewer));

      if (newViewers.length > 0) {
        logger.info(`${userId} kullanıcısının profili ${newViewers.length} yeni kişi tarafından görüntülendi`);

        // Bildirim içeriğini al
        const {title, body} = getNotificationContent("profileViewed", userLang, isPremium);

        // FCM mesajını oluştur
        const message = {
          token: token,
          notification: {
            title: title,
            body: body,
          },
          data: {
            type: "profileViewed",
            viewerCount: newViewers.length.toString(),
            viewerIds: JSON.stringify(newViewers),
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            priority: "high" as const,
            notification: {
              sound: "default",
              priority: "high" as const,
              channelId: "messages",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
                contentAvailable: true,
              },
            },
          },
        };

        // Bildirimi direkt gönder
        const response = await admin.messaging().send(message);
        logger.info("Profil görüntüleme bildirimi gönderildi:", response);
      }
    }

    // 2. comments map'ini kontrol et
    const beforeComments = beforeData.comments || {};
    const afterComments = afterData.comments || {};

    // Yeni yorum var mı kontrol et
    const beforeCommentKeys = Object.keys(beforeComments);
    const afterCommentKeys = Object.keys(afterComments);

    if (afterCommentKeys.length > beforeCommentKeys.length) {
      // Yeni yorumları bul
      const newCommentKeys = afterCommentKeys.filter((key) => !beforeCommentKeys.includes(key));

      if (newCommentKeys.length > 0) {
        logger.info(`${userId} kullanıcısına ${newCommentKeys.length} yeni yorum yapıldı`);

        // Bildirim içeriğini al
        const {title, body} = getNotificationContent("comment", userLang, isPremium);

        // Son yorumu al
        const lastCommentKey = newCommentKeys[newCommentKeys.length - 1];
        const lastComment = afterComments[lastCommentKey];

        // FCM mesajını oluştur
        const message = {
          token: token,
          notification: {
            title: title,
            body: body,
          },
          data: {
            type: "comment",
            commentCount: newCommentKeys.length.toString(),
            commentIds: JSON.stringify(newCommentKeys),
            lastCommentId: lastCommentKey,
            lastCommentText: lastComment.text || "",
            lastCommentUserId: lastComment.userId || "",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            priority: "high" as const,
            notification: {
              sound: "default",
              priority: "high" as const,
              channelId: "messages",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
                contentAvailable: true,
              },
            },
          },
        };

        // Bildirimi direkt gönder
        const response = await admin.messaging().send(message);
        logger.info("Yorum bildirimi gönderildi:", response);
      }
    }

    return null;
  } catch (error) {
    logger.error("Bildirim gönderme hatası:", error);
    return null;
  }
});

/**
 * Adverts koleksiyonundaki likes array'i değiştiğinde
 * direkt bildirim gönderen fonksiyon
 */
export const onAdvertLiked = onDocumentUpdated("events/{eventId}", async (event) => {
  try {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();
    const eventId = event.params.eventId;

    if (!beforeData || !afterData) {
      logger.info(`Belge bulunamadı veya silindi: ${eventId}`);
      return null;
    }

    // likes array'ini kontrol et
    const beforeLikes = beforeData.likers || [];
    const afterLikes = afterData.likers || [];

    // Yeni beğeniler varsa
    if (afterLikes.length > beforeLikes.length) {
      // Yeni beğenenleri bul
      const newLikes = afterLikes.filter((liker: string) => !beforeLikes.includes(liker));

      if (newLikes.length > 0) {
        logger.info(`${eventId} etkinliği ${newLikes.length} yeni kişi tarafından beğenildi`);

        // İlan sahibinin ID'sini al
        const creatorId = afterData.creatorUserID;
        if (!creatorId) {
          logger.error("İlan sahibi ID'si bulunamadı:", eventId);
          return null;
        }

        // Kullanıcı bilgilerini al
        const userDoc = await admin.firestore().collection("customers").doc(creatorId).get();
        if (!userDoc.exists) {
          logger.error("Kullanıcı bulunamadı:", creatorId);
          return null;
        }

        const userData = userDoc.data();
        const token = userData?.fcmToken;
        const userLang = userData?.languagePreference || "tr";
        const isPremium = userData?.isPremium === true;

        if (!token) {
          logger.error("Kullanıcı FCM tokeni bulunamadı:", creatorId);
          return null;
        }

        // Bildirim içeriğini al
        const {title, body} = getNotificationContent("likeAdvert", userLang, isPremium);

        // FCM mesajını oluştur
        const message = {
          token: token,
          notification: {
            title: title,
            body: body,
          },
          data: {
            type: "likeAdvert",
            eventId: eventId,
            likeCount: newLikes.length.toString(),
            likerIds: JSON.stringify(newLikes),
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            priority: "high" as const,
            notification: {
              sound: "default",
              priority: "high" as const,
              channelId: "messages",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
                contentAvailable: true,
              },
            },
          },
        };

        // Bildirimi direkt gönder
        const response = await admin.messaging().send(message);
        logger.info("İlan beğeni bildirimi gönderildi:", response);
      }
    }

    return null;
  } catch (error) {
    logger.error("Bildirim gönderme hatası:", error);
    return null;
  }
});

/**
 * Yeni bir ilan eklendiğinde, ilgili kullanıcılara bildirim gönderen fonksiyon
 * - Kullanıcının şehrine göre bildirim
 * - Kullanıcının ilgi alanlarına göre bildirim
 */
export const onNewAdvertCreated = onDocumentCreated("events/{eventId}", async (event) => {
  try {
    const advertData = event.data?.data();
    const eventId = event.params.eventId;

    if (!advertData) {
      logger.info(`Yeni ilan verisi bulunamadı: ${eventId}`);
      return null;
    }

    // İlan bilgilerini al
    const advertCity = advertData.location?.city;
    const advertCategory = advertData.advertType;
    const creatorId = advertData.creatorUserID;

    if (!advertCity || !advertCategory || !creatorId) {
      logger.error("İlan bilgileri eksik:", eventId);
      return null;
    }

    logger.info(`Yeni ilan oluşturuldu: ${eventId}, Şehir: ${advertCity}, Kategori: ${advertCategory}`);

    // Bildirim gönderilecek kullanıcıları bul
    const customersRef = admin.firestore().collection("customers");

    // 1. Aynı şehirdeki kullanıcıları bul (index gerektirmeyen basit sorgu)
    const cityQuery = await customersRef
      .where("location.city", "==", advertCity)
      .get();

    // 2. İlgili kategoriye ilgi duyan kullanıcıları bul (index gerektirmeyen basit sorgu)
    const categoryQuery = await customersRef
      .where("favoriteCategories", "array-contains", advertCategory)
      .get();

    // Bildirim gönderilecek kullanıcıları birleştir (tekrarları önle)
    const notifiedUserIds = new Set<string>();
    const cityUsers: FirebaseFirestore.DocumentData[] = [];
    const categoryUsers: FirebaseFirestore.DocumentData[] = [];

    // İlan sahibini Set'e ekleyerek bildirim almasını engelle
    // (Aşağıdaki kontrollerde Set'te olan kullanıcılar listeye eklenmeyecek)
    notifiedUserIds.add(creatorId);

    // Şehir bazlı kullanıcıları ekle
    cityQuery.forEach((doc) => {
      const userId = doc.id;
      const userData = doc.data();
      // FCM token kontrolünü burada yap
      if (!notifiedUserIds.has(userId) && userData.fcmToken) {
        notifiedUserIds.add(userId);
        cityUsers.push({id: userId, data: userData});
      }
    });

    // Kategori bazlı kullanıcıları ekle
    categoryQuery.forEach((doc) => {
      const userId = doc.id;
      const userData = doc.data();
      // FCM token kontrolünü burada yap
      if (!notifiedUserIds.has(userId) && userData.fcmToken) {
        notifiedUserIds.add(userId);
        categoryUsers.push({id: userId, data: userData});
      }
    });

    logger.info(`Bildirim gönderilecek kullanıcı sayısı: Şehir: ${cityUsers.length}, Kategori: ${categoryUsers.length}`);

    // Şehir bazlı bildirimleri gönder
    for (const user of cityUsers) {
      try {
        const userData = user.data;
        const token = userData.fcmToken;
        const userLang = userData.languagePreference || "tr";
        const isPremium = userData.isPremium === true;

        if (!token) continue;

        // Bildirim içeriğini al
        const {title, body} = getNotificationContent("newAdvertInCity", userLang, isPremium);

        // FCM mesajını oluştur
        const message = {
          token: token,
          notification: {
            title: title,
            body: body,
          },
          data: {
            type: "newAdvertInCity",
            eventId: eventId,
            city: advertCity,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            priority: "high" as const,
            notification: {
              sound: "default",
              priority: "high" as const,
              channelId: "messages",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
                contentAvailable: true,
              },
            },
          },
        };

        // Bildirimi gönder
        await admin.messaging().send(message);
        logger.info(`Şehir bildirimi gönderildi: ${user.id}`);
      } catch (error) {
        logger.error(`Şehir bildirimi gönderilirken hata: ${user.id}`, error);
      }
    }

    // Kategori bazlı bildirimleri gönder
    for (const user of categoryUsers) {
      try {
        const userData = user.data;
        const token = userData.fcmToken;
        const userLang = userData.languagePreference || "tr";
        const isPremium = userData.isPremium === true;

        if (!token) continue;

        // Bildirim içeriğini al
        const {title, body} = getNotificationContent("newAdvertInInterestArea", userLang, isPremium);

        // FCM mesajını oluştur
        const message = {
          token: token,
          notification: {
            title: title,
            body: body,
          },
          data: {
            type: "newAdvertInInterestArea",
            eventId: eventId,
            category: advertCategory,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            priority: "high" as const,
            notification: {
              sound: "default",
              priority: "high" as const,
              channelId: "messages",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
                contentAvailable: true,
              },
            },
          },
        };

        // Bildirimi gönder
        await admin.messaging().send(message);
        logger.info(`Kategori bildirimi gönderildi: ${user.id}`);
      } catch (error) {
        logger.error(`Kategori bildirimi gönderilirken hata: ${user.id}`, error);
      }
    }

    return null;
  } catch (error) {
    logger.error("Yeni ilan bildirimi gönderme hatası:", error);
    return null;
  }
});

/**
 * Chats koleksiyonundaki bir belge güncellendiğinde tetiklenen fonksiyon
 * Yeni mesaj geldiğinde alıcıya bildirim gönderir
 */
export const onNewMessage = onDocumentUpdated("chats/{chatId}", async (event) => {
  try {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();
    const chatId = event.params.chatId;

    if (!beforeData || !afterData) {
      logger.info(`Sohbet belgesi bulunamadı veya silindi: ${chatId}`);
      return null;
    }

    // Yeni mesaj var mı kontrol et
    const beforeLastMessageTime = beforeData.lastMessageTime?.toMillis() || 0;
    const afterLastMessageTime = afterData.lastMessageTime?.toMillis() || 0;

    // Yeni mesaj yoksa işlem yapma
    if (afterLastMessageTime <= beforeLastMessageTime) {
      return null;
    }

    // Mesaj bilgilerini al
    const lastMessage = afterData.lastMessage || "";
    const lastMessageSenderId = afterData.lastMessageSenderId || "";
    const receiverId = afterData.participants?.find((id: string) => id !== lastMessageSenderId);

    if (!lastMessageSenderId || !receiverId) {
      logger.error("Mesaj gönderen veya alıcı ID'si bulunamadı:", chatId);
      return null;
    }

    logger.info(`Yeni mesaj: ${chatId}, Gönderen: ${lastMessageSenderId}, Alıcı: ${receiverId}`);

    // Alıcı ve gönderen bilgilerini al
    const [receiverDoc, senderDoc] = await Promise.all([
      admin.firestore().collection("customers").doc(receiverId).get(),
      admin.firestore().collection("customers").doc(lastMessageSenderId).get(),
    ]);

    if (!receiverDoc.exists) {
      logger.error("Alıcı kullanıcı bulunamadı:", receiverId);
      return null;
    }

    if (!senderDoc.exists) {
      logger.error("Gönderen kullanıcı bulunamadı:", lastMessageSenderId);
      return null;
    }

    const receiverData = receiverDoc.data();
    const senderData = senderDoc.data();
    const token = receiverData?.fcmToken;
    const userLang = receiverData?.languagePreference || "tr";
    const isPremium = receiverData?.isPremium === true;
    const senderName = senderData?.firstName || "Kullanıcı";

    if (!token) {
      logger.error("Alıcı FCM tokeni bulunamadı:", receiverId);
      return null;
    }

    // Mesaj içeriğini düzenle (çok uzunsa kısalt)
    let messageText = lastMessage || "";
    if (messageText.length > 50) {
      messageText = messageText.substring(0, 47) + "...";
    }

    // Bildirim içeriğini al
    const {title} = getNotificationContent("message", userLang, isPremium);
    const body = senderName + ": " + messageText;

    // FCM mesajını oluştur
    const message = {
      token: token,
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: "message",
        chatId: chatId,
        senderId: lastMessageSenderId,
        receiverId: receiverId,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high" as const,
        notification: {
          sound: "default",
          priority: "high" as const,
          channelId: "messages",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
            contentAvailable: true,
          },
        },
      },
    };

    // Bildirimi direkt gönder
    const response = await admin.messaging().send(message);
    logger.info("Mesaj bildirimi gönderildi:", response);

    return null;
  } catch (error) {
    logger.error("Mesaj bildirimi gönderme hatası:", error);
    return null;
  }
});

/**
 * Her gün belirli bir saatte (örneğin sabah 9:00'da) tüm kullanıcılara bildirim gönderir
 * Türkiye saat dilimine göre ayarlanmış (Europe/Istanbul)
 */
export const sendDailyNotification = onSchedule({
  schedule: "0 9 * * *", // Her gün sabah 9:00'da çalışır (cron formatı)
  timeZone: "Europe/Istanbul", // Türkiye saat dilimi
}, async () => {
  try {
    logger.info("=== GÜNLÜK BİLDİRİM FONKSİYONU BAŞLADI ===");

    // Aktif FCM tokeni olan tüm kullanıcıları getir
    const usersSnapshot = await admin.firestore()
      .collection("customers")
      .where("fcmToken", "!=", "")
      .get();

    // Kullanıcı sayısını log'a yaz
    logger.info(`${usersSnapshot.size} kullanıcı bildirimi alacak`);

    if (usersSnapshot.empty) {
      logger.warn("Aktif token'a sahip kullanıcı bulunamadı");
      return;
    }

    // Toplu bildirim gönderimi için batch hazırla
    const batchSize = 500; // Firebase bir seferde maksimum 500 mesaj gönderilebilir
    const messages: admin.messaging.Message[] = [];

    // Tüm kullanıcılara bildirim için döngü
    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      const token = userData.fcmToken;
      const userLang = userData.languagePreference || "tr";

      if (!token) continue; // Token yoksa atla

      // "dailyTask" tipi bildirimin içeriğini al
      const {title, body} = getNotificationContent("dailyTask", userLang);

      // FCM bildirim mesajını oluştur
      const message: admin.messaging.Message = {
        token: token,
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: "dailyTask",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high" as const,
          notification: {
            sound: "default",
            priority: "high" as const,
            channelId: "messages",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
              contentAvailable: true,
            },
          },
        },
      };

      messages.push(message);

      // Batch limitine ulaşıldığında gönder
      if (messages.length === batchSize) {
        await sendBatchMessages(messages);
        messages.length = 0; // Array'i temizle
      }
    }

    // Kalan mesajları gönder
    if (messages.length > 0) {
      await sendBatchMessages(messages);
    }

    logger.info("=== GÜNLÜK BİLDİRİM FONKSİYONU TAMAMLANDI ===");
    return;
  } catch (error) {
    logger.error("Günlük bildirim gönderme hatası:", error);
    return;
  }
});

/**
 * Bildirimleri toplu olarak gönderen yardımcı fonksiyon
 * @param {admin.messaging.Message[]} messages - Gönderilecek bildirim mesajları
 */
async function sendBatchMessages(messages: admin.messaging.Message[]) {
  if (messages.length === 0) return;

  try {
    logger.info(`${messages.length} bildirim gönderiliyor...`);
    const response = await admin.messaging().sendEach(messages);
    logger.info(`${response.successCount} bildirim başarıyla gönderildi, ${response.failureCount} başarısız oldu`);

    if (response.failureCount > 0) {
      const failedMessages = response.responses.filter((resp, _) => resp.error);
      logger.warn(`Hatalı bildirimler: ${JSON.stringify(failedMessages)}`);
    }
  } catch (error) {
    logger.error("Toplu bildirim gönderme hatası:", error);
  }
}

/**
 * Tüm kullanıcılara doğrudan bildirim gönderen fonksiyon
 */
export const sendBroadcastNotification = onCall({
  maxInstances: 10,
}, async (request) => {
  try {
    // Bildirim verilerini al
    const {title, body, onlyIos, onlyAndroid} = request.data as {
      title: string;
      body: string;
      onlyIos: boolean;
      onlyAndroid: boolean;
    };

    logger.info("=== BROADCAST BİLDİRİM BAŞLADI ===");
    logger.info(`Başlık: ${title}`);
    logger.info(`İçerik: ${body}`);
    logger.info(`Sadece iOS: ${onlyIos}`);
    logger.info(`Sadece Android: ${onlyAndroid}`);

    // Platform koşulunu belirle
    let condition = "'all-users' in topics";

    if (onlyIos && !onlyAndroid) {
      condition = "'ios' in topics";
    } else if (!onlyIos && onlyAndroid) {
      condition = "'android' in topics";
    }

    // FCM mesajını oluştur
    const message = {
      condition: condition,
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: "broadcast",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high" as const,
        notification: {
          sound: "default",
          priority: "high" as const,
          channelId: "messages",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
            contentAvailable: true,
          },
        },
      },
    };

    // Bildirimi gönder
    const response = await admin.messaging().send(message);
    logger.info("Broadcast bildirimi gönderildi:", response);

    logger.info("=== BROADCAST BİLDİRİM TAMAMLANDI ===");

    return {success: true, messageId: response};
  } catch (error) {
    logger.error("Broadcast bildirim gönderme hatası:", error);
    throw new HttpsError(
      "internal",
      "Bildirim gönderilirken bir hata oluştu.",
      error
    );
  }
});
