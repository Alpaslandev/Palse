import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CircleProfilePicture extends StatelessWidget {
  const CircleProfilePicture({super.key, required this.imageUrl, this.radius = 24});
  final String? imageUrl;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    bool isPhoto = imageUrl != null && imageUrl != '' && imageUrl!.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundImage: isPhoto ? CachedNetworkImageProvider(imageUrl!) : const AssetImage('assets/images/dostum_olsana.png'),
    );
  }
}
