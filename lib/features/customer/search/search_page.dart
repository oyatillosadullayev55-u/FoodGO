import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../home/home_providers.dart';
import '../restaurants/restaurant_card.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;

  final _popularQueries = [
    'Lavash',
    'Burger',
    'Pitsa',
    'Osh',
    'Kofe',
    'Sushi',
    'Shashlik',
    'Somsa',
    'Doner',
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(restaurantQueryProvider.notifier).set(val);
    });
  }

  void _selectQuery(String q) {
    _controller.text = q;
    ref.read(restaurantQueryProvider.notifier).set(q);
  }

  @override
  Widget build(BuildContext context) {
    final restaurants = ref.watch(restaurantsProvider);
    final query = ref.watch(restaurantQueryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Qidiruv', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          // Yandex uslubidagi qidiruv maydoni
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.greyLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                controller: _controller,
                autofocus: false,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Restoran, taom yoki oshxona...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.dark, size: 22),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.grey),
                          onPressed: () {
                            _controller.clear();
                            ref.read(restaurantQueryProvider.notifier).set('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Ommabop so'rovlar chipslari
          if (query.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ommabop qidiruvlar',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.grey,
                      ),
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _popularQueries.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final item = _popularQueries[i];
                  return ActionChip(
                    label: Text(item),
                    backgroundColor: isDark ? AppColors.darkSurface : AppColors.greyLight,
                    side: BorderSide(color: isDark ? Colors.white10 : AppColors.borderLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark ? Colors.white : AppColors.dark,
                    ),
                    onPressed: () => _selectQuery(item),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Natijalar ro'yxati
          Expanded(
            child: restaurants.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryDark),
              ),
              error: (e, _) => ErrorView(
                message: friendlyError(e),
                onRetry: () => ref.invalidate(restaurantsProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyView(
                    icon: Icons.search_off_rounded,
                    title: 'Hech narsa topilmadi',
                    message: "Boshqa so'z yoki taom nomi bilan izlab ko'ring.",
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final r = list[i];
                    return RestaurantCard(
                      restaurant: r,
                      onTap: () => context.push(AppRoutes.restaurantPath(r.id)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
