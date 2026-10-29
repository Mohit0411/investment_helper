import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_helper/data/market_repository.dart';
import 'package:investment_helper/data/models.dart';
import 'package:investment_helper/features/learn/lesson_screen.dart';
import 'package:investment_helper/features/learn/lessons.dart';
import 'package:investment_helper/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _sample = MarketData.fromJson(jsonDecode(File('assets/sample_market.json').readAsStringSync()), DataSource.sample);

Future<void> _launch(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1080, 2400);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [marketDataProvider.overrideWith((ref) async => _sample)],
    child: const InvestmentHelperApp(),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('every tab renders from the sample data', (tester) async {
    await _launch(tester);
    expect(find.text('Market Pulse'), findsOneWidget);
    expect(find.text('Nifty 50'), findsOneWidget);

    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();
    expect(find.text('SIP Planner'), findsOneWidget);
    expect(find.text('Nifty 50 Index'), findsWidgets);

    await tester.tap(find.text('Funds'));
    await tester.pumpAndSettle();
    expect(find.text('Fund Rankings'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.school_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text(lessons.first.title));
    // Lesson markdown loads through real asset I/O, which widget tests don't run,
    // so only check the screen opens. Lesson files are checked in a test below.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LessonScreen), findsOneWidget);
  });

  testWidgets('learning tools open without errors', (tester) async {
    await _launch(tester);
    await tester.tap(find.byIcon(Icons.school_outlined));
    await tester.pumpAndSettle();

    for (final title in ['Option payoff visualiser', 'Leverage simulator', 'Time decay (theta)']) {
      await tester.scrollUntilVisible(find.text(title), 200, scrollable: find.byType(Scrollable).last);
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  test('every lesson has a markdown file', () {
    for (final l in lessons) {
      expect(File(l.asset).existsSync(), isTrue, reason: l.asset);
    }
  });
}
