import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/content_frame.dart';
import '../../marketplace/marketplace_providers.dart';
import '../../marketplace/notification_list.dart';

class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({super.key});

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage> {
  /// Sahifa ekranda turganda kelgan xabarlar o'qilgan hisoblanadi.
  void _markSeen() {
    final list = ref.read(notificationsProvider).asData?.value;
    if (list == null || list.isEmpty) return;
    final newest = list.first.createdAt.toIso8601String();
    if (ref.read(notificationsSeenProvider) == newest) return;
    ref.read(notificationsSeenProvider.notifier).set(newest);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(notificationsProvider);
    // Boshqa tabda turganda indexedStack sahifani yashiradi, shunda belgilamaymiz.
    if (TickerMode.valuesOf(context).enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _markSeen();
      });
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Xabarlar')),
      body: const ContentFrame(child: NotificationList()),
    );
  }
}
