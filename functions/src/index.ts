import * as admin from "firebase-admin";
import {onDocumentCreated} from "firebase-functions/v2/firestore";

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

      const message = {
        token: notification.token,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: {
          type: notification.type,
          receiverId: notification.receiverId,
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
      console.log("Bildirim başarıyla gönderildi:", response);

      // Bildirim belgesini sil
      await event.data?.ref.delete();
    } catch (error) {
      console.error("Bildirim gönderme hatası:", error);
    }
  }
);
