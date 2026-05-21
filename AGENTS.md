# AGENTS.md

## 1. Overview

Volcano Quest is a Flutter learning app centered on a local scientist profile, mission progression, and volcano-themed UI flows. The codebase is organized around feature screens backed by shared routing, theme, constants, persistence, and Riverpod state.

## 2. Folder Structure

- `lib`: application source.
  - `main.dart` and `app.dart`: bootstrapping, system UI setup, root `ProviderScope`, and `MaterialApp.router` composition.
  - `core`: cross-feature infrastructure.
    - `constants`: app-wide route-independent constants, preference keys, level metadata, and asset path constants.
    - `providers`: globally required provider contracts, currently the `SharedPreferences` provider overridden at startup and in tests.
    - `routing`: named route constants and the `GoRouter` provider that maps routes to feature screens.
    - `theme`: shared color tokens and dark `ThemeData`.
  - `data`: persistence-facing models and repositories.
    - `models`: immutable data objects with JSON conversion and `copyWith` helpers.
    - `repositories`: `SharedPreferences` storage, migration, decoding, and active-player selection logic.
  - `features`: user-facing app areas grouped by domain.
    - `onboarding`: splash and profile creation screens.
    - `player`: player profile state controller and profile selection screen.
    - `main_menu`: current player dashboard and mission navigation surface.
  - `shared/widgets`: reusable lab-styled widgets shared across screens.
- `test`: widget smoke tests that exercise app flows through the same provider overrides used by production startup.
- `assets`: image assets declared as a single `assets/` bundle in `pubspec.yaml`.
- `docs`: product/design reference documents; keep implementation changes aligned with them when they are relevant.
- `android`, `ios`, `linux`, `macos`, `web`, `windows`: Flutter platform shells and generated platform integration files.

## 3. Core Behaviors & Patterns

- **Riverpod wiring**: App state enters through providers rather than globals. `main.dart` obtains `SharedPreferences`, overrides `sharedPreferencesProvider`, and the app watches derived providers such as `routerProvider`, `playerRepositoryProvider`, `playerProvider`, and `playerProfilesProvider`.
- **Player state lifecycle**: `PlayerNotifier` starts with `PlayerModel.empty`, loads the persisted active player asynchronously, and protects newer mutations with `_mutationCount` before applying the load result. Mutating operations update state only through repository saves so memory state and local storage stay aligned.
- **Local persistence boundary**: `PlayerRepository` owns all `SharedPreferences` access for players. It stores players as encoded JSON strings under `AppConstants.prefPlayers`, filters out invalid decoded records, sets the active player id separately, and marks onboarding complete when at least one player is saved.
- **Legacy data recovery**: `loadPlayer()` begins by calling `migrateLegacyPlayer()`. Migration only runs when the multi-player list is empty, reads older single-player preference keys, creates a normal `PlayerModel`, and then saves through the current persistence path.
- **Failure containment**: JSON decode failures and malformed player records collapse to `PlayerModel.empty`, then `loadPlayers()` removes empty records by requiring non-empty `id` and `name`. UI-facing code therefore receives either valid profiles or the explicit empty player sentinel.
- **Navigation flow**: Routes are centralized in `AppRoutes`, with screen transitions using `context.go(...)` for primary flow changes and `context.push(...)` for level navigation. Async navigation after mutations checks `mounted` or `context.mounted` before using the current `BuildContext`.
- **UI composition**: Screens are mostly thin compositions of Flutter widgets plus private screen-local widgets. Shared primitives such as `LabButton`, `StatusDot`, `ScanLine`, and `LabBadge` carry the recurring lab visual language across splash, onboarding, profile selection, and menu screens.
- **Progress and index safety**: UI lookups for levels and avatar icons clamp indexes before reading fixed lists. Player progress is derived from `currentLevel`, `AppConstants.totalLevels`, and constant level metadata rather than duplicated literals in screens.

## 4. Conventions

- **Naming**: Dart files and directories use `snake_case`; classes, widgets, and models use `PascalCase`; variables, methods, providers, and private helpers use `camelCase`. Private implementation details use a leading underscore, as in `_AvatarTile`, `_decodePlayer`, and `_mutationCount`.
- **Feature placement**: Put feature UI under `lib/features/<feature>/screens`, feature state under `application`, shared persistence under `lib/data`, and cross-feature infrastructure under `lib/core`. Reusable visual primitives belong in `lib/shared/widgets`.
- **Providers**: Riverpod providers use descriptive `*Provider` names and are colocated with the layer they expose. Provider dependencies are obtained with `ref.watch(...)`; mutations are called through `ref.read(playerProvider.notifier)`.
- **Models and persistence**: Persisted models are immutable classes with `final` fields, a `const` constructor, `copyWith`, `toJson`, `fromJson`, and an explicit empty sentinel when the UI needs a no-profile state. JSON parsing should default missing or invalid fields instead of throwing through the repository boundary.
- **Constants**: Shared strings, preference keys, level metadata, and asset paths are centralized in `AppConstants`, `AppRoutes`, or `Assets`. Avoid repeating route paths, preference keys, or asset strings inside widgets.
- **Imports**: External package imports appear before local relative imports. Existing files use relative imports inside `lib`; keep new code consistent unless a wider import strategy is intentionally changed.
- **Widget structure**: Public screens are exported as `const` widgets where possible, while implementation-only subcomponents stay private in the same file. Stateful widgets dispose owned controllers and animation controllers.
- **Visual style**: UI uses `AppColors` and shared lab widgets for the dark teal lab theme. Text commonly uses uppercase labels, small letter spacing, thin borders, and compact cards; keep additions consistent with the existing screen density.
- **Async UI safety**: After awaited state changes, check `mounted` or `context.mounted` before navigation or context-dependent UI work. Empty input is handled at the screen boundary before calling state mutations.

## 5. Working Agreements

- Respond in the user's preferred language; if unspecified, infer from the codebase and keep technical terms in English.
- Ask before introducing new tests, lint rules, formatter setup, or broad refactors; add them only when explicitly requested.
- Before editing, review related usages, provider flows, persistence paths, and likely UI impact.
- Make the smallest focused change that fits the existing architecture and report any relevant side effects.
- Ask actively when scope, behavior, or tradeoffs require a user decision.
- Preserve public APIs and existing behavior unless the user asks to change them.
- After code changes, run the type check with `flutter analyze`.
- Keep new functions and widgets single-purpose and colocated with related code.
- Add external dependencies only when necessary, and explain why.
