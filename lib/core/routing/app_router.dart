import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/badges/screens/badges_screen.dart';
import '../../features/leaderboard/screens/leaderboard_screen.dart';
import '../../features/main_menu/screens/main_menu_screen.dart';
import '../../features/missions/screens/mission_one_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/player/screens/player_profiles_screen.dart';
import 'app_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.players,
        builder: (context, state) => const PlayerProfilesScreen(),
      ),
      GoRoute(
        path: AppRoutes.menu,
        builder: (context, state) => const MainMenuScreen(),
      ),
      GoRoute(
        path: AppRoutes.leaderboard,
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.badges,
        builder: (context, state) => const BadgesScreen(),
      ),
      GoRoute(
        path: AppRoutes.levelPath,
        builder: (context, state) {
          final levelId =
              int.tryParse(state.pathParameters['levelId'] ?? '') ?? 1;
          if (levelId != 1) {
            return MissionUnlockedScreen(levelId: levelId);
          }
          return MissionOneScreen(levelId: levelId);
        },
      ),
    ],
  );
});
