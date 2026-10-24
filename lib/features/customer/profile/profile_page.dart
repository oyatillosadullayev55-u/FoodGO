import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../auth/providers/auth_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & FoodGo ID', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: profile.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryDark),
        ),
        error: (e, _) => ErrorView(
          message: friendlyError(e),
          onRetry: () => ref.invalidate(profileProvider),
        ),
        data: (p) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // 1. FoodGo ID Foydalanuvchi ma'lumotlari
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? Colors.white10 : AppColors.borderLight,
                  width: 0.8,
                ),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                      child: const Icon(Icons.person_rounded, size: 36, color: AppColors.dark),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              p.fullName ?? 'Foydalanuvchi',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded, size: 18, color: AppColors.primaryDark),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          p.phone ?? '+998 90 123 45 67',
                          style: const TextStyle(color: AppColors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.grey),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profilni tahrirlash')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Yandex Plus Kartasi
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF232328), Color(0xFF141416)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.star_rounded, size: 16, color: AppColors.dark),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'FoodGo Club',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Obuna faol',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '14 850 ball',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ballarni FoodGo buyurtmalarida sarflang (1 ball = 1 so\'m)',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Bo'limlar
            _MenuSection(
              title: 'Buyurtmalar va To\'lovlar',
              items: [
                _MenuItem(
                  icon: Icons.location_on_rounded,
                  title: 'Mening manzillarim',
                  subtitle: 'Uy, Ishxona va boshqa manzillar',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'To\'lov usullari & FoodGo Pay',
                  subtitle: 'Bank kartalarini boshqarish',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.local_offer_rounded,
                  title: 'Promokodlar va Chegirmalar',
                  subtitle: 'Faol bonuslar va sovg\'alar',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            _MenuSection(
              title: 'Qo\'shimcha',
              items: [
                _MenuItem(
                  icon: Icons.notifications_none_rounded,
                  title: 'Bildirishnomalar',
                  subtitle: 'Buyurtma holati xabarlari',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.headset_mic_rounded,
                  title: 'Qo\'llab-quvvatlash xizmati',
                  subtitle: 'Yordam va savollar',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.info_outline_rounded,
                  title: 'Ilova haqida',
                  subtitle: 'FoodGo v1.0.0',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 4. Chiqish tugmasi
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                ref.invalidate(profileProvider);
                if (context.mounted) context.go(AppRoutes.login);
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Hisobdan chiqish'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});

  final String title;
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.grey),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white10 : AppColors.borderLight,
              width: 0.8,
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: isDark ? Colors.white10 : AppColors.borderLight,
            ),
            itemBuilder: (context, i) {
              final it = items[i];
              return ListTile(
                onTap: it.onTap,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(it.icon, color: AppColors.dark, size: 20),
                ),
                title: Text(
                  it.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
                subtitle: Text(
                  it.subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.grey),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}