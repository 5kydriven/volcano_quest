import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class BadgeAwardImage extends StatelessWidget {
  final String imagePath;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final double size;

  const BadgeAwardImage({
    super.key,
    required this.imagePath,
    this.fallbackIcon = Icons.military_tech_outlined,
    this.fallbackColor = AppColors.teal,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        return Icon(fallbackIcon, color: fallbackColor, size: size * 0.72);
      },
    );
  }
}
