import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/food_images.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/ui.dart';
import '../../../models/restaurant.dart';
import '../../marketplace/marketplace_providers.dart';
import 'catalog_scaffold.dart';

/// Do'kon rasmi; restoranda rasm bo'lmasa nomiga qarab tanlanadi.
String? storeImage(Restaurant r) => r.isShop
    ? r.imageUrl
    : FoodImages.getRestaurantImage(r.name, r.imageUrl);

class RestaurantsPage extends ConsumerStatefulWidget {
  const RestaurantsPage({super.key});

  @override
  ConsumerState<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends ConsumerState<RestaurantsPage> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final args = (kind: 'restaurant', categoryId: _category);
    final stores = ref.watch(storesProvider(args));

    return CatalogScaffold(
      title: 'Restoranlar',
      onRefresh: () async {
        ref.invalidate(categoriesByKindProvider('food'));
        ref.invalidate(storesProvider(args));
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: PromoBanner(
            title: 'Mazali taomlar endi yanada yaqin!',
            buttonLabel: 'Buyurtma qilish',
            image: 'assets/images/burger_banner.webp',
            gradient: const LinearGradient(
              colors: [Color(0xFF150B2E), Color(0xFF4A1D6B)],
            ),
            onTap: () => context.push(AppRoutes.customerSearch),
          ),
        ),
        CategoryChipsBar(
          kind: 'food',
          selected: _category,
          onSelected: (id) => setState(() => _category = id),
        ),
        CatalogSection(
          value: stores,
          onRetry: () => ref.invalidate(storesProvider(args)),
          builder: (list) => list.isEmpty
              ? const EmptyView(
                  icon: Icons.storefront_outlined,
                  title: "Restoran topilmadi",
                )
              : StoreGrid(stores: list),
        ),
      ],
    );
  }
}

class StoreGrid extends StatelessWidget {
  const StoreGrid({super.key, required this.stores});

  final List<Restaurant> stores;

  @override
  Widget build(BuildContext context) {
    return AdaptiveGrid(
      minItemWidth: 155,
      children: [for (final r in stores) _StoreCard(store: r)],
    );
  }
}

class _StoreCard extends ConsumerWidget {
  const _StoreCard({required this.store});

  final Restaurant store;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorite = ref.watch(
      favoritesProvider.select((f) => f.contains(store.id)),
    );
    return SoftCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push(AppRoutes.restaurantPath(store.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.35,
                child: AppImage(
                  storeImage(store),
                  width: double.infinity,
                  fallbackIcon: Icons.restaurant_rounded,
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: IconButton(
                  tooltip: favorite ? 'Sevimlidan olish' : 'Sevimliga qo\'shish',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black38,
                    foregroundColor: favorite
                        ? AppColors.accentRed
                        : Colors.white,
                  ),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    favorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 19,
                  ),
                  onPressed: () =>
                      ref.read(favoritesProvider.notifier).toggle(store.id),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                RatingLine(store.rating, count: store.ratingCount),
                const SizedBox(height: 2),
                Text(
                  store.deliveryTime ?? store.workingHours ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
