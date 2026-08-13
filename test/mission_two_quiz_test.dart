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
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(
      find.text(
        'Correct! The magma chamber is an underground reservoir where molten rock, called magma, accumulates beneath a volcano. When pressure builds up, magma may move toward the surface and contribute to a volcanic eruption.',
      ),
      findsOneWidget,
    );

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
    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(
      find.text(
        'Incorrect. A crater is a bowl-shaped depression found at or near the top of a volcano. It is an opening where volcanic materials may be released during an eruption. It does not store molten rock beneath the Earth\'s surface.\n\nCorrect Answer: Magma Chamber.',
      ),
      findsOneWidget,
    );

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

  testWidgets('wrong main vent answer shows specific explanation', (
    tester,
  ) async {
    await _pumpMissionTwo(tester);

    await _answerCurrentQuestion(tester, 'Main vent');

    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(
      find.text(
        'Incorrect. The main vent is the passage through which magma and volcanic materials travel toward the Earth\'s surface. It is not the underground storage area for molten rock.\n\nCorrect Answer: Magma Chamber.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('wrong lava flow answer shows specific explanation', (
    tester,
  ) async {
    await _pumpMissionTwo(tester);

    await _answerCurrentQuestion(tester, 'Lava flow');

    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(
      find.text(
        'Incorrect. A lava flow is molten rock that has erupted onto the Earth\'s surface and moves away from the volcano. It is not a storage area beneath the surface.\n\nCorrect Answer: Magma Chamber.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 2 correct shield volcano answer shows explanation', (
    tester,
  ) async {
    await _pumpMissionTwo(tester);
    await _goToQuestionTwo(tester);

    await _answerCurrentQuestion(tester, 'Shield volcano');

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(
      find.text(
        'Correct! A shield volcano is a broad, gently sloping volcano formed by repeated eruptions of fluid lava. Because the lava can flow over large distances, it builds up wide and relatively thin layers.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 2 cinder cone answer shows specific explanation', (
    tester,
  ) async {
    await _pumpMissionTwo(tester);
    await _goToQuestionTwo(tester);

    await _answerCurrentQuestion(tester, 'Cinder cone');

    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(
      find.text(
        'Incorrect. A cinder cone is a small, steep-sided volcano formed mainly from loose volcanic fragments, such as cinders and ash, that accumulate around a volcanic vent.\n\nCorrect Answer: Shield Volcano.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 2 composite volcano answer shows specific explanation', (
    tester,
  ) async {
    await _pumpMissionTwo(tester);
    await _goToQuestionTwo(tester);

    await _answerCurrentQuestion(tester, 'Composite volcano');

    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(
      find.text(
        'Incorrect. A composite volcano, also called a stratovolcano, is a steep-sided volcano made of alternating layers of lava, ash, and other volcanic materials.\n\nCorrect Answer: Shield Volcano.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 2 lava dome answer shows specific explanation', (
    tester,
  ) async {
    await _pumpMissionTwo(tester);
    await _goToQuestionTwo(tester);

    await _answerCurrentQuestion(tester, 'Lava dome');

    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(
      find.text(
        'Incorrect. A lava dome forms when thick, sticky lava accumulates near a volcanic vent instead of flowing far from the volcano.\n\nCorrect Answer: Shield Volcano.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 3 correct mayon answer shows explanation', (
    tester,
  ) async {
    await _pumpMissionTwo(tester);
    await _goToQuestionThree(tester);

    await _answerCurrentQuestion(tester, 'Mayon');

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(
      find.text(
        'Correct! Mayon Volcano is located in Albay, Bicol Region, and is known for its frequent volcanic activity. It is also famous for its symmetrical cone shape. Its activity makes it an important volcano to monitor for possible eruptions.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 3 isarog answer shows specific explanation', (
    tester,
  ) async {
    await _pumpMissionTwo(tester);
    await _goToQuestionThree(tester);

    await _answerCurrentQuestion(tester, 'Isarog');

    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(
      find.text(
        'Incorrect. Mount Isarog is a volcano in Camarines Sur, but it is not considered the most active volcano in the Bicol Region.\n\nCorrect Answer: Mayon.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 3 bulusan answer shows specific explanation', (
    tester,
  ) async {
    await _pumpMissionTwo(tester);
    await _goToQuestionThree(tester);

    await _answerCurrentQuestion(tester, 'Bulusan');

    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(
      find.text(
        'Incorrect. Bulusan Volcano is an active volcano in Sorsogon and has experienced eruptions, but the expected answer to this question is Mayon Volcano, which is recognized for its frequent activity.\n\nCorrect Answer: Mayon.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 3 iriga answer shows specific explanation', (
    tester,
  ) async {
    await _pumpMissionTwo(tester);
    await _goToQuestionThree(tester);

    await _answerCurrentQuestion(tester, 'Iriga');

    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(
      find.text(
        'Incorrect. Mount Iriga, also known as Asog, is a volcanic mountain in Camarines Sur. It is not the volcano identified as the most active in the Bicol Region.\n\nCorrect Answer: Mayon.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 4 correct strombolian answer shows explanation', (
    tester,
  ) async {
    await _pumpMissionTwo(tester);
    await _goToQuestionFour(tester);

    await _answerCurrentQuestion(tester, 'Strombolian eruption');

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(
      find.text(
        'Correct! A Strombolian eruption is a type of volcanic eruption characterized by relatively short, explosive bursts that can produce lava fountains and eject volcanic materials into the air. The activity is commonly caused by gas bubbles rising through magma.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 4 phreatic answer shows specific explanation', (
    tester,
  ) async {
    await _pumpMissionTwo(tester);
    await _goToQuestionFour(tester);

    await _answerCurrentQuestion(tester, 'Phreatic eruption');

    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(
      find.text(
        'Incorrect. A phreatic eruption occurs when groundwater or surface water is heated rapidly by hot rock or magma, causing an explosive release of steam and fragmented rock. It is not primarily characterized by lava fountains.\n\nCorrect Answer: Strombolian Eruption.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 4 vulcanian answer shows specific explanation', (
    tester,
  ) async {
    await _pumpMissionTwo(tester);
    await _goToQuestionFour(tester);

    await _answerCurrentQuestion(tester, 'Vulcanian eruption');

    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(
      find.text(
        'Incorrect. A Vulcanian eruption involves short, relatively powerful explosions that eject ash, rock fragments, and volcanic gases. Although lava may be involved, lava fountains are more characteristic of Strombolian eruptions.\n\nCorrect Answer: Strombolian Eruption.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 4 plinian answer shows specific explanation', (
    tester,
  ) async {
    await _pumpMissionTwo(tester);
    await _goToQuestionFour(tester);

    await _answerCurrentQuestion(tester, 'Plinian eruption');

    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(
      find.text(
        'Incorrect. A Plinian eruption is a highly explosive eruption that produces a tall column of ash and volcanic gases. It is not primarily characterized by lava fountains.\n\nCorrect Answer: Strombolian Eruption.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 5 correct tremors answer shows explanation', (
    tester,
  ) async {
    await _pumpMissionTwo(tester);
    await _goToQuestionFive(tester);

    await _answerCurrentQuestion(tester, 'Volcanic tremors');

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(
      find.text(
        'Correct! Volcanic tremors are continuous or repeated ground vibrations associated with the movement of magma and volcanic fluids beneath a volcano. An increase in volcanic tremors can be an important warning sign of possible volcanic activity.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 5 thunderstorms answer shows specific explanation', (
    tester,
  ) async {
    await _pumpMissionTwo(tester);
    await _goToQuestionFive(tester);

    await _answerCurrentQuestion(tester, 'Occurrence of thunderstorms');

    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(
      find.text(
        'Incorrect. Thunderstorms are weather phenomena caused by atmospheric conditions and are not, by themselves, a reliable sign that a volcanic eruption is about to occur.\n\nCorrect Answer: Volcanic Tremors.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 5 calm weather answer shows specific explanation', (
    tester,
  ) async {
    await _pumpMissionTwo(tester);
    await _goToQuestionFive(tester);

    await _answerCurrentQuestion(tester, 'Calm weather');

    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(
      find.text(
        'Incorrect. Calm weather describes relatively stable atmospheric conditions. It is not considered a warning sign of an impending volcanic eruption.\n\nCorrect Answer: Volcanic Tremors.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('question 5 steam activity answer shows specific explanation', (
    tester,
  ) async {
    await _pumpMissionTwo(tester);
    await _goToQuestionFive(tester);

    await _answerCurrentQuestion(tester, 'Decrease in steam activity');

    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(
      find.text(
        'Incorrect. A decrease in steam activity is not generally presented as a warning sign of an impending eruption. Changes or increases in volcanic gas and steam activity can provide information about changes occurring within a volcano.\n\nCorrect Answer: Volcanic Tremors.',
      ),
      findsOneWidget,
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

Future<void> _goToQuestionTwo(WidgetTester tester) async {
  await _answerCurrentQuestion(tester, 'Magma chamber');
  await _goNext(tester);
}

Future<void> _goToQuestionThree(WidgetTester tester) async {
  await _goToQuestionTwo(tester);
  await _answerCurrentQuestion(tester, 'Shield volcano');
  await _goNext(tester);
}

Future<void> _goToQuestionFour(WidgetTester tester) async {
  await _goToQuestionThree(tester);
  await _answerCurrentQuestion(tester, 'Mayon');
  await _goNext(tester);
}

Future<void> _goToQuestionFive(WidgetTester tester) async {
  await _goToQuestionFour(tester);
  await _answerCurrentQuestion(tester, 'Strombolian eruption');
  await _goNext(tester);
}

PlayerModel _loadSavedPlayer(SharedPreferences prefs) {
  final encodedPlayers = prefs.getStringList(AppConstants.prefPlayers) ?? [];
  final decoded = jsonDecode(encodedPlayers.single) as Map<String, Object?>;
  return PlayerModel.fromJson(decoded);
}
