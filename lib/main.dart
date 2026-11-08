import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/env.dart';
import 'core/utils/auth_link.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      child: FoodGoApp(
        initialRecovery: fromRecoveryLink,
        recoveryLinkError: linkError,
      ),
    ),
  );
}
