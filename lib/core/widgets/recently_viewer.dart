import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:provider/provider.dart';

class RecentlyViewer extends StatelessWidget {
  final Customer customer;
  final VoidCallback onProfileTap;
  const RecentlyViewer({super.key, required this.customer, required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    final Customer currentCustomer = context.read<AuthProvider>().user!;
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
                  _buildInfoRow(Icons.location_city, customer.location?.city ?? 'Şehir Yok'),
                  _buildInfoRow(Icons.cake, '${customer.getAge()}'),
                  _buildInfoRow(
                      Icons.directions_walk, customer.getDistanceFromCurrentLocation(currentCustomer.location!.lat, currentCustomer.location!.lon)),
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
