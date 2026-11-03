import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/food_images.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/app_map.dart';
import '../../core/widgets/content_frame.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/error_view.dart';
import '../../models/food_order.dart';
import '../../models/product.dart';
import '../../models/restaurant.dart';
import '../auth/providers/auth_providers.dart';
import '../delivery/delivery_providers.dart';

class RestaurantHomePage extends ConsumerStatefulWidget {
  const RestaurantHomePage({super.key});

  @override
  ConsumerState<RestaurantHomePage> createState() => _RestaurantHomePageState();
}

class _RestaurantHomePageState extends ConsumerState<RestaurantHomePage> {
  String? _restaurantId;
  String? _busyOrderId;

  Future<void> _refreshAll() async {
    ref.invalidate(myRestaurantsProvider);
    final id = _restaurantId;
    if (id != null) {
      ref.invalidate(restaurantProductsProvider(id));
      ref.invalidate(restaurantOrdersProvider(id));
    }
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    ref.invalidate(profileProvider);
    if (mounted) context.go(AppRoutes.login);
  }

  Future<void> _setOrderStatus(FoodOrder order, OrderStatus status) async {
    setState(() => _busyOrderId = order.id);
    try {
      await ref.read(deliveryRepositoryProvider).setStatus(order.id, status);
      if (_restaurantId != null) {
        ref.invalidate(restaurantOrdersProvider(_restaurantId!));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _busyOrderId = null);
    }
  }

  Future<void> _openProductEditor(
    String restaurantId, [
    Product? product,
  ]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _ProductEditorDialog(restaurantId: restaurantId, product: product),
    );
    if (saved == true) {
      ref.invalidate(restaurantProductsProvider(restaurantId));
    }
  }

  Future<void> _deleteProduct(String restaurantId, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Taomni o'chirish"),
        content: Text("'${product.name}' menyudan o'chirilsinmi?"),
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
    if (confirmed != true) return;
    try {
      await ref.read(deliveryRepositoryProvider).deleteProduct(product.id);
      ref.invalidate(restaurantProductsProvider(restaurantId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(myRestaurantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Restoran paneli',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Yangilash',
            onPressed: _refreshAll,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Chiqish',
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ContentFrame(
        maxWidth: 900,
        child: restaurantsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              ErrorView(message: friendlyError(e), onRetry: _refreshAll),
          data: (restaurants) {
            if (restaurants.isEmpty) {
              return const EmptyView(
                icon: Icons.storefront_outlined,
                title: 'Sizga biriktirilgan restoran yo\'q',
                message:
                    'Admin panelida restoran yaratilganda "Egasi emaili" sifatida '
                    'hisobingiz emaili ko\'rsatilishi kerak. Admin bilan bog\'laning.',
              );
            }

            final selected = restaurants.firstWhere(
              (r) => r.id == _restaurantId,
              orElse: () => restaurants.first,
            );
            _restaurantId = selected.id;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (restaurants.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: DropdownButtonFormField<String>(
                      initialValue: selected.id,
                      decoration: const InputDecoration(
                        labelText: 'Restoranni tanlang',
                      ),
                      items: [
                        for (final r in restaurants)
                          DropdownMenuItem(value: r.id, child: Text(r.name)),
                      ],
                      onChanged: (id) => setState(() => _restaurantId = id),
                    ),
                  ),
                _RestaurantHeader(restaurant: selected),
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          indicatorColor: AppColors.primary,
                          indicatorWeight: 3,
                          labelColor: AppColors.dark,
                          unselectedLabelColor: AppColors.grey,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                          tabs: const [
                            Tab(
                              text: 'Menyu',
                              icon: Icon(Icons.restaurant_menu_rounded),
                            ),
                            Tab(
                              text: 'Buyurtmalar',
                              icon: Icon(Icons.receipt_long_rounded),
                            ),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _MenuTab(
                                restaurantId: selected.id,
                                onEdit: (p) =>
                                    _openProductEditor(selected.id, p),
                                onAdd: () => _openProductEditor(selected.id),
                                onDelete: (p) => _deleteProduct(selected.id, p),
                              ),
                              _OrdersTab(
                                restaurantId: selected.id,
                                busyOrderId: _busyOrderId,
                                onStatus: _setOrderStatus,
                                onRefresh: _refreshAll,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RestaurantHeader extends StatelessWidget {
  const _RestaurantHeader({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final points = <MapPoint>[
      if (restaurant.location != null)
        MapPoint(
          point: restaurant.location!,
          icon: Icons.storefront_rounded,
          color: AppColors.primary,
          label: restaurant.name,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      restaurant.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (restaurant.isActive
                                  ? AppColors.success
                                  : AppColors.error)
                              .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      restaurant.isActive ? 'Faol' : 'Vaqtincha yopiq',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        color: restaurant.isActive
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.grey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      restaurant.address ?? 'Manzil ko\'rsatilmagan',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              if (points.isNotEmpty) ...[
                const SizedBox(height: 10),
                AppMap(points: points, height: 170, interactive: false),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTab extends ConsumerWidget {
  const _MenuTab({
    required this.restaurantId,
    required this.onEdit,
    required this.onAdd,
    required this.onDelete,
  });

  final String restaurantId;
  final ValueChanged<Product> onEdit;
  final VoidCallback onAdd;
  final ValueChanged<Product> onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(restaurantProductsProvider(restaurantId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.dark),
        label: const Text(
          "Taom qo'shish",
          style: TextStyle(color: AppColors.dark, fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(restaurantProductsProvider(restaurantId));
          await ref.read(restaurantProductsProvider(restaurantId).future);
        },
        child: productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorView(
            message: friendlyError(e),
            onRetry: () =>
                ref.invalidate(restaurantProductsProvider(restaurantId)),
          ),
          data: (products) {
            if (products.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 40),
                  EmptyView(
                    icon: Icons.fastfood_rounded,
                    title: 'Menyu bo\'sh',
                    message: 'Pastdagi sariq tugma orqali birinchi taomni qo\'shing.',
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                final img = FoodImages.getProductImage(
                  p.name,
                  p.categoryName,
                  p.imageUrl,
                );
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        img,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 56,
                          height: 56,
                          color: AppColors.primarySoft,
                          child: const Icon(
                            Icons.fastfood,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      p.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      '${formatSom(p.price)}${p.isAvailable ? '' : ' • mavjud emas'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Tahrirlash',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => onEdit(p),
                        ),
                        IconButton(
                          tooltip: "O'chirish",
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.error,
                          ),
                          onPressed: () => onDelete(p),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab({
    required this.restaurantId,
    required this.busyOrderId,
    required this.onStatus,
    required this.onRefresh,
  });

  final String restaurantId;
  final String? busyOrderId;
  final Future<void> Function(FoodOrder, OrderStatus) onStatus;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(restaurantOrdersProvider(restaurantId));

    return RefreshIndicator(
      onRefresh: () async {
        await onRefresh();
        await ref.read(restaurantOrdersProvider(restaurantId).future);
      },
      child: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: friendlyError(e),
          onRetry: () => ref.invalidate(restaurantOrdersProvider(restaurantId)),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 60),
                EmptyView(
                  icon: Icons.receipt_long_rounded,
                  title: 'Hozircha buyurtma yo\'q',
                  message: 'Mijozlar buyurtma berganda shu yerda ko\'rinadi.',
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final o = orders[i];
              final buttons = <(String, OrderStatus)>[
                if (o.status == OrderStatus.pending)
                  ('Tasdiqlash', OrderStatus.accepted),
                if (o.status == OrderStatus.pending)
                  ('Rad etish', OrderStatus.rejected),
                if (o.status == OrderStatus.accepted)
                  ('Tayyorlashni boshlash', OrderStatus.preparing),
                if (o.status == OrderStatus.preparing)
                  ('Tayyor', OrderStatus.readyForPickup),
              ];
              final points = <MapPoint>[
                if (o.restaurantLocation != null)
                  MapPoint(
                    point: o.restaurantLocation!,
                    icon: Icons.storefront_rounded,
                    color: AppColors.primary,
                  ),
                if (o.destination != null)
                  MapPoint(
                    point: o.destination!,
                    icon: Icons.home_rounded,
                    color: AppColors.dark,
                  ),
              ];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
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
                              'Buyurtma #${o.id.substring(0, 8)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          _StatusChip(status: o.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd.MM.yyyy HH:mm').format(o.createdAt),
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Summa: ${formatSom(o.total)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Manzil: ${o.addressText}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.grey,
                        ),
                      ),
                      Text(
                        'Telefon: ${o.phone}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.grey,
                        ),
                      ),
                      if (o.note != null && o.note!.trim().isNotEmpty)
                        Text(
                          'Izoh: ${o.note}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.grey,
                          ),
                        ),
                      if (points.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        AppMap(points: points, height: 160, interactive: false),
                      ],
                      if (buttons.isNotEmpty) ...[
                        const Divider(height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: [
                            for (final (label, status) in buttons)
                              ElevatedButton(
                                onPressed: busyOrderId == o.id
                                    ? null
                                    : () => onStatus(o, status),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      status == OrderStatus.rejected
                                      ? AppColors.error
                                      : AppColors.primary,
                                  foregroundColor:
                                      status == OrderStatus.rejected
                                      ? Colors.white
                                      : AppColors.dark,
                                ),
                                child: Text(label),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProductEditorDialog extends ConsumerStatefulWidget {
  const _ProductEditorDialog({required this.restaurantId, this.product});

  final String restaurantId;
  final Product? product;

  @override
  ConsumerState<_ProductEditorDialog> createState() =>
      _ProductEditorDialogState();
}

class _ProductEditorDialogState extends ConsumerState<_ProductEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late final TextEditingController _image;
  late bool _available;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(text: p?.price.toString() ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _image = TextEditingController(text: p?.imageUrl ?? '');
    _available = p?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    _image.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final price = int.tryParse(_price.text.trim()) ?? 0;
    if (name.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomi va narxini to\'g\'ri kiriting')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(deliveryRepositoryProvider);
      final img = _image.text.trim().isNotEmpty
          ? _image.text.trim()
          : FoodImages.getProductImage(name, null, null);
      final existing = widget.product;
      if (existing == null) {
        await repo.addProduct(
          restaurantId: widget.restaurantId,
          name: name,
          price: price,
          description: _description.text.trim(),
          imageUrl: img,
        );
      } else {
        await repo.updateProduct(existing.id, {
          'name': name,
          'price': price,
          'description': _description.text.trim(),
          'image_url': img,
          'is_available': _available,
        });
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.product == null ? "Yangi taom qo'shish" : 'Taomni tahrirlash',
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Taom nomi',
                  hintText: 'Lavash, Cheeseburger, Osh...',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Narxi (so'm)",
                  hintText: '35000',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'Tavsif (ixtiyoriy)',
                  hintText: "Mol go'shti, pishloq, sous...",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _image,
                decoration: const InputDecoration(
                  labelText: 'Rasm URL (ixtiyoriy)',
                  hintText: "Bo'sh qolsa avtomatik qo'yiladi",
                ),
              ),
              if (widget.product != null) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Menyuda mavjud'),
                  value: _available,
                  onChanged: (v) => setState(() => _available = v),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Bekor qilish'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.dark,
          ),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Saqlash'),
        ),
      ],
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
      OrderStatus.pending => AppColors.accentGold,
      OrderStatus.readyForPickup => AppColors.primaryDark,
      _ => AppColors.accentPurple,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
    );
  }
}
