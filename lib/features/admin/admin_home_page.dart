import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/food_images.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/app_map.dart';
import '../../core/widgets/content_frame.dart';
import '../../models/food_order.dart';
import '../../models/restaurant.dart';
import '../auth/data/user_profile.dart';
import '../auth/providers/auth_providers.dart';
import 'admin_providers.dart';
import 'create_staff_dialog.dart';

class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).signOut();
    ref.invalidate(profileProvider);
    if (mounted) context.go(AppRoutes.login);
  }

  void _refreshAll() {
    ref.invalidate(adminRestaurantsProvider);
    ref.invalidate(adminUsersProvider);
    ref.invalidate(adminOrdersProvider);
  }

  Future<void> _openEditor([Restaurant? restaurant]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RestaurantEditorDialog(restaurant: restaurant),
    );
    if (saved == true) {
      _refreshAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              restaurant == null
                  ? "Restoran qo'shildi. Mijozlar uni darhol ko'radi."
                  : 'Restoran yangilandi.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _delete(Restaurant restaurant) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Restoranni o'chirish"),
        content: Text(
          "'${restaurant.name}' restorani va uning menyusi o'chiriladi. "
          'Davom ettirasizmi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Yo'q"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text("O'chirish"),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminRepositoryProvider).deleteRestaurant(restaurant.id);
      _refreshAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  Future<void> _toggleActive(Restaurant restaurant, bool value) async {
    try {
      await ref
          .read(adminRepositoryProvider)
          .setRestaurantActive(restaurant.id, value);
      ref.invalidate(adminRestaurantsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final email = ref.read(supabaseProvider).auth.currentUser?.email ?? '';
    final stats = ref.watch(adminStatsProvider);
    final restaurants = ref.watch(adminRestaurantsProvider).asData?.value;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showCreateStaffDialog(context);
          if (created == true) {
            ref.invalidate(adminUsersProvider);
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.dark),
        label: const Text('Yangi xodim', style: TextStyle(color: AppColors.dark, fontWeight: FontWeight.w800)),
      ),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, size: 24),
            SizedBox(width: 8),
            Text('Admin panel', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          if (email.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : AppColors.greyLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                email,
                style: const TextStyle(fontSize: 12, color: AppColors.grey),
              ),
            ),
          IconButton(
            tooltip: 'Mijoz sayti',
            onPressed: () => context.go(AppRoutes.customerHome),
            icon: const Icon(Icons.storefront_outlined),
          ),
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Chiqish'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ContentFrame(
        maxWidth: 1040,
        child: Column(
          children: [
            _StatsRow(
              restaurants: restaurants?.length ?? 0,
              users: stats.users,
              activeOrders: stats.activeOrders,
            ),
            TabBar(
              controller: _tab,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.dark,
              unselectedLabelColor: AppColors.grey,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
              tabs: const [
                Tab(text: 'Restoranlar', icon: Icon(Icons.storefront_rounded)),
                Tab(text: 'Foydalanuvchilar', icon: Icon(Icons.people_rounded)),
                Tab(
                  text: 'Buyurtmalar',
                  icon: Icon(Icons.receipt_long_rounded),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _RestaurantsTab(
                    onAdd: () => _openEditor(),
                    onEdit: (r) => _openEditor(r),
                    onDelete: _delete,
                    onToggleActive: _toggleActive,
                    onRefresh: () async {
                      ref.invalidate(adminRestaurantsProvider);
                      await ref.read(adminRestaurantsProvider.future);
                    },
                  ),
                  _UsersTab(
                    onRefresh: () async {
                      ref.invalidate(adminUsersProvider);
                      await ref.read(adminUsersProvider.future);
                    },
                  ),
                  _OrdersTab(
                    onRefresh: () async {
                      ref.invalidate(adminOrdersProvider);
                      await ref.read(adminOrdersProvider.future);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.restaurants,
    required this.users,
    required this.activeOrders,
  });

  final int restaurants;
  final int users;
  final int activeOrders;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          _stat(Icons.storefront_rounded, 'Restoranlar', '$restaurants'),
          const SizedBox(width: 10),
          _stat(Icons.people_alt_rounded, 'Foydalanuvchilar', '$users'),
          const SizedBox(width: 10),
          _stat(
            Icons.delivery_dining_rounded,
            'Faol buyurtmalar',
            '$activeOrders',
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.dark),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantsTab extends ConsumerWidget {
  const _RestaurantsTab({
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
    required this.onRefresh,
  });

  final VoidCallback onAdd;
  final ValueChanged<Restaurant> onEdit;
  final ValueChanged<Restaurant> onDelete;
  final void Function(Restaurant, bool) onToggleActive;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurants = ref.watch(adminRestaurantsProvider);

    return restaurants.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryDark),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 44, color: AppColors.error),
              const SizedBox(height: 10),
              Text(friendlyError(e), textAlign: TextAlign.center),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminRestaurantsProvider),
                child: const Text('Qayta urinish'),
              ),
            ],
          ),
        ),
      ),
      data: (list) => RefreshIndicator(
        color: AppColors.dark,
        backgroundColor: AppColors.primary,
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Restoran qo'shsangiz, u mijozlar saytida darhol ko'rinadi.",
                    style: TextStyle(fontSize: 13, color: AppColors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text("Restoran qo'shish"),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Column(
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 56,
                      color: AppColors.grey,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Hozircha restoran yo'q.\nYuqoridagi tugma orqali qo'shing.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.grey),
                    ),
                  ],
                ),
              ),
            for (final r in list)
              _RestaurantCard(
                restaurant: r,
                onEdit: () => onEdit(r),
                onDelete: () => onDelete(r),
                onToggleActive: (v) => onToggleActive(r, v),
              ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({
    required this.restaurant,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  final Restaurant restaurant;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleActive;

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final image = FoodImages.getRestaurantImage(r.name, r.imageUrl);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                image,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 76,
                  height: 76,
                  color: AppColors.primarySoft,
                  child: const Icon(
                    Icons.restaurant,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Switch(
                        value: r.isActive,
                        activeThumbColor: AppColors.dark,
                        activeTrackColor: AppColors.primary,
                        onChanged: onToggleActive,
                      ),
                    ],
                  ),
                  Text(
                    r.address ?? 'Manzil kiritilmagan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: AppColors.grey,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          (r.ownerEmail == null || r.ownerEmail!.isEmpty)
                              ? 'Egasi tayinlanmagan'
                              : r.ownerEmail!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey,
                          ),
                        ),
                      ),
                      if (r.lat != null && r.lng != null)
                        Text(
                          '${r.lat!.toStringAsFixed(4)}, '
                          '${r.lng!.toStringAsFixed(4)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.grey,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: r.isActive
                              ? AppColors.success.withValues(alpha: 0.12)
                              : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          r.isActive ? 'Faol' : "O'chirilgan",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: r.isActive
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Tahrirlash'),
                      ),
                      IconButton(
                        tooltip: "O'chirish",
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsersTab extends ConsumerWidget {
  const _UsersTab({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(adminUsersProvider);
    final myId = ref.read(supabaseProvider).auth.currentUser?.id;

    return users.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryDark),
      ),
      error: (e, _) => Center(child: Text(friendlyError(e))),
      data: (list) => RefreshIndicator(
        color: AppColors.dark,
        backgroundColor: AppColors.primary,
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const Text(
              "Foydalanuvchi rolini o'zgartiring. Rol serverda saqlanadi va "
              "foydalanuvchi qayta kirganda tegishli panelga o'tadi.",
              style: TextStyle(fontSize: 13, color: AppColors.grey),
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 50),
                child: Center(
                  child: Text(
                    "Foydalanuvchilar ro'yxati bo'sh. SQL faylni ishga "
                    'tushirganingizni tekshiring.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.grey),
                  ),
                ),
              ),
            for (final u in list)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primarySoft,
                        child: Text(
                          (u.fullName ?? u.email ?? '?').characters.first
                              .toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.dark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    u.fullName?.isNotEmpty == true
                                        ? u.fullName!
                                        : 'Ismsiz foydalanuvchi',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ),
                                if (u.id == myId)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 6),
                                    child: Text(
                                      '(siz)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.grey,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              u.email ?? "email yo'q",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<UserRole>(
                        value: u.role,
                        underline: const SizedBox.shrink(),
                        borderRadius: BorderRadius.circular(14),
                        items: [
                          for (final role in UserRole.values)
                            DropdownMenuItem(
                              value: role,
                              child: Text(
                                role.label,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                        ],
                        onChanged: u.id == myId
                            ? null
                            : (role) async {
                                if (role == null) return;
                                try {
                                  await ref
                                      .read(adminRepositoryProvider)
                                      .updateUserRole(u.id, role);
                                  ref.invalidate(adminUsersProvider);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(friendlyError(e))),
                                    );
                                  }
                                }
                              },
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

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(adminOrdersProvider);
    final fmt = DateFormat('dd.MM.yyyy HH:mm');

    return orders.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryDark),
      ),
      error: (e, _) => Center(child: Text(friendlyError(e))),
      data: (list) => RefreshIndicator(
        color: AppColors.dark,
        backgroundColor: AppColors.primary,
        onRefresh: onRefresh,
        child: list.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 56,
                    color: AppColors.grey,
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: Text(
                      "Hozircha buyurtmalar yo'q.",
                      style: TextStyle(color: AppColors.grey),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final o = list[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '#${o.id.substring(0, 8)} · '
                                  '${o.restaurantName ?? 'Restoran'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                  ),
                                ),
                              ),
                              _StatusChip(status: o.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${o.addressText} · ${o.phone}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.grey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                formatSom(o.total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                fmt.format(o.createdAt),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.grey,
                                ),
                              ),
                            ],
                          ),
                          if (o.courierId != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Kuryer: ${o.courierId!.substring(0, 8)}…',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      OrderStatus.delivered => AppColors.success,
      OrderStatus.cancelled || OrderStatus.rejected => AppColors.error,
      OrderStatus.pending => AppColors.accentRed,
      _ => AppColors.primaryDark,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _RestaurantEditorDialog extends ConsumerStatefulWidget {
  const _RestaurantEditorDialog({this.restaurant});

  final Restaurant? restaurant;

  @override
  ConsumerState<_RestaurantEditorDialog> createState() =>
      _RestaurantEditorDialogState();
}

class _RestaurantEditorDialogState
    extends ConsumerState<_RestaurantEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _address;
  late final TextEditingController _ownerEmail;
  late final TextEditingController _imageUrl;
  late LatLng _location;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.restaurant;
    _name = TextEditingController(text: r?.name ?? '');
    _description = TextEditingController(text: r?.description ?? '');
    _address = TextEditingController(text: r?.address ?? '');
    _ownerEmail = TextEditingController(text: r?.ownerEmail ?? '');
    _imageUrl = TextEditingController(text: r?.imageUrl ?? '');
    _location = r?.location ?? kTashkentCenter;
    _isActive = r?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _address.dispose();
    _ownerEmail.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final address = _address.text.trim();
    if (name.isEmpty) {
      _snack('Restoran nomini kiriting');
      return;
    }
    if (address.isEmpty) {
      _snack('Manzilni kiriting');
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(adminRepositoryProvider);
    final image = _imageUrl.text.trim().isEmpty
        ? FoodImages.getRestaurantImage(name, null)
        : _imageUrl.text.trim();
    try {
      if (widget.restaurant == null) {
        await repo.createRestaurant(
          name: name,
          description: _description.text.trim().isEmpty
              ? 'Mazali taomlar'
              : _description.text.trim(),
          address: address,
          ownerEmail: _ownerEmail.text.trim(),
          lat: _location.latitude,
          lng: _location.longitude,
          imageUrl: image,
          isActive: _isActive,
        );
      } else {
        await repo.updateRestaurant(
          widget.restaurant!.id,
          name: name,
          description: _description.text.trim().isEmpty
              ? 'Mazali taomlar'
              : _description.text.trim(),
          address: address,
          ownerEmail: _ownerEmail.text.trim(),
          lat: _location.latitude,
          lng: _location.longitude,
          imageUrl: image,
          isActive: _isActive,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack(friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.restaurant != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isEdit ? 'Restoranni tahrirlash' : 'Yangi restoran',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Restoran nomi',
                        hintText: 'Osh Markazi, Evos, Rayhon...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _description,
                      decoration: const InputDecoration(
                        labelText: 'Tavsif',
                        hintText: 'Milliy taomlar, fast food...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _address,
                      decoration: const InputDecoration(
                        labelText: 'Manzil',
                        hintText: "Chilonzor, Bunyodkor ko'chasi 12",
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ownerEmail,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Egasi (email)',
                        hintText: 'owner@example.com',
                        helperText: "Shu email bilan kirgan foydalanuvchi restoran panelini boshqaradi.",
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _imageUrl,
                      decoration: const InputDecoration(
                        labelText: 'Rasm URL (ixtiyoriy)',
                        hintText: "Bo'sh qolsa avtomatik tanlanadi",
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Xaritada joylashuv',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        Switch(
                          value: _isActive,
                          activeThumbColor: AppColors.dark,
                          activeTrackColor: AppColors.primary,
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
                        const Text('Faol', style: TextStyle(fontSize: 12.5)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Xaritani bosing yoki barmog'ingiz bilan surib "
                      'restoranning aniq nuqtasini belgilang.',
                      style: TextStyle(fontSize: 12, color: AppColors.grey),
                    ),
                    const SizedBox(height: 8),
                    AppMap(
                      points: [
                        MapPoint(
                          point: _location,
                          icon: Icons.restaurant_rounded,
                          color: AppColors.primary,
                        ),
                      ],
                      center: _location,
                      height: 240,
                      zoom: 14,
                      onTap: (point) => setState(() => _location = point),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.pin_drop_outlined,
                          size: 16,
                          color: AppColors.grey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Lat: ${_location.latitude.toStringAsFixed(6)} · '
                          'Lng: ${_location.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.pop(context, false),
                      child: const Text('Bekor qilish'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.dark,
                              ),
                            )
                          : Text(isEdit ? 'Saqlash' : "Qo'shish"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
