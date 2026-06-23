import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volcano_quest/core/constants/app_constants.dart';
import 'package:volcano_quest/core/providers/shared_preferences_provider.dart';
import 'package:volcano_quest/core/routing/app_routes.dart';
import 'package:volcano_quest/data/models/player_model.dart';
import 'package:volcano_quest/features/main_menu/screens/main_menu_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mission button shows side quest after mission 3 completion', (
    tester,
  ) async {
    await _pumpMenu(
      tester,
      PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 3,
        completedMissionOrbs: {
          AppConstants.missionThreeId: AppConstants.missionThreeWordIds,
        },
      ),
    );

    final sideQuestFinder = find.text('SQ');

    expect(sideQuestFinder, findsOneWidget);

    await tester.ensureVisible(sideQuestFinder);
    await tester.pumpAndSettle();
    await tester.tap(sideQuestFinder);
    await tester.pumpAndSettle();

    expect(find.text('SIDE QUEST'), findsOneWidget);
    expect(find.text('Structure of a Volcano'), findsOneWidget);
  });

  testWidgets('mission button returns to level 4 after side quest completion', (
    tester,
  ) async {
    await _pumpMenu(
      tester,
      PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 4,
        completedMissionOrbs: {
          AppConstants.missionThreeId: AppConstants.missionThreeWordIds,
          AppConstants.sideQuestVolcanoStructureId:
              AppConstants.sideQuestVolcanoStructureQuestionIds,
        },
      ),
    );

    final levelFourFinder = find.text('4');

    expect(levelFourFinder, findsOneWidget);

    await tester.ensureVisible(levelFourFinder);
    await tester.pumpAndSettle();
    await tester.tap(levelFourFinder);
    await tester.pumpAndSettle();

    expect(find.text('LEVEL 4'), findsOneWidget);
    expect(find.text('Philippine Volcano Explorer'), findsOneWidget);
  });

  testWidgets('completed level node replays through replay route', (
    tester,
  ) async {
    await _pumpMenuWithRouter(
      tester,
      const PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 3,
      ),
    );

    final levelOneFinder = find.text('1');

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -850));
    await tester.pumpAndSettle();
    await tester.ensureVisible(levelOneFinder);
    await tester.pumpAndSettle();
    await tester.tap(levelOneFinder);
    await tester.pumpAndSettle();

    expect(find.text('REPLAY'), findsOneWidget);

    await tester.tap(find.text('REPLAY'));
    await tester.pumpAndSettle();

    expect(find.text('/level/1?replay=true'), findsOneWidget);
  });

  testWidgets('future level node remains locked and does not open dialog', (
    tester,
  ) async {
    await _pumpMenuWithRouter(
      tester,
      const PlayerModel(
        id: 'test-player',
        name: 'Ava',
        avatarIndex: 0,
        currentLevel: 2,
      ),
    );

    final lockedLevelFinder = find.text('5');

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
    await tester.pumpAndSettle();
    await tester.ensureVisible(lockedLevelFinder);
    await tester.pumpAndSettle();
    await tester.tap(lockedLevelFinder);
    await tester.pumpAndSettle();

    expect(find.text('START'), findsNothing);
    expect(find.text('REPLAY'), findsNothing);
  });
}

Future<void> _pumpMenu(WidgetTester tester, PlayerModel player) async {
  SharedPreferences.setMockInitialValues({
    AppConstants.prefPlayers: <String>[jsonEncode(player.toJson())],
    AppConstants.prefActivePlayerId: player.id,
    AppConstants.prefOnboardingDone: true,
  });
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: MainMenuScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpMenuWithRouter(
  WidgetTester tester,
  PlayerModel player,
) async {
  SharedPreferences.setMockInitialValues({
    AppConstants.prefPlayers: <String>[jsonEncode(player.toJson())],
    AppConstants.prefActivePlayerId: player.id,
    AppConstants.prefOnboardingDone: true,
  });
  final prefs = await SharedPreferences.getInstance();

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const MainMenuScreen()),
      GoRoute(
        path: AppRoutes.levelPath,
        builder: (context, state) => Text(state.uri.toString()),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}
