import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/content_frame.dart';
import '../providers/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _showLoginForm = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signIn(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (mounted) context.go(AppRoutes.gate);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ContentFrame(
              maxWidth: 480,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.delivery_dining_rounded,
                        color: AppColors.dark,
                        size: 46,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'FoodGo',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Xush kelibsiz! Qaysi rolda davom etasiz?',
                    style: TextStyle(color: AppColors.grey, fontSize: 14.5),
                  ),
                  const SizedBox(height: 28),

                  // 1-Rol: MIJOZ (Customer)
                  _RoleCard(
                    icon: Icons.person_rounded,
                    title: 'Mijoz rejimi',
                    subtitle: 'Restoranlar menyusini ko\'rish, taom tanlash va buyurtma berish',
                    badge: 'ASOSIY',
                    color: AppColors.primary,
                    iconColor: AppColors.dark,
                    textColor: AppColors.dark,
                    onTap: () => context.go(AppRoutes.customerHome),
                  ),
                  const SizedBox(height: 14),

                  // 2-Rol: OWNER (Restoran egasi)
                  _RoleCard(
                    icon: Icons.storefront_rounded,
                    title: 'Owner (Restoran Egasi)',
                    subtitle: 'Taomlar menyusi, yangi mahsulot qo\'shish va buyurtmalar holati',
                    badge: 'BOSHQARUV',
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    iconColor: AppColors.primaryDark,
                    textColor: isDark ? Colors.white : AppColors.dark,
                    border: Border.all(color: isDark ? Colors.white12 : AppColors.borderLight, width: 1.2),
                    onTap: () => context.go(AppRoutes.restaurantHome),
                  ),
                  const SizedBox(height: 14),

                  // 3-Rol: ADMIN (Administrator)
                  _RoleCard(
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Tizim Administratori (Admin)',
                    subtitle: 'Hamkor restoranlar, statistika va umumiy tizimni nazorat qilish',
                    badge: 'ADMIN',
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    iconColor: const Color(0xFF6A11CB),
                    textColor: isDark ? Colors.white : AppColors.dark,
                    border: Border.all(color: isDark ? Colors.white12 : AppColors.borderLight, width: 1.2),
                    onTap: () => context.go(AppRoutes.adminHome),
                  ),
                  const SizedBox(height: 28),

                  // Qo'shimcha: Email orqali kirish (ixtiyoriy)
                  InkWell(
                    onTap: () => setState(() => _showLoginForm = !_showLoginForm),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showLoginForm ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: AppColors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _showLoginForm ? 'Email orqali kirishni yopish' : 'Email va parol orqali kirish (ixtiyoriy)',
                            style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_showLoginForm) ...[
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'Email manzil',
                              prefixIcon: Icon(Icons.email_outlined, color: AppColors.dark),
                            ),
                            validator: Validators.email,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              hintText: 'Parol',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.dark),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: AppColors.grey,
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: Validators.password,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.dark,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.dark),
                                  )
                                : const Text('Hisobga kirish'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.color,
    required this.iconColor,
    required this.textColor,
    required this.onTap,
    this.border,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color color;
  final Color iconColor;
  final Color textColor;
  final VoidCallback onTap;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.dark.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withValues(alpha: 0.75),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: textColor.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
