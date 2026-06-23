import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volcano_quest/core/constants/app_constants.dart';
import 'package:volcano_quest/core/providers/shared_preferences_provider.dart';
import 'package:volcano_quest/data/models/player_model.dart';
import 'package:volcano_quest/features/missions/screens/mission_three_word_builder_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('solving a word awards 20 XP and records the word id', (
    tester,
  ) async {
    final prefs = await _pumpMissionThree(tester);

    await _solveCurrentWord(tester, 'MAGMA');

    expect(find.text('+20 XP RECORDED'), findsOneWidget);
    expect(find.text('20 XP'), findsWidgets);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 20);
    expect(
      savedPlayer.completedMissionOrbs[AppConstants.missionThreeId],
      contains(AppConstants.missionThreeWordIds[0]),
    );
  });

  testWidgets('letter bank includes extra distractor choices', (tester) async {
    await _pumpMissionThree(tester);

    final missingLetters = _visibleMissingLetters(tester, 'MAGMA');
    final bankLetters = _visibleBankLetters(tester);

    expect(bankLetters.length, greaterThan(missingLetters.length));
    expect(
      bankLetters.any((letter) => !missingLetters.contains(letter)),
      isTrue,
    );
  });

  testWidgets('wrong arrangement shows try again and awards no XP', (
    tester,
  ) async {
    final prefs = await _pumpMissionThree(tester);

    await _fillWrongCurrentWord(tester);
    await _submitCurrentWord(tester);

    expect(find.text('WRONG SEQUENCE - TRY AGAIN'), findsOneWidget);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 0);
    expect(
      savedPlayer.completedMissionOrbs[AppConstants.missionThreeId] ?? const [],
      isNot(contains(AppConstants.missionThreeWordIds[0])),
    );
  });

  testWidgets('completing all words awards badge and unlocks side quest', (
    tester,
  ) async {
    final prefs = await _pumpMissionThree(tester);

    await _solveCurrentWord(tester, 'MAGMA');
    await _solveCurrentWord(tester, 'LAVA');
    await _solveCurrentWord(tester, 'ASH');
    await _solveCurrentWord(tester, 'ERUPTION');

    expect(find.text('MISSION 3 COMPLETE'), findsOneWidget);
    expect(find.text('VOLCANO VOCABULARY BADGE'), findsOneWidget);
    expect(find.text('START SIDE QUEST'), findsOneWidget);
    expect(find.text('80 XP'), findsWidgets);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 80);
    expect(savedPlayer.currentLevel, 3);
    expect(
      savedPlayer.earnedBadges,
      contains(AppConstants.volcanoVocabularyBadge),
    );
  });

  testWidgets('already solved words are skipped without duplicate XP', (
    tester,
  ) async {
    final prefs = await _pumpMissionThree(
      tester,
      player: PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 3,
        totalXP: 20,
        completedMissionOrbs: {
          AppConstants.missionThreeId: [AppConstants.missionThreeWordIds[0]],
        },
      ),
    );

    expect(find.text('2/4'), findsOneWidget);

    await _solveCurrentWord(tester, 'LAVA');
    await _solveCurrentWord(tester, 'ASH');
    await _solveCurrentWord(tester, 'ERUPTION');

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 80);
    expect(savedPlayer.completedMissionOrbs[AppConstants.missionThreeId], [
      AppConstants.missionThreeWordIds[0],
      AppConstants.missionThreeWordIds[1],
      AppConstants.missionThreeWordIds[2],
      AppConstants.missionThreeWordIds[3],
    ]);
  });
}

Future<SharedPreferences> _pumpMissionThree(
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
      child: const MaterialApp(
        home: MissionThreeWordBuilderScreen(levelId: 3, randomSeed: 7),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return prefs;
}

Future<void> _solveCurrentWord(WidgetTester tester, String word) async {
  final neededLetters = _visibleMissingLetters(tester, word);

  for (final letter in neededLetters) {
    await _tapLetter(tester, letter);
  }

  await _submitCurrentWord(tester);
}

Future<void> _fillWrongCurrentWord(WidgetTester tester) async {
  final bankTexts = find.descendant(
    of: find.byWidgetPredicate((widget) {
      return widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith(
            'mission3-letter-',
          );
    }, skipOffstage: false),
    matching: find.byType(Text),
  );
  final letters = <String>[];
  for (final element in bankTexts.evaluate()) {
    final widget = element.widget;
    if (widget is Text && widget.data != null) {
      letters.add(widget.data!);
    }
  }

  final wrongLetters = letters.reversed.toList();
  if (wrongLetters.join() == letters.join() && wrongLetters.length > 1) {
    final first = wrongLetters.removeAt(0);
    wrongLetters.add(first);
  }

  for (final letter in wrongLetters) {
    await _tapLetter(tester, letter);
  }
}

List<String> _visibleMissingLetters(WidgetTester tester, String word) {
  final missing = <String>[];
  for (var index = 0; index < word.length; index++) {
    final slotText = find.descendant(
      of: find.byKey(ValueKey('mission3-slot-$index')),
      matching: find.text(word[index]),
    );
    if (slotText.evaluate().isEmpty) {
      missing.add(word[index]);
    }
  }
  return missing;
}

Future<void> _tapLetter(WidgetTester tester, String letter) async {
  final letterTiles = find.byWidgetPredicate((widget) {
    return widget.key is ValueKey<String> &&
        (widget.key! as ValueKey<String>).value.startsWith('mission3-letter-');
  }, skipOffstage: false);

  Finder? matchingTile;
  for (final element in letterTiles.evaluate()) {
    final tile = find.byWidget(element.widget);
    final letterText = find.descendant(of: tile, matching: find.text(letter));
    if (letterText.evaluate().isNotEmpty) {
      matchingTile = tile;
      break;
    }
  }

  expect(
    matchingTile,
    isNotNull,
    reason: 'Missing $letter from visible bank ${_visibleBankLetters(tester)}',
  );
  await tester.ensureVisible(matchingTile!);
  await tester.tap(matchingTile);
  await tester.pumpAndSettle();
}

List<String> _visibleBankLetters(WidgetTester tester) {
  final letterTiles = find.byWidgetPredicate((widget) {
    return widget.key is ValueKey<String> &&
        (widget.key! as ValueKey<String>).value.startsWith('mission3-letter-');
  }, skipOffstage: false);
  final letters = <String>[];
  for (final element in letterTiles.evaluate()) {
    final texts = find.descendant(
      of: find.byWidget(element.widget),
      matching: find.byType(Text),
    );
    for (final textElement in texts.evaluate()) {
      final widget = textElement.widget;
      if (widget is Text && widget.data != null) {
        letters.add(widget.data!);
      }
    }
  }
  return letters;
}

Future<void> _submitCurrentWord(WidgetTester tester) async {
  final submitButton = find.widgetWithText(ElevatedButton, 'SUBMIT WORD');
  await tester.ensureVisible(submitButton);
  await tester.tap(submitButton);
  await tester.pumpAndSettle();
}

PlayerModel _loadSavedPlayer(SharedPreferences prefs) {
  final encodedPlayers = prefs.getStringList(AppConstants.prefPlayers) ?? [];
  final decoded = jsonDecode(encodedPlayers.single) as Map<String, Object?>;
  return PlayerModel.fromJson(decoded);
}
