import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class FoodGoApp extends StatefulWidget {
  const FoodGoApp({super.key, this.initialRecovery = false});

  /// Tiklash havolasi orqali ochilgan bo'lsa, ilova darhol yangi parol
  /// sahifasini ko'rsatadi.
  final bool initialRecovery;

  /// Web/desktopda ilova keng ekranga cho'zilib ketmasligi uchun
  /// kontent markazda, cheklangan kenglikda ko'rsatiladi.
  static const double webMaxWidth = 1080;

  @override
  State<FoodGoApp> createState() => _FoodGoAppState();
}

class _FoodGoAppState extends State<FoodGoApp> {
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    // Supabase havoladan sessiyani tiklaganda shu hodisa keladi.
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.passwordRecovery) {
        appRouter.go(AppRoutes.resetPassword);
      }
    });
    if (widget.initialRecovery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appRouter.go(AppRoutes.resetPassword);
      });
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

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
            final width = constraints.maxWidth > FoodGoApp.webMaxWidth
                ? FoodGoApp.webMaxWidth
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
