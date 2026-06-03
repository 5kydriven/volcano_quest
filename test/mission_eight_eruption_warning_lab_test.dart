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
import 'package:volcano_quest/features/missions/screens/mission_eight_eruption_warning_lab_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders one eruption warning sign at a time', (tester) async {
    await _pumpMissionEight(tester);

    expect(find.text('ERUPTION WARNING LAB'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mission8-warning-image-placeholder')),
      findsOneWidget,
    );
    expect(find.text('Shaking ground'), findsOneWidget);
    expect(find.text('Red glowing crater'), findsNothing);
    expect(find.text('TREMORS'), findsOneWidget);
    expect(find.text('CRATER GLOW'), findsOneWidget);
    expect(find.text('STEAMING'), findsOneWidget);
    expect(find.text('GROUND SWELLING'), findsOneWidget);
    expect(find.text('0% COMPLETE'), findsOneWidget);
    expect(find.text('12.5 XP'), findsOneWidget);
  });

  testWidgets(
    'level 8 route opens the warning lab instead of briefing fallback',
    (tester) async {
      await _pumpAppAtLevelEight(tester);

      await tester.tap(find.text('INITIALIZE MISSION'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('AVA'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CONTINUE MISSION'));
      await tester.pumpAndSettle();

      expect(find.text('ERUPTION WARNING LAB'), findsOneWidget);
      expect(find.text('NEW RESEARCH BRIEFING AVAILABLE SOON'), findsNothing);
    },
  );

  testWidgets('correct tap awards XP and advances progress', (tester) async {
    final prefs = await _pumpMissionEight(tester);

    await _answerCurrentSign(tester, 'tremors', 'tremors');

    expect(find.text('Red glowing crater'), findsOneWidget);
    expect(find.text('Shaking ground'), findsNothing);
    expect(find.text('25% COMPLETE'), findsOneWidget);
    expect(find.text('+12.5 XP RECORDED'), findsOneWidget);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 12);
    expect(savedPlayer.currentLevel, 8);
    expect(savedPlayer.completedMissionOrbs[AppConstants.missionEightId], [
      AppConstants.missionEightWarningSignIds[0],
    ]);
    expect(
      savedPlayer.completedMissionOrbs[AppConstants
          .missionEightCorrectAnswersId],
      [AppConstants.missionEightWarningSignIds[0]],
    );
  });

  testWidgets('wrong tap advances without XP or badge', (tester) async {
    final prefs = await _pumpMissionEight(tester);

    await _answerCurrentSign(tester, 'tremors', 'crater_glow');

    expect(find.text('Red glowing crater'), findsOneWidget);
    expect(find.text('CORRECT WARNING SIGN: TREMORS'), findsOneWidget);
    expect(find.text('25% COMPLETE'), findsOneWidget);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 0);
    expect(savedPlayer.completedMissionOrbs[AppConstants.missionEightId], [
      AppConstants.missionEightWarningSignIds[0],
    ]);
    expect(
      savedPlayer.completedMissionOrbs[AppConstants
              .missionEightCorrectAnswersId] ??
          const [],
      isEmpty,
    );
    expect(
      savedPlayer.earnedBadges,
      isNot(contains(AppConstants.eruptionWarningSpecialistBadge)),
    );
  });

  testWidgets('perfect lab awards 70 XP, badge, and unlocks level 9', (
    tester,
  ) async {
    final prefs = await _pumpMissionEight(tester);

    await _submitPerfectWarningLab(tester);

    expect(find.text('MISSION 8 COMPLETE'), findsOneWidget);
    expect(find.text('ERUPTION WARNING SPECIALIST BADGE'), findsOneWidget);
    expect(find.text('4/4'), findsOneWidget);
    expect(find.text('70 XP'), findsWidgets);
    expect(find.text('READ FIELD LESSON'), findsOneWidget);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 70);
    expect(savedPlayer.currentLevel, 9);
    expect(
      savedPlayer.completedMissionOrbs[AppConstants.missionEightId],
      AppConstants.missionEightWarningSignIds,
    );
    expect(
      savedPlayer.completedMissionOrbs[AppConstants
          .missionEightCorrectAnswersId],
      AppConstants.missionEightWarningSignIds,
    );
    expect(
      savedPlayer.earnedBadges,
      contains(AppConstants.eruptionWarningSpecialistBadge),
    );
  });

  testWidgets('non-perfect completion unlocks level 9 without badge', (
    tester,
  ) async {
    final prefs = await _pumpMissionEight(tester);

    await _answerCurrentSign(tester, 'tremors', 'crater_glow');
    await _answerCurrentSign(tester, 'crater_glow', 'crater_glow');
    await _answerCurrentSign(tester, 'steaming', 'steaming');
    await _answerCurrentSign(tester, 'ground_swelling', 'ground_swelling');

    expect(find.text('MISSION 8 COMPLETE'), findsOneWidget);
    expect(find.text('WARNING LAB REVIEW COMPLETE'), findsOneWidget);
    expect(find.text('ERUPTION WARNING SPECIALIST BADGE'), findsNothing);
    expect(find.text('3/4'), findsOneWidget);
    expect(find.text('38 XP'), findsWidgets);
    expect(find.text('READ FIELD LESSON'), findsOneWidget);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 38);
    expect(savedPlayer.currentLevel, 9);
    expect(
      savedPlayer.earnedBadges,
      isNot(contains(AppConstants.eruptionWarningSpecialistBadge)),
    );
  });

  testWidgets('already completed mission does not duplicate XP or badge', (
    tester,
  ) async {
    final prefs = await _pumpMissionEight(
      tester,
      player: const PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 9,
        totalXP: 70,
        earnedBadges: [AppConstants.eruptionWarningSpecialistBadge],
        completedMissionOrbs: {
          AppConstants.missionEightId: AppConstants.missionEightWarningSignIds,
          AppConstants.missionEightCorrectAnswersId:
              AppConstants.missionEightWarningSignIds,
        },
      ),
    );

    expect(find.text('MISSION 8 COMPLETE'), findsOneWidget);
    expect(find.text('ERUPTION WARNING SPECIALIST BADGE'), findsOneWidget);

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.totalXP, 70);
    expect(savedPlayer.currentLevel, 9);
    expect(
      savedPlayer.earnedBadges.where(
        (badge) => badge == AppConstants.eruptionWarningSpecialistBadge,
      ),
      hasLength(1),
    );
  });

  testWidgets('level 9 is gated by the level 8 field lesson', (tester) async {
    final prefs = await _pumpAppAtLevelNineWithoutLesson(tester);

    await tester.tap(find.text('INITIALIZE MISSION'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AVA'));
    await tester.pumpAndSettle();

    expect(find.text('READ FIELD LESSON'), findsOneWidget);
    expect(find.text('Advanced Volcano Response'), findsOneWidget);

    await tester.tap(find.text('READ FIELD LESSON'));
    await tester.pumpAndSettle();

    expect(find.text('FIELD LESSON'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('COMPLETE LESSON'),
      400,
      scrollable: find.byType(Scrollable),
    );
    await tester.ensureVisible(find.text('COMPLETE LESSON'));
    await tester.tap(find.text('COMPLETE LESSON'));
    await tester.pumpAndSettle();

    final savedPlayer = _loadSavedPlayer(prefs);
    expect(savedPlayer.completedMissionOrbs[AppConstants.levelEightLessonId], [
      AppConstants.levelEightLessonCompleteId,
    ]);
    expect(find.text('MISSION 9 UNLOCKED'), findsOneWidget);
    expect(find.text('NEW RESEARCH BRIEFING AVAILABLE SOON'), findsOneWidget);
  });

  testWidgets('badge collection displays Eruption Warning Specialist', (
    tester,
  ) async {
    await _pumpBadges(
      tester,
      player: const PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 9,
        totalXP: 70,
        earnedBadges: [AppConstants.eruptionWarningSpecialistBadge],
      ),
    );

    expect(find.text('ERUPTION WARNING SPECIALIST'), findsOneWidget);
    expect(find.text('70 XP'), findsOneWidget);
  });
}

Future<SharedPreferences> _pumpMissionEight(
  WidgetTester tester, {
  PlayerModel? player,
}) async {
  final testPlayer =
      player ??
      const PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 8,
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
        home: MissionEightEruptionWarningLabScreen(levelId: 8),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return prefs;
}

Future<void> _pumpAppAtLevelEight(WidgetTester tester) async {
  const testPlayer = PlayerModel(
    id: 'test-player',
    name: 'Ava',
    avatarIndex: 0,
    currentLevel: 8,
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

Future<SharedPreferences> _pumpAppAtLevelNineWithoutLesson(
  WidgetTester tester,
) async {
  const testPlayer = PlayerModel(
    id: 'test-player',
    name: 'Ava',
    avatarIndex: 0,
    currentLevel: 9,
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

  return prefs;
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

Future<void> _submitPerfectWarningLab(WidgetTester tester) async {
  await _answerCurrentSign(tester, 'tremors', 'tremors');
  await _answerCurrentSign(tester, 'crater_glow', 'crater_glow');
  await _answerCurrentSign(tester, 'steaming', 'steaming');
  await _answerCurrentSign(tester, 'ground_swelling', 'ground_swelling');
}

Future<void> _answerCurrentSign(
  WidgetTester tester,
  String signId,
  String answerId,
) async {
  final button = find.byKey(ValueKey('mission8-$signId-$answerId'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

PlayerModel _loadSavedPlayer(SharedPreferences prefs) {
  final encodedPlayers = prefs.getStringList(AppConstants.prefPlayers) ?? [];
  final decoded = jsonDecode(encodedPlayers.single) as Map<String, Object?>;
  return PlayerModel.fromJson(decoded);
}
