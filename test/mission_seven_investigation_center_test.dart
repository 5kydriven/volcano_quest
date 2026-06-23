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
import 'package:volcano_quest/features/missions/screens/mission_seven_investigation_center_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders one volcano investigation at a time', (tester) async {
    await _pumpMissionSeven(tester);

    expect(find.text('VOLCANO INVESTIGATION CENTER'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mission7-volcano-image-placeholder')),
      findsOneWidget,
    );
    expect(find.text('Mayon Volcano'), findsOneWidget);
    expect(find.text('Taal Volcano'), findsNothing);
    expect(find.text('ERUPTION RECORDS'), findsOneWidget);
    expect(find.text('GAS EMISSIONS'), findsOneWidget);
    expect(find.text('SEISMIC ACTIVITY'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('INACTIVE'), findsOneWidget);
    expect(find.text('0% COMPLETE'), findsOneWidget);
  });

  testWidgets(
    'level 7 route opens the investigation center instead of briefing fallback',
    (tester) async {
      await _pumpAppAtLevelSeven(tester);

      await tester.tap(find.text('INITIALIZE MISSION'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('AVA'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CONTINUE MISSION'));
      await tester.pumpAndSettle();

      expect(find.text('VOLCANO INVESTIGATION CENTER'), findsOneWidget);
      expect(find.text('NEW RESEARCH BRIEFING AVAILABLE SOON'), findsNothing);
    },
  );

  testWidgets('analyze stays disabled until current volcano is classified', (
    tester,
  ) async {
    await _pumpMissionSeven(tester);

    expect(_analyzeButton(tester).onPressed, isNull);

    await _selectClassification(tester, 'mayon', 'active');

    expect(_analyzeButton(tester).onPressed, isNotNull);
  });

  testWidgets('wrong classification advances to next volcano without XP', (
    tester,
  ) async {
    final prefs = await _pumpMissionSeven(tester);

    await _answerCurrentVolcano(tester, 'mayon', 'inactive');

    expect(find.text('Taal Volcano'), findsOneWidget);
    expect(find.text('Mayon Volcano'), findsNothing);
    expect(find.text('25% COMPLETE'), findsOneWidget);
    expect(
      find.text('INCORRECT CLASSIFICATION - CORRECT ANSWER: ACTIVE'),
      findsOneWidget,
    );

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 0);
    expect(savedPlayer.completedMissionOrbs[AppConstants.missionSevenId], [
      AppConstants.missionSevenVolcanoIds[0],
    ]);
    expect(
      savedPlayer.completedMissionOrbs[AppConstants
              .missionSevenCorrectAnswersId] ??
          const [],
      isEmpty,
    );
  });

  testWidgets('correct classification awards 10 XP and advances progress', (
    tester,
  ) async {
    final prefs = await _pumpMissionSeven(tester);

    await _answerCurrentVolcano(tester, 'mayon', 'active');

    expect(find.text('Taal Volcano'), findsOneWidget);
    expect(find.text('Mayon Volcano'), findsNothing);
    expect(find.text('25% COMPLETE'), findsOneWidget);
    expect(find.text('+10 XP RECORDED'), findsOneWidget);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 10);
    expect(savedPlayer.currentLevel, 7);
    expect(savedPlayer.completedMissionOrbs[AppConstants.missionSevenId], [
      AppConstants.missionSevenVolcanoIds[0],
    ]);
  });

  testWidgets('all correct classifications award 60 XP, badge, and unlock', (
    tester,
  ) async {
    final prefs = await _pumpMissionSeven(tester);

    await _submitPerfectInvestigation(tester);

    expect(find.text('MISSION 7 COMPLETE'), findsOneWidget);
    expect(find.text('LAVA BRIDGE CHAMPION'), findsOneWidget);
    expect(find.text('4/4'), findsOneWidget);
    expect(find.text('60 XP'), findsWidgets);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 60);
    expect(savedPlayer.currentLevel, 8);
    expect(
      savedPlayer.completedMissionOrbs[AppConstants.missionSevenId],
      AppConstants.missionSevenVolcanoIds,
    );
    expect(
      savedPlayer.completedMissionOrbs[AppConstants
          .missionSevenCorrectAnswersId],
      AppConstants.missionSevenVolcanoIds,
    );
    expect(
      savedPlayer.earnedBadges,
      contains(AppConstants.lavaBridgeChampionBadge),
    );
  });

  testWidgets('non-perfect completion unlocks level 8 without badge', (
    tester,
  ) async {
    final prefs = await _pumpMissionSeven(tester);

    await _answerCurrentVolcano(tester, 'mayon', 'inactive');
    await _answerCurrentVolcano(tester, 'taal', 'active');
    await _answerCurrentVolcano(tester, 'arayat', 'inactive');
    await _answerCurrentVolcano(tester, 'makiling', 'inactive');

    expect(find.text('MISSION 7 COMPLETE'), findsOneWidget);
    expect(find.text('INVESTIGATION REVIEW COMPLETE'), findsOneWidget);
    expect(find.text('LAVA BRIDGE CHAMPION'), findsNothing);
    expect(find.text('3/4'), findsOneWidget);
    expect(find.text('30 XP'), findsWidgets);
    expect(find.text('PROCEED TO MISSION 8'), findsOneWidget);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 30);
    expect(savedPlayer.currentLevel, 8);
    expect(
      savedPlayer.earnedBadges,
      isNot(contains(AppConstants.lavaBridgeChampionBadge)),
    );
  });

  testWidgets('already completed mission does not duplicate XP or badge', (
    tester,
  ) async {
    final prefs = await _pumpMissionSeven(
      tester,
      player: const PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 8,
        totalXP: 60,
        earnedBadges: [AppConstants.lavaBridgeChampionBadge],
        completedMissionOrbs: {
          AppConstants.missionSevenId: AppConstants.missionSevenVolcanoIds,
          AppConstants.missionSevenCorrectAnswersId:
              AppConstants.missionSevenVolcanoIds,
        },
      ),
    );

    expect(find.text('MISSION 7 COMPLETE'), findsOneWidget);
    expect(find.text('LAVA BRIDGE CHAMPION'), findsOneWidget);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 60);
    expect(savedPlayer.currentLevel, 8);
    expect(
      savedPlayer.earnedBadges.where(
        (badge) => badge == AppConstants.lavaBridgeChampionBadge,
      ),
      hasLength(1),
    );
  });

  testWidgets('badge collection displays Lava Bridge Champion', (tester) async {
    await _pumpBadges(
      tester,
      player: const PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 8,
        totalXP: 60,
        earnedBadges: [AppConstants.lavaBridgeChampionBadge],
      ),
    );

    expect(find.text('LAVA BRIDGE CHAMPION'), findsOneWidget);
    expect(find.text('60 XP'), findsOneWidget);
  });
}

Future<SharedPreferences> _pumpMissionSeven(
  WidgetTester tester, {
  PlayerModel? player,
}) async {
  final testPlayer =
      player ??
      const PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 7,
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
        home: MissionSevenInvestigationCenterScreen(levelId: 7),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return prefs;
}

Future<void> _pumpAppAtLevelSeven(WidgetTester tester) async {
  const testPlayer = PlayerModel(
    id: 'test-player',
    name: 'Ava',
    avatarIndex: 0,
    currentLevel: 7,
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

Future<void> _submitPerfectInvestigation(WidgetTester tester) async {
  await _answerCurrentVolcano(tester, 'mayon', 'active');
  await _answerCurrentVolcano(tester, 'taal', 'active');
  await _answerCurrentVolcano(tester, 'arayat', 'inactive');
  await _answerCurrentVolcano(tester, 'makiling', 'inactive');
}

Future<void> _answerCurrentVolcano(
  WidgetTester tester,
  String volcanoId,
  String classification,
) async {
  await _selectClassification(tester, volcanoId, classification);
  await _tapAnalyze(tester);
}

Future<void> _selectClassification(
  WidgetTester tester,
  String volcanoId,
  String classification,
) async {
  final button = find.byKey(ValueKey('mission7-$volcanoId-$classification'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _tapAnalyze(WidgetTester tester) async {
  final button = find.widgetWithText(ElevatedButton, 'ANALYZE VOLCANO');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

ElevatedButton _analyzeButton(WidgetTester tester) {
  return tester.widget<ElevatedButton>(
    find.widgetWithText(ElevatedButton, 'ANALYZE VOLCANO'),
  );
}

PlayerModel _loadSavedPlayer(SharedPreferences prefs) {
  final encodedPlayers = prefs.getStringList(AppConstants.prefPlayers) ?? [];
  final decoded = jsonDecode(encodedPlayers.single) as Map<String, Object?>;
  return PlayerModel.fromJson(decoded);
}
