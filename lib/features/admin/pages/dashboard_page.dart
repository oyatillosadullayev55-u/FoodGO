import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../core/widgets/ui.dart';
import '../../../repositories/admin_repository.dart';
import '../admin_providers.dart';

/// Savdo, foyda va o'sish ko'rsatkichlari.
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key, this.onOpenVerification, this.onOpenDisputes});

  final VoidCallback? onOpenVerification;
  final VoidCallback? onOpenDisputes;

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _days = 14;

  @override
  Widget build(BuildContext context) {
    final provider = adminAnalyticsProvider(_days);
    return ContentFrame(
      maxWidth: 1200,
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(provider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            ChipsBar<int>(
              selected: _days,
              onSelected: (d) => setState(() => _days = d),
              items: const [(7, '7 kun'), (14, '14 kun'), (30, '30 kun')],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: AsyncValueView<DbRow>(
                value: ref.watch(provider),
                onRetry: () => ref.invalidate(provider),
                builder: _content,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(DbRow a) {
    int n(String key) => (a[key] as num?)?.toInt() ?? 0;
    final daily = [
      for (final d in (a['daily'] as List? ?? const []))
        Map<String, dynamic>.from(d as Map),
    ];
    final top = [
      for (final d in (a['top_stores'] as List? ?? const []))
        Map<String, dynamic>.from(d as Map),
    ];
    final day = DateFormat('dd.MM');
    List<(String, int)> series(String key) => [
      for (final d in daily)
        (
          day.format(DateTime.parse(d['day'] as String)),
          (d[key] as num).toInt(),
        ),
    ];

    Widget tappable(Widget child, VoidCallback? onTap) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: IgnorePointer(child: child),
    );

    Widget chart(String title, Widget body) => SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          body,
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdaptiveGrid(
          minItemWidth: 220,
          children: [
            StatTile(
              label: 'Savdo hajmi',
              value: formatSom(n('revenue')),
              icon: Icons.payments_rounded,
              hint: '${n('delivered')} ta yetkazilgan',
            ),
            StatTile(
              label: 'Platforma komissiyasi',
              value: formatSom(n('commission')),
              icon: Icons.trending_up_rounded,
              color: AppColors.success,
            ),
            StatTile(
              label: 'Buyurtmalar',
              value: '${n('orders')}',
              icon: Icons.receipt_long_rounded,
              color: AppColors.accentBlue,
              hint: '${n('cancelled')} ta bekor qilingan',
            ),
            StatTile(
              label: 'Xizmat so\'rovlari',
              value: '${n('service_requests')}',
              icon: Icons.engineering_rounded,
              color: AppColors.warning,
            ),
            StatTile(
              label: 'Foydalanuvchilar',
              value: '${n('users')}',
              icon: Icons.people_rounded,
              hint: "${n('stores')} do'kon · ${n('masters')} usta",
            ),
            tappable(
              StatTile(
                label: 'Tasdiq kutayotgan',
                value: '${n('pending_partners')}',
                icon: Icons.verified_user_rounded,
                color: AppColors.warning,
                hint: "Ko'rish uchun bosing",
              ),
              widget.onOpenVerification,
            ),
            tappable(
              StatTile(
                label: 'Ochiq shikoyatlar',
                value: '${n('open_complaints')}',
                icon: Icons.gavel_rounded,
                color: AppColors.error,
                hint: "Ko'rish uchun bosing",
              ),
              widget.onOpenDisputes,
            ),
          ],
        ),
        const SizedBox(height: 14),
        AdaptiveGrid(
          minItemWidth: 380,
          children: [
            chart(
              'Kunlik savdo',
              MiniBarChart(data: series('revenue'), format: formatSom),
            ),
            chart(
              'Kunlik buyurtmalar',
              MiniBarChart(data: series('orders'), format: (v) => '$v ta'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const SectionHeader("Eng yaxshi do'konlar"),
        const SizedBox(height: 8),
        if (top.isEmpty)
          const Text(
            "Bu davrda buyurtma bo'lmagan.",
            style: TextStyle(color: AppColors.grey),
          ),
        for (var i = 0; i < top.length; i++)
          SoftCard(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    top[i]['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '${top[i]['orders']} ta · '
                  '${formatSom(top[i]['revenue'] as num)}',
                ),
              ],
            ),
          ),
      ],
    );
  }
}
