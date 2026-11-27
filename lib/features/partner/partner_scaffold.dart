import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../auth/providers/auth_providers.dart';

typedef PartnerTab = ({
  IconData icon,
  String label,
  Widget view,
  int badge,
});

/// Hamkor panellari qolipi: telefonda pastki menyu, keng ekranda yon panel.
class PartnerScaffold extends StatefulWidget {
  const PartnerScaffold({
    super.key,
    required this.title,
    required this.tabs,
    this.actions = const [],
    this.banner,
  });

  final String title;
  final List<PartnerTab> tabs;
  final List<Widget> actions;

  /// Sarlavha ostidagi ogohlantirish (masalan, tasdiq kutilmoqda).
  final Widget? banner;

  @override
  State<PartnerScaffold> createState() => _PartnerScaffoldState();
}

class _PartnerScaffoldState extends State<PartnerScaffold> {
  int _index = 0;

  Widget _icon(PartnerTab t) => Badge.count(
    count: t.badge,
    isLabelVisible: t.badge > 0,
    backgroundColor: AppColors.accentRed,
    child: Icon(t.icon),
  );

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final index = _index.clamp(0, widget.tabs.length - 1);
    final body = Column(
      children: [
        ?widget.banner,
        Expanded(child: widget.tabs[index].view),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [...widget.actions, const SizedBox(width: 6)],
      ),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: NavigationRailLabelType.all,
                  indicatorColor: AppColors.primarySoft,
                  destinations: [
                    for (final t in widget.tabs)
                      NavigationRailDestination(
                        icon: _icon(t),
                        label: Text(t.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final t in widget.tabs)
                  NavigationDestination(icon: _icon(t), label: t.label),
              ],
            ),
    );
  }
}

/// Barcha hamkor va admin panellari uchun chiqish.
Future<void> signOut(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(pushServiceProvider).unregister();
  } catch (_) {
    // Push sozlanmagan bo'lsa ham chiqish davom etadi
  }
  await ref.read(authRepositoryProvider).signOut();
  ref.invalidate(profileProvider);
  if (context.mounted) context.go(AppRoutes.login);
}

class SignOutButton extends ConsumerWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Chiqish',
      icon: const Icon(Icons.logout_rounded),
      onPressed: () => signOut(context, ref),
    );
  }
}
