/// Ekranni haqiqiy shrift va rasmlar bilan chizib, xohlasa PNG saqlaydi.
///
///   flutter test test/screens_test.dart --dart-define=SCREENSHOTS=true
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:osongo/core/theme/app_theme.dart';

const saveScreenshots = bool.fromEnvironment('SCREENSHOTS');
const phone = Size(390, 844);
const desktop = Size(1280, 820);

final _boundary = GlobalKey();

/// Test muhitidagi kvadrat shrift o'rniga Flutter bilan keladigan Roboto.
Future<void> loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    var any = false;
    for (final path in files) {
      final file = File(path);
      if (!file.existsSync()) continue;
      any = true;
      loader.addFont(
        file.readAsBytes().then((b) => ByteData.view(b.buffer)),
      );
    }
    if (any) await loader.load();
  }

  final roboto = [
    for (final w in ['Regular', 'Medium', 'Bold', 'Black'])
      '$dir/Roboto-$w.ttf',
  ];
  await load('Roboto', roboto);
  await load('MaterialIcons', ['$dir/MaterialIcons-Regular.otf']);
}

/// Xarita kafellari keshi qurilma papkasini so'raydi: testda vaqtinchalik papka.
void mockMapCacheDirectory() {
  final directory = Directory.systemTemp.createTempSync('osongo_test').path;
  TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => directory,
      );
}

/// [route] berilsa [routes] bilan, aks holda [home] chiziladi.
Future<void> pumpScreen(
  WidgetTester tester, {
  required List<Override> overrides,
  Size size = phone,
  Widget? home,
  List<RouteBase>? routes,
  String? route,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  // Testda soyalar qora ramka bo'lib chiziladi; skrinshot uchun yoqamiz.
  debugDisableShadows = false;
  final base = AppTheme.light;
  // Shrift oilasi berilmagan uslublar testda kvadrat shriftga tushib qoladi.
  ButtonStyle roboto(ButtonStyle style) => style.copyWith(
    textStyle: WidgetStatePropertyAll(
      style.textStyle!.resolve({})!.copyWith(fontFamily: 'Roboto'),
    ),
  );
  final theme = base.copyWith(
    appBarTheme: base.appBarTheme.copyWith(
      titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
        fontFamily: 'Roboto',
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: roboto(base.elevatedButtonTheme.style!),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: roboto(base.filledButtonTheme.style!),
    ),
  );
  final router = routes == null
      ? null
      : GoRouter(initialLocation: route, routes: routes);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      // Xato holatida avtomatik qayta urinish testda taymer qoldiradi.
      retry: (_, _) => null,
      child: RepaintBoundary(
        key: _boundary,
        child: router == null
            ? MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: theme,
                home: home,
              )
            : MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: theme,
                routerConfig: router,
              ),
      ),
    ),
  );
  await settle(tester);
}

/// pumpAndSettle cheksiz animatsiyalarda qotib qoladi, shu sabab qadamlab.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate().toList()) {
      final image = (element.widget as Image).image;
      // Faqat ilova ichidagi rasmlar: xarita kafellari testda yuklanmaydi
      // va ularni kutish testni qotirib qo'yadi.
      if (image is AssetImage || image is ExactAssetImage) {
        await precacheImage(image, element);
      }
    }
  });
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> capture(WidgetTester tester, String name) async {
  if (!saveScreenshots) return;
  await tester.runAsync(() async {
    final render =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: 1.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/screenshots/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

/// Daraxtni yopadi: taymer va obunalar test oxirigacha qolmaydi.
Future<void> closeScreen(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
  // Flutter test oxirida global sozlama asl holida bo'lishini talab qiladi.
  debugDisableShadows = true;
}
