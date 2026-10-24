import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../auth/providers/auth_providers.dart';
import '../customer/home/home_providers.dart';

class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  bool _loading = false;

  void _showAddRestaurantDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final addressController = TextEditingController();
    final imageController = TextEditingController(
      text: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=500',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Yangi hamkor restoran qo'shish"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Restoran nomi'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Tavsif (masalan: Fast food, Milliy taomlar)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Manzil'),
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
              if (name.isEmpty) return;
              Navigator.pop(context);

              setState(() => _loading = true);
              try {
                final client = ref.read(supabaseProvider);
                await client.from('restaurants').insert({
                  'name': name,
                  'description': descController.text.trim().isEmpty ? 'Mazali taomlar' : descController.text.trim(),
                  'address': addressController.text.trim().isEmpty ? 'Toshkent sh.' : addressController.text.trim(),
                  'image_url': imageController.text.trim(),
                  'rating': 4.9,
                  'open_time': '08:00:00',
                  'close_time': '23:00:00',
                });
                ref.invalidate(restaurantsProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Restoran muvaffaqiyatli qo'shildi!")),
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
        title: const Text('Admin Paneli — Hamkorlar', style: TextStyle(fontWeight: FontWeight.w800)),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _showAddRestaurantDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.dark),
        label: const Text("Hamkor (Restoran) qo'shish", style: TextStyle(color: AppColors.dark, fontWeight: FontWeight.w800)),
      ),
      body: restaurantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryDark)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(friendlyError(e), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(restaurantsProvider),
                child: const Text('Qayta urinish'),
              ),
            ],
          ),
        ),
        data: (restaurants) => ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: restaurants.length,
          itemBuilder: (context, index) {
            final r = restaurants[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: r.imageUrl != null
                      ? Image.network(r.imageUrl!, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: Colors.grey[300]))
                      : Container(width: 60, height: 60, color: Colors.grey[300]),
                ),
                title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(r.description ?? '', style: const TextStyle(fontSize: 13, color: AppColors.grey)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text('${r.rating}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        const SizedBox(width: 12),
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.grey),
                        const SizedBox(width: 2),
                        Expanded(child: Text(r.address ?? 'Toshkent', style: const TextStyle(fontSize: 12, color: AppColors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Restoranni o'chirish"),
                        content: Text("'${r.name}' restoranini o'chirmoqchimisiz?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Yo'q")),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(foregroundColor: AppColors.error),
                            child: const Text("O'chirish"),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    try {
                      final client = ref.read(supabaseProvider);
                      await client.from('restaurants').delete().eq('id', r.id);
                      ref.invalidate(restaurantsProvider);
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
  }
}
