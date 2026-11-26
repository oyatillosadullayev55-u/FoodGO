import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/ui.dart';
import '../../../repositories/admin_repository.dart';
import '../admin_providers.dart';

/// Signal subyekti foydalanuvchi bo'lgan turlar (bloklash mumkin).
const _userSignals = {'many_cancellations', 'order_burst', 'shared_phone'};

/// Qoidaga asoslangan shubhali holatlar ro'yxati.
class FraudPage extends ConsumerWidget {
  const FraudPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentFrame(
      maxWidth: 1000,
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(adminFraudProvider.future),
        child: AsyncValueView<List<DbRow>>(
          value: ref.watch(adminFraudProvider),
          onRetry: () => ref.invalidate(adminFraudProvider),
          builder: (signals) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const SoftCard(
                child: Text(
                  "Bu ro'yxat sodda qoidalarga asoslangan va dalil emas: "
                  "bloklashdan oldin buyurtmalarni tekshiring.\n"
                  "Qoidalar: 7 kunda 3+ bekor qilish, 1 soatda 5+ buyurtma, "
                  "o'rtachadan 5 barobar katta summa, bitta telefon 3+ hisobda.",
                  style: TextStyle(fontSize: 12.5),
                ),
              ),
              const SizedBox(height: 12),
              if (signals.isEmpty)
                const EmptyView(
                  icon: Icons.verified_rounded,
                  title: "Shubhali holat yo'q",
                ),
              for (final s in signals) _card(context, ref, s),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, WidgetRef ref, DbRow s) {
    final high = s['severity'] == 'high';
    final color = high ? AppColors.error : AppColors.warning;
    return SoftCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(Icons.warning_amber_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s['subject'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${s['detail']} (${s['hits']})',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
                ),
                const SizedBox(height: 6),
                StatusPill(high ? 'Yuqori xavf' : "O'rta xavf", color: color),
              ],
            ),
          ),
          if (_userSignals.contains(s['signal']))
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: () async {
                final sure = await confirmDialog(
                  context,
                  title: 'Foydalanuvchi bloklansinmi?',
                  message: s['signal'] == 'shared_phone'
                      ? 'Shu telefonni ishlatgan hisoblardan bittasi '
                            'bloklanadi. Qolganlarini Foydalanuvchilar '
                            "bo'limida tekshiring."
                      : s['subject'] as String,
                  action: 'Bloklash',
                );
                if (!sure || !context.mounted) return;
                final ok = await runAdminAction(
                  context,
                  () => ref.read(adminRepositoryProvider).update(
                    'profiles',
                    s['subject_id'] as String,
                    {'is_blocked': true},
                  ),
                );
                if (ok && context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Bloklandi')));
                }
              },
              child: const Text('Bloklash'),
            ),
        ],
      ),
    );
  }
}
