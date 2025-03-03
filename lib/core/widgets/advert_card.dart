import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/widgets/circle_profile_picture.dart';
import 'package:provider/provider.dart';

// Kullanıcı ilanlarını gösteren kart tasarımı
class AdvertCard extends StatelessWidget {
  const AdvertCard({
    super.key,
    required this.advert,
    this.isUserAdvert = false,
    this.onProfileTap,
    this.onLikeTap,
    this.onMessageTap,
    this.isLiked = false,
    this.onDeleteTap,
    this.onSeeViewersTap,
    this.isMyLikes = false,
    this.isFriendProfile = false,
  });

  final Advert advert;
  final bool isUserAdvert;
  final bool isMyLikes;
  final bool isFriendProfile;

  final VoidCallback? onProfileTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onSeeViewersTap;
  final bool isLiked;

  @override
  Widget build(BuildContext context) {
    final currentCustomer = context.read<AuthProvider>().user!;
    return Card(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 10, children: [
          // Üst kısım - Kullanıcı bilgileri
          _profileHeader(),

          Row(
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    WidgetSpan(
                      child: Icon(Icons.location_on_outlined, size: 12, color: Colors.blue),
                    ),
                    TextSpan(
                      text:
                          ' ${advert.location?.city}, ${advert.location?.district} (${advert.getDistanceFromCurrentLocation(currentCustomer.location!.lat, currentCustomer.location!.lon)})',
                      style: TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              RichText(
                text: TextSpan(
                  children: [
                    WidgetSpan(
                      child: Icon(Icons.calendar_month_outlined, size: 12, color: Colors.blue),
                    ),
                    TextSpan(
                      text: ' ${DateFormat('dd/MM/yyyy').format(advert.startEventDate!)} - ${DateFormat('HH:mm').format(advert.startEventDate!)}',
                      style: TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),

          // İlan Başlığı
          Text(
            advert.advertName,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          // Açıklama metni
          Text(
            advert.description,
            style: const TextStyle(color: Colors.grey),
          ),

          if (!advert.advertImage.contains('assets/images/'))
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: advert.advertImage,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                advert.advertImage,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),

          if (!isFriendProfile) ...[
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
                  if (!isMyLikes) _buildButton('Beğen', isLiked ? Icons.favorite : Icons.favorite_border, onLikeTap ?? () {}, showCount: true),
                  const SizedBox(width: 20),
                  _buildButton('Mesaj', Icons.message_outlined, onMessageTap ?? () {}),
                ],
              ),
          ],
        ]));
  }

  Widget _profileHeader() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onProfileTap,
      leading: CircleProfilePicture(imageUrl: advert.creatorProfilePicture),
      title: Row(
        spacing: 4,
        children: [
          Text(
            advert.creatorName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (advert.creatorIsVerified == true)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.verified, color: Colors.blue, size: 16),
            ),
          if (advert.creatorIsPremium == true)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.verified, color: Colors.yellow, size: 16),
            ),
          SvgPicture.asset(
            'assets/vectors/vector_7_x2.svg',
            width: 14,
            height: 14,
          ),
          Text(
            '${advert.creatorAverageRating}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      subtitle: Text(advert.advertType),
      trailing: Text(DateFormat('dd/MM/yyyy').format(advert.createdAt!)),
    );
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
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.all(Radius.circular(50)),
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
                advert.likers.length.toString(),
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
}
