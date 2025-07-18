// functions/src/match/getSmartMatches.ts
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";

const db = getFirestore();

export const getSmartMatches = onCall(
  {enforceAppCheck: false},
  async (request) => {
    logger.info("getSmartMatches tetiklendi", {uid: request.auth?.uid});

    const uid = request.auth?.uid;
    if (!uid) {
      logger.error("Kimlik doğrulanmamış kullanıcı.");
      throw new HttpsError("unauthenticated", "Kullanıcı girişi gerekli.");
    }

    /* Kullanıcı verisi */
    const userSnap = await db.collection("customers").doc(uid).get();
    if (!userSnap.exists) {
      logger.error("Kullanıcı bulunamadı", {uid});
      throw new HttpsError("not-found", "Kullanıcı bulunamadı.");
    }
    const user = userSnap.data()!;
    logger.info("Kullanıcı verisi alındı.", {uid});

    const now = new Date(); // 'now' değişkenini burada bir kez tanımla
    const isPremium = user.isPremium === true;

    /* Haftalık limit kontrolü */
    const startOfWeek = new Date(now);
    startOfWeek.setDate(now.getDate() - now.getDay()); // Pazar günü referans alınır
    startOfWeek.setHours(0, 0, 0, 0);

    const weeklyMatchCountSnap = await db
      .collection("customers")
      .doc(uid)
      .collection("matches")
      .where("matchedAt", ">=", startOfWeek)
      .count()
      .get();

    if (!isPremium && weeklyMatchCountSnap.data().count >= 5) {
      logger.warn("Haftalık limit aşıldı", {uid});
      throw new HttpsError(
        "resource-exhausted",
        "Haftalık 5 eşleşme hakkınızı kullandınız."
      );
    }

    /* Mevcut eşleşmeleri getir ve ID'lerini bir sete at */
    const existingMatchesSnap = await db
      .collection("customers")
      .doc(uid)
      .collection("matches")
      .get();
    const existingMatchIds = new Set(
      existingMatchesSnap.docs.map((doc) => doc.id)
    );

    /* Adayları getir (Şehir filtresi olmadan, daha geniş havuz) */
    const candidatesSnap = await db
      .collection("customers")
      .limit(300) // Performans ve maliyet için limit
      .get();

    const userFavCats = (
      Array.isArray(user.favoriteCategories) ? user.favoriteCategories : []
    ) as string[];
    const userCity = user.location?.city ?? null;
    const userGender = user.gender ?? null;

    /* Skorlama */
    const scored = candidatesSnap.docs
      .filter((doc) => {
        const c = doc.data();
        // Profil fotoğrafı kontrolü: URL null/undefined değilse ve 10 karakterden uzunsa geçerli say.
        const hasProfilePicture =
          c.profilePictureUrl && c.profilePictureUrl.length >= 10;

        return (
          doc.id !== uid && !existingMatchIds.has(doc.id) && hasProfilePicture
        );
      }) // Kendini, daha önce eşleşmiş olanları ve profil fotosu olmayanları hariç tut
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
          const common = c.favoriteCategories.filter((cat: string) =>
            userFavCats.includes(cat)
          );
          score += common.length * 15; // her ortak kategori 15 puan
        }

        // 4) Doğrulanmış hesap mı? (Daha güvenli kontrol)
        if (c.verification === true) score += 15;
        if (user.verification === true && c.verification === true) {
          score += 10; // İkisi de verified ise ekstra
        }

        return {
          uid: doc.id,
          score,
          name: c.nickname,
          photoUrl: c.profilePictureUrl,
          gender: c.gender, // Cinsiyet bilgisini ekle
        };
      });

    // Puanlamaya göre teorik olarak ulaşılabilecek maksimum skor.
    // Konum(40) + Cinsiyet(30) + Kategori(3*15=45) + Doğrulama(25) = 140

    /* En yüksek 5 skoru seç, en az bir kadın profil olacak şekilde ayarla */
    const sortedCandidates = scored
      .filter((m) => m.score > 0)
      .sort((a, b) => b.score - a.score);

    const top5WithDetails = sortedCandidates.slice(0, 5);

    // Seçilen ilk 5'te kadın var mı kontrol et (cinsiyet 'Female' veya 'Kadın' olabilir)
    const hasFemaleInTop5 = top5WithDetails.some(
      (m) =>
        typeof m.gender === "string" &&
        (m.gender.toLowerCase() === "female" ||
          m.gender.toLowerCase() === "kadın")
    );

    // Eğer ilk 5'te kadın yoksa ve genel listede kadın aday varsa
    if (!hasFemaleInTop5) {
      const highestScoringFemale = sortedCandidates.find(
        (m) =>
          typeof m.gender === "string" &&
          (m.gender.toLowerCase() === "female" ||
            m.gender.toLowerCase() === "kadın")
      );

      if (highestScoringFemale) {
        if (top5WithDetails.length < 5) {
          // Eğer liste 5'ten azsa, direkt ekle
          top5WithDetails.push(highestScoringFemale);
        } else {
          // Eğer liste doluysa, en düşük skorluyu çıkar ve kadını ekle
          top5WithDetails.pop(); // En düşük skorlu (sıralı olduğu için sonda)
          top5WithDetails.push(highestScoringFemale);
        }
        // Puan bütünlüğünü korumak için listeyi tekrar puana göre sırala
        top5WithDetails.sort((a, b) => b.score - a.score);
      }
    }

    /* Son listeyi oluştur ve veritabanı/yanıt formatına çevir */
    const finalMatches = top5WithDetails.map((m) => ({
      matchedUserId: m.uid,
      name: m.name ?? null,
      photoUrl: m.photoUrl ?? null,
      score: m.score, // Yüzdeye çevirmeyi kaldır, ham puanı kullan
      matchedAt: Timestamp.fromDate(now),
    }));

    /* Kaydet */
    const batch = db.batch();
    finalMatches.forEach((matchData) => {
      const ref = db
        .collection("customers")
        .doc(uid)
        .collection("matches")
        .doc(matchData.matchedUserId);
      batch.set(ref, matchData);
    });
    await batch.commit();

    logger.info("Eşleşmeler başarıyla oluşturuldu ve kaydedildi.", {
      uid,
      count: finalMatches.length,
    });

    /* Response */
    return {
      matches: finalMatches,
    };
  }
);
