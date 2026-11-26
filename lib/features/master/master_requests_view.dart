import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/utils/phone.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/content_frame.dart';
import '../../core/widgets/ui.dart';
import '../../models/marketplace.dart';
import '../marketplace/marketplace_providers.dart';
import '../marketplace/service_status_color.dart';
import 'master_providers.dart';

/// Usta uchun so'rovlar: yangi, jarayonda va tugagan.
class MasterRequestsView extends ConsumerStatefulWidget {
  const MasterRequestsView({super.key, required this.masterId});

  final String masterId;

  @override
  ConsumerState<MasterRequestsView> createState() => _MasterRequestsViewState();
}

enum _Filter { fresh, active, finished }

class _MasterRequestsViewState extends ConsumerState<MasterRequestsView> {
  _Filter _filter = _Filter.fresh;
  String? _busyId;

  static bool _matches(_Filter f, ServiceStatus s) => switch (f) {
    _Filter.fresh => s == ServiceStatus.fresh,
    _Filter.active => !s.isFinished && s != ServiceStatus.fresh,
    _Filter.finished => s.isFinished,
  };

  Future<int?> _askPrice() {
    final controller = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ish narxi'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
          ],
          decoration: const InputDecoration(
            labelText: "Mijozdan olingan summa (so'm)",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () {
              final price = int.tryParse(controller.text) ?? 0;
              if (price > 0) Navigator.pop(ctx, price);
            },
            child: const Text('Yakunlash'),
          ),
        ],
      ),
    );
  }

  Future<void> _setStatus(ServiceRequest r, ServiceStatus status) async {
    int? price;
    if (status == ServiceStatus.completed) {
      price = await _askPrice();
      if (price == null || !mounted) return;
    }
    setState(() => _busyId = r.id);
    try {
      await ref
          .read(marketplaceRepositoryProvider)
          .setServiceStatus(r.id, status, price: price);
      ref.invalidate(masterRequestsProvider(widget.masterId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = masterRequestsProvider(widget.masterId);
    return ContentFrame(
      child: AsyncValueView<List<ServiceRequest>>(
        value: ref.watch(provider),
        onRetry: () => ref.invalidate(provider),
        builder: (all) {
          int count(_Filter f) =>
              all.where((r) => _matches(f, r.status)).length;
          final shown = all.where((r) => _matches(_filter, r.status)).toList();
          return Column(
            children: [
              const SizedBox(height: 8),
              ChipsBar<_Filter>(
                selected: _filter,
                onSelected: (f) => setState(() => _filter = f),
                items: [
                  (_Filter.fresh, 'Yangi (${count(_Filter.fresh)})'),
                  (_Filter.active, 'Jarayonda (${count(_Filter.active)})'),
                  (_Filter.finished, 'Tugagan (${count(_Filter.finished)})'),
                ],
              ),
              Expanded(
                child: shown.isEmpty
                    ? const Center(
                        child: Text(
                          "Bu bo'limda buyurtma yo'q",
                          style: TextStyle(color: AppColors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: shown.length,
                        itemBuilder: (_, i) => _Card(
                          request: shown[i],
                          busy: _busyId == shown[i].id,
                          onStatus: (s) => _setStatus(shown[i], s),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Holatga o'tkazish tugmasining yozuvi.
String masterActionLabel(ServiceStatus s) => switch (s) {
  ServiceStatus.accepted => 'Qabul qilish',
  ServiceStatus.onTheWay => "Yo'lga chiqdim",
  ServiceStatus.inProgress => 'Ishni boshlash',
  ServiceStatus.completed => 'Yakunlash',
  ServiceStatus.rejected => 'Rad etish',
  _ => 'Bekor qilish',
};

class _Card extends StatelessWidget {
  const _Card({
    required this.request,
    required this.busy,
    required this.onStatus,
  });

  final ServiceRequest request;
  final bool busy;
  final void Function(ServiceStatus) onStatus;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final date = DateFormat('dd.MM.yyyy HH:mm');
    return SoftCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.serviceType,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
                  ),
                ),
              ),
              StatusPill(r.status.label, color: serviceStatusColor(r.status)),
            ],
          ),
          Text(
            date.format(r.createdAt),
            style: const TextStyle(fontSize: 12, color: AppColors.grey),
          ),
          if (r.description != null) ...[
            const SizedBox(height: 6),
            Text(r.description!),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(r.addressText)),
            ],
          ),
          if (!r.status.isFinished)
            TextButton.icon(
              onPressed: () => callPhone(context, r.phone),
              icon: const Icon(Icons.phone_rounded, size: 18),
              label: Text('${r.customerName ?? 'Mijoz'} · ${r.phone}'),
            ),
          if (r.price != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Narx: ${formatSom(r.price!)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          if (r.status.masterNext.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final next in r.status.masterNext)
                  if (next == ServiceStatus.rejected ||
                      next == ServiceStatus.cancelled)
                    TextButton(
                      onPressed: busy ? null : () => onStatus(next),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: Text(masterActionLabel(next)),
                    )
                  else
                    FilledButton(
                      onPressed: busy ? null : () => onStatus(next),
                      child: Text(masterActionLabel(next)),
                    ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
