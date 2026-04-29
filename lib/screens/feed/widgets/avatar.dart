import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class FeedAvatar extends StatelessWidget {
  final String photoUrl;
  final String username;
  final double size;

  const FeedAvatar(
      {super.key, required this.photoUrl, required this.username, required this.size});

  @override
  Widget build(BuildContext context) {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';
    if (photoUrl.isNotEmpty && !photoUrl.startsWith('#')) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (c2, u2, e2) =>
              FeedInitialAvatar(initial: initial, size: size, colorHex: photoUrl),
        ),
      );
    }
    return FeedInitialAvatar(initial: initial, size: size, colorHex: photoUrl);
  }
}

class FeedInitialAvatar extends StatelessWidget {
  final String initial;
  final double size;
  final String colorHex;

  const FeedInitialAvatar(
      {super.key, required this.initial, required this.size, required this.colorHex});

  Color get _color {
    try {
      if (colorHex.startsWith('#') && colorHex.length == 7) {
        return Color(int.parse('FF${colorHex.substring(1)}', radix: 16));
      }
    } catch (_) {}
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(initial,
          style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.35,
              fontWeight: FontWeight.w800)),
    );
  }
}