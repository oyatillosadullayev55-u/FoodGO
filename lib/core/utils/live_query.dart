import 'dart:async';

import 'package:flutter/foundation.dart';

/// [changes] hodisa bersa yoki [poll] vaqti kelsa, [load] ni qayta chaqiradi.
/// Realtime xatolari ilovani buzmaydi: poll ishlashda davom etadi.
/// Ma'lumot bir marta kelgan bo'lsa, keyingi vaqtinchalik xato eski
/// ro'yxatni ErrorView bilan almashtirmaydi.
Stream<T> liveQuery<T>({
  required Future<T> Function() load,
  required Stream<Object?> Function() changes,
  Duration? poll,
}) {
  late final StreamController<T> controller;
  StreamSubscription<Object?>? sub;
  Timer? timer;
  var running = false;
  var rerun = false;
  var hasValue = false;
  var cancelled = false;

  Future<void> run() async {
    if (running) {
      rerun = true;
      return;
    }
    running = true;
    try {
      do {
        rerun = false;
        try {
          final value = await load();
          if (cancelled) return;
          hasValue = true;
          controller.add(value);
        } catch (e, st) {
          if (cancelled) return;
          if (!hasValue) {
            controller.addError(e, st);
          } else {
            debugPrint('liveQuery: $e');
          }
        }
      } while (rerun);
    } finally {
      running = false;
    }
  }

  controller = StreamController<T>(
    onListen: () {
      run();
      sub = changes().listen(
        (_) => run(),
        onError: (Object e) => debugPrint('Realtime xatosi: $e'),
      );
      if (poll != null) timer = Timer.periodic(poll, (_) => run());
    },
    onCancel: () async {
      cancelled = true;
      timer?.cancel();
      await sub?.cancel();
    },
  );
  return controller.stream;
}
