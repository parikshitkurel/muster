import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muster/main.dart';

void main() {
  testWidgets('MusterApp loads and renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MusterApp()));
    await tester.pumpAndSettle();
    expect(find.text('MUSTER'), findsWidgets);
  });
}
