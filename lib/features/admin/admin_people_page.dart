import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_value_view.dart';
import '../../repositories/staff_account_repository.dart';
import 'create_staff_dialog.dart';

final staffListProvider = FutureProvider.autoDispose<List<StaffMember>>(
  (ref) => ref.watch(staffAccountRepositoryProvider).list(),
);

const staffTabs = [
  ('restaurant', 'Restoranlar', Icons.storefront_rounded),
  ('shop', 'Magazinlar', Icons.shopping_bag_rounded),
  ('master', 'Ustalar', Icons.engineering_rounded),
  ('courier', 'Kuryerlar', Icons.delivery_dining_rounded),
];

/// Xodim akkauntlarini yaratish va chiqarish.
class AdminPeoplePage extends ConsumerWidget {
  const AdminPeoplePage({super.key});

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
      length: staffTabs.length,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'add_staff',
          onPressed: () => _add(context, ref),
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Yangi xodim'),
        ),
        body: Column(
          children: [
            TabBar(tabs: [for (final t in staffTabs) Tab(text: t.$2)]),
            Expanded(
              child: AsyncValueView<List<StaffMember>>(
                value: staff,
                onRetry: () => ref.invalidate(staffListProvider),
                builder: (all) => TabBarView(
                  children: [
                    for (final (role, label, icon) in staffTabs)
                      _List(
                        items: all.where((m) => m.role == role).toList(),
                        icon: icon,
                        empty: "$label ro'yxati bo'sh",
                        onRemove: (m) => _remove(context, ref, m),
                      ),
                  ],
                ),
              ),
            ),
          ],
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
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final m = items[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primarySoft,
              child: Icon(icon, color: AppColors.primary),
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
