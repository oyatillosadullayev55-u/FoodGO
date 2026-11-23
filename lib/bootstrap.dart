import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_flavor.dart';
import 'core/constants/env.dart';
import 'core/router/app_router.dart';
import 'core/utils/auth_link.dart';

/// Uchala ilova uchun umumiy ishga tushirish. Farqi faqat [flavor] va
/// [routes] da: har bir main_*.dart faylida o'zining sahifalari beriladi.
Future<void> bootstrap({
  required AppFlavor flavor,
  required List<RouteBase> routes,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  AppFlavor.current = flavor;
  initRouter(flavor, routes);

  // Havoladan kelgan ma'lumotni Supabase o'qib tozalashidan oldin saqlaymiz.
  final fromRecoveryLink = isPasswordRecoveryLink();
  final linkError = passwordRecoveryLinkError();

  // Buzilgan havola GoRouter'ni chalg'itmasligi uchun avval tozalanadi.
  if (linkError != null) cleanAuthLinkFromAddressBar();

  try {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
    );
  } catch (e) {
    if (fromRecoveryLink || linkError != null) {
      cleanAuthLinkFromAddressBar();
      reloadPage();
      return;
    }
  }

  // Sessiya o'qilgach tokenni manzil qatoridan olib tashlaymiz.
  if (linkError == null) cleanAuthLinkFromAddressBar();

  runApp(
    ProviderScope(
      child: OsonGoApp(
        initialRecovery: fromRecoveryLink,
        recoveryLinkError: linkError,
      ),
    ),
  );
}
