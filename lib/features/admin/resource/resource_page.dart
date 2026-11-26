import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../core/widgets/ui.dart';
import '../../../repositories/admin_repository.dart';
import '../admin_providers.dart';
import 'admin_resource.dart';
import 'resource_form.dart';

/// Ro'yxat, qo'shish, tahrirlash va o'chirish.
class ResourcePage extends ConsumerWidget {
  const ResourcePage({super.key, required this.resource, this.header});

  final AdminResource resource;

  /// Ro'yxat ustidagi qo'shimcha blok (masalan, yig'indilar).
  final Widget Function(List<DbRow> rows)? header;

  Future<void> _edit(BuildContext context, WidgetRef ref, [DbRow? row]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => ResourceForm(resource: resource, row: row),
    );
    if (saved == true) ref.invalidate(adminTableProvider(resource.query));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, DbRow row) async {
    final sure = await confirmDialog(
      context,
      title: "O'chirilsinmi?",
      message:
          "'${resource.itemTitle(row)}' butunlay o'chiriladi. "
          "Bog'liq yozuvlarga ta'sir qilishi mumkin.",
      action: "O'chirish",
    );
    if (!sure || !context.mounted) return;
    final ok = await runAdminAction(
      context,
      () => ref
          .read(adminRepositoryProvider)
          .delete(resource.table, row['id'] as Object),
    );
    if (ok) ref.invalidate(adminTableProvider(resource.query));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = adminTableProvider(resource.query);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_${resource.table}',
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(resource.createLabel),
      ),
      body: ContentFrame(
        maxWidth: 1000,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(provider.future),
          child: AsyncValueView<List<DbRow>>(
            value: ref.watch(provider),
            onRetry: () => ref.invalidate(provider),
            builder: (rows) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                if (header != null) ...[
                  header!(rows),
                  const SizedBox(height: 14),
                ],
                if (rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      "Hali yozuv yo'q",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.grey),
                    ),
                  ),
                for (final row in rows)
                  SoftCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    onTap: () => _edit(context, ref, row),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primarySoft,
                          child: Icon(resource.icon, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resource.itemTitle(row),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (resource.itemSubtitle != null)
                                Text(
                                  resource.itemSubtitle!(row),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (row['is_active'] == false)
                          const StatusPill("O'chiq", color: AppColors.grey),
                        if (resource.canDelete)
                          IconButton(
                            tooltip: "O'chirish",
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.error,
                            ),
                            onPressed: () => _delete(context, ref, row),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
