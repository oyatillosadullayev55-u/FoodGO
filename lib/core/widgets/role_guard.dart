import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/user_profile.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../errors/error_mapper.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';

/// Qaysi panelga yo'naltirish kerakligini profil bo'yicha aniqlaydi.
String homeRouteFor(UserProfile profile) {
  if (profile.role == UserRole.admin) return AppRoutes.adminHome;
  if (profile.role == UserRole.restaurant || profile.ownsRestaurant) {
    return AppRoutes.restaurantHome;
  }
  if (profile.role == UserRole.courier) return AppRoutes.courierHome;
  return AppRoutes.customerHome;
}

class RoleGuard extends ConsumerWidget {
  const RoleGuard({
    super.key,
    required this.allowed,
    required this.child,
  });

  final Set<UserRole> allowed;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return profile.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryDark),
        ),
      ),
      error: (e, _) => _AccessScreen(
        icon: Icons.error_outline_rounded,
        title: 'Profilni yuklab bo\'lmadi',
        message: friendlyError(e),
        onRetry: () => ref.invalidate(profileProvider),
      ),
      data: (p) {
        final isGuest = p.id == 'guest_user';
        if (isGuest) {
          return _AccessScreen(
            icon: Icons.lock_outline_rounded,
            title: 'Tizimga kirish kerak',
            message:
                'Bu bo\'lim faqat tizimga kirgan foydalanuvchilar uchun. '
                'Iltimos, hisobingiz bilan kiring.',
            actionLabel: 'Kirish',
            onAction: () => context.go(AppRoutes.login),
          );
        }
        if (!allowed.contains(p.role) &&
            !(p.ownsRestaurant && allowed.contains(UserRole.restaurant))) {
          return _AccessScreen(
            icon: Icons.block_rounded,
            title: 'Ruxsat yo\'q',
            message:
                'Bu bo\'lim sizning rolingiz uchun ochiq emas. '
                'Sizning rolingiz: ${p.role.label}.',
            actionLabel: 'O\'z panelimga o\'tish',
            onAction: () => context.go(homeRouteFor(p)),
            onSignOut: () => _signOut(context, ref),
          );
        }
        return child;
      },
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).signOut();
    ref.invalidate(profileProvider);
    if (context.mounted) context.go(AppRoutes.login);
  }
}

class _AccessScreen extends StatelessWidget {
  const _AccessScreen({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.onRetry,
    this.onSignOut,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onRetry;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
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
                  child: Icon(icon, size: 38, color: AppColors.dark),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.grey, fontSize: 14),
                ),
                const SizedBox(height: 22),
                if (actionLabel != null && onAction != null)
                  ElevatedButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                if (onRetry != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: onRetry,
                    child: const Text('Qayta urinish'),
                  ),
                ],
                if (onSignOut != null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: onSignOut,
                    child: const Text('Boshqa hisob bilan kirish'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
