import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volcano_quest/core/constants/app_constants.dart';
import 'package:volcano_quest/core/constants/assets.dart';
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

    // The final question's feedback stays on screen until the user
    // explicitly continues, instead of jumping straight to the summary.
    expect(find.text('SIDE QUEST COMPLETE'), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await _tapButton(tester, 'VIEW RESULTS');

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

  testWidgets('lesson image opens full display when tapped', (tester) async {
    await _pumpSideQuest(tester);

    expect(find.text('VOLCANO STRUCTURE DIAGRAM'), findsOneWidget);

    final lessonImage = find.byKey(
      ValueKey('lesson-image-${Assets.volcanoParts}'),
    );
    await tester.ensureVisible(lessonImage);
    await tester.pumpAndSettle();
    await tester.tap(lessonImage);
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('VOLCANO STRUCTURE DIAGRAM'), findsWidgets);

    await tester.tap(find.byTooltip('Close image'));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsNothing);
  });

  testWidgets('wrong answers count as answered without XP', (tester) async {
    final prefs = await _pumpSideQuest(tester);

    await _startQuiz(tester);
    await _answerCurrentQuestion(tester, 'Crater');

    expect(find.text('CORRECT ANSWER: MAGMA CHAMBER'), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(
      find.text(
        'Incorrect. A crater is a bowl-shaped depression or opening located at or near the top of a volcano. It may be an outlet for volcanic materials during an eruption, but it does not store magma beneath the volcano.\n\nCorrect Answer: Magma Chamber.',
      ),
      findsOneWidget,
    );

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

  testWidgets('question 1 correct magma chamber answer shows explanation', (
    tester,
  ) async {
    await _pumpSideQuest(tester);
    await _startQuiz(tester);

    await _answerCurrentQuestion(tester, 'Magma chamber');

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(
      find.text(
        'Correct! The magma chamber is an underground reservoir where molten rock, called magma, is stored beneath a volcano. As magma accumulates and pressure increases, it may move upward through the volcanic vent and contribute to an eruption.\n\nWhy is it correct? The magma chamber is the part of the volcano that stores magma before it reaches the surface.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 1 side vent answer shows specific explanation', (
    tester,
  ) async {
    await _pumpSideQuest(tester);
    await _startQuiz(tester);

    await _answerCurrentQuestion(tester, 'Side vent');

    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(
      find.text(
        'Incorrect. A side vent is an opening on the side of a volcano through which magma, gases, and other volcanic materials may escape. It is not the underground storage area for magma.\n\nCorrect Answer: Magma Chamber.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 1 base answer shows specific explanation', (
    tester,
  ) async {
    await _pumpSideQuest(tester);
    await _startQuiz(tester);

    await _answerCurrentQuestion(tester, 'Base');

    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(
      find.text(
        'Incorrect. The base is the bottom or lower part of a volcano. Although it forms part of the volcano\'s structure, it does not serve as a reservoir for molten rock.\n\nCorrect Answer: Magma Chamber.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 2 correct active volcanoes answer shows explanation', (
    tester,
  ) async {
    await _pumpSideQuest(tester);
    await _goToQuestionTwo(tester);

    await _answerCurrentQuestion(tester, 'Active volcanoes');

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(
      find.text(
        'Correct! Active volcanoes are volcanoes that have erupted in historical times or have evidence of eruption within the geologically recent past. They may still show signs of volcanic activity and therefore require monitoring.\n\nWhy is it correct? The description refers to volcanoes that have erupted within the last 10,000 years and may still be capable of erupting.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 2 inactive volcanoes answer shows explanation', (
    tester,
  ) async {
    await _pumpSideQuest(tester);
    await _goToQuestionTwo(tester);

    await _answerCurrentQuestion(tester, 'Inactive volcanoes');

    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(
      find.text(
        'Incorrect. Inactive volcanoes are volcanoes that are not currently showing signs of activity and have no recent eruption history according to the classification being used.\n\nCorrect Answer: Active Volcanoes.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 2 potentially active answer shows explanation', (
    tester,
  ) async {
    await _pumpSideQuest(tester);
    await _goToQuestionTwo(tester);

    await _answerCurrentQuestion(tester, 'Potentially active volcanoes');

    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(
      find.text(
        'Incorrect. Potentially active is not the classification that best matches the description in the question. The question specifically refers to volcanoes with evidence of eruption within the last 10,000 years that may still show activity.\n\nCorrect Answer: Active Volcanoes.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 2 shield volcanoes answer shows explanation', (
    tester,
  ) async {
    await _pumpSideQuest(tester);
    await _goToQuestionTwo(tester);

    await _answerCurrentQuestion(tester, 'Shield volcanoes');

    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(
      find.text(
        'Incorrect. A shield volcano is a type of volcano characterized by its broad shape and gently sloping sides. It describes a volcano\'s shape and structure, not its level of volcanic activity.\n\nCorrect Answer: Active Volcanoes.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 3 correct phreatic answer shows explanation', (
    tester,
  ) async {
    await _pumpSideQuest(tester);
    await _goToQuestionThree(tester);

    await _answerCurrentQuestion(tester, 'Phreatic or hydrothermal');

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(
      find.text(
        'Correct! A phreatic eruption, also called a steam-driven eruption, occurs when water comes into contact with hot rocks or heated material beneath the surface. The water rapidly turns into steam, causing an explosive release of steam, rock fragments, and other materials.\n\nWhy is it correct? The question describes an eruption caused by the interaction of water with hot rocks, which is characteristic of a phreatic or hydrothermal eruption.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 3 strombolian answer shows explanation', (
    tester,
  ) async {
    await _pumpSideQuest(tester);
    await _goToQuestionThree(tester);

    await _answerCurrentQuestion(tester, 'Strombolian');

    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(
      find.text(
        'Incorrect. A Strombolian eruption is characterized by intermittent explosive bursts that commonly eject lava fragments and may produce lava fountains. It is not primarily caused by hot rocks coming into contact with water.\n\nCorrect Answer: Phreatic or Hydrothermal.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 3 vulcanian answer shows explanation', (tester) async {
    await _pumpSideQuest(tester);
    await _goToQuestionThree(tester);

    await _answerCurrentQuestion(tester, 'Vulcanian');

    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(
      find.text(
        'Incorrect. A Vulcanian eruption involves short, relatively powerful explosions that eject ash, volcanic gases, and rock fragments. It is not specifically a steam-driven eruption caused by water contacting hot rocks.\n\nCorrect Answer: Phreatic or Hydrothermal.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 3 phreatomagmatic answer shows explanation', (
    tester,
  ) async {
    await _pumpSideQuest(tester);
    await _goToQuestionThree(tester);

    await _answerCurrentQuestion(tester, 'Phreatomagmatic');

    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(
      find.text(
        'Incorrect. A phreatomagmatic eruption occurs when water directly interacts with magma, producing explosive activity. The question describes hot rocks interacting with water rather than direct magma-water interaction.\n\nCorrect Answer: Phreatic or Hydrothermal.',
      ),
      findsOneWidget,
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
  while (find.text('STRUCTURE LESSON').evaluate().isNotEmpty) {
    await _tapButton(tester, 'NEXT');
  }
}

Future<void> _answerCurrentQuestion(WidgetTester tester, String answer) async {
  await tester.ensureVisible(find.text(answer));
  // ensureVisible triggers an animated scroll; settle it before computing
  // the tap position so it doesn't land mid-scroll on the wrong widget.
  await tester.pumpAndSettle();
  await tester.tap(find.text(answer));
  await tester.pumpAndSettle();
  await _tapButton(tester, 'SUBMIT ANSWER');
  // The feedback panel is appended below the answer options inside the same
  // scrollable list, so it can end up below the fold on shorter viewports.
  await tester.drag(find.byType(ListView), const Offset(0, -600));
  await tester.pumpAndSettle();
}

Future<void> _goNext(WidgetTester tester) async {
  await _tapButton(tester, 'NEXT QUESTION');
}

Future<void> _goToQuestionTwo(WidgetTester tester) async {
  await _startQuiz(tester);
  await _answerCurrentQuestion(tester, 'Magma chamber');
  await _goNext(tester);
}

Future<void> _goToQuestionThree(WidgetTester tester) async {
  await _goToQuestionTwo(tester);
  await _answerCurrentQuestion(tester, 'Active volcanoes');
  await _goNext(tester);
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
