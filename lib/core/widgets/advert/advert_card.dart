import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/models/customer.dart';

// Kullanıcı ilanlarını gösteren kart tasarımı
class AdvertCard extends StatelessWidget {
  const AdvertCard({
    super.key,
    required this.advert,
    required this.customer,
    this.isUserAdvert = false,
    this.onProfileTap,
    this.onLikeTap,
    this.onMessageTap,
    this.isLiked = false,
    this.onDeleteTap,
    this.onSeeViewersTap,
  });

  final Advert advert;
  final Customer customer;
  final bool isUserAdvert;

  final VoidCallback? onProfileTap;

  final VoidCallback? onLikeTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onSeeViewersTap;
  final bool isLiked;

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
                if (advert.countUUIDs.length > 1)
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

          Column(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildButton('Beğenenleri Gör', Icons.visibility_outlined, onSeeViewersTap ?? () {}),
                    const SizedBox(width: 10),
                    _buildButton('Sil', Icons.delete_outlined, onDeleteTap ?? () {}, isDelete: true),
                  ],
                ),

              // Alt kısım - Beğeni ve mesaj butonları
              if (!isUserAdvert)
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildButton('Beğen', isLiked ? Icons.favorite : Icons.favorite_border, onLikeTap ?? () {}, showCount: true),
                    const SizedBox(width: 10),
                    _buildButton('Mesaj', Icons.message_outlined, onMessageTap ?? () {}),
                  ],
                ),
            ],
          ),
        ]));
  }

// Özel buton tasarımı oluşturur
  Widget _buildButton(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool showCount = false, // Yeni opsiyonel parametre
    bool isDelete = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(50),
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Row(
          children: [
            Icon(icon, color: showCount || isDelete ? Colors.red : Colors.black),
            if (showCount) // Sadece showCount true ise sayıyı göster
              const SizedBox(width: 3),
            if (showCount)
              Text(
                advert.countUUIDs.length.toString(),
                style: const TextStyle(color: Colors.black),
              ),
          ],
        ), // İkon siyah renkte
        label: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black), // Metin siyah renkte
            children: [
              TextSpan(
                text: '| ',
                style: const TextStyle(color: Colors.grey), // | simgesi gri renkte
              ),
              TextSpan(text: label),
            ],
          ),
        ),
      ),
    );
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
