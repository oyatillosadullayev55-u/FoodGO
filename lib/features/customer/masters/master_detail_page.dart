import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/phone.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../core/widgets/ui.dart';
import '../../../models/marketplace.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/marketplace_providers.dart';

class MasterDetailPage extends ConsumerWidget {
  const MasterDetailPage({super.key, required this.masterId});

  final String masterId;

  Future<void> _order(BuildContext context, WidgetRef ref, Master m) async {
    final profile = ref.read(profileProvider).asData?.value;
    if (profile == null || profile.id == 'guest_user') {
      context.push(AppRoutes.login);
      return;
    }
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _RequestForm(master: m, phone: profile.phone),
    );
    if (sent == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "So'rov yuborildi. Holatini Buyurtmalar bo'limida kuzating.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final master = ref.watch(masterProvider(masterId));
    final reviews = ref.watch(masterReviewsProvider(masterId));
    final loaded = master.asData?.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Usta')),
      bottomNavigationBar: loaded == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                // heightFactor: panel faqat o'z balandligicha joy oladi.
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 728),
                    child: Row(
                      children: [
                        IconButton.outlined(
                          tooltip: "Qo'ng'iroq qilish",
                          style: IconButton.styleFrom(
                            fixedSize: const Size(52, 52),
                            foregroundColor: AppColors.primary,
                          ),
                          icon: const Icon(Icons.phone_rounded),
                          onPressed: () => callPhone(context, loaded.phone),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _order(context, ref, loaded),
                            child: const Text('Ustani chaqirish'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      body: ContentFrame(
        child: AsyncValueView<Master>(
          value: master,
          onRetry: () => ref.invalidate(masterProvider(masterId)),
          builder: (m) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SoftCard(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AppImage(
                        m.photoUrl,
                        width: 96,
                        height: 96,
                        fallbackIcon: Icons.engineering_rounded,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.fullName,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (m.specialty != null)
                            Text(
                              m.specialty!,
                              style: const TextStyle(color: AppColors.primary),
                            ),
                          const SizedBox(height: 4),
                          RatingLine(m.rating, count: m.ratingCount),
                          if (m.eta != null)
                            Text(
                              'Yetib borish: ${m.eta}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (m.priceFrom != null) ...[
                const SizedBox(height: 12),
                StatTile(
                  label: 'Xizmat narxi',
                  value: '${formatSom(m.priceFrom!)} dan',
                  icon: Icons.payments_rounded,
                  hint: "Yakuniy narx ish bajarilgach belgilanadi",
                ),
              ],
              if (m.about != null && m.about!.trim().isNotEmpty) ...[
                const SizedBox(height: 18),
                const SectionHeader('Usta haqida'),
                const SizedBox(height: 6),
                Text(m.about!, style: const TextStyle(height: 1.4)),
              ],
              const SizedBox(height: 18),
              const SectionHeader('Mijozlar bahosi'),
              const SizedBox(height: 8),
              ReviewList(reviews: reviews.asData?.value ?? const []),
            ],
          ),
        ),
      ),
    );
  }
}

class ReviewList extends StatelessWidget {
  const ReviewList({super.key, required this.reviews});

  final List<Review> reviews;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const Text(
        "Hali izoh qoldirilmagan.",
        style: TextStyle(color: AppColors.grey),
      );
    }
    final date = DateFormat('dd.MM.yyyy');
    return Column(
      children: [
        for (final r in reviews)
          SoftCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.customerName ?? 'Mijoz',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    for (var i = 1; i <= 5; i++)
                      Icon(
                        i <= r.rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 16,
                        color: AppColors.accentGold,
                      ),
                  ],
                ),
                if (r.comment != null) ...[
                  const SizedBox(height: 6),
                  Text(r.comment!),
                ],
                const SizedBox(height: 4),
                Text(
                  date.format(r.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.grey),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RequestForm extends ConsumerStatefulWidget {
  const _RequestForm({required this.master, this.phone});

  final Master master;
  final String? phone;

  @override
  ConsumerState<_RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends ConsumerState<_RequestForm> {
  final _form = GlobalKey<FormState>();
  late final _type = TextEditingController(text: widget.master.specialty ?? '');
  late final _phone = TextEditingController(text: widget.phone ?? '+998');
  final _address = TextEditingController();
  final _description = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _type.dispose();
    _phone.dispose();
    _address.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(marketplaceRepositoryProvider)
          .createServiceRequest(
            masterId: widget.master.id,
            serviceType: _type.text.trim(),
            address: _address.text.trim(),
            phone: _phone.text.trim(),
            description: _description.text.trim(),
          );
      ref.invalidate(myServiceRequestsProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = friendlyError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.master.fullName}ni chaqirish',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _type,
                decoration: const InputDecoration(labelText: 'Xizmat turi'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Xizmat turini kiriting'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Manzil'),
                validator: (v) => (v == null || v.trim().length < 5)
                    ? "Manzilni to'liq kiriting"
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefon'),
                validator: Validators.phone,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _description,
                maxLines: 3,
                minLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Muammo tavsifi (ixtiyoriy)',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _send,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("So'rov yuborish"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
