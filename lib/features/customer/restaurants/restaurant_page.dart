import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../models/product.dart';
import '../../../models/restaurant.dart';
import '../cart/cart_provider.dart';
import '../products/product_tile.dart';
import 'restaurant_providers.dart';

class RestaurantPage extends ConsumerWidget {
  const RestaurantPage({super.key, required this.restaurantId});

  final String restaurantId;

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(restaurantProvider(restaurantId));
    ref.invalidate(productsProvider(restaurantId));
    try {
      await ref.read(productsProvider(restaurantId).future);
    } catch (_) {
      // Xato ekranda ErrorView orqali ko'rsatiladi.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurant = ref.watch(restaurantProvider(restaurantId));
    final products = ref.watch(productsProvider(restaurantId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          restaurant.maybeWhen(data: (r) => r.name, orElse: () => ''),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Havola nusxalandi')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sevimlilarga qo\'shildi')),
              );
            },
          ),
        ],
      ),
      body: restaurant.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryDark),
        ),
        error: (e, _) => ErrorView(
          message: friendlyError(e),
          onRetry: () => _refresh(ref),
        ),
        data: (r) => RefreshIndicator(
          color: AppColors.dark,
          backgroundColor: AppColors.primary,
          onRefresh: () => _refresh(ref),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
            children: [
              _Header(restaurant: r),
              const SizedBox(height: 18),
              products.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primaryDark),
                  ),
                ),
                error: (e, _) => ErrorView(
                  message: friendlyError(e),
                  onRetry: () => ref.invalidate(productsProvider(restaurantId)),
                ),
                data: (list) => list.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: EmptyView(
                          icon: Icons.restaurant_menu_rounded,
                          title: "Menyu hali bo'sh",
                          message: "Bu restoran hali taom qo'shmagan.",
                        ),
                      )
                    : _Menu(restaurant: r, products: list),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: _CartBar(restaurantId: restaurantId),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.borderLight,
          width: 0.8,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rasm
          SizedBox(
            height: 180,
            width: double.infinity,
            child: r.imageUrl == null
                ? const _HeaderPlaceholder()
                : CachedNetworkImage(
                    imageUrl: r.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const _HeaderPlaceholder(),
                    errorWidget: (_, _, _) => const _HeaderPlaceholder(),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        r.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: AppColors.dark),
                          const SizedBox(width: 3),
                          Text(
                            r.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppColors.dark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (r.description != null && r.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    r.description!,
                    style: const TextStyle(color: AppColors.grey, fontSize: 13.5),
                  ),
                ],
                const SizedBox(height: 14),
                // Yandex ma'lumotlar qatori: Yetkazish vaqti, narxi, manzil
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _badge(
                      Icons.schedule_rounded,
                      '20–30 daq',
                      isDark: isDark,
                    ),
                    _badge(
                      Icons.delivery_dining_rounded,
                      'Yetkazish ${formatSom(kDeliveryFee)}',
                      isDark: isDark,
                    ),
                    if (r.workingHours != null)
                      _badge(
                        Icons.access_time_rounded,
                        r.workingHours!,
                        isDark: isDark,
                      ),
                  ],
                ),
                if (r.address != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          r.address!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.grey, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String label, {required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.greyLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.dark),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderPlaceholder extends StatelessWidget {
  const _HeaderPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primarySoft,
      child: const Center(
        child: Icon(Icons.restaurant_rounded, size: 56, color: AppColors.primaryDark),
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.restaurant, required this.products});

  final Restaurant restaurant;
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Product>>{};
    for (final p in products) {
      groups.putIfAbsent(p.categoryName ?? 'Boshqa', () => []).add(p);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 10),
            child: Row(
              children: [
                Text(
                  entry.key,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.value.length}',
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          for (final p in entry.value)
            ProductTile(restaurant: restaurant, product: p),
        ],
      ],
    );
  }
}

class _CartBar extends ConsumerWidget {
  const _CartBar({required this.restaurantId});

  final String restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    if (cart.isEmpty || cart.restaurant?.id != restaurantId) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.go(AppRoutes.customerCart),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.dark,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${cart.count}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Savatga o\'tish',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.dark,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      formatSom(cart.subtotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, color: AppColors.dark, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}