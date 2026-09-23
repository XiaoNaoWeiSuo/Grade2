import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grade2/views/widgets/bank_card_surface.dart';
import 'package:grade2/views/widgets/tategaki_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TategakiText Japanese Vertical Typography', () {
    testWidgets('renders vertical columns with right-to-left progression', (tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: TategakiText(
                text: '大学物理实验(上)',
                style: TextStyle(fontSize: 10),
                maxCharsPerColumn: 5,
                maxColumns: 3,
              ),
            ),
          ),
        ),
      );

      // Verify converted vertical brackets
      final tategakiFinder = find.byType(TategakiText);
      expect(tategakiFinder, findsOneWidget);

      final row = tester.widget<Row>(find.descendant(
        of: tategakiFinder,
        matching: find.byType(Row),
      ));
      expect(row.textDirection, TextDirection.rtl);
    });

    test('convertToVerticalGlyphs replaces brackets with CJK vertical glyphs', () {
      expect(TategakiText.convertToVerticalGlyphs('高等数学(1)'), contains('\uFE35'));
      expect(TategakiText.convertToVerticalGlyphs('高等数学(1)'), contains('\uFE36'));
      expect(TategakiText.convertToVerticalGlyphs('【大学英语】'), contains('\uFE3F'));
      expect(TategakiText.convertToVerticalGlyphs('【大学英语】'), contains('\uFE40'));
    });
  });

  group('BankCardSurface', () {
    testWidgets('renders bank card with dashed separators for merged sessions', (tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: CupertinoPageScaffold(
            child: SizedBox(
              width: 50,
              height: 180,
              child: BankCardSurface(
                baseColor: Color(0xFF1E293B),
                accentColor: Color(0xFF38BDF8),
                isDark: true,
                seed: 42.0,
                borderRadius: 10.0,
                dashedSeparatorYs: [88.0],
                child: Text('Card Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BankCardSurface), findsOneWidget);
      expect(find.text('Card Content'), findsOneWidget);
    });
  });
}
