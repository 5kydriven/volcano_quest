import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volcano_quest/core/constants/app_constants.dart';
import 'package:volcano_quest/core/providers/shared_preferences_provider.dart';
import 'package:volcano_quest/data/models/player_model.dart';
import 'package:volcano_quest/features/missions/screens/mission_four_map_quiz_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('correct answer awards 30 XP once and records volcano', (
    tester,
  ) async {
    final prefs = await _pumpMissionFour(tester);

    await _openVolcanoQuestion(tester, 'mayon');
    await _answerCurrentQuestion(tester, 'Perfect cone shape');

    expect(find.text('+30 XP RECORDED'), findsOneWidget);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 30);
    expect(
      savedPlayer.completedMissionOrbs[AppConstants.missionFourId],
      contains(AppConstants.missionFourVolcanoIds[0]),
    );
    expect(
      savedPlayer.completedMissionOrbs[AppConstants
          .missionFourCorrectAnswersId],
      contains(AppConstants.missionFourVolcanoIds[0]),
    );
  });

  testWidgets('wrong answer records volcano without XP', (tester) async {
    final prefs = await _pumpMissionFour(tester);

    await _openVolcanoQuestion(tester, 'mayon');
    await _answerCurrentQuestion(tester, 'Tallest volcano');

    expect(find.text('CORRECT ANSWER: PERFECT CONE SHAPE'), findsOneWidget);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 0);
    expect(
      savedPlayer.completedMissionOrbs[AppConstants.missionFourId],
      contains(AppConstants.missionFourVolcanoIds[0]),
    );
    expect(
      savedPlayer.completedMissionOrbs[AppConstants
              .missionFourCorrectAnswersId] ??
          const [],
      isNot(contains(AppConstants.missionFourVolcanoIds[0])),
    );
  });

  testWidgets('question step hides fun facts after next is pressed', (
    tester,
  ) async {
    await _pumpMissionFour(tester);

    await _tapVolcano(tester, 'mayon');

    expect(find.text('Famous for its perfect cone shape'), findsOneWidget);

    await _tapButton(tester, 'NEXT');

    expect(find.text('Why is Mayon Volcano famous?'), findsOneWidget);
    expect(find.text('Famous for its perfect cone shape'), findsNothing);
  });

  testWidgets('completing all volcanoes advances and awards both badges', (
    tester,
  ) async {
    final prefs = await _pumpMissionFour(tester);

    await _answerVolcano(tester, 'mayon', 'Perfect cone shape');
    await _answerVolcano(tester, 'apo', 'Mount Apo');
    await _answerVolcano(tester, 'makiling', 'Inactive');
    await _answerVolcano(tester, 'taal', 'Batangas');
    await _answerVolcano(tester, 'pinatubo', 'Trekking');

    expect(find.text('MISSION 4 COMPLETE'), findsOneWidget);
    expect(find.text('PHILIPPINE VOLCANO EXPLORER'), findsOneWidget);
    expect(find.text('VOLCANO EXPLORER CHAMPION'), findsOneWidget);
    expect(find.text('150 XP'), findsWidgets);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 150);
    expect(savedPlayer.currentLevel, 5);
    expect(
      savedPlayer.earnedBadges,
      contains(AppConstants.philippineVolcanoExplorerBadge),
    );
    expect(
      savedPlayer.earnedBadges,
      contains(AppConstants.volcanoExplorerChampionBadge),
    );
  });

  testWidgets('completion without perfect score skips champion badge', (
    tester,
  ) async {
    final prefs = await _pumpMissionFour(tester);

    await _answerVolcano(tester, 'mayon', 'Tallest volcano');
    await _answerVolcano(tester, 'apo', 'Mount Apo');
    await _answerVolcano(tester, 'makiling', 'Inactive');
    await _answerVolcano(tester, 'taal', 'Batangas');
    await _answerVolcano(tester, 'pinatubo', 'Trekking');

    expect(find.text('MISSION 4 COMPLETE'), findsOneWidget);
    expect(find.text('PHILIPPINE VOLCANO EXPLORER'), findsOneWidget);
    expect(find.text('VOLCANO EXPLORER CHAMPION'), findsNothing);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 120);
    expect(savedPlayer.currentLevel, 5);
    expect(
      savedPlayer.earnedBadges,
      contains(AppConstants.philippineVolcanoExplorerBadge),
    );
    expect(
      savedPlayer.earnedBadges,
      isNot(contains(AppConstants.volcanoExplorerChampionBadge)),
    );
  });

  testWidgets('answered volcanoes cannot duplicate XP', (tester) async {
    final prefs = await _pumpMissionFour(
      tester,
      player: PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 4,
        totalXP: 30,
        completedMissionOrbs: {
          AppConstants.missionFourId: [AppConstants.missionFourVolcanoIds[0]],
          AppConstants.missionFourCorrectAnswersId: [
            AppConstants.missionFourVolcanoIds[0],
          ],
        },
      ),
    );

    await _tapVolcano(tester, 'mayon');

    expect(find.text('FACTS'), findsNothing);

    await _answerVolcano(tester, 'apo', 'Mount Apo');

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 60);
    expect(
      savedPlayer.completedMissionOrbs[AppConstants
          .missionFourCorrectAnswersId],
      [
        AppConstants.missionFourVolcanoIds[0],
        AppConstants.missionFourVolcanoIds[1],
      ],
    );
  });
}

Future<SharedPreferences> _pumpMissionFour(
  WidgetTester tester, {
  PlayerModel? player,
}) async {
  final testPlayer =
      player ??
      const PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 4,
      );

  SharedPreferences.setMockInitialValues({
    AppConstants.prefPlayers: <String>[jsonEncode(testPlayer.toJson())],
    AppConstants.prefActivePlayerId: testPlayer.id,
    AppConstants.prefOnboardingDone: true,
  });
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: MissionFourMapQuizScreen(levelId: 4)),
    ),
  );
  await tester.pumpAndSettle();

  return prefs;
}

Future<void> _answerVolcano(
  WidgetTester tester,
  String volcanoId,
  String answer,
) async {
  await _openVolcanoQuestion(tester, volcanoId);
  await _answerCurrentQuestion(tester, answer);
  if (find.text('BACK TO MAP').evaluate().isNotEmpty) {
    await _tapButton(tester, 'BACK TO MAP');
  }
}

Future<void> _openVolcanoQuestion(WidgetTester tester, String volcanoId) async {
  await _tapVolcano(tester, volcanoId);
  await _tapButton(tester, 'NEXT');
}

Future<void> _tapVolcano(WidgetTester tester, String volcanoId) async {
  final marker = find.byKey(ValueKey('mission4-volcano-$volcanoId'));
  await tester.ensureVisible(marker);
  await tester.tap(marker);
  await tester.pumpAndSettle();
}

Future<void> _answerCurrentQuestion(WidgetTester tester, String answer) async {
  final answerFinder = find.text(answer);
  await tester.ensureVisible(answerFinder);
  await tester.tap(answerFinder);
  await tester.pumpAndSettle();
  await _tapButton(tester, 'SUBMIT ANSWER');
}

Future<void> _tapButton(WidgetTester tester, String label) async {
  final button = find.widgetWithText(ElevatedButton, label);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  tester.widget<ElevatedButton>(button).onPressed!();
  await tester.pumpAndSettle();
}

PlayerModel _loadSavedPlayer(SharedPreferences prefs) {
  final encodedPlayers = prefs.getStringList(AppConstants.prefPlayers) ?? [];
  final decoded = jsonDecode(encodedPlayers.single) as Map<String, Object?>;
  return PlayerModel.fromJson(decoded);
}
