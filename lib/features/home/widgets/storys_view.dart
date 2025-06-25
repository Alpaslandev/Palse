import 'package:flutter/material.dart';
import 'package:palseapp/core/utils/app_theme.dart';

// Hikayeler görünümü widget'ı - Instagram benzeri yuvarlak profil fotoğrafları
class StorysView extends StatelessWidget {
  const StorysView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 102,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6, // İlk item + butonu, sonraki 5 item kullanıcı hikayeleri
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAddStoryItem(context);
          }
          return _buildStoryItem(context, index);
        },
      ),
    );
  }

  // Hikaye ekleme butonu widget'ı
  Widget _buildAddStoryItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          // Hikaye ekleme fonksiyonu
          debugPrint('Hikaye ekle tıklandı');
        },
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
                color: Theme.of(context).cardColor,
              ),
              child: const Icon(
                Icons.add,
                size: 32,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hikaye Ekle',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Kullanıcı hikayesi item widget'ı
  Widget _buildStoryItem(BuildContext context, int index) {
    // Geçici kullanıcı isimleri
    final userNames = ['Ahmet', 'Ayşe', 'Mehmet', 'Fatma', 'Ali'];

    // Geçici renkler hikaye çerçevesi için
    final colors = [
      Colors.purple,
      Colors.orange,
      Colors.green,
      Colors.blue,
      Colors.red,
    ];

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          // Hikaye görüntüleme fonksiyonu
          debugPrint('${userNames[index - 1]} hikayesi açıldı');
        },
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colors[(index - 1) % colors.length],
                    colors[(index - 1) % colors.length].withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Container(
                    color: colors[(index - 1) % colors.length].withOpacity(0.2),
                    child: Icon(
                      Icons.person,
                      size: 32,
                      color: colors[(index - 1) % colors.length],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 64,
              child: Text(
                userNames[(index - 1) % userNames.length],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
