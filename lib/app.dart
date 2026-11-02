import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class FoodGoApp extends StatelessWidget {
  const FoodGoApp({super.key});

  /// Web/desktopda ilova keng ekranga cho'zilib ketmasligi uchun
  /// kontent markazda, cheklangan kenglikda ko'rsatiladi.
  static const double webMaxWidth = 1080;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FoodGo — tez yetkazib berish',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth > webMaxWidth
                ? webMaxWidth
                : constraints.maxWidth;
            return ColoredBox(
              color: isDark ? const Color(0xFF0E0E10) : const Color(0xFFECECF0),
              child: Center(
                child: SizedBox(
                  width: width,
                  height: constraints.maxHeight.isFinite
                      ? constraints.maxHeight
                      : null,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
