import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/content_frame.dart';
import '../../../core/widgets/ui.dart';
import '../../marketplace/marketplace_providers.dart';
import '../home/home_page.dart';
import '../home/service_tiles.dart';

/// Barcha xizmatlar va faol aksiyalar.
class ServicesPage extends ConsumerWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesProvider).asData?.value;
    final promos = ref.watch(promotionsProvider).asData?.value ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Xizmatlar')),
      body: ContentFrame(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // "Boshqa" bo'limi shu sahifaning o'ziga olib keladi, ko'rsatilmaydi.
            ServiceGrid(
              services: [
                for (final s in services ?? kDefaultServices)
                  if (s.code != 'other') s,
              ],
            ),
            if (promos.isNotEmpty) ...[
              const SizedBox(height: 22),
              const SectionHeader('Aksiyalar'),
              const SizedBox(height: 10),
              for (final p in promos)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PromoBanner(
                    title: p.discountPercent == null
                        ? p.title
                        : '-${p.discountPercent}% · ${p.title}',
                    buttonLabel: "Ko'rish",
                    image: p.imageUrl,
                    onTap: () => context.push(promoRoute(p.serviceCode)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
