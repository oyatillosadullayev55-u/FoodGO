import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../marketplace/marketplace_providers.dart';
import '../marketplace/notification_list.dart';

/// Hamkor panelidagi qo'ng'iroqcha: admin va tizim xabarlari.
class NotificationsButton extends ConsumerWidget {
  const NotificationsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsProvider);
    return IconButton(
      tooltip: 'Xabarlar',
      icon: Badge.count(
        count: unread,
        isLabelVisible: unread > 0,
        backgroundColor: AppColors.accentRed,
        child: const Icon(Icons.notifications_none_rounded),
      ),
      onPressed: () {
        final newest = ref
            .read(notificationsProvider)
            .asData
            ?.value
            .firstOrNull;
        if (newest != null) {
          ref
              .read(notificationsSeenProvider.notifier)
              .set(newest.createdAt.toIso8601String());
        }
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Xabarlar')),
              body: const NotificationList(),
            ),
          ),
        );
      },
    );
  }
}
