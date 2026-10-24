import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../restaurants/restaurant_card.dart';
import 'home_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _search = TextEditingController();
  Timer? _debounce;
  final _selectedQuickFilter = 'all';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(restaurantQueryProvider.notifier).set(value);
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(categoriesProvider);
    ref.invalidate(restaurantsProvider);
    try {
      await ref.read(restaurantsProvider.future);
    } catch (_) {
      // Xato ekranda ko'rsatiladi
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).maybeWhen(
      data: (p) => p,
      orElse: () => null,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.dark,
          backgroundColor: AppColors.primary,
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // 1. Yandex manzillar va yetkazish vaqti paneli
              _YandexAddressBar(address: profile?.fullName != null ? 'Toshkent, Amir Temur sh.' : 'Yetkazish manzilini tanlang'),
              const SizedBox(height: 14),

              // 2. Yandex uslubidagi qidiruv paneli
              _YandexSearchBar(
                controller: _search,
                onChanged: _onSearchChanged,
                onClear: () {
                  _search.clear();
                  ref.read(restaurantQueryProvider.notifier).set('');
                },
              ),
              const SizedBox(height: 18),

              // 3. Yandex Go / Eats aksiyalar va storiyalar karuseli
              const _YandexPromoBanners(),
              const SizedBox(height: 18),

              // 4. Kategoriya ikonkalari
              const _QuickCategoryIcons(),
              const SizedBox(height: 12),

              // 5. Kategoriya chipslari
              _CategoryChips(),
              const SizedBox(height: 20),

              // 6. Restoranlar sarlavhasi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Restoranlar',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : AppColors.greyLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 14, color: AppColors.grey),
                        SizedBox(width: 4),
                        Text(
                          'Filter',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 7. Restoranlar ro'yxati
              _RestaurantList(quickFilter: _selectedQuickFilter),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== Yandex Manzil va Vaqt Paneli =====
class _YandexAddressBar extends StatelessWidget {
  const _YandexAddressBar({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // Manzil tanlash
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Yetkazish manzili: Toshkent shahri'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_on_rounded, size: 18, color: AppColors.dark),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              'Yetkazish manzili',
                              style: TextStyle(fontSize: 11, color: AppColors.grey, fontWeight: FontWeight.w600),
                            ),
                            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.grey),
                          ],
                        ),
                        Text(
                          address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Yetkazish vaqti badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white12 : AppColors.borderLight),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, size: 16, color: AppColors.yandexRed),
              SizedBox(width: 4),
              Text(
                '25 daq',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===== Yandex Qidiruv Paneli =====
class _YandexSearchBar extends StatelessWidget {
  const _YandexSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.greyLight,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Restoran yoki taom qidirish...',
          hintStyle: const TextStyle(color: AppColors.grey, fontSize: 14, fontWeight: FontWeight.w400),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.dark, size: 22),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.grey),
                  onPressed: onClear,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

// ===== Yandex Aksiya va Reklama Bannerlari =====
class _YandexPromoBanners extends StatelessWidget {
  const _YandexPromoBanners();

  @override
  Widget build(BuildContext context) {
    final banners = [
      _PromoData(
        title: 'Tezkor yetkazish',
        subtitle: '20–30 daqiqada',
        caption: 'Issiq taomlar eshigingizda',
        color: AppColors.primary,
        textColor: AppColors.dark,
        icon: Icons.delivery_dining_rounded,
        tag: 'Yandex Go',
      ),
      _PromoData(
        title: '20% chegirma',
        subtitle: 'Barcha yangi mijozlarga',
        caption: 'Promokod: GO20',
        color: AppColors.yandexRed,
        textColor: Colors.white,
        icon: Icons.local_offer_rounded,
        tag: 'AKSIYA',
      ),
      _PromoData(
        title: 'Yandex Plus',
        subtitle: '+10% keshbek',
        caption: 'Har bir buyurtmada ballar',
        color: const Color(0xFF6A11CB),
        textColor: Colors.white,
        icon: Icons.star_rounded,
        tag: 'Plus',
      ),
      _PromoData(
        title: 'Bepul yetkazish',
        subtitle: '50 000 so\'mdan yuqori',
        caption: 'Tanlangan restoranlarda',
        color: const Color(0xFF2E9E5B),
        textColor: Colors.white,
        icon: Icons.eco_rounded,
        tag: '0 so\'m',
      ),
    ];

    return SizedBox(
      height: 122,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: banners.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final b = banners[index];
          return Container(
            width: 250,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: b.color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: b.color.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        b.tag,
                        style: TextStyle(
                          color: b.textColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      b.title,
                      style: TextStyle(
                        color: b.textColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      b.subtitle,
                      style: TextStyle(
                        color: b.textColor.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Icon(
                    b.icon,
                    size: 54,
                    color: b.textColor.withValues(alpha: 0.22),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PromoData {
  const _PromoData({
    required this.title,
    required this.subtitle,
    required this.caption,
    required this.color,
    required this.textColor,
    required this.icon,
    required this.tag,
  });

  final String title;
  final String subtitle;
  final String caption;
  final Color color;
  final Color textColor;
  final IconData icon;
  final String tag;
}

// ===== Tezkor Kategoriya Ikonkalari (Yandex uslubi) =====
class _QuickCategoryIcons extends ConsumerWidget {
  const _QuickCategoryIcons();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final quicks = [
      {'emoji': '🍔', 'name': 'Burger'},
      {'emoji': '🍕', 'name': 'Pitsa'},
      {'emoji': '🍣', 'name': 'Sushi'},
      {'emoji': '🍗', 'name': 'Fastfood'},
      {'emoji': '☕', 'name': 'Qahva'},
      {'emoji': '🍲', 'name': 'Milliy'},
      {'emoji': '🍰', 'name': 'Shirinlik'},
      {'emoji': '🥗', 'name': 'Salat'},
    ];

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: quicks.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final item = quicks[i];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              ref.read(restaurantQueryProvider.notifier).set(item['name']!);
            },
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? Colors.white10 : AppColors.borderLight,
                      width: 0.8,
                    ),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      item['emoji']!,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item['name']!,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ===== Kategoriya Chipslari =====
class _CategoryChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final selected = ref.watch(selectedCategoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return categories.maybeWhen(
      data: (list) => SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _chip(
              context,
              label: 'Barchasi',
              isSelected: selected == null,
              isDark: isDark,
              onTap: () =>
                  ref.read(selectedCategoryProvider.notifier).select(null),
            ),
            for (final c in list)
              _chip(
                context,
                label: '${c.icon ?? ''} ${c.name}'.trim(),
                isSelected: selected == c.id,
                isDark: isDark,
                onTap: () => ref
                    .read(selectedCategoryProvider.notifier)
                    .select(selected == c.id ? null : c.id),
              ),
          ],
        ),
      ),
      orElse: () => const SizedBox(height: 40),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkSurface : AppColors.greyLight),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? Colors.white10 : AppColors.borderLight),
              width: 0.8,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? AppColors.dark
                  : (isDark ? Colors.white70 : AppColors.dark),
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ===== Restoranlar Ro'yxati =====
class _RestaurantList extends ConsumerWidget {
  const _RestaurantList({required this.quickFilter});

  final String quickFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurants = ref.watch(restaurantsProvider);

    return restaurants.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryDark),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: ErrorView(
          message: friendlyError(e),
          onRetry: () => ref.invalidate(restaurantsProvider),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: EmptyView(
              icon: Icons.search_off_rounded,
              title: 'Restoran topilmadi',
              message: "Boshqa nom yoki kategoriya bilan qidirib ko'ring.",
            ),
          );
        }
        return Column(
          children: [
            for (final r in list)
              RestaurantCard(
                restaurant: r,
                onTap: () => context.push(AppRoutes.restaurantPath(r.id)),
              ),
          ],
        );
      },
    );
  }
}
