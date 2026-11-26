import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ui.dart';
import '../../../models/restaurant.dart';
import '../../marketplace/marketplace_providers.dart';
import 'catalog_scaffold.dart';
import 'product_grid.dart';
import 'restaurants_page.dart';

/// Magazinlar: do'konlar qatori va ularning mahsulotlari.
class ShopsPage extends ConsumerStatefulWidget {
  const ShopsPage({super.key});

  @override
  ConsumerState<ShopsPage> createState() => _ShopsPageState();
}

class _ShopsPageState extends ConsumerState<ShopsPage> {
  static const _shops = (kind: 'shop', categoryId: null);
  String? _category;

  @override
  Widget build(BuildContext context) {
    final shops = ref.watch(storesProvider(_shops)).asData?.value ?? const [];
    final products = ref.watch(shopProductsProvider(_category));

    return CatalogScaffold(
      title: 'Magazinlar',
      onRefresh: () async {
        ref.invalidate(categoriesByKindProvider('shop'));
        ref.invalidate(storesProvider(_shops));
        ref.invalidate(shopProductsProvider(_category));
      },
      children: [
        CategoryChipsBar(
          kind: 'shop',
          selected: _category,
          onSelected: (id) => setState(() => _category = id),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: PromoBanner(
            title: "Onlayn do'konlar siz uchun!",
            buttonLabel: "Ko'rish",
            image: 'assets/images/headphones.webp',
            onTap: () => context.push(AppRoutes.products),
          ),
        ),
        if (shops.isNotEmpty) _ShopStrip(shops: shops),
        CatalogSection(
          value: products,
          onRetry: () => ref.invalidate(shopProductsProvider(_category)),
          builder: (list) => ProductGrid(items: list),
        ),
      ],
    );
  }
}

class _ShopStrip extends StatelessWidget {
  const _ShopStrip({required this.shops});

  final List<Restaurant> shops;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          for (final s in shops)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: SoftCard(
                padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
                onTap: () => context.push(AppRoutes.restaurantPath(s.id)),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AppImage(
                        storeImage(s),
                        width: 42,
                        height: 42,
                        fallbackIcon: Icons.storefront_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          s.deliveryTime ?? "Do'kon",
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
