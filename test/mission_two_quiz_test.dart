import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volcano_quest/core/constants/app_constants.dart';
import 'package:volcano_quest/core/providers/shared_preferences_provider.dart';
import 'package:volcano_quest/data/models/player_model.dart';
import 'package:volcano_quest/features/missions/screens/mission_two_quiz_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('correct answer adds 15 XP once', (tester) async {
    final prefs = await _pumpMissionTwo(tester);

    await _answerCurrentQuestion(tester, 'Magma chamber');

    expect(find.text('+15 XP RECORDED'), findsOneWidget);
    expect(find.text('15 XP'), findsWidgets);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 15);
    expect(
      savedPlayer.completedMissionOrbs[AppConstants.missionTwoCorrectAnswersId],
      contains(AppConstants.missionTwoQuestionIds[0]),
    );
  });

  testWidgets('wrong answer shows correct answer and adds no XP', (
    tester,
  ) async {
    final prefs = await _pumpMissionTwo(tester);

    await _answerCurrentQuestion(tester, 'Crater');

    expect(find.text('CORRECT ANSWER: MAGMA CHAMBER'), findsOneWidget);
    expect(find.text('0 XP'), findsOneWidget);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 0);
    expect(
      savedPlayer.completedMissionOrbs[AppConstants.missionTwoId],
      contains(AppConstants.missionTwoQuestionIds[0]),
    );
    expect(
      savedPlayer.completedMissionOrbs[AppConstants
              .missionTwoCorrectAnswersId] ??
          const [],
      isNot(contains(AppConstants.missionTwoQuestionIds[0])),
    );
  });

  testWidgets('completing mission awards badge and advances to level 3', (
    tester,
  ) async {
    final prefs = await _pumpMissionTwo(tester);

    await _answerCurrentQuestion(tester, 'Magma chamber');
    await _goNext(tester);
    await _answerCurrentQuestion(tester, 'Shield volcano');
    await _goNext(tester);
    await _answerCurrentQuestion(tester, 'Mayon');
    await _goNext(tester);
    await _answerCurrentQuestion(tester, 'Strombolian eruption');
    await _goNext(tester);
    await _answerCurrentQuestion(tester, 'Volcanic tremors');
    await _goNext(tester);

    expect(find.text('MISSION 2 COMPLETE'), findsOneWidget);
    expect(find.text('LAVA INVESTIGATOR BADGE'), findsOneWidget);
    expect(find.text('75 XP'), findsWidgets);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 75);
    expect(savedPlayer.currentLevel, 3);
    expect(
      savedPlayer.earnedBadges,
      contains(AppConstants.lavaInvestigatorBadge),
    );
  });

  testWidgets('already answered questions are skipped without duplicate XP', (
    tester,
  ) async {
    final prefs = await _pumpMissionTwo(
      tester,
      player: PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 2,
        totalXP: 15,
        completedMissionOrbs: {
          AppConstants.missionTwoId: [AppConstants.missionTwoQuestionIds[0]],
          AppConstants.missionTwoCorrectAnswersId: [
            AppConstants.missionTwoQuestionIds[0],
          ],
        },
      ),
    );

    expect(
      find.text(
        'Which type of volcano is formed from wide, thin layers of lava?',
      ),
      findsOneWidget,
    );

    await _answerCurrentQuestion(tester, 'Shield volcano');
    await _goNext(tester);
    await _answerCurrentQuestion(tester, 'Mayon');
    await _goNext(tester);
    await _answerCurrentQuestion(tester, 'Strombolian eruption');
    await _goNext(tester);
    await _answerCurrentQuestion(tester, 'Volcanic tremors');
    await _goNext(tester);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 75);
    expect(
      savedPlayer.completedMissionOrbs[AppConstants.missionTwoCorrectAnswersId],
      hasLength(5),
    );
  });

  testWidgets('replay starts completed quiz without changing saved progress', (
    tester,
  ) async {
    final completedPlayer = PlayerModel(
      id: 'test-player',
      name: 'Ava',
      avatarIndex: 0,
      currentLevel: 3,
      totalXP: 75,
      earnedBadges: const [AppConstants.lavaInvestigatorBadge],
      completedMissionOrbs: {
        AppConstants.missionTwoId: AppConstants.missionTwoQuestionIds,
        AppConstants.missionTwoCorrectAnswersId:
            AppConstants.missionTwoQuestionIds,
      },
    );
    final prefs = await _pumpMissionTwo(
      tester,
      player: completedPlayer,
      isReplay: true,
    );

    expect(
      find.text(
        "Which part of the volcano stores molten rock beneath the Earth's surface?",
      ),
      findsOneWidget,
    );

    await _answerCurrentQuestion(tester, 'Magma chamber');

    expect(find.text('PRACTICE ANSWER RECORDED'), findsOneWidget);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, completedPlayer.totalXP);
    expect(savedPlayer.currentLevel, completedPlayer.currentLevel);
    expect(
      savedPlayer.completedMissionOrbs,
      completedPlayer.completedMissionOrbs,
    );
    expect(savedPlayer.earnedBadges, completedPlayer.earnedBadges);
  });
}

Future<SharedPreferences> _pumpMissionTwo(
  WidgetTester tester, {
  PlayerModel? player,
  bool isReplay = false,
}) async {
  final testPlayer =
      player ??
      const PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 2,
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
      child: MaterialApp(
        home: MissionTwoQuizScreen(levelId: 2, isReplay: isReplay),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return prefs;
}

Future<void> _answerCurrentQuestion(WidgetTester tester, String answer) async {
  final answerTile = find.ancestor(
    of: find.text(answer),
    matching: find.byType(InkWell),
  );
  await tester.ensureVisible(answerTile);
  await tester.pumpAndSettle();
  await tester.tap(answerTile);
  await tester.pumpAndSettle();
  final submitButton = find.widgetWithText(ElevatedButton, 'SUBMIT ANSWER');
  await tester.ensureVisible(submitButton);
  await tester.pumpAndSettle();
  tester.widget<ElevatedButton>(submitButton).onPressed!();
  await tester.pumpAndSettle();
}

Future<void> _goNext(WidgetTester tester) async {
  if (find.text('MISSION 2 COMPLETE').evaluate().isNotEmpty) {
    return;
  }

  final nextQuestion = find.widgetWithText(ElevatedButton, 'NEXT QUESTION');
  final viewResults = find.widgetWithText(ElevatedButton, 'VIEW RESULTS');
  if (nextQuestion.evaluate().isNotEmpty) {
    await tester.ensureVisible(nextQuestion);
    await tester.pumpAndSettle();
    tester.widget<ElevatedButton>(nextQuestion).onPressed!();
  } else {
    await tester.ensureVisible(viewResults);
    await tester.pumpAndSettle();
    tester.widget<ElevatedButton>(viewResults).onPressed!();
  }
  await tester.pumpAndSettle();
}

PlayerModel _loadSavedPlayer(SharedPreferences prefs) {
  final encodedPlayers = prefs.getStringList(AppConstants.prefPlayers) ?? [];
  final decoded = jsonDecode(encodedPlayers.single) as Map<String, Object?>;
  return PlayerModel.fromJson(decoded);
}
