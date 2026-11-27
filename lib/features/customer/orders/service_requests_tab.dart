import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/phone.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/ui.dart';
import '../../../models/marketplace.dart';
import '../../marketplace/marketplace_providers.dart';
import '../../marketplace/service_status_color.dart';
import '../support/feedback_dialogs.dart';

/// Mijozning ustalarga yuborgan so'rovlari.
class ServiceRequestsTab extends ConsumerWidget {
  const ServiceRequestsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueView<List<ServiceRequest>>(
      value: ref.watch(myServiceRequestsProvider),
      onRetry: () => ref.invalidate(myServiceRequestsProvider),
      builder: (list) => list.isEmpty
          ? const EmptyView(
              icon: Icons.engineering_outlined,
              title: "Xizmat buyurtmalari yo'q",
              message: "Ustalar bo'limidan mutaxassis chaqiring.",
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) => _RequestCard(request: list[i]),
            ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.request});

  final ServiceRequest request;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("So'rovni bekor qilasizmi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Yo'q"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Bekor qilish'),
          ),
        ],
      ),
    );
    if (sure != true) return;
    try {
      await ref
          .read(marketplaceRepositoryProvider)
          .setServiceStatus(request.id, ServiceStatus.cancelled);
      ref.invalidate(myServiceRequestsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = request;
    return SoftCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.masterName ?? 'Usta',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
                  ),
                ),
              ),
              StatusPill(r.status.label, color: serviceStatusColor(r.status)),
            ],
          ),
          const SizedBox(height: 4),
          Text(r.serviceType),
          Text(
            '${DateFormat('dd.MM.yyyy HH:mm').format(r.createdAt)} · ${r.addressText}',
            style: const TextStyle(fontSize: 12, color: AppColors.grey),
          ),
          if (r.price != null) ...[
            const SizedBox(height: 6),
            Text(
              'Ish narxi: ${formatSom(r.price!)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            children: [
              if (!r.status.isFinished && r.masterPhone != null)
                TextButton.icon(
                  onPressed: () => callPhone(context, r.masterPhone),
                  icon: const Icon(Icons.phone_rounded, size: 17),
                  label: const Text("Qo'ng'iroq"),
                ),
              if (r.status.customerCanCancel)
                TextButton(
                  onPressed: () => _cancel(context, ref),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Bekor qilish'),
                ),
              if (r.status == ServiceStatus.completed)
                TextButton.icon(
                  onPressed: () =>
                      showReviewDialog(context, serviceRequestId: r.id),
                  icon: const Icon(Icons.star_outline_rounded, size: 18),
                  label: const Text('Baholash'),
                ),
              TextButton(
                onPressed: () =>
                    showComplaintDialog(context, serviceRequestId: r.id),
                style: TextButton.styleFrom(foregroundColor: AppColors.grey),
                child: const Text('Shikoyat'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
