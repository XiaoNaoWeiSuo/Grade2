import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grade2/main.dart';

void main() {
  testWidgets('GradeApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GradeApp()));
    await tester.pump();
    expect(find.byType(GradeApp), findsOneWidget);
  });
}
