import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../marketplace/marketplace_providers.dart';
import 'catalog_scaffold.dart';
import 'product_grid.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    return CatalogScaffold(
      title: 'Mahsulotlar',
      onRefresh: () async {
        ref.invalidate(categoriesByKindProvider('shop'));
        ref.invalidate(shopProductsProvider(_category));
      },
      children: [
        CategoryChipsBar(
          kind: 'shop',
          selected: _category,
          onSelected: (id) => setState(() => _category = id),
        ),
        CatalogSection(
          value: ref.watch(shopProductsProvider(_category)),
          onRetry: () => ref.invalidate(shopProductsProvider(_category)),
          builder: (list) => ProductGrid(items: list),
        ),
      ],
    );
  }
}
