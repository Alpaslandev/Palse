// functions/src/match/getSmartMatches.ts
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getFirestore, Timestamp} from "firebase-admin/firestore";

const db = getFirestore();


const getAge = (birthday?: Timestamp) => {
  if (!birthday) return null;
  const birth = birthday.toDate();
  const today = new Date();
  let age = today.getFullYear() - birth.getFullYear();
  const m = today.getMonth() - birth.getMonth();
  if (m < 0 || (m === 0 && today.getDate() < birth.getDate())) age--;
  return age;
};

export const getSmartMatches = onCall({enforceAppCheck: true}, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Kullanıcı girişi gerekli.");

  /* Kullanıcı verisi */
  const userSnap = await db.collection("users").doc(uid).get();
  if (!userSnap.exists) throw new HttpsError("not-found", "Kullanıcı bulunamadı.");
  const user = userSnap.data();

  const isPremium = user?.isPremium === true;

  /* Haftalık limit kontrolü */
  const now = new Date();
  const startOfWeek = new Date(now);
  startOfWeek.setDate(now.getDate() - now.getDay()); // Pazartesi
  startOfWeek.setHours(0, 0, 0, 0);

  const weeklyMatchCount = await db
    .collection("users")
    .doc(uid)
    .collection("matches")
    .where("matchedAt", ">=", startOfWeek)
    .count()
    .get();

  if (!isPremium && weeklyMatchCount.data().count >= 5) {
    throw new HttpsError("resource-exhausted", "Haftalık 5 eşleşme hakkınızı kullandınız.");
  }

  /* Mevcut eşleşmeleri getir ve ID'lerini bir sete at */
  const existingMatchesSnap = await db.collection("users").doc(uid).collection("matches").get();
  const existingMatchIds = new Set(existingMatchesSnap.docs.map((doc) => doc.id));


  /* Adayları getir (Şehir filtresi olmadan, daha geniş havuz) */
  const candidatesSnap = await db
    .collection("users")
    // .where('uid', '!=', uid) // doc.id ile kontrol daha verimli
    .limit(300) // Performans ve maliyet için limit geri eklendi
    .get();

  const userAge = getAge(user?.birthday);
  const userFavCats = (Array.isArray(user?.favoriteCategories) ? user?.favoriteCategories : []) as string[];
  const userCity = user?.location?.city ?? null;
  const userGender = user?.gender ?? null;

  /* Skorlama */
  const scored = candidatesSnap.docs
    .filter((doc) => doc.id !== uid && !existingMatchIds.has(doc.id)) // Kendini ve daha önce eşleşmiş olanları hariç tut
    .map((doc) => {
      const c = doc.data();
      let score = 0;

      // 1) Konum Puanlaması (Aynı şehir öncelikli)
      if (userCity && c.location?.city === userCity) {
        score += 40;
      }

      // 2) Cinsiyet Puanlaması (Karşı cinsiyet öncelikli)
      if (userGender && c.gender && c.gender !== userGender) {
        score += 30;
      }

      // 3) Favori kategori örtüşmeleri (Puanı artırıldı)
      if (Array.isArray(c.favoriteCategories)) {
        const common = c.favoriteCategories.filter((cat: string) => userFavCats.includes(cat));
        score += common.length * 15; // her ortak kategori 15 puan
      }

      // 4) Yaş yakınlığı
      const candAge = getAge(c.birthday);
      if (candAge !== null && userAge !== null) {
        const diff = Math.abs(candAge - userAge);
        if (diff <= 2) score += 25;
        else if (diff <= 5) score += 15;
        else if (diff <= 10) score += 5;
      }

      // 5) Doğrulanmış hesap mı? (Daha güvenli kontrol)
      if (c.verification === true) score += 15;
      if (user?.verification === true && c.verification === true) score += 10; // İkisi de verified ise ekstra

      return {uid: doc.id, score, name: c.name, photoUrl: c.photoUrl};
    });

  // Puanlamaya göre teorik olarak ulaşılabilecek maksimum skor.
  // Konum(40) + Cinsiyet(30) + Kategori(3*15=45) + Yaş(25) + Doğrulama(25) = 165
  const maxScore = 165;

  /* En yüksek 5 skoru seç, yüzdeye çevir ve null kontrolü yap */
  const top5 = scored
    .filter((m) => m.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, 5)
    .map((m) => ({
      uid: m.uid,
      name: m.name ?? null,
      photoUrl: m.photoUrl ?? null,
      score: Math.round((m.score / maxScore) * 100), // Puanı yüzdeye çevir
    }));

  /* Kaydet */
  const batch = db.batch();
  top5.forEach((m) => {
    const ref = db.collection("users").doc(uid).collection("matches").doc(m.uid);
    batch.set(ref, {
      matchedUserId: m.uid,
      matchedAt: new Date(),
      score: m.score, // Yüzdelik skor
      name: m.name, // Null kontrolü zaten yapıldı
      photoUrl: m.photoUrl, // Null kontrolü zaten yapıldı
    });
  });
  await batch.commit();

  /* Response */
  return {
    matches: top5,
  };
});
