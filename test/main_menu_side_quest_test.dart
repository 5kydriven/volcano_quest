import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volcano_quest/core/constants/app_constants.dart';
import 'package:volcano_quest/core/providers/shared_preferences_provider.dart';
import 'package:volcano_quest/data/models/player_model.dart';
import 'package:volcano_quest/features/main_menu/screens/main_menu_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mission button shows side quest after mission 3 completion', (
    tester,
  ) async {
    await _pumpMenu(
      tester,
      PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 3,
        completedMissionOrbs: {
          AppConstants.missionThreeId: AppConstants.missionThreeWordIds,
        },
      ),
    );

    final sideQuestFinder = find.text('SQ');

    expect(sideQuestFinder, findsOneWidget);

    await tester.ensureVisible(sideQuestFinder);
    await tester.pumpAndSettle();
    await tester.tap(sideQuestFinder);
    await tester.pumpAndSettle();

    expect(find.text('SIDE QUEST'), findsOneWidget);
    expect(find.text('Structure of a Volcano'), findsOneWidget);
  });

  testWidgets('mission button returns to level 4 after side quest completion', (
    tester,
  ) async {
    await _pumpMenu(
      tester,
      PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 4,
        completedMissionOrbs: {
          AppConstants.missionThreeId: AppConstants.missionThreeWordIds,
          AppConstants.sideQuestVolcanoStructureId:
              AppConstants.sideQuestVolcanoStructureQuestionIds,
        },
      ),
    );

    final levelFourFinder = find.text('4');

    expect(levelFourFinder, findsOneWidget);

    await tester.ensureVisible(levelFourFinder);
    await tester.pumpAndSettle();
    await tester.tap(levelFourFinder);
    await tester.pumpAndSettle();

    expect(find.text('LEVEL 4'), findsOneWidget);
    expect(find.text('Philippine Volcano Explorer'), findsOneWidget);
  });
}

Future<void> _pumpMenu(WidgetTester tester, PlayerModel player) async {
  SharedPreferences.setMockInitialValues({
    AppConstants.prefPlayers: <String>[jsonEncode(player.toJson())],
    AppConstants.prefActivePlayerId: player.id,
    AppConstants.prefOnboardingDone: true,
  });
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: MainMenuScreen()),
    ),
  );
  await tester.pumpAndSettle();
}
