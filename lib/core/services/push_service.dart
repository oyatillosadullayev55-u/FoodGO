import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../router/app_router.dart';

class PushService {
  PushService(this._client);

  final SupabaseClient _client;
  final _local = FlutterLocalNotificationsPlugin();
  String? _token;
  bool _inited = false;

  static const _channel = AndroidNotificationChannel(
    'orders',
    'Buyurtmalar',
    importance: Importance.high,
  );

  Future<void> init() async {
    if (kIsWeb || _inited) return;
    _inited = true;

    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (r) {
        final p = r.payload;
        if (p == null) return;
        _open(Map<String, dynamic>.from(jsonDecode(p) as Map));
      },
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    FirebaseMessaging.onMessage.listen(_showForeground);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(m.data));

    FirebaseMessaging.instance.onTokenRefresh.listen((t) {
      _token = t;
      _upload(t);
    });

    _client.auth.onAuthStateChange.listen((s) {
      if (s.session != null) _register();
    });
    if (_client.auth.currentSession != null) _register();
  }

  Future<void> _register() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      _token = token;
      await _upload(token);
    } catch (e) {
      debugPrint('Push register xatosi: $e');
    }
  }

  Future<void> _upload(String token) async {
    if (_client.auth.currentSession == null) return;
    try {
      await _client.rpc('register_device_token', params: {
        'p_token': token,
        'p_platform': defaultTargetPlatform.name,
      });
    } catch (e) {
      debugPrint('Token yuklanmadi: $e');
    }
  }

  Future<void> unregister() async {
    final t = _token;
    if (t == null || _client.auth.currentSession == null) return;
    try {
      await _client.rpc('unregister_device_token', params: {'p_token': t});
    } catch (_) {}
  }

  void _showForeground(RemoteMessage m) {
    final n = m.notification;
    if (n == null) return;
    _local.show(
      m.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(m.data),
    );
  }

  void _open(Map<String, dynamic> d) {
    switch (d['target']) {
      case 'restaurant':
        appRouter.go(AppRoutes.restaurantHome);
      case 'courier':
        appRouter.go(AppRoutes.courierHome);
      default:
        final id = d['order_id'] as String?;
        if (id != null) appRouter.go(AppRoutes.orderPath(id));
    }
  }
}
