import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_flavor.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/role_guard.dart';
import '../data/user_profile.dart';
import '../providers/auth_providers.dart';

/// Kirgandan keyin foydalanuvchini o'z paneliga yo'naltiradi.
/// Hisob boshqa ilovaga tegishli bo'lsa (masalan, kuryer mijoz ilovasiga
/// kirsa), qaysi ilovadan foydalanish kerakligini aytadi.
class RoleGatePage extends ConsumerWidget {
  const RoleGatePage({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).signOut();
    ref.invalidate(profileProvider);
    if (context.mounted) context.go(AppRoutes.login);
  }

  void _goAfterBuild(BuildContext context, String route) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go(route);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final flavor = AppFlavor.current;

    return Scaffold(
      body: Center(
        child: profile.when(
          loading: () => const CircularProgressIndicator(),
          data: (p) {
            // Sessiya yo'q: mijoz ilovasida katalog, qolganlarida kirish.
            if (p.id == 'guest_user') {
              _goAfterBuild(
                context,
                flavor.allowsGuest ? AppRoutes.customerHome : AppRoutes.login,
              );
              return const CircularProgressIndicator();
            }

            if (!flavor.accepts(p)) {
              return _WrongAppView(
                role: p.role,
                onSignOut: () => _signOut(context, ref),
              );
            }

            _goAfterBuild(context, homeRouteFor(p));
            return const CircularProgressIndicator();
          },
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(friendlyError(e), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(profileProvider),
                  child: const Text('Qayta urinish'),
                ),
                TextButton(
                  onPressed: () => _signOut(context, ref),
                  child: const Text('Chiqish'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WrongAppView extends StatelessWidget {
  const _WrongAppView({required this.role, required this.onSignOut});

  final UserRole role;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.phonelink_lock_rounded,
                size: 38,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Bu hisob boshqa ilovaga tegishli',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              AppFlavor.current.wrongAppMessage(role),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.grey, fontSize: 14),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: onSignOut,
              child: const Text('Boshqa hisob bilan kirish'),
            ),
          ],
        ),
      ),
    );
  }
}
