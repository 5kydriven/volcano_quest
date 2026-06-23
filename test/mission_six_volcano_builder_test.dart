import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volcano_quest/app.dart';
import 'package:volcano_quest/core/constants/app_constants.dart';
import 'package:volcano_quest/core/providers/shared_preferences_provider.dart';
import 'package:volcano_quest/data/models/player_model.dart';
import 'package:volcano_quest/features/missions/screens/mission_six_volcano_builder_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders the volcano builder prompts and answer types', (
    tester,
  ) async {
    await _pumpMissionSix(tester);

    expect(find.text('VOLCANO CONSTRUCTION SIMULATOR'), findsOneWidget);
    expect(
      find.text('It is the most abundant and the simplest type of volcano.'),
      findsOneWidget,
    );
    expect(find.text('CINDER CONE'), findsOneWidget);
    expect(find.text('SHIELD VOLCANO'), findsOneWidget);
    expect(find.text('COMPOSITE VOLCANO'), findsOneWidget);
  });

  testWidgets(
    'level 6 route opens the volcano builder instead of briefing fallback',
    (tester) async {
      await _pumpAppAtLevelSix(tester);

      await tester.tap(find.text('INITIALIZE MISSION'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('AVA'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CONTINUE MISSION'));
      await tester.pumpAndSettle();

      expect(find.text('VOLCANO CONSTRUCTION SIMULATOR'), findsOneWidget);
      expect(find.text('NEW RESEARCH BRIEFING AVAILABLE SOON'), findsNothing);
    },
  );

  testWidgets('wrong answer retries without XP or progress', (tester) async {
    final prefs = await _pumpMissionSix(tester);

    await _answerCurrentQuestion(tester, 'SHIELD VOLCANO');

    expect(find.text('TYPE MISMATCH - TRY AGAIN'), findsOneWidget);
    expect(find.text('0% COMPLETE'), findsOneWidget);
    expect(find.text('PUZZLE TILES 0/5'), findsOneWidget);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 0);
    expect(
      savedPlayer.completedMissionOrbs[AppConstants.missionSixId] ?? const [],
      isEmpty,
    );
  });

  testWidgets('correct answer drops one puzzle tile and advances prompt', (
    tester,
  ) async {
    final prefs = await _pumpMissionSix(tester);

    await _answerCurrentQuestion(tester, 'CINDER CONE');

    expect(find.text('20% COMPLETE'), findsOneWidget);
    expect(find.text('PUZZLE TILES 1/5'), findsOneWidget);
    expect(find.text('+50 XP - VOLCANO PART LOCKED'), findsOneWidget);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 50);
    expect(savedPlayer.completedMissionOrbs[AppConstants.missionSixId], [
      AppConstants.missionSixBuilderPartIds[0],
    ]);
  });

  testWidgets('completing all prompts awards 50 XP each, badge, and unlock', (
    tester,
  ) async {
    final prefs = await _pumpMissionSix(tester);

    await _answerCurrentQuestion(tester, 'CINDER CONE');
    await _answerCurrentQuestion(tester, 'SHIELD VOLCANO');
    await _answerCurrentQuestion(tester, 'SHIELD VOLCANO');
    await _answerCurrentQuestion(tester, 'COMPOSITE VOLCANO');
    await _answerCurrentQuestion(tester, 'CINDER CONE');

    expect(find.text('MISSION 6 COMPLETE'), findsOneWidget);
    expect(find.text('VOLCANO ARCHITECT BADGE'), findsOneWidget);
    expect(find.text('250 XP'), findsWidgets);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 250);
    expect(savedPlayer.currentLevel, 7);
    expect(
      savedPlayer.completedMissionOrbs[AppConstants.missionSixId],
      AppConstants.missionSixBuilderPartIds,
    );
    expect(
      savedPlayer.earnedBadges,
      contains(AppConstants.volcanoArchitectBadge),
    );
  });

  testWidgets('already completed mission does not duplicate XP', (
    tester,
  ) async {
    final prefs = await _pumpMissionSix(
      tester,
      player: const PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 7,
        totalXP: 250,
        earnedBadges: [AppConstants.volcanoArchitectBadge],
        completedMissionOrbs: {
          AppConstants.missionSixId: AppConstants.missionSixBuilderPartIds,
        },
      ),
    );

    expect(find.text('MISSION 6 COMPLETE'), findsOneWidget);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 250);
    expect(savedPlayer.currentLevel, 7);
    expect(
      savedPlayer.earnedBadges.where(
        (badge) => badge == AppConstants.volcanoArchitectBadge,
      ),
      hasLength(1),
    );
  });
}

Future<SharedPreferences> _pumpMissionSix(
  WidgetTester tester, {
  PlayerModel? player,
}) async {
  final testPlayer =
      player ??
      const PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 6,
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
        home: MissionSixVolcanoBuilderScreen(levelId: 6),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return prefs;
}

Future<void> _pumpAppAtLevelSix(WidgetTester tester) async {
  const testPlayer = PlayerModel(
    id: 'test-player',
    name: 'Ava',
    avatarIndex: 0,
    currentLevel: 6,
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

Future<void> _answerCurrentQuestion(WidgetTester tester, String answer) async {
  await tester.ensureVisible(find.text(answer));
  await tester.tap(find.text(answer));
  await tester.pumpAndSettle();

  await tester.ensureVisible(find.text('LOCK VOLCANO TYPE'));
  await tester.tap(find.text('LOCK VOLCANO TYPE'));
  await tester.pumpAndSettle();
}

PlayerModel _loadSavedPlayer(SharedPreferences prefs) {
  final encodedPlayers = prefs.getStringList(AppConstants.prefPlayers) ?? [];
  final decoded = jsonDecode(encodedPlayers.single) as Map<String, Object?>;
  return PlayerModel.fromJson(decoded);
}
