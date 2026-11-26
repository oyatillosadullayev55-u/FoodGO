import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/phone.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/ui.dart';
import '../../../models/marketplace.dart';
import '../../marketplace/marketplace_providers.dart';
import '../catalog/catalog_scaffold.dart';

class MastersPage extends ConsumerStatefulWidget {
  const MastersPage({super.key});

  @override
  ConsumerState<MastersPage> createState() => _MastersPageState();
}

class _MastersPageState extends ConsumerState<MastersPage> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final masters = ref.watch(mastersProvider(_category));
    return CatalogScaffold(
      title: 'Ustalar',
      onRefresh: () async {
        ref.invalidate(categoriesByKindProvider('master'));
        ref.invalidate(mastersProvider(_category));
      },
      children: [
        CategoryChipsBar(
          kind: 'master',
          selected: _category,
          onSelected: (id) => setState(() => _category = id),
        ),
        CatalogSection(
          value: masters,
          onRetry: () => ref.invalidate(mastersProvider(_category)),
          builder: (list) => list.isEmpty
              ? const EmptyView(
                  icon: Icons.engineering_outlined,
                  title: 'Usta topilmadi',
                  message: "Bu yo'nalishda hozircha tasdiqlangan usta yo'q.",
                )
              : Column(
                  children: [for (final m in list) _MasterRow(master: m)],
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: PromoBanner(
            title: "Ustalar xizmatlari endilikda OsonGo'da!",
            buttonLabel: 'Batafsil',
            image: 'assets/images/master_thumbs.webp',
            gradient: const LinearGradient(
              colors: [Color(0xFF6A2BE8), Color(0xFFB696FF)],
            ),
            onTap: () => context.push(AppRoutes.services),
          ),
        ),
      ],
    );
  }
}

class _MasterRow extends StatelessWidget {
  const _MasterRow({required this.master});

  final Master master;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      onTap: () => context.push(AppRoutes.masterPath(master.id)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AppImage(
              master.photoUrl,
              width: 74,
              height: 68,
              fallbackIcon: Icons.engineering_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  master.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                RatingLine(master.rating, count: master.ratingCount),
                const SizedBox(height: 2),
                Text(
                  [?master.specialty, ?master.eta].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                ),
              ],
            ),
          ),
          IconButton.filled(
            tooltip: "Qo'ng'iroq qilish",
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.phone_rounded, size: 19),
            onPressed: () => callPhone(context, master.phone),
          ),
        ],
      ),
    );
  }
}
