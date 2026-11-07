import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../repositories/staff_account_repository.dart';
import '../auth/providers/auth_providers.dart';

final staffAccountRepositoryProvider = Provider<StaffAccountRepository>(
  (ref) => StaffAccountRepository(ref.watch(supabaseProvider)),
);

/// Muvaffaqiyatli yaratilsa true qaytaradi.
Future<bool?> showCreateStaffDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _CreateStaffDialog(),
  );
}

class _CreateStaffDialog extends ConsumerStatefulWidget {
  const _CreateStaffDialog();

  @override
  ConsumerState<_CreateStaffDialog> createState() => _CreateStaffDialogState();
}

class _CreateStaffDialogState extends ConsumerState<_CreateStaffDialog> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  String _role = 'restaurant';
  bool _obscure = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  String _generatePassword() {
    // o'xshash belgilar (0/O, 1/l/I) yo'q
    const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(10, (_) => chars[r.nextInt(chars.length)]).join();
  }

  String get _roleLabel => _role == 'courier' ? 'Kuryer' : 'Restoran egasi';

  Future<void> _save() async {
    final email = _email.text.trim();
    final password = _password.text;

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _error = "Email noto'g'ri");
      return;
    }
    if (password.length < 8) {
      setState(() => _error = "Parol kamida 8 belgidan iborat bo'lsin");
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(staffAccountRepositoryProvider).create(
            email: email,
            password: password,
            role: _role,
            fullName: _name.text,
          );
      if (!mounted) return;
      await _showCredentials(email, password);
      if (mounted) Navigator.pop(context, true);
    } on StaffAccountException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Parol faqat shu yerda ko'rinadi, keyin uni qayta ko'rib bo'lmaydi.
  Future<void> _showCredentials(String email, String password) {
    final text = 'FoodGo $_roleLabel hisobi\nEmail: $email\nParol: $password';
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Hisob yaratildi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(text),
            const SizedBox(height: 12),
            const Text(
              "Parolni hozir nusxalab oling: keyin ko'rsatilmaydi. "
              'Xodim kirgach, uni o\'zgartirishi mumkin.',
              style: TextStyle(fontSize: 12.5, color: AppColors.grey),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Nusxalandi')),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Nusxalash'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.dark,
            ),
            child: const Text('Tayyor'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yangi xodim hisobi'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: const [
                  DropdownMenuItem(
                    value: 'restaurant',
                    child: Text('Restoran egasi'),
                  ),
                  DropdownMenuItem(value: 'courier', child: Text('Kuryer')),
                ],
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _role = v ?? 'restaurant'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Ism (ixtiyoriy)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: _obscure,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Parol (kamida 8 belgi)',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: "Parol o'ylab topish",
                        icon: const Icon(Icons.auto_fix_high_rounded),
                        onPressed: _saving
                            ? null
                            : () => setState(() {
                                  _password.text = _generatePassword();
                                  _obscure = false;
                                }),
                      ),
                      IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ],
                  ),
                ),
              ),
              if (_role == 'restaurant') ...[
                const SizedBox(height: 10),
                const Text(
                  'Keyin "Restoranlar" bo\'limida restoranning "Egasi (email)" '
                  'maydoniga shu emailni kiriting.',
                  style: TextStyle(fontSize: 12, color: AppColors.grey),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Bekor qilish'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.dark,
          ),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Yaratish'),
        ),
      ],
    );
  }
}
