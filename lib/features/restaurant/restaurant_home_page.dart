import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/food_images.dart';
import '../../core/utils/money.dart';
import '../../models/food_order.dart';
import '../../models/restaurant.dart';
import '../auth/providers/auth_providers.dart';
import '../customer/home/home_providers.dart';
import '../customer/orders/orders_providers.dart';
import '../customer/restaurants/restaurant_providers.dart';

class RestaurantHomePage extends ConsumerStatefulWidget {
  const RestaurantHomePage({super.key});

  @override
  ConsumerState<RestaurantHomePage> createState() => _RestaurantHomePageState();
}

class _RestaurantHomePageState extends ConsumerState<RestaurantHomePage>
    with SingleTickerProviderStateMixin {
  Restaurant? _selectedRestaurant;
  bool _loading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddProductDialog(String restaurantId) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();
    final imageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Yangi taom qo'shish"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Taom nomi',
                  hintText: 'Masalan: Lavash, Cheeseburger, Osh...',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Narxi (so\'m)',
                  hintText: '35000',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Tavsif (ixtiyoriy)',
                  hintText: 'Mol go\'shti, pishloq, sous...',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(
                  labelText: 'Rasm URL (bo\'sh qolsa avtomatik qo\'yiladi)',
                  hintText: 'https://...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final price = int.tryParse(priceController.text.trim()) ?? 0;
              if (name.isEmpty || price <= 0) return;
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);

              setState(() => _loading = true);
              try {
                final client = ref.read(supabaseProvider);
                final img = imageController.text.trim().isNotEmpty
                    ? imageController.text.trim()
                    : FoodImages.getProductImage(name, null, null);

                await client.from('products').insert({
                  'restaurant_id': restaurantId,
                  'name': name,
                  'price': price,
                  'description': descController.text.trim(),
                  'image_url': img,
                  'is_available': true,
                });
                ref.invalidate(productsProvider(restaurantId));
                messenger.showSnackBar(
                  const SnackBar(content: Text("Taom muvaffaqiyatli qo'shildi!")),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text(friendlyError(e))),
                );
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Qo'shish"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(restaurantsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedRestaurant == null
              ? 'Owner — Restoran Paneli'
              : _selectedRestaurant!.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: _selectedRestaurant != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedRestaurant = null),
              )
            : null,
        actions: [
          TextButton.icon(
            onPressed: () => context.go(AppRoutes.customerHome),
            icon: const Icon(Icons.storefront_rounded, size: 18),
            label: const Text('Mijoz rejimi', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Yuqori Rol Almashtirgich
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.greyLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : AppColors.borderLight, width: 0.8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => context.go(AppRoutes.customerHome),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_outline_rounded, size: 16, color: AppColors.grey),
                            SizedBox(width: 4),
                            Text(
                              'Mijoz',
                              style: TextStyle(
                                color: AppColors.grey,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.storefront_rounded, size: 16, color: AppColors.dark),
                          SizedBox(width: 4),
                          Text(
                            'Owner (Faol)',
                            style: TextStyle(
                              color: AppColors.dark,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: InkWell(
                      onTap: () => context.go(AppRoutes.adminHome),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.admin_panel_settings_outlined, size: 16, color: AppColors.grey),
                            SizedBox(width: 4),
                            Text(
                              'Admin',
                              style: TextStyle(
                                color: AppColors.grey,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: restaurantsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryDark),
              ),
              error: (e, _) => Center(child: Text(friendlyError(e))),
              data: (restaurants) {
                if (restaurants.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.storefront_outlined, size: 56, color: AppColors.grey),
                          const SizedBox(height: 12),
                          const Text(
                            'Hozircha restoranlar mavjud emas.\nAdmin panelidan yangi restoran qo\'shishingiz mumkin.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.go(AppRoutes.adminHome),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            child: const Text('Admin paneliga o\'tish'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Agar restoran tanlanmagan bo'lsa
                if (_selectedRestaurant == null) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Boshqarish uchun restoraningizni tanlang:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                      ...restaurants.map((r) {
                        final img = FoodImages.getRestaurantImage(r.name, r.imageUrl);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => setState(() => _selectedRestaurant = r),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      img,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 64,
                                        height: 64,
                                        color: AppColors.primarySoft,
                                        child: const Icon(Icons.restaurant, color: AppColors.primaryDark),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r.name,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          r.description ?? 'Mazali taomlar',
                                          style: const TextStyle(fontSize: 13, color: AppColors.grey),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          r.address ?? 'Toshkent',
                                          style: const TextStyle(fontSize: 12, color: AppColors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.grey),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }

                // Restoran tanlangan: Menyu va Buyurtmalar
                final productsAsync = ref.watch(productsProvider(_selectedRestaurant!.id));
                final ordersAsync = ref.watch(ordersProvider);

                return Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      labelColor: AppColors.dark,
                      unselectedLabelColor: AppColors.grey,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      tabs: const [
                        Tab(text: 'Taomlar menyusi', icon: Icon(Icons.restaurant_menu_rounded)),
                        Tab(text: 'Buyurtmalar', icon: Icon(Icons.receipt_long_rounded)),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // 1-Tab: Taomlar
                          Scaffold(
                            floatingActionButton: FloatingActionButton.extended(
                              onPressed: _loading
                                  ? null
                                  : () => _showAddProductDialog(_selectedRestaurant!.id),
                              backgroundColor: AppColors.primary,
                              icon: const Icon(Icons.add, color: AppColors.dark),
                              label: const Text(
                                "Yangi taom qo'shish",
                                style: TextStyle(color: AppColors.dark, fontWeight: FontWeight.w800),
                              ),
                            ),
                            body: productsAsync.when(
                              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryDark)),
                              error: (e, _) => Center(child: Text(friendlyError(e))),
                              data: (products) => products.isEmpty
                                  ? const Center(
                                      child: Text(
                                        "Bu restoranda hozircha taomlar yo'q.\nPastdagi sariq tugma orqali taom qo'shing.",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: AppColors.grey),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                                      itemCount: products.length,
                                      itemBuilder: (context, index) {
                                        final p = products[index];
                                        final img = FoodImages.getProductImage(p.name, p.categoryName, p.imageUrl);

                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                                  child: const Icon(Icons.fastfood, color: AppColors.primaryDark),
                                                ),
                                              ),
                                            ),
                                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                            subtitle: Text(
                                              formatSom(p.price),
                                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.dark),
                                            ),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                                              onPressed: () async {
                                                try {
                                                  final client = ref.read(supabaseProvider);
                                                  await client.from('products').delete().eq('id', p.id);
                                                  ref.invalidate(productsProvider(_selectedRestaurant!.id));
                                                } catch (err) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text(friendlyError(err))),
                                                    );
                                                  }
                                                }
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ),

                          // 2-Tab: Restoran Buyurtmalari
                          ordersAsync.when(
                            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryDark)),
                            error: (e, _) => Center(child: Text(friendlyError(e))),
                            data: (orders) {
                              if (orders.isEmpty) {
                                return const Center(
                                  child: Text(
                                    "Hozircha buyurtmalar kelib tushmadi.",
                                    style: TextStyle(color: AppColors.grey),
                                  ),
                                );
                              }
                              return ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: orders.length,
                                itemBuilder: (context, i) {
                                  final o = orders[i];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Buyurtma #${o.id.substring(0, 8)}',
                                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  o.status.label,
                                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Summa: ${formatSom(o.total)}',
                                            style: const TextStyle(fontWeight: FontWeight.w700),
                                          ),
                                          Text(
                                            'Manzil: ${o.addressText}',
                                            style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
                                          ),
                                          const Divider(height: 18),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              if (o.status == OrderStatus.pending)
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    try {
                                                      final client = ref.read(supabaseProvider);
                                                      await client.from('orders').update({'status': 'preparing'}).eq('id', o.id);
                                                      ref.invalidate(ordersProvider);
                                                    } catch (_) {}
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.primary,
                                                    foregroundColor: AppColors.dark,
                                                  ),
                                                  child: const Text('Qabul qilish (Tayyorlash)'),
                                                ),
                                              if (o.status == OrderStatus.preparing)
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    try {
                                                      final client = ref.read(supabaseProvider);
                                                      await client.from('orders').update({'status': 'delivered'}).eq('id', o.id);
                                                      ref.invalidate(ordersProvider);
                                                    } catch (_) {}
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.success,
                                                    foregroundColor: Colors.white,
                                                  ),
                                                  child: const Text('Yetkazildi deb belgilash'),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
