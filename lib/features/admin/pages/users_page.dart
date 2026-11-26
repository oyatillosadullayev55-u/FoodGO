import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../core/widgets/ui.dart';
import '../../../repositories/admin_repository.dart';
import '../../auth/data/user_profile.dart';
import '../admin_providers.dart';

/// Barcha foydalanuvchilar: qidirish, rol berish va bloklash.
class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  String? _role;
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _update(DbRow user, DbRow values, String question) async {
    final sure = await confirmDialog(
      context,
      title: question,
      message: (user['full_name'] ?? user['email'] ?? '') as String,
      action: 'Tasdiqlash',
    );
    if (!sure || !mounted) return;
    final ok = await runAdminAction(
      context,
      () => ref
          .read(adminRepositoryProvider)
          .update('profiles', user['id'] as String, values),
    );
    if (ok) ref.invalidate(adminUsersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final provider = adminUsersProvider((role: _role, query: _query));
    final me = ref.watch(adminRepositoryProvider).currentUserId;

    return ContentFrame(
      maxWidth: 1000,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Ism, email yoki telefon',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () {
                  if (mounted) setState(() => _query = v);
                });
              },
            ),
          ),
          ChipsBar<String?>(
            selected: _role,
            onSelected: (r) => setState(() => _role = r),
            items: [
              (null, 'Barchasi'),
              for (final r in UserRole.values) (r.name, r.label),
            ],
          ),
          Expanded(
            child: AsyncValueView<List<DbRow>>(
              value: ref.watch(provider),
              onRetry: () => ref.invalidate(provider),
              builder: (users) => users.isEmpty
                  ? const Center(child: Text('Foydalanuvchi topilmadi'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: users.length,
                      itemBuilder: (_, i) => _tile(users[i], me),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(DbRow u, String? me) {
    final role = UserRole.fromString(u['role'] as String?);
    final blocked = u['is_blocked'] == true;
    final name = (u['full_name'] as String?)?.trim();

    return SoftCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: blocked
                ? AppColors.error.withValues(alpha: 0.15)
                : AppColors.primarySoft,
            child: Icon(
              blocked ? Icons.block_rounded : Icons.person_rounded,
              color: blocked ? AppColors.error : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name == null || name.isEmpty ? 'Ismsiz' : name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  [u['email'], u['phone']].whereType<String>().join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.grey),
                ),
              ],
            ),
          ),
          StatusPill(role.label, color: AppColors.primary),
          // Admin o'zini qulflab qo'ymasligi uchun o'z hisobida menyu yo'q.
          if (u['id'] != me)
            PopupMenuButton<Object>(
              tooltip: 'Amallar',
              onSelected: (v) {
                if (v is UserRole) {
                  _update(u, {'role': v.name}, "Rol: ${v.label}?");
                } else {
                  _update(
                    u,
                    {'is_blocked': !blocked},
                    blocked ? 'Blokdan chiqarilsinmi?' : 'Bloklansinmi?',
                  );
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'block',
                  child: Text(blocked ? 'Blokdan chiqarish' : 'Bloklash'),
                ),
                const PopupMenuDivider(),
                for (final r in UserRole.values)
                  if (r != role)
                    PopupMenuItem(value: r, child: Text('${r.label} qilish')),
              ],
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}
