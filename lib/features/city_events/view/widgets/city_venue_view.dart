import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class CityVenueView extends StatelessWidget {
  final String name;
  final String types;
  final String? photoUrl;
  final String? iconUrl;
  final double lat;
  final double lng;

  const CityVenueView({
    super.key,
    required this.name,
    required this.types,
    this.photoUrl,
    this.iconUrl,
    required this.lat,
    required this.lng,
  });

  void _openMap() {
    final url =
        Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: photoUrl != null
                ? Image.network(
                    photoUrl!,
                    width: 80,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 80,
                    height: 100,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 32),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              spacing: 6,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (iconUrl != null)
                      Image.network(iconUrl!, width: 18, height: 18),
                    if (iconUrl != null) const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
                Text(
                  types[0].toUpperCase() + types.substring(1),
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                GestureDetector(
                  onTap: _openMap,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primaryColor),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "Haritada Göster",
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12.0, top: 4),
                    child: Text(
                      'Powered by Google',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
