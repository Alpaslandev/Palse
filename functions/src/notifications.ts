// Bildirim mesajları için tip tanımlamaları
export interface MessageTemplate {
  [key: string]: string;
}

export interface MessageVariants {
  premium?: MessageTemplate;
  nonPremium?: MessageTemplate;
  normal?: MessageTemplate;
  fallback?: MessageTemplate;
}

export interface NotificationContent {
  title: MessageTemplate;
  body: MessageVariants;
}

export interface NotificationMessages {
  [key: string]: NotificationContent;
}

// Bildirim mesajlarını çoklu dil desteği ile tanımlama
export const notificationMessages: NotificationMessages = {
  likeAdvert: {
    title: {
      tr: "Harika!",
      en: "Awesome!",
    },
    body: {
      premium: {
        tr: "💖 İlanınız beğenildi! Kimin beğendiğini görmek için ✨ premium üye olun.",
        en: "💖 Your advert was liked! Become a ✨ premium member to see who liked it.",
      },
      nonPremium: {
        tr: "💖 İlanınız beğenildi! Beğenenleri görmek için tıklayın.",
        en: "💖 Your advert was liked! Click to see who liked it.",
      },
    },
  },
  comment: {
    title: {
      tr: "Dikkatler Üzerinde!",
      en: "You're in the Spotlight!",
    },
    body: {
      nonPremium: {
        tr: "Profiline yorum yapıldı! Hemen görüntüle",
        en: "Someone commented on your profile! View now",
      },
    },
  },
  newAdvertInCity: {
    title: {
      tr: "Yalnız Değilsin!",
      en: "You're Not Alone!",
    },
    body: {
      nonPremium: {
        tr: "🏙️ Şehrinizde harika bir ilan eklendi, hemen göz atın! 👀",
        en: "🏙️ An awesome advert was added in your city, check it out now! 👀",
      },
    },
  },
  newAdvertInInterestArea: {
    title: {
      tr: "Aradığını Buldun!",
      en: "Found What You're Looking For!",
    },
    body: {
      nonPremium: {
        tr: "✨ İlgi alanınıza hitap eden yepyeni bir ilan var! Hadi, kaçırmadan inceleyin! 🔍",
        en: "✨ There's a brand new advert in your area of interest! Don't miss it, check it out now! 🔍",
      },
    },
  },
  message: {
    title: {
      tr: "Yeni Mesaj",
      en: "New Message",
    },
    body: {
      normal: {
        tr: "{senderName}: {messageText}",
        en: "{senderName}: {messageText}",
      },
      fallback: {
        tr: "Yeni bir mesajınız var",
        en: "You have a new message",
      },
    },
  },
  dailyTask: {
    title: {
      tr: "Günlük Görevler",
      en: "Daily Tasks",
    },
    body: {
      nonPremium: {
        tr: "Bugün Palse'de XP kazanma zamanı! Bir ilan oluştur ve bir mesaj gönder, +100 XP senin olsun! 🎯",
        en: "Time to earn XP on Palse today! Create an advert and send a message to get +100 XP! 🎯",
      },
    },
  },
  dailyTaskCompleted: {
    title: {
      tr: "Görevler Tamamlandı",
      en: "Tasks Completed",
    },
    body: {
      nonPremium: {
        tr: "Günlük görevlerin tamamlandı! +100 XP kazandın! 🎉",
        en: "Your daily tasks are completed! You earned +100 XP! 🎉",
      },
    },
  },
  welcomeNotification: {
    title: {
      tr: "Çaylak!",
      en: "Rookie!",
    },
    body: {
      nonPremium: {
        tr: "Hoş geldin! İlk ilanını oluştur ve ilk mesajını gönder, toplam 1000 XP kazan! 🎉",
        en: "Welcome! Create your first advert and send your first message to earn 1000 XP! 🎉",
      },
    },
  },
  messageFromOldFriend: {
    title: {
      tr: "Özledik!",
      en: "Missed You!",
    },
    body: {
      nonPremium: {
        tr: "Uzun zamandır görüşmedik! Giriş yap ve bir mesaj gönder, hemen +35 XP kazan!",
        en: "We haven't seen you in a while! Log in and send a message to earn +35 XP!",
      },
    },
  },
};

// Bildirim için içerik seçme yardımcı fonksiyonu
export function getNotificationContent(
  notificationType: string,
  userLang = "tr",
  isPremium = false
): { title: string, body: string } {
  const notificationConfig = notificationMessages[notificationType];

  if (!notificationConfig) {
    return {
      title: "Yeni Bildirim",
      body: "Bildiriminiz var",
    };
  }

  // Premium kullanıcılar için farklı mesaj varsa kullan
  const messageType = isPremium && notificationConfig.body.premium ?
    "premium" :
    notificationConfig.body.nonPremium ?
      "nonPremium" :
      "normal";

  // Title ve body seç
  const title = notificationConfig.title[userLang] || notificationConfig.title.tr || "Yeni Bildirim";
  const body = notificationConfig.body[messageType]?.[userLang] ||
             notificationConfig.body.nonPremium?.[userLang] ||
             notificationConfig.body.normal?.[userLang] ||
             notificationConfig.body.fallback?.[userLang] ||
             notificationConfig.body.fallback?.tr ||
             "Yeni bildiriminiz var";

  return {title, body};
}
