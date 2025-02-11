import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/widgets/advert/advert_detail.dart';

// Kullanıcı ilanlarını gösteren kart tasarımı
class AdvertCard extends StatelessWidget {
  const AdvertCard({
    super.key,
    required this.advert,
    required this.customer,
    this.isUserAdvert = false,
    this.isLiked = false,
    this.onProfileTap,
    this.onAdvertDetailTap,
    this.onLikeTap,
    this.onMessageTap,
  });

  final Advert advert;
  final Customer customer;
  final bool isUserAdvert;
  final bool isLiked;
  final VoidCallback? onProfileTap;
  final VoidCallback? onAdvertDetailTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onMessageTap;

  @override
  Widget build(BuildContext context) {
    return Card(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.all(8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Üst kısım - Kullanıcı bilgileri
          ListTile(
            onTap: onProfileTap,
            leading: CircleAvatar(
              backgroundImage: NetworkImage(customer.profilePictureUrl ?? ""),
            ),
            title: Row(
              spacing: 4,
              children: [
                Text(
                  customer.firstName ?? "advert",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (advert.likesUUID.length > 1)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.verified, color: Colors.blue, size: 16),
                  ),
                SvgPicture.asset(
                  'assets/vectors/vector_7_x2.svg',
                  width: 16.7,
                  height: 15.8,
                ),
                Text(
                  '1',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
            subtitle: Text(' ${advert.advertType}'),
            trailing: Text(DateFormat('dd/MM/yyyy').format(advert.createdAt!)),
          ),

          GestureDetector(
            onTap: onAdvertDetailTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Konum bilgisi
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text('${advert.city}, ${advert.district}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const Spacer(),
                      const Icon(Icons.calendar_month_outlined, size: 12, color: Colors.blue),
                      const SizedBox(width: 4),
                      if (advert.startEventDate != null)
                        Text('${DateFormat('dd/MM/yyyy').format(advert.startEventDate!)} - ${DateFormat('HH:mm').format(advert.startEventDate!)}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),

                // İlan Başlığı
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "${advert.advertName} ${calculateDistance(advert.geoPoint ?? GeoPoint(0, 0), customer.geoPoint ?? GeoPoint(0, 0))}",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Açıklama metni
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    advert.description,
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

                const SizedBox(height: 10),

                if (isUserAdvert)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AdvertDetail(advert: advert)));
                      },
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('| Görüntüleyenleri Gör'),
                    ),
                  ),

                // Alt kısım - Beğeni ve mesaj butonları
                if (!isUserAdvert)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      children: [
                        if (!isLiked)
                          TextButton.icon(
                            onPressed: onLikeTap,
                            icon: const Icon(Icons.favorite_border),
                            label: Text('| ${advert.likesUUID.length}'),
                          ),
                        TextButton.icon(
                          onPressed: onMessageTap,
                          icon: const Icon(Icons.message_outlined),
                          label: const Text('| Mesaj'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ]));
  }

  // İki konum arasındaki mesafeyi kilometre cinsinden hesaplar
  String calculateDistance(GeoPoint customerLocation, GeoPoint advertLocation) {
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
