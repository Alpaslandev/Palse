import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/features/city_events/model/event_model.dart';
import 'package:url_launcher/url_launcher.dart';

// Şehirdeki etkinlikleri gösteren kart tasarımı
class CityEventView extends StatelessWidget {
  final EventModel event;
  const CityEventView({super.key, required this.event});

  // Etkinlik URL'sini aç
  void _openEventUrl() async {
    if (await canLaunchUrl(Uri.parse(event.url))) {
      await launchUrl(Uri.parse(event.url));
    }
  }

  // Tarih formatını düzenle
  String _formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy - HH:mm', 'tr_TR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etkinlik posteri
          if (event.posterUrl != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                event.posterUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 64),
                  );
                },
              ),
            ),

          // Etkinlik detayları
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Etkinlik adı
                Text(
                  event.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Mekan bilgisi
                if (event.venueName != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.venueName!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Tarih bilgisi
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _formatDate(event.start),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Ücret durumu ve bilet butonu
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            AppTheme.darkHintTextColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Etkinlik.io',
                        style: TextStyle(
                          color: AppTheme.darkHintTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _openEventUrl,
                      style: TextButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Detaylı Bilgi'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
