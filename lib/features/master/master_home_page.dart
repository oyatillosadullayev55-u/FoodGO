import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/content_frame.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/ui.dart';
import '../../models/marketplace.dart';
import '../customer/masters/master_detail_page.dart';
import '../marketplace/marketplace_providers.dart';
import '../partner/documents_card.dart';
import '../partner/earnings_view.dart';
import '../partner/notifications_button.dart';
import '../partner/partner_scaffold.dart';
import 'master_providers.dart';
import 'master_requests_view.dart';

/// Usta paneli: buyurtmalar, daromad, baholar va profil.
class MasterHomePage extends ConsumerWidget {
  const MasterHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(myMasterProvider)
        .when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Scaffold(
            appBar: AppBar(actions: const [SignOutButton()]),
            body: ErrorView(
              message: friendlyError(e),
              onRetry: () => ref.invalidate(myMasterProvider),
            ),
          ),
          data: (master) {
            if (master == null) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Usta paneli'),
                  actions: const [SignOutButton()],
                ),
                body: const EmptyView(
                  icon: Icons.engineering_outlined,
                  title: 'Usta profili topilmadi',
                  message: 'Administrator hisobingizga usta profilini '
                      'biriktirishi kerak.',
                ),
              );
            }
            final provider = masterRequestsProvider(master.id);
            final fresh =
                ref
                    .watch(provider)
                    .asData
                    ?.value
                    .where((r) => r.status == ServiceStatus.fresh)
                    .length ??
                0;
            return PartnerScaffold(
              title: master.fullName,
              banner: VerificationBanner.of(master.verificationStatus),
              actions: [
                const NotificationsButton(),
                IconButton(
                  tooltip: 'Yangilash',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () {
                    ref.invalidate(myMasterProvider);
                    ref.invalidate(provider);
                  },
                ),
              ],
              tabs: [
                (
                  icon: Icons.assignment_rounded,
                  label: 'Buyurtmalar',
                  badge: fresh,
                  view: MasterRequestsView(masterId: master.id),
                ),
                (
                  icon: Icons.bar_chart_rounded,
                  label: 'Daromad',
                  badge: 0,
                  view: _IncomeTab(masterId: master.id),
                ),
                (
                  icon: Icons.star_rounded,
                  label: 'Baholar',
                  badge: 0,
                  view: _ReviewsTab(master: master),
                ),
                (
                  icon: Icons.person_rounded,
                  label: 'Profil',
                  badge: 0,
                  view: _ProfileTab(master: master),
                ),
              ],
            );
          },
        );
  }
}

class _IncomeTab extends ConsumerWidget {
  const _IncomeTab({required this.masterId});

  final String masterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = masterRequestsProvider(masterId);
    return ref
        .watch(provider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorView(
            message: friendlyError(e),
            onRetry: () => ref.invalidate(provider),
          ),
          data: (all) {
            final now = DateTime.now();
            final done = all
                .where((r) => r.status == ServiceStatus.completed)
                .toList();
            return EarningsView(
              countLabel: 'ta ish',
              onRefresh: () async => ref.invalidate(provider),
              commission: done
                  .where(
                    (r) =>
                        r.createdAt.year == now.year &&
                        r.createdAt.month == now.month,
                  )
                  .fold(0, (sum, r) => sum + r.commission),
              entries: [
                for (final r in done)
                  (
                    title: r.serviceType,
                    subtitle: r.addressText,
                    at: r.createdAt,
                    amount: r.price ?? 0,
                  ),
              ],
            );
          },
        );
  }
}

class _ReviewsTab extends ConsumerWidget {
  const _ReviewsTab({required this.master});

  final Master master;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(masterReviewsProvider(master.id));
    return ContentFrame(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StatTile(
            label: 'Umumiy reyting',
            value: master.ratingCount == 0
                ? '—'
                : master.rating.toStringAsFixed(1),
            icon: Icons.star_rounded,
            color: AppColors.accentGold,
            hint: '${master.ratingCount} ta baho',
          ),
          const SizedBox(height: 14),
          reviews.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(friendlyError(e)),
            data: (list) => ReviewList(reviews: list),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends ConsumerStatefulWidget {
  const _ProfileTab({required this.master});

  final Master master;

  @override
  ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<_ProfileTab> {
  late final _phone = TextEditingController(text: widget.master.phone ?? '');
  late final _price = TextEditingController(
    text: widget.master.priceFrom?.toString() ?? '',
  );
  late final _eta = TextEditingController(text: widget.master.eta ?? '');
  late final _about = TextEditingController(text: widget.master.about ?? '');
  late String? _category = widget.master.categoryId;
  late bool _active = widget.master.isActive;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_phone, _price, _eta, _about]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    String? text(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    try {
      await ref.read(marketplaceRepositoryProvider).updateMaster(
        widget.master.id,
        {
          'phone': text(_phone),
          'price_from': int.tryParse(_price.text),
          'eta': text(_eta),
          'about': text(_about),
          'category_id': _category,
          'is_active': _active,
        },
      );
      ref.invalidate(myMasterProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Saqlandi')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        ref.watch(categoriesByKindProvider('master')).asData?.value ?? const [];
    return ContentFrame(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Buyurtma qabul qilaman'),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
                if (categories.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    initialValue: categories.any((c) => c.id == _category)
                        ? _category
                        : null,
                    decoration: const InputDecoration(labelText: "Yo'nalish"),
                    items: [
                      for (final c in categories)
                        DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (v) => _category = v,
                  ),
                  const SizedBox(height: 10),
                ],
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefon'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: "Boshlang'ich narx (so'm)",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _eta,
                  decoration: const InputDecoration(
                    labelText: 'Yetib borish vaqti',
                    hintText: '20–30 daqiqa',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _about,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: "O'zim haqimda"),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('Saqlash'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const DocumentsCard(),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: () => signOut(context, ref),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Hisobdan chiqish'),
          ),
        ],
      ),
    );
  }
}
