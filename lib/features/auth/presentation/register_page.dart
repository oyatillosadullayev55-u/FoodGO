import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../core/widgets/role_guard.dart';
import '../data/auth_repository.dart';
import '../data/user_profile.dart';
import '../providers/auth_providers.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

enum _ConfirmAction { resend, login }

enum _ExistingAction { resetPassword, login }

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordAgain = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _obscureAgain = true;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _passwordAgain.dispose();
    super.dispose();
  }

  String get _emailValue => _email.text.trim();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .signUp(
            email: _emailValue,
            password: _password.text,
            fullName: _name.text.trim(),
            phone: Validators.cleanPhone(_phone.text),
          );
      if (!mounted) return;

      switch (result.status) {
        case SignUpStatus.signedIn:
          ref.invalidate(profileProvider);
          await _chooseDestination();
        case SignUpStatus.needsConfirmation:
          await _showConfirmationDialog();
        case SignUpStatus.emailTaken:
          await _showExistingAccountDialog();
      }
    } catch (e) {
      if (mounted) _showMessage(friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _chooseDestination() async {
    UserProfile profile;
    try {
      profile = await ref.read(authRepositoryProvider).fetchProfile();
    } catch (_) {
      profile = const UserProfile(id: '', role: UserRole.customer);
    }
    if (!mounted) return;

    final route = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DestinationDialog(profile: profile),
    );
    if (!mounted) return;
    context.go(route ?? homeRouteFor(profile));
  }

  Future<void> _showConfirmationDialog() async {
    final action = await showDialog<_ConfirmAction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Emailingizni tasdiqlang'),
        content: Text(
          'Hisob yaratildi, lekin Supabase email tasdiqlashni talab qilmoqda. '
          '$_emailValue manziliga yuborilgan xatdagi havolani bosing.\n\n'
          'Xat kelmasa, "Qayta yuborish" tugmasini bosing (spam papkasini ham '
          'tekshiring).',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_ConfirmAction.login),
            child: const Text('Kirish'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_ConfirmAction.resend),
            child: const Text('Qayta yuborish'),
          ),
        ],
      ),
    );
    if (!mounted) return;

    if (action == _ConfirmAction.login) {
      context.go(AppRoutes.login);
    } else if (action == _ConfirmAction.resend) {
      await _resendConfirmation();
    }
  }

  Future<void> _resendConfirmation() async {
    try {
      await ref.read(authRepositoryProvider).resendConfirmation(_emailValue);
      if (mounted) {
        _showMessage(
          'Tasdiqlash xati qayta yuborildi. Emailingizni tekshiring.',
        );
      }
    } catch (e) {
      if (mounted) _showMessage(friendlyError(e));
    }
  }

  Future<void> _showExistingAccountDialog() async {
    final action = await showDialog<_ExistingAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hisob allaqachon mavjud'),
        content: Text(
          '$_emailValue allaqachon ro\'yxatdan o\'tgan, kiritilgan parol esa '
          'mos kelmadi.\n\n'
          'Parolni tiklang yoki shu hisob bilan kiring.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_ExistingAction.resetPassword),
            child: const Text('Parolni tiklash'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_ExistingAction.login),
            child: const Text('Kirish'),
          ),
        ],
      ),
    );
    if (!mounted) return;

    if (action == _ExistingAction.login) {
      context.go(AppRoutes.login);
    } else if (action == _ExistingAction.resetPassword) {
      try {
        await ref.read(authRepositoryProvider).resetPassword(_emailValue);
        if (mounted) {
          _showMessage('Parolni tiklash havolasi $_emailValue ga yuborildi.');
        }
      } catch (e) {
        if (mounted) _showMessage(friendlyError(e));
      }
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: ContentFrame(
            maxWidth: 440,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ro'yxatdan o'tish",
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Mijoz sifatida ro'yxatdan o'ting. Admin, restoran va kuryer "
                    "rollari administrator tomonidan beriladi.",
                    style: TextStyle(color: AppColors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Ism va familiya',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: Validators.name,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Telefon: +998 90 123 45 67',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: Validators.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: 'Parol (kamida 6 ta belgi)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordAgain,
                    obscureText: _obscureAgain,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'Parolni qayta kiriting',
                      prefixIcon: const Icon(Icons.lock_reset_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureAgain
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _obscureAgain = !_obscureAgain),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Parolni qayta kiriting';
                      }
                      if (value != _password.text) {
                        return 'Parollar mos kelmadi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.dark,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.dark,
                            ),
                          )
                        : const Text("Ro'yxatdan o'tish"),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text(
                        "Hisobingiz bormi? Kirish",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}

class _DestinationDialog extends StatelessWidget {
  const _DestinationDialog({required this.profile});

  final UserProfile profile;

  List<_Destination> get _items {
    final items = <_Destination>[
      const _Destination(
        'Bosh sahifa — katalog',
        Icons.storefront_outlined,
        AppRoutes.customerHome,
      ),
      const _Destination(
        'Buyurtmalarim',
        Icons.receipt_long_outlined,
        AppRoutes.customerOrders,
      ),
      const _Destination(
        'Savatcha',
        Icons.shopping_bag_outlined,
        AppRoutes.customerCart,
      ),
      const _Destination(
        'Profil',
        Icons.person_outline,
        AppRoutes.customerProfile,
      ),
    ];

    if (profile.role == UserRole.admin) {
      items.insert(
        0,
        const _Destination(
          'Admin panel',
          Icons.admin_panel_settings_outlined,
          AppRoutes.adminHome,
        ),
      );
    } else if (profile.role == UserRole.restaurant || profile.ownsRestaurant) {
      items.insert(
        0,
        const _Destination(
          'Restoran paneli',
          Icons.restaurant_outlined,
          AppRoutes.restaurantHome,
        ),
      );
    } else if (profile.role == UserRole.courier) {
      items.insert(
        0,
        const _Destination(
          'Kuryer paneli',
          Icons.delivery_dining_outlined,
          AppRoutes.courierHome,
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Qaysi sahifaga o'tamiz?"),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in _items)
              ListTile(
                leading: Icon(item.icon, color: AppColors.dark),
                title: Text(item.label),
                onTap: () => Navigator.of(context).pop(item.route),
              ),
            if (profile.role == UserRole.customer &&
                !profile.ownsRestaurant) ...[
              const Divider(height: 8),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 6, 24, 2),
                child: Text(
                  'Restoran yoki kuryer paneliga o\'tish uchun administrator '
                  'ruxsat berishi kerak.',
                  style: TextStyle(fontSize: 12, color: AppColors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
