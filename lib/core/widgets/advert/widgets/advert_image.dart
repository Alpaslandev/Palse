import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

// İlan görselini gösteren widget
class AdvertImage extends StatelessWidget {
  const AdvertImage({
    super.key,
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (!imageUrl.contains('assets/images/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        imageUrl,
        width: double.infinity,
        height: 250,
        fit: BoxFit.cover,
      ),
    );
  }
}
