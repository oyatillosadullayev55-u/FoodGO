import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodgo/core/widgets/async_value_view.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('yuklanish holatida indikator ko\'rinadi', (tester) async {
    await tester.pumpWidget(_wrap(
      AsyncValueView<List<int>>(
        value: const AsyncLoading(),
        builder: (_) => const Text('data'),
      ),
    ));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('data'), findsNothing);
  });

  testWidgets('xato holatida "Qayta urinish" ishlaydi', (tester) async {
    var retried = 0;
    await tester.pumpWidget(_wrap(
      AsyncValueView<List<int>>(
        value: AsyncError(Exception('tarmoq'), StackTrace.empty),
        onRetry: () => retried++,
        builder: (_) => const Text('data'),
      ),
    ));
    await tester.tap(find.text('Qayta urinish'));
    expect(retried, 1);
  });

  testWidgets('bo\'sh ro\'yxatda emptyView ko\'rinadi', (tester) async {
    await tester.pumpWidget(_wrap(
      AsyncValueView<List<int>>(
        value: const AsyncData(<int>[]),
        isEmpty: (l) => l.isEmpty,
        emptyView: const Text('bo\'sh'),
        builder: (_) => const Text('data'),
      ),
    ));
    expect(find.text('bo\'sh'), findsOneWidget);
  });

  testWidgets('ma\'lumot bo\'lsa builder ishlaydi', (tester) async {
    await tester.pumpWidget(_wrap(
      AsyncValueView<List<int>>(
        value: const AsyncData([1, 2]),
        isEmpty: (l) => l.isEmpty,
        emptyView: const Text('bo\'sh'),
        builder: (l) => Text('soni: ${l.length}'),
      ),
    ));
    expect(find.text('soni: 2'), findsOneWidget);
  });
}
