import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../providers/auth_providers.dart';

class RolePlaceholder extends ConsumerWidget {
  const RolePlaceholder(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$title paneli tez orada tayyor bo\'ladi',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
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
    );
  }
}