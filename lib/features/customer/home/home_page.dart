import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_wordmark.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../core/widgets/ui.dart';
import '../../../models/marketplace.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/marketplace_providers.dart';
import 'service_tiles.dart';

const _fallbackCities = ["Farg'ona", "Marg'ilon", "Qo'qon", 'Toshkent'];

const _fallbackPromos = [
  Promotion(
    id: 'food',
    title: "Eng mazali taomlar faqat OsonGo'da!",
    serviceCode: 'food',
    imageUrl: 'assets/images/promo_pizza.webp',
  ),
  Promotion(
    id: 'master',
    title: 'Ustalar xizmatlari tez va ishonchli',
    serviceCode: 'master',
    imageUrl: 'assets/images/promo_master.webp',
  ),
];

/// Aksiya qaysi bo'limga olib borishi.
String promoRoute(String? serviceCode) => switch (serviceCode) {
  'master' => AppRoutes.masters,
  'shop' => AppRoutes.shops,
  'product' => AppRoutes.products,
  'delivery' => AppRoutes.delivery,
  _ => AppRoutes.restaurants,
};

/// Super-ilovaning bosh sahifasi: barcha xizmatlar bir joyda.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(servicesProvider);
    ref.invalidate(promotionsProvider);
    ref.invalidate(notificationsProvider);
    try {
      await ref.read(servicesProvider.future);
    } catch (_) {
      // Pastdagi bo'limlar standart ko'rinishda qoladi
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesProvider).asData?.value;
    final loaded = ref.watch(promotionsProvider).asData?.value;
    final promos = (loaded == null || loaded.isEmpty)
        ? _fallbackPromos
        : loaded;

    return Scaffold(
      body: SafeArea(
        child: ContentFrame(
          child: RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const _TopBar(),
                const SizedBox(height: 12),
                const _SearchBox(),
                const SizedBox(height: 16),
                const _Hero(),
                const SizedBox(height: 16),
                ServiceGrid(services: services ?? kDefaultServices),
                const SizedBox(height: 14),
                SectionHeader(
                  'Mashhur xizmatlar',
                  icon: Icons.local_fire_department_rounded,
                  actionLabel: 'Barchasi',
                  onAction: () => context.push(AppRoutes.services),
                ),
                const SizedBox(height: 6),
                _Promos(promos: promos),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar();

  Future<void> _pickRegion(BuildContext context, WidgetRef ref) async {
    List<String> names;
    try {
      final regions = await ref.read(regionsProvider.future);
      names = [
        for (final r in regions)
          if (r.kind != 'viloyat') r.name,
      ];
    } catch (_) {
      names = const [];
    }
    if (names.isEmpty) names = _fallbackCities;
    if (!context.mounted) return;

    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          for (final name in names)
            ListTile(
              leading: const Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
              ),
              title: Text(name),
              onTap: () => Navigator.pop(ctx, name),
            ),
        ],
      ),
    );
    if (picked != null) {
      await ref.read(selectedRegionProvider.notifier).set(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final region = ref.watch(selectedRegionProvider) ?? _fallbackCities.first;
    final unread = ref.watch(unreadNotificationsProvider);
    final name = ref.watch(profileProvider).asData?.value.fullName?.trim();

    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _pickRegion(context, ref),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      region,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                ],
              ),
            ),
          ),
          ),
        ),
        IconButton(
          tooltip: 'Xabarlar',
          onPressed: () => context.go(AppRoutes.customerMessages),
          icon: Badge.count(
            count: unread,
            isLabelVisible: unread > 0,
            backgroundColor: AppColors.accentRed,
            child: const Icon(Icons.notifications_none_rounded, size: 27),
          ),
        ),
        const SizedBox(width: 4),
        Semantics(
          button: true,
          label: 'Profil',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.go(AppRoutes.customerProfile),
            child: CircleAvatar(
              radius: 21,
              backgroundColor: AppColors.primary,
              child: name == null || name.isEmpty
                  ? const Icon(Icons.person_rounded, color: Colors.white)
                  : Text(
                      name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    void open() => context.push(AppRoutes.customerSearch);
    return Row(
      children: [
        Expanded(
          child: Material(
            color: isDark ? AppColors.darkSurface : AppColors.primarySoft,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: open,
              child: const SizedBox(
                height: 50,
                child: Row(
                  children: [
                    SizedBox(width: 14),
                    Icon(Icons.search_rounded, color: AppColors.grey),
                    SizedBox(width: 10),
                    Text(
                      'Nima izlaysiz?',
                      style: TextStyle(color: AppColors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filled(
          tooltip: 'Qidirish',
          onPressed: open,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            fixedSize: const Size(50, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.search_rounded),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        height: 184,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3B0DA6), Color(0xFF6A2BE8)],
          ),
        ),
        child: InkWell(
          onTap: () => context.push(AppRoutes.services),
          child: const Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: 196,
                child: FadedLeftImage(
                  'assets/images/hero_courier.webp',
                  fadeStop: 0.32,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BrandWordmark(size: 30, onDark: true),
                    SizedBox(height: 6),
                    Text(
                      'Barchasi bir ilovada!',
                      style: TextStyle(color: Colors.white, fontSize: 13.5),
                    ),
                    SizedBox(height: 18),
                    PillButton('Boshlash', filled: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Promos extends StatelessWidget {
  const _Promos({required this.promos});

  final List<Promotion> promos;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final width = promos.length == 1 ? c.maxWidth : (c.maxWidth - 10) / 2;
        return SizedBox(
          height: 146,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: promos.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final p = promos[i];
              return SizedBox(
                width: width,
                child: PromoBanner(
                  title: p.title,
                  buttonLabel: 'Buyurtma qilish',
                  image: p.imageUrl,
                  height: 146,
                  compact: true,
                  gradient: p.serviceCode == 'master'
                      ? const LinearGradient(
                          colors: [Color(0xFF14248F), AppColors.accentBlue],
                        )
                      : AppColors.brandGradient,
                  onTap: () => context.push(promoRoute(p.serviceCode)),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
