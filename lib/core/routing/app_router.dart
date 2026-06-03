import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../features/badges/screens/badges_screen.dart';
import '../../features/leaderboard/screens/leaderboard_screen.dart';
import '../../features/main_menu/screens/main_menu_screen.dart';
import '../../features/missions/screens/mission_eight_eruption_warning_lab_screen.dart';
import '../../features/missions/screens/mission_four_map_quiz_screen.dart';
import '../../features/missions/screens/mission_five_anatomy_lab_screen.dart';
import '../../features/missions/screens/level_eight_field_lesson_screen.dart';
import '../../features/missions/screens/mission_nine_assessment_screen.dart';
import '../../features/missions/screens/mission_one_screen.dart';
import '../../features/missions/screens/mission_seven_investigation_center_screen.dart';
import '../../features/missions/screens/mission_six_volcano_builder_screen.dart';
import '../../features/missions/screens/mission_three_word_builder_screen.dart';
import '../../features/missions/screens/mission_two_quiz_screen.dart';
import '../../features/missions/screens/volcano_structure_side_quest_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/player/screens/player_profiles_screen.dart';
import '../../features/player/application/player_controller.dart';
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
        path: AppRoutes.sideQuestVolcanoStructure,
        builder: (context, state) => const VolcanoStructureSideQuestScreen(),
      ),
      GoRoute(
        path: AppRoutes.levelEightLesson,
        builder: (context, state) => const LevelEightFieldLessonScreen(),
      ),
      GoRoute(
        path: AppRoutes.levelPath,
        builder: (context, state) {
          final levelId =
              int.tryParse(state.pathParameters['levelId'] ?? '') ?? 1;
          if (levelId == 1) {
            return MissionOneScreen(levelId: levelId);
          }
          if (levelId == 2) {
            return MissionTwoQuizScreen(levelId: levelId);
          }
          if (levelId == 3) {
            return MissionThreeWordBuilderScreen(levelId: levelId);
          }
          if (levelId == 4) {
            return MissionFourMapQuizScreen(levelId: levelId);
          }
          if (levelId == 5) {
            return MissionFiveAnatomyLabScreen(levelId: levelId);
          }
          if (levelId == 6) {
            return MissionSixVolcanoBuilderScreen(levelId: levelId);
          }
          if (levelId == 7) {
            return MissionSevenInvestigationCenterScreen(levelId: levelId);
          }
          if (levelId == 8) {
            return MissionEightEruptionWarningLabScreen(levelId: levelId);
          }
          if (levelId == 9) {
            final player = ref.read(playerProvider);
            final lessonComplete =
                player.completedMissionOrbs[AppConstants.levelEightLessonId]
                    ?.contains(AppConstants.levelEightLessonCompleteId) ??
                false;
            if (!lessonComplete) {
              return const LevelEightFieldLessonScreen();
            }
            return MissionNineAssessmentScreen(levelId: levelId);
          }
          return MissionUnlockedScreen(levelId: levelId);
        },
      ),
    ],
  );
});
