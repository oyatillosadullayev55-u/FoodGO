import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../core/widgets/ui.dart';
import '../../../repositories/admin_repository.dart';
import '../admin_providers.dart';

final _complaints = tableQuery('complaints');

const _statuses = {
  'open': ('Yangi', AppColors.warning),
  'in_review': ("Ko'rilmoqda", AppColors.primary),
  'resolved': ('Hal qilindi', AppColors.success),
  'rejected': ('Rad etildi', AppColors.error),
};

/// Mijoz va sotuvchi nizolari.
class DisputesPage extends ConsumerStatefulWidget {
  const DisputesPage({super.key});

  @override
  ConsumerState<DisputesPage> createState() => _DisputesPageState();
}

class _DisputesPageState extends ConsumerState<DisputesPage> {
  String? _status = 'open';

  Future<void> _update(DbRow complaint, DbRow values) async {
    final ok = await runAdminAction(
      context,
      () => ref
          .read(adminRepositoryProvider)
          .update('complaints', complaint['id'] as String, values),
    );
    if (ok) ref.invalidate(adminTableProvider(_complaints));
  }

  Future<void> _decide(DbRow complaint) async {
    final values = await showDialog<DbRow>(
      context: context,
      builder: (_) => const _DecisionDialog(),
    );
    if (values != null && mounted) await _update(complaint, values);
  }

  @override
  Widget build(BuildContext context) {
    final provider = adminTableProvider(_complaints);
    return ContentFrame(
      maxWidth: 1000,
      child: AsyncValueView<List<DbRow>>(
        value: ref.watch(provider),
        onRetry: () => ref.invalidate(provider),
        builder: (all) {
          final shown = [
            for (final c in all)
              if (_status == null || c['status'] == _status) c,
          ];
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 14),
            children: [
              ChipsBar<String?>(
                selected: _status,
                onSelected: (s) => setState(() => _status = s),
                items: [
                  for (final s in _statuses.entries)
                    (
                      s.key,
                      '${s.value.$1} '
                          '(${all.where((c) => c['status'] == s.key).length})',
                    ),
                  (null, 'Barchasi'),
                ],
              ),
              if (shown.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    "Bu bo'limda shikoyat yo'q",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.grey),
                  ),
                ),
              for (final c in shown)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: _card(c),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _card(DbRow c) {
    final status = c['status'] as String;
    final (label, color) = _statuses[status]!;
    final open = status == 'open' || status == 'in_review';
    final order = c['order_id'] as String?;
    final request = c['service_request_id'] as String?;
    final refund = (c['refund_amount'] as num?)?.toInt() ?? 0;

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c['subject'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              StatusPill(label, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(c['body'] as String),
          const SizedBox(height: 6),
          Text(
            [
              DateFormat('dd.MM.yyyy HH:mm').format(
                DateTime.parse(c['created_at'] as String).toLocal(),
              ),
              if (order != null) 'Buyurtma #${order.substring(0, 8)}',
              if (request != null) 'Xizmat #${request.substring(0, 8)}',
            ].join(' · '),
            style: const TextStyle(fontSize: 12, color: AppColors.grey),
          ),
          if (c['resolution'] != null) Text('Qaror: ${c['resolution']}'),
          if (refund > 0) Text('Qaytarish: ${formatSom(refund)}'),
          if (open) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (status == 'open')
                  OutlinedButton(
                    onPressed: () => _update(c, {'status': 'in_review'}),
                    child: const Text("Ko'rib chiqishga olish"),
                  ),
                FilledButton(
                  onPressed: () => _decide(c),
                  child: const Text('Qaror qabul qilish'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DecisionDialog extends StatefulWidget {
  const _DecisionDialog();

  @override
  State<_DecisionDialog> createState() => _DecisionDialogState();
}

class _DecisionDialogState extends State<_DecisionDialog> {
  final _resolution = TextEditingController();
  final _refund = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _resolution.dispose();
    _refund.dispose();
    super.dispose();
  }

  void _submit(String status) {
    final text = _resolution.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Qaror matnini yozing');
      return;
    }
    Navigator.pop<DbRow>(context, {
      'status': status,
      'resolution': text,
      'refund_amount': status == 'resolved'
          ? int.tryParse(_refund.text) ?? 0
          : 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nizo bo\'yicha qaror'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _resolution,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Mijozga javob',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _refund,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                decoration: const InputDecoration(
                  labelText: "Qaytariladigan summa (ixtiyoriy)",
                  helperText:
                      "Faqat moliyada qayd etiladi, pul o'zi o'tkazilmaydi",
                  helperMaxLines: 2,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Yopish'),
        ),
        TextButton(
          onPressed: () => _submit('rejected'),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Rad etish'),
        ),
        FilledButton(
          onPressed: () => _submit('resolved'),
          child: const Text('Hal qilindi'),
        ),
      ],
    );
  }
}
