import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../core/widgets/ui.dart';
import '../../../models/food_order.dart';
import '../../../models/marketplace.dart';
import '../../../repositories/admin_repository.dart';
import '../../delivery/delivery_providers.dart';
import '../../marketplace/marketplace_providers.dart';
import '../../marketplace/service_status_color.dart';
import '../admin_providers.dart';

final _orders = tableQuery(
  'orders',
  select: '*, restaurants(name,address,lat,lng)',
);
final _requests = tableQuery(
  'service_requests',
  select: '*, masters(full_name, phone)',
);

/// Barcha mahsulot buyurtmalari va xizmat so'rovlari.
class AdminOrdersPage extends ConsumerWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [Tab(text: 'Buyurtmalar'), Tab(text: 'Xizmatlar')],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _List(
                  query: _orders,
                  builder: (row) {
                    final o = FoodOrder.fromMap(row);
                    return _Entry(
                      title:
                          '#${o.id.substring(0, 8)} · '
                          '${o.restaurantName ?? "Do'kon"}',
                      subtitle: o.addressText,
                      at: o.createdAt,
                      amount: o.total,
                      status: o.status.label,
                      color: o.status.isFailed
                          ? AppColors.error
                          : o.status == OrderStatus.delivered
                          ? AppColors.success
                          : AppColors.primary,
                      onCancel: o.status.isActive
                          ? () => ref
                                .read(deliveryRepositoryProvider)
                                .setStatus(o.id, OrderStatus.cancelled)
                          : null,
                    );
                  },
                ),
                _List(
                  query: _requests,
                  builder: (row) {
                    final r = ServiceRequest.fromMap(row);
                    return _Entry(
                      title: '${r.serviceType} · ${r.masterName ?? 'Usta'}',
                      subtitle: r.addressText,
                      at: r.createdAt,
                      amount: r.price,
                      status: r.status.label,
                      color: serviceStatusColor(r.status),
                      onCancel: r.status.isFinished
                          ? null
                          : () => ref
                                .read(marketplaceRepositoryProvider)
                                .setServiceStatus(
                                  r.id,
                                  ServiceStatus.cancelled,
                                ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _List extends ConsumerWidget {
  const _List({required this.query, required this.builder});

  final TableQuery query;
  final _Entry Function(DbRow) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = adminTableProvider(query);
    return ContentFrame(
      maxWidth: 1000,
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(provider.future),
        child: AsyncValueView<List<DbRow>>(
          value: ref.watch(provider),
          onRetry: () => ref.invalidate(provider),
          builder: (rows) => rows.isEmpty
              ? const Center(child: Text("Hali buyurtma yo'q"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final entry = builder(rows[i]);
                    return _EntryCard(
                      entry: entry,
                      onCancel: entry.onCancel == null
                          ? null
                          : () async {
                              final sure = await confirmDialog(
                                context,
                                title: 'Bekor qilinsinmi?',
                                message: entry.title,
                                action: 'Bekor qilish',
                              );
                              if (!sure || !context.mounted) return;
                              final ok = await runAdminAction(
                                context,
                                entry.onCancel!,
                              );
                              if (ok) ref.invalidate(provider);
                            },
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _Entry {
  const _Entry({
    required this.title,
    required this.subtitle,
    required this.at,
    required this.status,
    required this.color,
    this.amount,
    this.onCancel,
  });

  final String title;
  final String subtitle;
  final DateTime at;
  final String status;
  final Color color;
  final int? amount;
  final Future<void> Function()? onCancel;
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, this.onCancel});

  final _Entry entry;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              StatusPill(entry.status, color: entry.color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${DateFormat('dd.MM.yyyy HH:mm').format(entry.at)} · '
            '${entry.subtitle}',
            style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
          ),
          Row(
            children: [
              if (entry.amount != null)
                Text(
                  formatSom(entry.amount!),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              const Spacer(),
              if (onCancel != null)
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Bekor qilish'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
