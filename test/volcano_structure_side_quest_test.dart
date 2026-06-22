import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volcano_quest/core/constants/app_constants.dart';
import 'package:volcano_quest/core/providers/shared_preferences_provider.dart';
import 'package:volcano_quest/data/models/player_model.dart';
import 'package:volcano_quest/features/missions/screens/volcano_structure_side_quest_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('correct answers award 25 XP and advance to level 4', (
    tester,
  ) async {
    final prefs = await _pumpSideQuest(tester);

    await _startQuiz(tester);
    await _answerCurrentQuestion(tester, 'Magma chamber');
    await _goNext(tester);
    await _answerCurrentQuestion(tester, 'Active volcanoes');
    await _goNext(tester);
    await _answerCurrentQuestion(tester, 'Phreatic or hydrothermal');

    expect(find.text('SIDE QUEST COMPLETE'), findsOneWidget);
    expect(find.text('25 XP'), findsWidgets);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 25);
    expect(savedPlayer.currentLevel, 4);
    expect(
      savedPlayer.completedMissionOrbs[AppConstants
          .sideQuestVolcanoStructureCorrectAnswersId],
      AppConstants.sideQuestVolcanoStructureQuestionIds,
    );
  });

  testWidgets('wrong answers count as answered without XP', (tester) async {
    final prefs = await _pumpSideQuest(tester);

    await _startQuiz(tester);
    await _answerCurrentQuestion(tester, 'Crater');

    expect(find.text('CORRECT ANSWER: MAGMA CHAMBER'), findsOneWidget);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 0);
    expect(
      savedPlayer.completedMissionOrbs[AppConstants
          .sideQuestVolcanoStructureId],
      contains(AppConstants.sideQuestVolcanoStructureQuestionIds[0]),
    );
    expect(
      savedPlayer.completedMissionOrbs[AppConstants
              .sideQuestVolcanoStructureCorrectAnswersId] ??
          const [],
      isNot(contains(AppConstants.sideQuestVolcanoStructureQuestionIds[0])),
    );
  });

  testWidgets('answered questions are skipped without duplicate XP', (
    tester,
  ) async {
    final prefs = await _pumpSideQuest(
      tester,
      player: PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 3,
        totalXP: 10,
        completedMissionOrbs: {
          AppConstants.sideQuestVolcanoStructureId: [
            AppConstants.sideQuestVolcanoStructureQuestionIds[0],
          ],
          AppConstants.sideQuestVolcanoStructureCorrectAnswersId: [
            AppConstants.sideQuestVolcanoStructureQuestionIds[0],
          ],
        },
      ),
    );

    await _startQuiz(tester);

    expect(
      find.text(
        'According to PHIVOLCS, which volcanoes erupted within the last 10,000 years and may still show activity?',
      ),
      findsOneWidget,
    );

    await _answerCurrentQuestion(tester, 'Active volcanoes');
    await _goNext(tester);
    await _answerCurrentQuestion(tester, 'Phreatic or hydrothermal');

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 25);
    expect(savedPlayer.currentLevel, 4);
    expect(
      savedPlayer.completedMissionOrbs[AppConstants
          .sideQuestVolcanoStructureCorrectAnswersId],
      AppConstants.sideQuestVolcanoStructureQuestionIds,
    );
  });
}

Future<SharedPreferences> _pumpSideQuest(
  WidgetTester tester, {
  PlayerModel? player,
}) async {
  final testPlayer =
      player ??
      const PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 3,
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
      child: const MaterialApp(home: VolcanoStructureSideQuestScreen()),
    ),
  );
  await tester.pumpAndSettle();

  return prefs;
}

Future<void> _startQuiz(WidgetTester tester) async {
  while (find.text('START CHECK').evaluate().isEmpty) {
    await _tapButton(tester, 'NEXT');
  }
  await _tapButton(tester, 'START CHECK');
}

Future<void> _answerCurrentQuestion(WidgetTester tester, String answer) async {
  await tester.ensureVisible(find.text(answer));
  await tester.tap(find.text(answer));
  await tester.pumpAndSettle();
  await _tapButton(tester, 'SUBMIT');
}

Future<void> _goNext(WidgetTester tester) async {
  await _tapButton(tester, 'NEXT');
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
