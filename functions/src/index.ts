import * as admin from "firebase-admin";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {getNotificationContent} from "./notifications";

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
