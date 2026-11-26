import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../core/widgets/ui.dart';
import '../../marketplace/marketplace_providers.dart';

/// Katalog sahifalarining umumiy qolipi: sarlavha, qidiruv va aylanadigan matn.
class CatalogScaffold extends StatelessWidget {
  const CatalogScaffold({
    super.key,
    required this.title,
    required this.children,
    required this.onRefresh,
  });

  final String title;
  final List<Widget> children;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Qidirish',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push(AppRoutes.customerSearch),
          ),
        ],
      ),
      body: ContentFrame(
        maxWidth: 900,
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 28),
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Bazadagi kategoriyalardan "Barchasi" bilan chiplar.
class CategoryChipsBar extends ConsumerWidget {
  const CategoryChipsBar({
    super.key,
    required this.kind,
    required this.selected,
    required this.onSelected,
  });

  final String kind;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list =
        ref.watch(categoriesByKindProvider(kind)).asData?.value ?? const [];
    return ChipsBar<String?>(
      selected: selected,
      onSelected: onSelected,
      items: [
        (null, 'Barchasi'),
        for (final c in list) (c.id, c.name),
      ],
    );
  }
}

/// Ro'yxat bo'lagi: yuklanish, xato va ma'lumot holatlari bir xil ko'rinadi.
class CatalogSection<T> extends StatelessWidget {
  const CatalogSection({
    super.key,
    required this.value,
    required this.onRetry,
    required this.builder,
  });

  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AsyncValueView<T>(value: value, onRetry: onRetry, builder: builder),
    );
  }
}
