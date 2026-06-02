import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volcano_quest/app.dart';
import 'package:volcano_quest/core/constants/app_constants.dart';
import 'package:volcano_quest/core/providers/shared_preferences_provider.dart';
import 'package:volcano_quest/data/models/player_model.dart';
import 'package:volcano_quest/features/missions/screens/mission_five_anatomy_lab_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders the six volcano anatomy labels', (tester) async {
    await _pumpMissionFive(tester);

    expect(find.text('magma chamber'), findsOneWidget);
    expect(find.text('main vent'), findsOneWidget);
    expect(find.text('secondary vent'), findsOneWidget);
    expect(find.text('crater'), findsOneWidget);
    expect(find.text('lava flow'), findsOneWidget);
    expect(find.text('ash cloud'), findsOneWidget);
  });

  testWidgets(
    'level 5 route opens the anatomy lab instead of briefing fallback',
    (tester) async {
      await _pumpAppAtLevelFive(tester);

      await tester.tap(find.text('INITIALIZE MISSION'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('AVA'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CONTINUE MISSION'));
      await tester.pumpAndSettle();

      expect(find.text('VOLCANO ANATOMY SCAN'), findsOneWidget);
      expect(find.text('NEW RESEARCH BRIEFING AVAILABLE SOON'), findsNothing);
    },
  );

  testWidgets('wrong placement keeps progress and XP unchanged', (
    tester,
  ) async {
    final prefs = await _pumpMissionFive(tester);

    await _placeLabel(tester, 'magma_chamber', 'crater');

    expect(find.text('magma chamber does not match crater'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mission5-label-magma_chamber')),
      findsOneWidget,
    );

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 0);
    expect(
      savedPlayer.completedMissionOrbs[AppConstants.missionFiveId] ?? const [],
      isEmpty,
    );
  });

  testWidgets('correct placement locks the label into its target', (
    tester,
  ) async {
    final prefs = await _pumpMissionFive(tester);

    await _placeLabel(tester, 'magma_chamber', 'magma_chamber');

    expect(find.text('magma chamber locked'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mission5-label-magma_chamber')),
      findsNothing,
    );
    expect(find.text('1/6'), findsOneWidget);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 0);
    expect(
      savedPlayer.completedMissionOrbs[AppConstants.missionFiveId] ?? const [],
      isEmpty,
    );
  });

  testWidgets('completing all labels awards XP, badge, and level 6 unlock', (
    tester,
  ) async {
    final prefs = await _pumpMissionFive(tester);

    for (final partId in AppConstants.missionFiveAnatomyPartIds) {
      await _placeLabel(tester, partId, partId);
    }

    expect(find.text('MISSION 5 COMPLETE'), findsOneWidget);
    expect(find.text('MAGMA ANALYST BADGE'), findsOneWidget);
    expect(find.text('40 XP'), findsWidgets);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 40);
    expect(savedPlayer.currentLevel, 6);
    expect(
      savedPlayer.completedMissionOrbs[AppConstants.missionFiveId],
      AppConstants.missionFiveAnatomyPartIds,
    );
    expect(savedPlayer.earnedBadges, contains(AppConstants.magmaAnalystBadge));
  });

  testWidgets('already completed mission does not duplicate XP', (
    tester,
  ) async {
    final prefs = await _pumpMissionFive(
      tester,
      player: const PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 6,
        totalXP: 40,
        earnedBadges: [AppConstants.magmaAnalystBadge],
        completedMissionOrbs: {
          AppConstants.missionFiveId: AppConstants.missionFiveAnatomyPartIds,
        },
      ),
    );

    expect(find.text('MISSION 5 COMPLETE'), findsOneWidget);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 40);
    expect(savedPlayer.currentLevel, 6);
    expect(
      savedPlayer.earnedBadges.where(
        (badge) => badge == AppConstants.magmaAnalystBadge,
      ),
      hasLength(1),
    );
  });
}

Future<SharedPreferences> _pumpMissionFive(
  WidgetTester tester, {
  PlayerModel? player,
}) async {
  final testPlayer =
      player ??
      const PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 5,
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
        home: MissionFiveAnatomyLabScreen(
          levelId: 5,
          modelPreview: ColoredBox(color: Colors.black),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return prefs;
}

Future<void> _pumpAppAtLevelFive(WidgetTester tester) async {
  const testPlayer = PlayerModel(
    id: 'test-player',
    name: 'Ava',
    avatarIndex: 0,
    currentLevel: 5,
  );

  SharedPreferences.setMockInitialValues({
    AppConstants.prefPlayers: <String>[jsonEncode(testPlayer.toJson())],
    AppConstants.prefActivePlayerId: testPlayer.id,
    AppConstants.prefOnboardingDone: true,
  });
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        missionFiveModelPreviewProvider.overrideWithValue(
          const ColoredBox(color: Colors.black),
        ),
      ],
      child: const VolcanoQuestApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _placeLabel(
  WidgetTester tester,
  String labelId,
  String targetId,
) async {
  final label = find.byKey(ValueKey('mission5-label-$labelId'));
  await tester.ensureVisible(label);
  await tester.tap(label);
  await tester.pumpAndSettle();

  final target = find.byKey(ValueKey('mission5-target-$targetId'));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

PlayerModel _loadSavedPlayer(SharedPreferences prefs) {
  final encodedPlayers = prefs.getStringList(AppConstants.prefPlayers) ?? [];
  final decoded = jsonDecode(encodedPlayers.single) as Map<String, Object?>;
  return PlayerModel.fromJson(decoded);
}
