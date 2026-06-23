import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volcano_quest/app.dart';
import 'package:volcano_quest/core/constants/app_constants.dart';
import 'package:volcano_quest/core/providers/shared_preferences_provider.dart';
import 'package:volcano_quest/data/models/player_model.dart';
import 'package:volcano_quest/features/badges/screens/badges_screen.dart';
import 'package:volcano_quest/features/missions/screens/mission_nine_assessment_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders the final assessment one question at a time', (
    tester,
  ) async {
    await _pumpMissionNine(tester);

    expect(find.text('FINAL ASSESSMENT'), findsOneWidget);
    expect(find.text('Which statement is INCORRECT?'), findsOneWidget);
    expect(find.text('QUESTION 1/5'), findsOneWidget);
    expect(find.text('0% COMPLETE'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsOneWidget);
    expect(
      find.text('Volcanoes that do not produce lava is not dangerous.'),
      findsOneWidget,
    );
  });

  testWidgets('correct answer records progress and correct answer id', (
    tester,
  ) async {
    final prefs = await _pumpMissionNine(tester);

    await _answerCurrentQuestion(tester, 'incorrect_statement', 3);
    final nextButton = find.widgetWithText(ElevatedButton, 'NEXT QUESTION');
    tester.widget<ElevatedButton>(nextButton).onPressed!();
    await tester.pumpAndSettle();

    expect(
      find.text(
        'What is the term used to represent the opening of the volcano where magma comes out?',
      ),
      findsOneWidget,
    );
    expect(find.text('20% COMPLETE'), findsOneWidget);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 0);
    expect(savedPlayer.completedMissionOrbs[AppConstants.missionNineId], [
      AppConstants.missionNineQuestionIds[0],
    ]);
    expect(
      savedPlayer.completedMissionOrbs[AppConstants
          .missionNineCorrectAnswersId],
      [AppConstants.missionNineQuestionIds[0]],
    );
  });

  testWidgets('wrong answer records attempt without XP or correct id', (
    tester,
  ) async {
    final prefs = await _pumpMissionNine(tester);

    await _answerCurrentQuestion(tester, 'incorrect_statement', 0);

    expect(
      find.text(
        'CORRECT ANSWER: VOLCANOES THAT DO NOT PRODUCE LAVA IS NOT DANGEROUS.',
      ),
      findsOneWidget,
    );

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 0);
    expect(savedPlayer.completedMissionOrbs[AppConstants.missionNineId], [
      AppConstants.missionNineQuestionIds[0],
    ]);
    expect(
      savedPlayer.completedMissionOrbs[AppConstants
              .missionNineCorrectAnswersId] ??
          const [],
      isEmpty,
    );
    expect(
      savedPlayer.earnedBadges,
      isNot(contains(AppConstants.volcanoMasterBadge)),
    );
  });

  testWidgets('completion awards 100 XP and Volcano Master Badge once', (
    tester,
  ) async {
    final prefs = await _pumpMissionNine(tester);

    await _submitPerfectAssessment(tester);

    expect(find.text('ANSWER RECORDED'), findsOneWidget);
    expect(find.text('VIEW RESULTS'), findsOneWidget);
    expect(find.text('MISSION 9 COMPLETE'), findsNothing);

    final viewResultsButton = find.widgetWithText(
      ElevatedButton,
      'VIEW RESULTS',
    );
    tester.widget<ElevatedButton>(viewResultsButton).onPressed!();
    await tester.pumpAndSettle();

    expect(find.text('MISSION 9 COMPLETE'), findsOneWidget);
    expect(find.text('VOLCANO MASTER BADGE'), findsOneWidget);
    expect(
      find.text('Congratulations, Ava! You completed all missions.'),
      findsOneWidget,
    );
    expect(find.text('5/5'), findsOneWidget);
    expect(find.text('100 XP'), findsWidgets);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 100);
    expect(savedPlayer.currentLevel, 9);
    expect(
      savedPlayer.completedMissionOrbs[AppConstants.missionNineId],
      AppConstants.missionNineQuestionIds,
    );
    expect(
      savedPlayer.completedMissionOrbs[AppConstants
          .missionNineCorrectAnswersId],
      AppConstants.missionNineQuestionIds,
    );
    expect(savedPlayer.earnedBadges, contains(AppConstants.volcanoMasterBadge));
  });

  testWidgets('completed assessment does not duplicate XP or badge', (
    tester,
  ) async {
    final prefs = await _pumpMissionNine(
      tester,
      player: const PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 9,
        totalXP: 100,
        earnedBadges: [AppConstants.volcanoMasterBadge],
        completedMissionOrbs: {
          AppConstants.missionNineId: AppConstants.missionNineQuestionIds,
          AppConstants.missionNineCorrectAnswersId:
              AppConstants.missionNineQuestionIds,
        },
      ),
    );

    expect(find.text('MISSION 9 COMPLETE'), findsOneWidget);
    expect(find.text('VOLCANO MASTER BADGE'), findsOneWidget);
    expect(
      find.text('Congratulations, Ava! You completed all missions.'),
      findsOneWidget,
    );

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 100);
    expect(
      savedPlayer.earnedBadges.where(
        (badge) => badge == AppConstants.volcanoMasterBadge,
      ),
      hasLength(1),
    );
  });

  testWidgets('level 9 route opens assessment after field lesson', (
    tester,
  ) async {
    await _pumpAppAtLevelNineWithLesson(tester);

    await tester.tap(
      find.byKey(const ValueKey('splashInitializeMissionButton')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('AVA').last);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('9'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('9'));
    await tester.pumpAndSettle();

    expect(find.text('Assessment'), findsOneWidget);

    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();

    expect(find.text('FINAL ASSESSMENT'), findsOneWidget);
    expect(find.text('NEW RESEARCH BRIEFING AVAILABLE SOON'), findsNothing);
  });

  testWidgets('badge collection displays Volcano Master', (tester) async {
    await _pumpBadges(
      tester,
      player: const PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 9,
        totalXP: 100,
        earnedBadges: [AppConstants.volcanoMasterBadge],
      ),
    );

    expect(find.text('VOLCANO MASTER'), findsOneWidget);
    expect(find.text('100 XP'), findsOneWidget);
  });
}

Future<SharedPreferences> _pumpMissionNine(
  WidgetTester tester, {
  PlayerModel? player,
}) async {
  final testPlayer =
      player ??
      const PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 9,
        completedMissionOrbs: {
          AppConstants.levelEightLessonId: [
            AppConstants.levelEightLessonCompleteId,
          ],
        },
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
      child: const MaterialApp(home: MissionNineAssessmentScreen(levelId: 9)),
    ),
  );
  await tester.pumpAndSettle();

  return prefs;
}

Future<void> _pumpAppAtLevelNineWithLesson(WidgetTester tester) async {
  const testPlayer = PlayerModel(
    id: 'test-player',
    name: 'Ava',
    avatarIndex: 0,
    currentLevel: 9,
    completedMissionOrbs: {
      AppConstants.levelEightLessonId: [
        AppConstants.levelEightLessonCompleteId,
      ],
    },
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
      child: const VolcanoQuestApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpBadges(
  WidgetTester tester, {
  required PlayerModel player,
}) async {
  SharedPreferences.setMockInitialValues({
    AppConstants.prefPlayers: <String>[jsonEncode(player.toJson())],
    AppConstants.prefActivePlayerId: player.id,
    AppConstants.prefOnboardingDone: true,
  });
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: BadgesScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _submitPerfectAssessment(WidgetTester tester) async {
  await _answerAndContinue(tester, 'incorrect_statement', 3);
  await _answerAndContinue(tester, 'volcano_opening', 3);
  await _answerAndContinue(tester, 'sticky_lava_type', 2);
  await _answerAndContinue(tester, 'active_volcanoes', 2);
  await _answerCurrentQuestion(tester, 'pinatubo_eruption', 2);
}

Future<void> _answerAndContinue(
  WidgetTester tester,
  String questionId,
  int answerIndex,
) async {
  await _answerCurrentQuestion(tester, questionId, answerIndex);
  final nextButton = find.widgetWithText(ElevatedButton, 'NEXT QUESTION');
  tester.widget<ElevatedButton>(nextButton).onPressed!();
  await tester.pumpAndSettle();
}

Future<void> _answerCurrentQuestion(
  WidgetTester tester,
  String questionId,
  int answerIndex,
) async {
  final button = find.byKey(ValueKey('mission9-$questionId-$answerIndex'));
  await tester.scrollUntilVisible(button, 120);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
  final submitButton = find.widgetWithText(ElevatedButton, 'SUBMIT ANSWER');
  tester.widget<ElevatedButton>(submitButton).onPressed!();
  await tester.pumpAndSettle();
}

PlayerModel _loadSavedPlayer(SharedPreferences prefs) {
  final encodedPlayers = prefs.getStringList(AppConstants.prefPlayers) ?? [];
  final decoded = jsonDecode(encodedPlayers.single) as Map<String, Object?>;
  return PlayerModel.fromJson(decoded);
}
