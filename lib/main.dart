import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/env.dart';
import 'core/utils/auth_link.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.isConfigured) {
    runApp(const _ConfigErrorApp());
    return;
  }

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
    // Buzilgan tiklash havolasi tufayli yiqilgan bo'lsa, manzilni tozalab
    // sahifani qayta yuklaymiz — aks holda ilova xato ekranida qotib qoladi.
    if (fromRecoveryLink || linkError != null) {
      cleanAuthLinkFromAddressBar();
      reloadPage();
      return;
    }
    runApp(
      _ConfigErrorApp(message: 'Supabase ulanishida xatolik yuz berdi:\n$e'),
    );
    return;
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

class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              message ??
                  'Supabase sozlanmagan.\n\n'
                      'Ilovani --dart-define=SUPABASE_URL=... va '
                      '--dart-define=SUPABASE_ANON_KEY=... bilan ishga '
                      'tushiring.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
