# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Volcano Quest is a Flutter learning app centered on a local "scientist" (player) profile, a 9-level volcano-themed mission progression, badges, and a leaderboard. State is Riverpod, navigation is `go_router`, and persistence is `SharedPreferences` (players/settings) plus a local Drift/SQLite cache (leaderboard sync) with optional Firebase Firestore sync.

## Commands

```bash
flutter pub get
```

```bash
flutter analyze
```
Run after any code change — this is the project's required type/lint check (see `analysis_options.yaml`, based on `flutter_lints` with `prefer_single_quotes` enabled).

```bash
flutter test
```

```bash
flutter test test/mission_two_quiz_test.dart
```
Run a single test file. To run one test case, add `--plain-name "test name"`.

```bash
flutter run
```

Drift generates `lib/data/local/app_database.g.dart` from `lib/data/local/app_database.dart` via `build_runner` (declared in `dev_dependencies`). Regenerate after editing tables:
```bash
dart run build_runner build --delete-conflicting-outputs
```

There is no CI config and no lint/format step beyond `flutter analyze` — that command is the source of truth for correctness before committing.

## Architecture

### Layering

- `lib/main.dart` / `lib/app.dart`: bootstrapping. `main.dart` initializes `SharedPreferences` and (on Android, non-web) Firebase, then wraps `VolcanoQuestApp` in a `ProviderScope` with `sharedPreferencesProvider` overridden — every test does the same override instead of hitting real storage. `app.dart` builds `MaterialApp.router`, wires the audio controller to route changes (background music per screen via `MissionAudioProfile.bgmForLocation`), and resumes audio on the first user tap (`retryAfterUserInteraction`) to satisfy browser/OS autoplay policies.
- `lib/core`: cross-feature infrastructure — `constants` (route-independent constants, pref keys, per-mission id/XP tables, asset paths), `providers` (`sharedPreferencesProvider`, `appDatabaseProvider`, `firebaseFirestoreProvider` — all overridden in tests), `routing` (`AppRoutes` path constants + `routerProvider`'s `GoRouter`), `theme` (dark lab theme), `audio` (`AudioController`, `AudioCatalog`, `MissionAudioProfile`).
- `lib/data`: persistence.
  - `models`: immutable data classes (`copyWith`/`toJson`/`fromJson`), with an explicit empty sentinel (`PlayerModel.empty`) for the no-profile UI state.
  - `repositories`: `PlayerRepository` (all `SharedPreferences` access for players) and `LeaderboardRepository` (combines local players, a Drift cache, and an optional Firestore remote source).
  - `local`: the Drift `AppDatabase` (leaderboard cache + sync state tables) and platform-conditional connection setup (`database_connection.dart` picks `database_connection_io.dart` vs `_unsupported.dart` via `dart.library.io`).
- `lib/features/<feature>`: `screens` (UI) + `application` (Riverpod controllers/notifiers) per feature — `onboarding`, `player`, `main_menu`, `missions`, `badges`, `leaderboard`, `settings`.
- `lib/shared/widgets`: reusable lab-styled primitives (`LabButton`, `StatusDot`, `ScanLine`, `LabBadge`, mission panels/backgrounds) shared across screens.

### Player state and persistence

- `PlayerNotifier` (`lib/features/player/application/player_controller.dart`) starts at `PlayerModel.empty`, loads the persisted active player asynchronously, and guards against races with `_mutationCount`: any mutation increments the counter, and the initial `_load()` only applies its result if no mutation has happened yet.
- Every mutating method (per-mission completion, XP, badges, level advancement) reads current state, computes the update, and calls `_repo.savePlayer(...)`, so in-memory state and `SharedPreferences` never diverge. Each of the nine missions (plus the volcano-structure side quest and the level-8 field lesson) has its own dedicated method in `PlayerNotifier` encoding that mission's XP table, completion criteria, badge, and level-unlock rule — read the sibling method for an existing mission before adding a new one.
- Progress for a mission is tracked as a list of completed/answered ids under `state.completedMissionOrbs[<missionId>]`, with a parallel `<missionId>_correct_answers` key for quiz-style missions that need to distinguish "answered" from "answered correctly" (used for perfect-score badges and bonus XP). All mission ids, orb/question/part id lists, and XP amounts live in `AppConstants` — never hardcode them in a screen.
- `PlayerRepository.loadPlayer()` calls `migrateLegacyPlayer()` first, which only runs when the multi-player list is empty; it reads pre-multi-profile single-player pref keys and, if a name is present, converts them into a normal saved `PlayerModel`. JSON decode failures and malformed records collapse to `PlayerModel.empty`; `loadPlayers()` then filters out anything with an empty `id`/`name`.

### Routing

- Routes are centralized in `AppRoutes` (`lib/core/routing/app_routes.dart`); build query-carrying paths through its helpers (`AppRoutes.replay(...)`, `.replayLevel(...)`, `.playersFromMenu`, `.requiredStarterKnowledge`) rather than concatenating strings.
- `routerProvider` (`lib/core/routing/app_router.dart`) maps most routes 1:1 to a screen, but `/level/:levelId` branches by parsed `levelId` to the matching mission screen and reads `replay` from query params. Level 9 has special handling: it checks `player.completedMissionOrbs[levelEightLessonId]` to decide whether to show the level-8 field lesson (mission prerequisite) or the level-9 assessment.
- Use `context.go(...)` for primary flow transitions and `context.push(...)` for level navigation (so back returns to the previous screen), matching existing screens. After an awaited state mutation, check `mounted`/`context.mounted` before touching `BuildContext`.

### Adding or editing a mission

A mission screen typically: reads `playerProvider`, renders question/interaction UI from a hardcoded content list, calls the mission's dedicated `PlayerNotifier` method on each answer/interaction, and shows a completion panel (`lib/shared/widgets/mission_complete_panel.dart`) when all ids for that mission are present in `completedMissionOrbs`. When adding a mission or side quest, follow the same shape: id/XP/badge constants in `AppConstants`, a notifier method in `PlayerNotifier`, a route in `AppRoutes`/`app_router.dart`, and a widget test under `test/` that pumps the screen with mocked `SharedPreferences` (see `test/mission_two_quiz_test.dart` for the pattern of asserting both UI feedback and the persisted `PlayerModel`).

### Leaderboard sync

`LeaderboardRepository.loadEntries()` merges local players (from `PlayerRepository`) with a Drift-cached remote snapshot (`CachedLeaderboardEntries`), preferring local entries when a player is both local and cached remotely. `syncIfOnline()` is a no-op (`LeaderboardSyncStatus.unavailable`) when no `LeaderboardRemoteDataSource` is available (i.e., Firebase wasn't initialized — see `firebaseFirestoreProvider`, which returns `null` if `Firebase.apps.isEmpty`), checks connectivity via `LeaderboardConnectionChecker` before touching the network, uploads each local player only if its content hash changed since the last upload (tracked in the `LeaderboardSyncState` Drift table), then re-caches the fetched remote top entries. This repository is exercised through fakes in `test/leaderboard_repository_test.dart` — implement `LeaderboardRemoteDataSource`/`LeaderboardConnectionChecker` there rather than hitting real Firestore/connectivity.

### Audio

`AudioController` (`lib/core/audio/audio_controller.dart`) owns one looping BGM player and a small round-robin pool of SFX players (`AudioCatalog` maps `BgmTrack`/`SfxCue` enums to asset paths, supporting multiple SFX variants per cue). It detects the Flutter test binding and goes fully no-op (`_isNoop`) so widget tests never touch real audio playback. Every playback call is guarded by request/stop ids so a stale async completion can't stomp a newer one. `app.dart` drives desired BGM off the current route via `MissionAudioProfile.bgmForLocation`.

### Dependencies declared but not currently wired in

`flame`, `rive`, `flutter_3d_controller`, `confetti`, and `lottie` are in `pubspec.yaml` but have no usage under `lib/` as of this writing — don't assume mission screens use them without checking; grep first if a mission's visuals/physics seem like they should come from one of these.

## Conventions

- **Naming**: files/directories `snake_case`; classes/widgets/models `PascalCase`; variables/methods/providers `camelCase`; private helpers get a leading underscore (`_AvatarTile`, `_decodePlayer`, `_mutationCount`).
- **Feature placement**: feature UI in `lib/features/<feature>/screens`, feature state in `lib/features/<feature>/application`, shared persistence in `lib/data`, cross-feature infrastructure in `lib/core`, reusable visual primitives in `lib/shared/widgets`.
- **Providers**: descriptive `*Provider` names, colocated with the layer they expose; read dependencies with `ref.watch(...)`, call mutations through `ref.read(xProvider.notifier)`.
- **Models/persistence**: immutable classes with `final` fields, `const` constructor, `copyWith`, `toJson`/`fromJson`; JSON parsing defaults missing/invalid fields instead of throwing across the repository boundary.
- **Constants**: route paths, pref keys, mission ids, XP tables, and asset paths live in `AppConstants`/`AppRoutes`/`Assets` — don't repeat literals in widgets.
- **Imports**: package imports before local imports; local imports inside `lib` are relative — stay consistent with existing files.
- **Visual style**: dark teal "lab" theme via `AppColors` and the shared lab widgets; uppercase labels, small letter spacing, thin borders, compact cards.
- Prefer the smallest change that fits this architecture; ask before adding new tests, lint rules, formatter config, external dependencies, or broad refactors that aren't explicitly requested.
