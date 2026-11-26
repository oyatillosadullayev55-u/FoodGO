import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// "OsonGo" yozuvi.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.size = 28, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Oson',
            style: TextStyle(
              color: onDark || isDark ? Colors.white : AppColors.dark,
            ),
          ),
          TextSpan(
            text: 'Go',
            style: TextStyle(
              color: onDark ? const Color(0xFFC4A5FF) : AppColors.primaryLight,
            ),
          ),
        ],
      ),
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
      ),
    );
  }
}

/// Sumka, qoshiq va sanchqi tasvirlangan ilova belgisi.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icon/icon.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'OsonGo',
    );
  }
}
