import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui.dart';
import '../marketplace/marketplace_providers.dart';

final myDocumentsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
      (ref) => ref.watch(marketplaceRepositoryProvider).fetchMyDocuments(),
    );

const documentTypes = ['Pasport / ID karta', 'Guvohnoma', 'Litsenziya'];

/// Hamkor tekshiruv uchun hujjat rasmini yuklaydi.
/// Fayl yopiq bucket'da saqlanadi, uni faqat egasi va admin ko'radi.
class DocumentsCard extends ConsumerStatefulWidget {
  const DocumentsCard({super.key});

  @override
  ConsumerState<DocumentsCard> createState() => _DocumentsCardState();
}

class _DocumentsCardState extends ConsumerState<DocumentsCard> {
  bool _busy = false;

  Future<void> _upload(String type) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        imageQuality: 85,
      );
      if (file == null) return;
      setState(() => _busy = true);
      await ref
          .read(marketplaceRepositoryProvider)
          .uploadDocument(
            docType: type,
            fileName: file.name,
            bytes: await file.readAsBytes(),
          );
      ref.invalidate(myDocumentsProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Hujjat yuborildi')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final docs = ref.watch(myDocumentsProvider);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Hujjatlar',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
              if (_busy)
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                PopupMenuButton<String>(
                  tooltip: 'Hujjat yuklash',
                  icon: const Icon(
                    Icons.upload_file_rounded,
                    color: AppColors.primary,
                  ),
                  onSelected: _upload,
                  itemBuilder: (_) => [
                    for (final t in documentTypes)
                      PopupMenuItem(value: t, child: Text(t)),
                  ],
                ),
            ],
          ),
          docs.when(
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (e, _) => Text(
              friendlyError(e),
              style: const TextStyle(color: AppColors.grey, fontSize: 12.5),
            ),
            data: (list) => list.isEmpty
                ? const Text(
                    'Tekshiruv uchun pasport yoki guvohnoma rasmini yuklang.',
                    style: TextStyle(color: AppColors.grey, fontSize: 12.5),
                  )
                : Column(
                    children: [
                      for (final d in list)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(Icons.description_outlined),
                          title: Text(d['doc_type'] as String),
                          subtitle: d['admin_note'] == null
                              ? null
                              : Text(d['admin_note'] as String),
                          trailing: DocumentStatusPill(d['status'] as String),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// 'pending' / 'approved' / 'rejected' holatini ko'rsatadi.
class DocumentStatusPill extends StatelessWidget {
  const DocumentStatusPill(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'approved' => ('Tasdiqlangan', AppColors.success),
      'rejected' => ('Rad etilgan', AppColors.error),
      _ => ('Tekshirilmoqda', AppColors.warning),
    };
    return StatusPill(label, color: color);
  }
}

/// Tasdiqlanmagan hamkor uchun yuqoridagi ogohlantirish.
class VerificationBanner extends StatelessWidget {
  const VerificationBanner({super.key, required this.status});

  final String status;

  static Widget? of(String status) =>
      status == 'approved' ? null : VerificationBanner(status: status);

  @override
  Widget build(BuildContext context) {
    final rejected = status == 'rejected';
    final color = rejected ? AppColors.error : AppColors.warning;
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        rejected
            ? "Profil rad etilgan. Hujjatlarni yangilang yoki administrator "
                  "bilan bog'laning."
            : "Profil tekshirilmoqda: tasdiqlanguncha mijozlarga ko'rinmaydi.",
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
    );
  }
}
