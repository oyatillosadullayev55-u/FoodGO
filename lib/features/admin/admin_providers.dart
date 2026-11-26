import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/error_mapper.dart';
import '../../repositories/admin_repository.dart';
import '../auth/providers/auth_providers.dart';

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.watch(supabaseProvider)),
);

/// Jadval so'rovi. Bir xil kalit bir xil natijani qayta ishlatadi.
typedef TableQuery = ({
  String table,
  String select,
  String orderBy,
  bool ascending,
  bool broadcastOnly,
});

TableQuery tableQuery(
  String table, {
  String select = '*',
  String orderBy = 'created_at',
  bool ascending = false,
  bool broadcastOnly = false,
}) => (
  table: table,
  select: select,
  orderBy: orderBy,
  ascending: ascending,
  broadcastOnly: broadcastOnly,
);

final adminTableProvider = FutureProvider.autoDispose
    .family<List<DbRow>, TableQuery>(
      (ref, q) => ref
          .watch(adminRepositoryProvider)
          .list(
            q.table,
            select: q.select,
            orderBy: q.orderBy,
            ascending: q.ascending,
            isNull: q.broadcastOnly ? const ['user_id'] : const [],
          ),
    );

final adminAnalyticsProvider = FutureProvider.autoDispose.family<DbRow, int>(
  (ref, days) => ref.watch(adminRepositoryProvider).analytics(days),
);

final adminFraudProvider = FutureProvider.autoDispose<List<DbRow>>(
  (ref) => ref.watch(adminRepositoryProvider).fraudSignals(),
);

final adminUsersProvider = FutureProvider.autoDispose
    .family<List<DbRow>, ({String? role, String query})>(
      (ref, a) => ref
          .watch(adminRepositoryProvider)
          .users(role: a.role, query: a.query),
    );

/// Admin amalini bajaradi, xatoni ko'rsatadi. Muvaffaqiyatda true.
Future<bool> runAdminAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    return true;
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(friendlyError(e))));
    return false;
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String action,
}) async {
  final sure = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return sure == true;
}
