import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/widgets/advert/helper/calculate_distance.dart';

class RecentlyViewer extends StatelessWidget {
  final Customer customer;
  final GeoPoint currentLocation;
  final VoidCallback onProfileTap;
  const RecentlyViewer({super.key, required this.customer, required this.currentLocation, required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    final distance = calculateDistance(
      currentLocation,
      customer.geoPoint ?? GeoPoint(0, 0),
    );

    return GestureDetector(
      onTap: onProfileTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profil Resmi ve Temel Bilgiler
            CircleAvatar(
              radius: 30,
              backgroundImage: CachedNetworkImageProvider(
                customer.profilePictureUrl ?? '',
                errorListener: (error) => Icon(Icons.error),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${customer.firstName} ${customer.lastName}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Detay Bilgileri
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(Icons.location_city, customer.city ?? 'Şehir Yok'),
                  _buildInfoRow(Icons.cake, '${customer.getAge()}'),
                  _buildInfoRow(Icons.directions_walk, distance),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
