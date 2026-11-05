import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      await ref
          .read(authRepositoryProvider)
          .signIn(email: _email.text.trim(), password: _password.text);
      ref.invalidate(profileProvider);
      if (mounted) context.go(AppRoutes.gate);
    } catch (e) {
      if (mounted) {
        if (_isEmailNotConfirmed(e)) {
          await _showUnconfirmedDialog();
        } else {
          _showMessage(friendlyError(e));
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isEmailNotConfirmed(Object error) {
    if (error is! AuthException) return false;
    final m = error.message.toLowerCase();
    return m.contains('email not confirmed') ||
        m.contains('email not verified') ||
        m.contains('not confirmed');
  }

  Future<void> _showUnconfirmedDialog() async {
    final resend = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Email tasdiqlanmagan'),
        content: Text(
          '${_email.text.trim()} manzili hali tasdiqlanmagan. '
          'Emailingizga yuborilgan havolani bosing.\n\n'
          'Xat kelmagan bo\'lsa, qayta yuborishimiz mumkin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Qayta yuborish'),
          ),
        ],
      ),
    );
    if (resend != true || !mounted) return;

    try {
      await ref
          .read(authRepositoryProvider)
          .resendConfirmation(_email.text.trim());
      if (mounted) {
        _showMessage(
          'Tasdiqlash xati qayta yuborildi. Emailingizni tekshiring.',
        );
      }
    } catch (e) {
      if (mounted) _showMessage(friendlyError(e));
    }
  }

  Future<void> _forgotPassword() async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _ForgotPasswordDialog(initialEmail: _email.text.trim()),
    );
    if (!mounted || email == null) return;

    if (email.isEmpty || !email.contains('@')) {
      _showMessage("To'g'ri email manzil kiriting");
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(email);
      _email.text = email;
      if (mounted) {
        _showMessage(
          'Tiklash havolasi $email ga yuborildi. Xatdagi havolani bosib, '
          'yangi parol o\'rnatasiz.',
        );
      }
    } catch (e) {
      if (mounted) _showMessage(friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ContentFrame(
              maxWidth: 440,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
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
                      child: const Icon(
                        Icons.delivery_dining_rounded,
                        color: AppColors.dark,
                        size: 46,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Center(
                    child: Text(
                      'FoodGo',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Hisobingizga kiring',
                      style: TextStyle(color: AppColors.grey, fontSize: 14.5),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark ? Colors.white10 : AppColors.borderLight,
                        width: 0.8,
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'Email manzil',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: AppColors.dark,
                              ),
                            ),
                            validator: Validators.email,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              hintText: 'Parol',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                color: AppColors.dark,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AppColors.grey,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: Validators.password,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _loading ? null : _forgotPassword,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.dark,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                minimumSize: const Size(0, 32),
                              ),
                              child: const Text(
                                'Parolni unutdingizmi?',
                                style: TextStyle(fontSize: 12.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.dark,
                                      ),
                                    )
                                  : const Text('Kirish'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Hisobingiz yo'qmi?",
                        style: TextStyle(color: AppColors.grey, fontSize: 13.5),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.register),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.dark,
                        ),
                        child: const Text(
                          "Ro'yxatdan o'tish",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.customerHome),
                    icon: const Icon(Icons.explore_outlined, size: 18),
                    label: const Text('Mehmon sifatida davom etish'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.dark,
                      side: const BorderSide(
                        color: AppColors.borderLight,
                        width: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: AppColors.dark,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Admin, restoran egasi va kuryer hisoblari faqat "
                            "administrator tomonidan beriladi. Ro'yxatdan "
                            "o'tgan oddiy foydalanuvchi mijoz sifatida boshlaydi.",
                            style: TextStyle(fontSize: 12.5, height: 1.35),
                          ),
                        ),
                      ],
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

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialEmail,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Parolni tiklash'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Email manzilingizni kiriting — parolni yangilash havolasini '
            'yuboramiz.',
            style: TextStyle(fontSize: 13.5, height: 1.4),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
            decoration: const InputDecoration(
              hintText: 'Email manzil',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Bekor qilish'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Yuborish'),
        ),
      ],
    );
  }
}
