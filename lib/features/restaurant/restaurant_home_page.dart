import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product.dart';
import '../../models/restaurant.dart';
import '../auth/providers/auth_providers.dart';
import '../customer/home/home_providers.dart';
import '../customer/restaurants/restaurant_providers.dart';

class RestaurantHomePage extends ConsumerStatefulWidget {
  const RestaurantHomePage({super.key});

  @override
  ConsumerState<RestaurantHomePage> createState() => _RestaurantHomePageState();
}

class _RestaurantHomePageState extends ConsumerState<RestaurantHomePage> {
  Restaurant? _selectedRestaurant;
  bool _loading = false;

  void _showAddProductDialog(String restaurantId) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();
    final imageController = TextEditingController(
      text: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500',
    );

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
                decoration: const InputDecoration(labelText: 'Taom nomi'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Narxi (so\'m)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Tavsif'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(labelText: 'Rasm URL manzili'),
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
              Navigator.pop(context);

              setState(() => _loading = true);
              try {
                final client = ref.read(supabaseProvider);
                await client.from('products').insert({
                  'restaurant_id': restaurantId,
                  'name': name,
                  'price': price,
                  'description': descController.text.trim(),
                  'image_url': imageController.text.trim(),
                  'is_available': true,
                });
                ref.invalidate(productsProvider(restaurantId));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Taom muvaffaqiyatli qo'shildi!")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(friendlyError(e))),
                  );
                }
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedRestaurant == null
              ? 'Hamkor (Restoran) Paneli'
              : 'Menyu: ${_selectedRestaurant!.name}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: _selectedRestaurant != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedRestaurant = null),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              ref.invalidate(profileProvider);
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: restaurantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryDark)),
        error: (e, _) => Center(child: Text(friendlyError(e))),
        data: (restaurants) {
          if (restaurants.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Hozircha hamkor restoranlar mavjud emas.\nAdmin panelidan restoran qo\'shing.',
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

          if (_selectedRestaurant == null) {
            // Restoran tanlash oynasi
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Mahsulot kiritish uchun restoraningizni tanlang:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                ...restaurants.map((r) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: r.imageUrl != null
                              ? Image.network(r.imageUrl!, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 50, height: 50, color: Colors.grey[300]))
                              : Container(width: 50, height: 50, color: Colors.grey[300]),
                        ),
                        title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        subtitle: Text(r.description ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => setState(() => _selectedRestaurant = r),
                      ),
                    )),
              ],
            );
          }

          // Tanlangan restoran menyusi va taomlar
          final productsAsync = ref.watch(productsProvider(_selectedRestaurant!.id));

          return Scaffold(
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _loading ? null : () => _showAddProductDialog(_selectedRestaurant!.id),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: AppColors.dark),
              label: const Text("Taom (Mahsulot) qo'shish", style: TextStyle(color: AppColors.dark, fontWeight: FontWeight.w800)),
            ),
            body: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(friendlyError(e))),
              data: (products) => products.isEmpty
                  ? const Center(
                      child: Text(
                        "Bu restoranda hozircha taomlar yo'q.\nPastdagi tugma orqali taom qo'shing.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final p = products[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: p.imageUrl != null
                                  ? Image.network(p.imageUrl!, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 50, height: 50, color: Colors.grey[300]))
                                  : Container(width: 50, height: 50, color: Colors.grey[300]),
                            ),
                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text('${p.price} so\'m', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.dark)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.error),
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
          );
        },
      ),
    );
  }
}