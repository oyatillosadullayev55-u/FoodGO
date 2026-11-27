import 'package:flutter/material.dart';

/// OsonGo binafsha dizayn tizimi.
class AppColors {
  // Brend binafsha
  static const primary = Color(0xFF5B16E0);
  static const primaryDark = Color(0xFF3E0AB2); // Bosilgan holat, gradient oxiri
  static const primaryLight = Color(0xFF8C46FF); // Gradient boshi
  static const primarySoft = Color(0xFFEFE9FF); // Mayin fon / chip

  /// [primary] va gradient ustidagi matn va ikonkalar.
  static const onPrimary = Colors.white;

  // Matn va fonlar
  static const dark = Color(0xFF17123A); // Asosiy to'q ko'k matn
  static const grey = Color(0xFF7C7896); // Ikkinchi darajali matn
  static const greyLight = Color(0xFFF4F2FB); // Mayin fon
  static const borderLight = Color(0xFFE9E5F6); // Kartalar chegarasi
  static const scaffold = Color(0xFFF8F7FD);

  // Urg'u ranglari
  static const accentRed = Color(0xFFEF2D46);
  static const accentPurple = Color(0xFF8C46FF);
  static const accentGold = Color(0xFFFFB300); // Yulduzcha
  static const accentBlue = Color(0xFF2447D8);

  static const success = Color(0xFF1F9D63);
  static const warning = Color(0xFFF08C00);
  static const error = Color(0xFFE5484D);

  // Tungi rejim
  static const darkBg = Color(0xFF0F0C1D);
  static const darkSurface = Color(0xFF1A1630);
  static const darkSurfaceElevated = Color(0xFF262041);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primaryLight],
  );
}
