import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../repositories/staff_account_repository.dart';
import '../auth/providers/auth_providers.dart';
import 'create_staff_dialog.dart';

final staffListProvider = FutureProvider.autoDispose<List<StaffMember>>(
  (ref) => ref.watch(staffAccountRepositoryProvider).list(),
);

/// Admin ilovasining yagona sahifasi: xodim qo'shish va chiqarish.
class AdminPeoplePage extends ConsumerWidget {
  const AdminPeoplePage({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(pushServiceProvider).unregister();
    } catch (_) {}
    await ref.read(authRepositoryProvider).signOut();
    ref.invalidate(profileProvider);
    if (context.mounted) context.go(AppRoutes.login);
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final ok = await showCreateStaffDialog(context);
    if (ok == true) ref.invalidate(staffListProvider);
  }

  Future<void> _remove(
      BuildContext context, WidgetRef ref, StaffMember m) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xodimni chiqarish'),
        content: Text(
          '${m.title} hisobi o\'chiriladi va u endi kira olmaydi. Davom etasizmi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Chiqarish'),
          ),
        ],
      ),
    );
    if (sure != true) return;
    try {
      await ref.read(staffAccountRepositoryProvider).remove(m.id);
      ref.invalidate(staffListProvider);
    } on StaffAccountException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(staffListProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('OsonGo Admin'),
          actions: [
            IconButton(
              tooltip: 'Yangilash',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(staffListProvider),
            ),
            IconButton(
              tooltip: 'Chiqish',
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => _logout(context, ref),
            ),
          ],
          bottom: const TabBar(
            tabs: [Tab(text: 'Restoranlar'), Tab(text: 'Kuryerlar')],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _add(context, ref),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.dark,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Yangi xodim'),
        ),
        body: staff.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.toString()),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(staffListProvider),
                  child: const Text('Qayta urinish'),
                ),
              ],
            ),
          ),
          data: (all) => TabBarView(
            children: [
              _List(
                items: all.where((m) => m.role == 'restaurant').toList(),
                icon: Icons.storefront_rounded,
                empty: "Hali restoran egasi yo'q",
                onRemove: (m) => _remove(context, ref, m),
              ),
              _List(
                items: all.where((m) => m.role == 'courier').toList(),
                icon: Icons.delivery_dining_rounded,
                empty: "Hali kuryer yo'q",
                onRemove: (m) => _remove(context, ref, m),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.items,
    required this.icon,
    required this.empty,
    required this.onRemove,
  });

  final List<StaffMember> items;
  final IconData icon;
  final String empty;
  final void Function(StaffMember) onRemove;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return Center(child: Text(empty));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final m = items[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primarySoft,
              child: Icon(icon, color: AppColors.dark),
            ),
            title: Text(m.title,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(m.email ?? ''),
            trailing: IconButton(
              tooltip: 'Chiqarish',
              icon: const Icon(Icons.person_remove_rounded,
                  color: AppColors.error),
              onPressed: () => onRemove(m),
            ),
          ),
        );
      },
    );
  }
}
