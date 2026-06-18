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

    await tester.tap(
      find.byKey(const ValueKey('splashInitializeMissionButton')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Scientist profiles'), findsOneWidget);
    expect(find.text('NO SCIENTIST PROFILES FOUND'), findsOneWidget);
    expect(find.text('CREATE NEW SCIENTIST'), findsOneWidget);

    await tester.tap(find.text('CREATE NEW SCIENTIST'));
    await tester.pumpAndSettle();

    expect(find.text('DEPLOY TO LAB BASE'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'Ava');
    await tester.ensureVisible(find.text('DEPLOY TO LAB BASE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DEPLOY TO LAB BASE'));
    await tester.pumpAndSettle();

    expect(find.text('VOLCANO QUEST'), findsNothing);
    expect(find.text('Volcano Quest'), findsOneWidget);
    expect(find.text('AVA'), findsOneWidget);

    await tester.ensureVisible(find.text('Switch player'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch player'));
    await tester.pumpAndSettle();

    expect(find.text('Scientist profiles'), findsOneWidget);
    expect(find.text('AVA'), findsOneWidget);

    await tester.tap(find.text('CREATE NEW SCIENTIST'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText), 'Ben');
    await tester.ensureVisible(find.text('DEPLOY TO LAB BASE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DEPLOY TO LAB BASE'));
    await tester.pumpAndSettle();

    expect(find.text('BEN'), findsOneWidget);

    await tester.ensureVisible(find.text('Switch player'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch player'));
    await tester.pumpAndSettle();

    expect(find.text('AVA'), findsOneWidget);
    expect(find.text('BEN'), findsOneWidget);

    await tester.tap(find.text('AVA'));
    await tester.pumpAndSettle();

    expect(find.text('Volcano Quest'), findsOneWidget);
    expect(find.text('AVA'), findsOneWidget);
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

    await tester.tap(
      find.byKey(const ValueKey('splashInitializeMissionButton')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Scientist profiles'), findsOneWidget);
    expect(find.text('AVA'), findsOneWidget);

    await tester.tap(find.text('AVA'));
    await tester.pumpAndSettle();

    expect(find.text('Volcano Quest'), findsOneWidget);
    expect(find.text('AVA'), findsOneWidget);
  });
}
