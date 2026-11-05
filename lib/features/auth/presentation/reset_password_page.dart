import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/content_frame.dart';
import '../providers/auth_providers.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _passwordAgain = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _obscureAgain = true;

  @override
  void dispose() {
    _password.dispose();
    _passwordAgain.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).updatePassword(_password.text);
      ref.invalidate(profileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Parol muvaffaqiyatli yangilandi')),
        );
      context.go(AppRoutes.gate);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSession = ref.watch(authRepositoryProvider).currentSession != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ContentFrame(
              maxWidth: 440,
              child: hasSession ? _form(context) : _expired(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _expired(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(
            Icons.link_off_rounded,
            size: 36,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Havola eskirgan',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'Parolni tiklash havolasi eskirgan yoki sessiya topilmadi. '
          'Iltimos, login sahifasida "Parolni unutdingizmi?" orqali yangi '
          'havola oling.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.grey, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 22),
        ElevatedButton(
          onPressed: () => context.go(AppRoutes.login),
          child: const Text('Kirish sahifasiga qaytish'),
        ),
      ],
    );
  }

  Widget _form(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Yangi parol',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hisobingiz uchun yangi parol o\'rnating. Keyingi safar shu parol '
            'bilan kirasiz.',
            style: TextStyle(color: AppColors.grey, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _password,
            obscureText: _obscure,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'Yangi parol (kamida 6 ta belgi)',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (value) {
              if (value == null || value.length < 6) {
                return "Parol kamida 6 ta belgidan iborat bo'lsin";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordAgain,
            obscureText: _obscureAgain,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Yangi parolni qayta kiriting',
              prefixIcon: const Icon(Icons.lock_reset_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureAgain ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscureAgain = !_obscureAgain),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Parolni qayta kiriting';
              }
              if (value != _password.text) return 'Parollar mos kelmadi';
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.dark,
                    ),
                  )
                : const Text('Parolni yangilash'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _loading ? null : () => context.go(AppRoutes.login),
            style: TextButton.styleFrom(foregroundColor: AppColors.dark),
            child: const Text('Kirish sahifasiga qaytish'),
          ),
        ],
      ),
    );
  }
}
