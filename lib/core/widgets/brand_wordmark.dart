import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.size = 28, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: [
        TextSpan(
          text: 'Oson',
          style: TextStyle(color: onDark ? Colors.white : AppColors.dark),
        ),
        const TextSpan(text: 'Go', style: TextStyle(color: AppColors.primary)),
      ]),
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
      ),
    );
  }
}
