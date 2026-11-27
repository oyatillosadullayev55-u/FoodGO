import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../core/widgets/ui.dart';
import '../../../repositories/admin_repository.dart';
import '../../partner/documents_card.dart';
import '../admin_providers.dart';

final _stores = tableQuery('restaurants', orderBy: 'name', ascending: true);
final _masters = tableQuery('masters', orderBy: 'created_at');
final _documents = tableQuery('partner_documents');
final _profiles = tableQuery('profiles', orderBy: 'full_name', ascending: true);

/// Do'kon va ustalarni tasdiqlash, hujjatlarni tekshirish.
class VerificationPage extends StatelessWidget {
  const VerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: "Do'konlar"),
              Tab(text: 'Ustalar'),
              Tab(text: 'Hujjatlar'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _PartnerList(table: 'restaurants'),
                _PartnerList(table: 'masters'),
                _DocumentList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerList extends ConsumerStatefulWidget {
  const _PartnerList({required this.table});

  final String table;

  @override
  ConsumerState<_PartnerList> createState() => _PartnerListState();
}

class _PartnerListState extends ConsumerState<_PartnerList> {
  String? _status = 'pending';

  bool get _isMaster => widget.table == 'masters';
  TableQuery get _query => _isMaster ? _masters : _stores;

  Future<void> _update(DbRow row, DbRow values) async {
    final ok = await runAdminAction(
      context,
      () => ref
          .read(adminRepositoryProvider)
          .update(widget.table, row['id'] as String, values),
    );
    if (ok) ref.invalidate(adminTableProvider(_query));
  }

  Future<void> _commission(DbRow row) async {
    final controller = TextEditingController(
      text: row['commission_percent']?.toString() ?? '',
    );
    // '' — umumiy qoidaga qaytarish, null — bekor qilindi.
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alohida komissiya'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Foiz (0–100)',
            helperText: "Bo'sh qoldirilsa umumiy qoida ishlaydi",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              final value = num.tryParse(text);
              if (text.isEmpty ||
                  (value != null && value >= 0 && value <= 100)) {
                Navigator.pop(ctx, text);
              }
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    await _update(row, {'commission_percent': num.tryParse(result)});
  }

  @override
  Widget build(BuildContext context) {
    final provider = adminTableProvider(_query);
    return ContentFrame(
      maxWidth: 1000,
      child: AsyncValueView<List<DbRow>>(
        value: ref.watch(provider),
        onRetry: () => ref.invalidate(provider),
        builder: (all) {
          final shown = [
            for (final r in all)
              if (_status == null || r['verification_status'] == _status) r,
          ];
          final pending = all
              .where((r) => r['verification_status'] == 'pending')
              .length;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              ChipsBar<String?>(
                selected: _status,
                onSelected: (s) => setState(() => _status = s),
                items: [
                  ('pending', 'Kutilmoqda ($pending)'),
                  ('approved', 'Tasdiqlangan'),
                  ('rejected', 'Rad etilgan'),
                  (null, 'Barchasi'),
                ],
              ),
              if (shown.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    "Bu bo'limda hamkor yo'q",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.grey),
                  ),
                ),
              for (final r in shown)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: _card(r),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _card(DbRow r) {
    final status = r['verification_status'] as String? ?? 'pending';
    final title = (r[_isMaster ? 'full_name' : 'name'] ?? '') as String;
    final details = [
      if (!_isMaster) r['kind'] == 'shop' ? 'Magazin' : 'Restoran',
      r['owner_email'],
      r['phone'],
      r['address'],
    ].whereType<String>().join(' · ');
    final percent = r['commission_percent'];

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              DocumentStatusPill(status),
            ],
          ),
          if (details.isNotEmpty)
            Text(
              details,
              style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (status != 'approved')
                FilledButton.icon(
                  onPressed: () =>
                      _update(r, {'verification_status': 'approved'}),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Tasdiqlash'),
                ),
              if (status != 'rejected')
                OutlinedButton(
                  onPressed: () async {
                    final sure = await confirmDialog(
                      context,
                      title: 'Rad etilsinmi?',
                      message: '$title mijozlarga ko\'rinmaydi.',
                      action: 'Rad etish',
                    );
                    if (sure) {
                      await _update(r, {'verification_status': 'rejected'});
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                  child: const Text('Rad etish'),
                ),
              TextButton.icon(
                onPressed: () => _commission(r),
                icon: const Icon(Icons.percent_rounded, size: 17),
                label: Text(
                  percent == null ? 'Komissiya: umumiy' : 'Komissiya: $percent%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentList extends ConsumerWidget {
  const _DocumentList();

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    DbRow doc,
    String status,
  ) async {
    String? note;
    if (status == 'rejected') {
      final controller = TextEditingController();
      note = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rad etish sababi'),
          content: TextField(controller: controller, autofocus: true),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Rad etish'),
            ),
          ],
        ),
      );
      if (note == null || !context.mounted) return;
    }
    final ok = await runAdminAction(
      context,
      () => ref.read(adminRepositoryProvider).update(
        'partner_documents',
        doc['id'] as String,
        {'status': status, 'admin_note': note},
      ),
    );
    if (ok) ref.invalidate(adminTableProvider(_documents));
  }

  Future<void> _open(BuildContext context, WidgetRef ref, String path) async {
    String? url;
    final ok = await runAdminAction(context, () async {
      url = await ref.read(adminRepositoryProvider).documentUrl(path);
    });
    if (!ok || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: Stack(
          children: [
            InteractiveViewer(
              child: AppImage(url, fit: BoxFit.contain, width: 600),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                tooltip: 'Yopish',
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = adminTableProvider(_documents);
    final names = {
      for (final p
          in ref.watch(adminTableProvider(_profiles)).asData?.value ??
              const <DbRow>[])
        p['id']: (p['full_name'] ?? p['email'] ?? 'Foydalanuvchi') as String,
    };
    return ContentFrame(
      maxWidth: 1000,
      child: AsyncValueView<List<DbRow>>(
        value: ref.watch(provider),
        onRetry: () => ref.invalidate(provider),
        builder: (docs) => docs.isEmpty
            ? const Center(child: Text('Yuklangan hujjat yo\'q'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i];
                  final status = d['status'] as String;
                  return SoftCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${names[d['user_id']] ?? 'Foydalanuvchi'} — '
                                '${d['doc_type']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            DocumentStatusPill(status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: () => _open(
                                context,
                                ref,
                                d['file_path'] as String,
                              ),
                              icon: const Icon(Icons.visibility_rounded),
                              label: const Text("Ko'rish"),
                            ),
                            if (status != 'approved')
                              TextButton(
                                onPressed: () =>
                                    _review(context, ref, d, 'approved'),
                                child: const Text('Tasdiqlash'),
                              ),
                            if (status != 'rejected')
                              TextButton(
                                onPressed: () =>
                                    _review(context, ref, d, 'rejected'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                ),
                                child: const Text('Rad etish'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
