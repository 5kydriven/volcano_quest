import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volcano_quest/app.dart';
import 'package:volcano_quest/core/constants/app_constants.dart';
import 'package:volcano_quest/core/providers/shared_preferences_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('creates and switches between local players', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const VolcanoQuestApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Lahar Lab'), findsOneWidget);
    expect(find.bySemanticsLabel('Initialize mission'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Initialize mission'));
    await tester.pumpAndSettle();

    expect(find.text('Scientist Profiles'), findsWidgets);
    expect(find.text('NO SCIENTIST PROFILES FOUND'), findsWidgets);
    expect(find.bySemanticsLabel('Create new scientist'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Create new scientist'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Deploy to lab base'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'Ava');
    await tester.ensureVisible(find.bySemanticsLabel('Deploy to lab base'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Deploy to lab base'));
    await tester.pumpAndSettle();

    expect(find.text('LEVEL 1 SCIENTIST'), findsOneWidget);
    expect(find.text('AVA'), findsWidgets);

    await tester.ensureVisible(find.byTooltip('Switch player'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Switch player'));
    await tester.pumpAndSettle();

    expect(find.text('Scientist Profiles'), findsWidgets);
    expect(find.text('AVA'), findsWidgets);

    await tester.tap(find.bySemanticsLabel('Create new scientist'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText), 'Ben');
    await tester.ensureVisible(find.bySemanticsLabel('Deploy to lab base'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Deploy to lab base'));
    await tester.pumpAndSettle();

    expect(find.text('BEN'), findsWidgets);

    await tester.ensureVisible(find.byTooltip('Switch player'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Switch player'));
    await tester.pumpAndSettle();

    expect(find.text('AVA'), findsWidgets);
    expect(find.text('BEN'), findsWidgets);

    await tester.tap(find.text('AVA').last);
    await tester.pumpAndSettle();

    expect(find.text('LEVEL 1 SCIENTIST'), findsOneWidget);
    expect(find.text('AVA'), findsWidgets);
  });

  testWidgets('moves returning legacy players from splash to profile select', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      AppConstants.prefOnboardingDone: true,
      AppConstants.prefPlayerName: 'Ava',
      AppConstants.prefAvatarIndex: 0,
      AppConstants.prefCurrentLevel: 1,
      AppConstants.prefTotalXP: 0,
      AppConstants.prefEarnedBadges: <String>[],
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const VolcanoQuestApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Initialize mission'));
    await tester.pumpAndSettle();

    expect(find.text('Scientist Profiles'), findsWidgets);
    expect(find.text('AVA'), findsWidgets);

    await tester.tap(find.text('AVA').last);
    await tester.pumpAndSettle();

    expect(find.text('LEVEL 1 SCIENTIST'), findsOneWidget);
    expect(find.text('AVA'), findsWidgets);
  });
}
