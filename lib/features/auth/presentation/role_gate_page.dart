import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/router/app_router.dart';
import '../data/user_profile.dart';
import '../providers/auth_providers.dart';

String _routeFor(UserRole role) => switch (role) {
  UserRole.customer => AppRoutes.customerHome,
  UserRole.courier => AppRoutes.courierHome,
  UserRole.restaurant => AppRoutes.restaurantHome,
  UserRole.admin => AppRoutes.adminHome,
};

class RoleGatePage extends ConsumerWidget {
  const RoleGatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      body: Center(
        child: profile.when(
          loading: () => const CircularProgressIndicator(),
          data: (p) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go(_routeFor(p.role));
            });
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
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    ref.invalidate(profileProvider);
                    if (context.mounted) context.go(AppRoutes.login);
                  },
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