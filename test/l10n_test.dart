import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grade2/l10n/app_settings.dart';
import 'package:grade2/l10n/app_strings.dart';

void main() {
  group('AppLocale & AppStrings i18n tests', () {
    test('All 5 supported locales have correct subtags and RTL status', () {
      expect(supportedAppLocales.length, 5);

      final zhHans = supportedAppLocales.firstWhere((l) => l.code == 'zh-Hans');
      expect(zhHans.locale.languageCode, 'zh');
      expect(zhHans.locale.scriptCode, 'Hans');
      expect(zhHans.isRtl, isFalse);

      final zhHant = supportedAppLocales.firstWhere((l) => l.code == 'zh-Hant');
      expect(zhHant.locale.languageCode, 'zh');
      expect(zhHant.locale.scriptCode, 'Hant');
      expect(zhHant.isRtl, isFalse);

      final en = supportedAppLocales.firstWhere((l) => l.code == 'en');
      expect(en.locale.languageCode, 'en');
      expect(en.isRtl, isFalse);

      final ja = supportedAppLocales.firstWhere((l) => l.code == 'ja');
      expect(ja.locale.languageCode, 'ja');
      expect(ja.isRtl, isFalse);

      final ur = supportedAppLocales.firstWhere((l) => l.code == 'ur');
      expect(ur.locale.languageCode, 'ur');
      expect(ur.isRtl, isTrue);
    });

    test('Translations match across all locales and methods format correctly', () {
      for (final l in supportedAppLocales) {
        final strings = AppStrings(l.code);
        expect(strings.timetable.isNotEmpty, isTrue);
        expect(strings.grades.isNotEmpty, isTrue);
        expect(strings.account.isNotEmpty, isTrue);
        expect(strings.student.isNotEmpty, isTrue);
        expect(strings.hello('Alice').contains('Alice'), isTrue);
        expect(strings.thisWeek(3).contains('3'), isTrue);
        expect(strings.studentIdNo('12345').contains('12345'), isTrue);
        expect(strings.enrolledOfCap('25', '30').contains('25'), isTrue);
        expect(strings.lessonsOverlapping(2, '08:00-11:40').contains('2'), isTrue);
      }
    });

    testWidgets('AppL10nScope provides reactive context.l10n and responds to updates',
        (tester) async {
      late AppStrings readStrings;

      Widget buildHarness(AppLocale locale) {
        return AppL10nScope(
          strings: AppStrings(locale.code),
          locale: locale,
          child: CupertinoApp(
            home: Builder(
              builder: (ctx) {
                readStrings = ctx.l10n;
                return Text(ctx.l10n.timetable);
              },
            ),
          ),
        );
      }

      await tester.pumpWidget(buildHarness(const AppLocale('zh-Hans', '简体中文')));
      expect(find.text('课表'), findsOneWidget);
      expect(readStrings.timetable, '课表');

      await tester.pumpWidget(buildHarness(const AppLocale('en', 'English')));
      expect(find.text('Timetable'), findsOneWidget);
      expect(readStrings.timetable, 'Timetable');

      await tester.pumpWidget(buildHarness(const AppLocale('ja', '日本語')));
      expect(find.text('時間割'), findsOneWidget);
      expect(readStrings.timetable, '時間割');

      await tester.pumpWidget(buildHarness(const AppLocale('zh-Hant', '繁體中文')));
      expect(find.text('課表'), findsOneWidget);
      expect(readStrings.timetable, '課表');

      await tester.pumpWidget(buildHarness(const AppLocale('ur', 'اردو')));
      expect(find.text('نظام اوقات'), findsOneWidget);
      expect(readStrings.timetable, 'نظام اوقات');
    });

    test('appStringsProvider reflects appSettingsProvider state', () {
      final scope = ProviderContainer();

      expect(scope.read(appStringsProvider).timetable, '课表');
      expect(scope.read(localeProvider).code, 'zh-Hans');

      scope.read(appSettingsProvider.notifier).setLocale(const AppLocale('en', 'English'));
      expect(scope.read(appStringsProvider).timetable, 'Timetable');
      expect(scope.read(localeProvider).code, 'en');

      scope.dispose();
    });
  });
}
