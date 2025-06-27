import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Uygulama genelinde kullanılan yuvarlak profil fotoğrafı widget'ı
///
/// Farklı boyutlar için radius parametresi kullanılabilir:
/// - Küçük: 16
/// - Normal: 24 (varsayılan)
/// - Büyük: 32
/// - Çok büyük: 40
class CircleProfilePicture extends StatelessWidget {
  const CircleProfilePicture({
    super.key,
    required this.imageUrl,
    this.radius = 24,
    this.backgroundColor,
  });

  final String? imageUrl;
  final double? radius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    bool isPhoto = imageUrl != null && imageUrl != '' && imageUrl!.isNotEmpty;

    return Container(
      width: (radius ?? 24) * 2,
      height: (radius ?? 24) * 2,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        shape: BoxShape.circle,
        image: DecorationImage(
          image: isPhoto
              ? CachedNetworkImageProvider(imageUrl!)
              : const AssetImage('assets/images/dostum_olsana_trimmed.png')
                  as ImageProvider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
