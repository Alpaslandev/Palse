import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/widgets/advert/advert_detail.dart';
import 'package:palseapp/core/widgets/advert/helper/calculate_distance.dart';

// Kullanıcı ilanlarını gösteren kart tasarımı
class AdvertCard extends StatelessWidget {
  const AdvertCard({
    super.key,
    required this.advert,
    this.user,
  });

  final Advert advert;
  final Customer? user;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdvertDetail(advert: advert))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst kısım - Kullanıcı bilgileri
            ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(advert.advertImage),
              ),
              title: Row(
                spacing: 4,
                children: [
                  Text(
                    advert.creatorName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (advert.count > 1)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.verified, color: Colors.blue, size: 16),
                    ),
                  SvgPicture.asset(
                    'assets/vectors/vector_7_x2.svg',
                    width: 16.7,
                    height: 15.8,
                  ),
                  Text(advert.count.toString().substring(0, advert.count.toString().length < 4 ? advert.count.toString().length : 4),
                      style: const TextStyle(fontSize: 11)),
                ],
              ),
              subtitle: Text(' ${advert.advertType}'),
              trailing: Text(advert.advertLastUsage),
            ),

            // Konum bilgisi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 12, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text('${advert.city} - ${advert.district}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const Spacer(),
                  const Icon(Icons.calendar_month_outlined, size: 12, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text('${advert.advertDate} - ${advert.advertTime}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),

            // İlan Başlığı
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "${advert.advertName} ${calculateDistance(advert.geoPoint!, user?.geoPoint ?? GeoPoint(0, 0))}",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Açıklama metni
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                advert.advertContext,
                style: const TextStyle(color: Colors.grey),
              ),
            ),

            // Ana görsel
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                advert.advertImage,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),

            // Alt kısım - Beğeni ve mesaj butonları
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.favorite_border),
                    label: Text('${advert.count}'),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.message_outlined),
                    label: const Text('Mesaj'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // İki konum arasındaki mesafeyi kilometre cinsinden hesaplar
  String calculateDistance(GeoPoint customerLocation, GeoPoint advertLocation) {
    final GeoPoint customerLocation = GeoPoint(38.4843365, 27.130625);

    const int earthRadius = 6371000; // Dünya yarıçapı (metre)

    double lat1 = customerLocation.latitude * (pi / 180);
    double lon1 = customerLocation.longitude * (pi / 180);
    double lat2 = advertLocation.latitude * (pi / 180);
    double lon2 = advertLocation.longitude * (pi / 180);

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    final distance = (earthRadius * c / 1000).ceil();

    final distanceString = "$distance km";

    return distanceString; // Direkt olarak km cinsinden sonuç
  }
}
