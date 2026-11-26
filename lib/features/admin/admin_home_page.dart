import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/brand_wordmark.dart';
import '../../core/widgets/ui.dart';
import '../../repositories/admin_repository.dart';
import '../partner/partner_scaffold.dart';
import 'admin_people_page.dart';
import 'pages/admin_orders_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/disputes_page.dart';
import 'pages/fraud_page.dart';
import 'pages/users_page.dart';
import 'pages/verification_page.dart';
import 'resource/resource_page.dart';
import 'resources.dart';

enum AdminSection {
  dashboard('Statistika', Icons.dashboard_rounded),
  orders('Buyurtmalar', Icons.receipt_long_rounded),
  users('Foydalanuvchilar', Icons.people_rounded),
  staff('Xodimlar', Icons.badge_rounded),
  verification('Tasdiqlash', Icons.verified_user_rounded),
  services('Servislar', Icons.apps_rounded),
  categories('Kategoriyalar', Icons.category_rounded),
  commissions('Komissiyalar', Icons.percent_rounded),
  plans('Tariflar', Icons.workspace_premium_rounded),
  subscriptions('Obunalar', Icons.card_membership_rounded),
  promotions('Aksiyalar', Icons.campaign_rounded),
  notifications('Xabarnomalar', Icons.notifications_active_rounded),
  regions('Hududlar', Icons.map_rounded),
  finance('Moliya', Icons.account_balance_rounded),
  disputes('Nizolar', Icons.gavel_rounded),
  fraud('Firibgarlik', Icons.shield_rounded);

  const AdminSection(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Super Admin boshqaruv paneli.
class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key, this.initial = AdminSection.dashboard});

  final AdminSection initial;

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  late AdminSection _section = widget.initial;

  void _open(AdminSection s) => setState(() => _section = s);

  Widget _page() => switch (_section) {
    AdminSection.dashboard => DashboardPage(
      onOpenVerification: () => _open(AdminSection.verification),
      onOpenDisputes: () => _open(AdminSection.disputes),
    ),
    AdminSection.orders => const AdminOrdersPage(),
    AdminSection.users => const UsersPage(),
    AdminSection.staff => const AdminPeoplePage(),
    AdminSection.verification => const VerificationPage(),
    AdminSection.services => ResourcePage(resource: servicesResource),
    AdminSection.categories => ResourcePage(resource: categoriesResource),
    AdminSection.commissions => ResourcePage(resource: commissionResource),
    AdminSection.plans => ResourcePage(resource: plansResource),
    AdminSection.subscriptions => ResourcePage(
      resource: subscriptionsResource,
    ),
    AdminSection.promotions => ResourcePage(resource: promotionsResource),
    AdminSection.notifications => ResourcePage(
      resource: notificationsResource,
    ),
    AdminSection.regions => ResourcePage(resource: regionsResource),
    AdminSection.finance => ResourcePage(
      resource: transactionsResource,
      header: (rows) => FinanceSummary(rows: rows),
    ),
    AdminSection.disputes => const DisputesPage(),
    AdminSection.fraud => const FraudPage(),
  };

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 1000;
    // Har bo'lim o'z holati bilan yangidan quriladi.
    final page = KeyedSubtree(key: ValueKey(_section), child: _page());

    return Scaffold(
      appBar: AppBar(
        title: Text(_section.label),
        actions: const [SignOutButton(), SizedBox(width: 6)],
      ),
      drawer: isWide
          ? null
          : Drawer(
              backgroundColor: _Menu.background,
              child: Builder(
                builder: (drawerContext) => _Menu(
                  selected: _section,
                  onSelected: (s) {
                    Navigator.pop(drawerContext);
                    _open(s);
                  },
                ),
              ),
            ),
      body: isWide
          ? Row(
              children: [
                SizedBox(
                  width: 240,
                  child: Material(
                    color: _Menu.background,
                    child: _Menu(selected: _section, onSelected: _open),
                  ),
                ),
                Expanded(child: page),
              ],
            )
          : page,
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.selected, required this.onSelected});

  static const background = Color(0xFF1D1147);

  final AdminSection selected;
  final ValueChanged<AdminSection> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 6, 8, 16),
            child: Row(
              children: [
                BrandLogo(size: 36),
                SizedBox(width: 10),
                BrandWordmark(size: 20, onDark: true),
              ],
            ),
          ),
          for (final s in AdminSection.values)
            ListTile(
              dense: true,
              selected: s == selected,
              selectedTileColor: AppColors.primary,
              selectedColor: Colors.white,
              textColor: Colors.white70,
              iconColor: Colors.white70,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: Icon(s.icon, size: 20),
              title: Text(
                s.label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () => onSelected(s),
            ),
        ],
      ),
    );
  }
}

/// Bajarilgan va kutilayotgan summalar turi bo'yicha.
class FinanceSummary extends StatelessWidget {
  const FinanceSummary({super.key, required this.rows});

  final List<DbRow> rows;

  @override
  Widget build(BuildContext context) {
    int sum(String kind, {String? status}) => rows
        .where(
          (r) =>
              r['kind'] == kind &&
              r['status'] != 'cancelled' &&
              (status == null || r['status'] == status),
        )
        .fold(0, (total, r) => total + (r['amount'] as num).toInt());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdaptiveGrid(
          minItemWidth: 210,
          children: [
            for (final (kind, icon, color) in const [
              ('commission', Icons.trending_up_rounded, AppColors.success),
              ('subscription', Icons.card_membership_rounded, AppColors.primary),
              ('payout', Icons.north_east_rounded, AppColors.warning),
              ('refund', Icons.undo_rounded, AppColors.error),
            ])
              StatTile(
                label: transactionKinds[kind]!,
                value: formatSom(sum(kind)),
                icon: icon,
                color: color,
                hint: 'Kutilmoqda: ${formatSom(sum(kind, status: 'pending'))}',
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          "Hisob-kitob qaydlari (oxirgi 500 ta). To'lov tizimi ulanmagan: "
          "pul o'tkazmalari tashqarida bajariladi.",
          style: TextStyle(fontSize: 12, color: AppColors.grey),
        ),
      ],
    );
  }
}
