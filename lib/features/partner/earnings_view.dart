import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/earnings.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/content_frame.dart';
import '../../core/widgets/ui.dart';

/// Tarixdagi bitta yozuv.
typedef IncomeEntry = ({
  String title,
  String subtitle,
  DateTime at,
  int amount,
});

/// Bugungi va oylik daromad, 14 kunlik diagramma va tarix.
class EarningsView extends StatelessWidget {
  const EarningsView({
    super.key,
    required this.entries,
    required this.onRefresh,
    this.commission = 0,
    this.countLabel = 'ta buyurtma',
    this.extra = const [],
    this.now,
  });

  final List<IncomeEntry> entries;
  final Future<void> Function() onRefresh;

  /// Joriy oyda ushlab qolingan komissiya (0 bo'lsa ko'rsatilmaydi).
  final int commission;
  final String countLabel;
  final List<Widget> extra;

  /// Testlar uchun.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final summary = EarningsSummary.from(
      [for (final e in entries) (at: e.at, amount: e.amount)],
      now: now ?? DateTime.now(),
      days: 14,
    );
    final day = DateFormat('dd.MM');
    final full = DateFormat('dd.MM.yyyy HH:mm');

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ContentFrame(
        maxWidth: 900,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            AdaptiveGrid(
              minItemWidth: 190,
              children: [
                StatTile(
                  label: 'Bugun',
                  value: formatSom(summary.today),
                  icon: Icons.today_rounded,
                  hint: '${summary.todayCount} $countLabel',
                ),
                StatTile(
                  label: 'Shu oy',
                  value: formatSom(summary.month),
                  icon: Icons.calendar_month_rounded,
                  color: AppColors.success,
                  hint: '${summary.monthCount} $countLabel',
                ),
                if (commission > 0)
                  StatTile(
                    label: 'Komissiyadan keyin (oy)',
                    value: formatSom(summary.month - commission),
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppColors.warning,
                    hint: 'Komissiya: ${formatSom(commission)}',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Oxirgi 14 kun',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  MiniBarChart(
                    data: [
                      for (final d in summary.daily)
                        (day.format(d.day), d.amount),
                    ],
                    format: formatSom,
                  ),
                ],
              ),
            ),
            ...extra,
            const SizedBox(height: 18),
            const SectionHeader('Tarix'),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              const Text(
                "Bu davrda yakunlangan ish yo'q.",
                style: TextStyle(color: AppColors.grey),
              ),
            for (final e in entries.take(100))
              SoftCard(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${full.format(e.at)} · ${e.subtitle}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      formatSom(e.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
