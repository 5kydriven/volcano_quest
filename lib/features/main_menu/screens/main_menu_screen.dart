import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/assets.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/player_model.dart';
import '../../player/application/player_controller.dart';

class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final missionsDone = _completedMissionCount(player);
    final progress = missionsDone / AppConstants.totalLevels;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(Assets.splashBg, fit: BoxFit.cover),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: Color(0x330A0F1A)),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(player),
                      const SizedBox(height: 12),
                      _buildTitle(),
                      const SizedBox(height: 18),
                      _buildMissionButton(context, player),
                      const SizedBox(height: 14),
                      _buildProgressSection(progress, missionsDone),
                      const SizedBox(height: 14),
                      _buildStatsRow(player, missionsDone),
                      const SizedBox(height: 14),
                      _buildNavButton(
                        context: context,
                        asset: Assets.mainMenuLeaderboardButtonList,
                        onTap: () => context.push(AppRoutes.leaderboard),
                      ),
                      const SizedBox(height: 2),
                      _buildNavButton(
                        context: context,
                        asset: Assets.mainMenuBadgeCollectionButton,
                        badge: player.earnedBadges.isNotEmpty
                            ? '${player.earnedBadges.length}'
                            : null,
                        onTap: () => context.push(AppRoutes.badges),
                      ),
                      const SizedBox(height: 2),
                      _buildNavButton(
                        context: context,
                        asset: Assets.mainMenuSwitchPlayerButton,
                        onTap: () => context.go(AppRoutes.players),
                      ),
                      const SizedBox(height: 2),
                      _buildNavButton(
                        context: context,
                        asset: Assets.mainMenuSettingsButton,
                        onTap: () => context.push(AppRoutes.settings),
                      ),
                      const SizedBox(height: 18),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _completedMissionCount(PlayerModel player) {
    final missionNineComplete = AppConstants.missionNineQuestionIds.every(
      (id) =>
          player.completedMissionOrbs[AppConstants.missionNineId]?.contains(
            id,
          ) ??
          false,
    );
    if (missionNineComplete) {
      return AppConstants.totalLevels;
    }
    return (player.currentLevel - 1).clamp(0, AppConstants.totalLevels);
  }

  Widget _buildHeader(PlayerModel player) {
    final avatarAsset = Assets
        .avatars[player.avatarIndex.clamp(0, Assets.avatars.length - 1)]
        .imagePath;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        final avatarSize = compact ? 112.0 : 136.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: avatarSize,
                    height: avatarSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: avatarSize * 0.58,
                          height: avatarSize * 0.58,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF20140F),
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(avatarSize),
                          child: Image.asset(
                            avatarAsset,
                            width: avatarSize * 0.45,
                            height: avatarSize * 0.45,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned.fill(
                          child: Image.asset(
                            Assets.mainMenuAvatarBorder,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          player.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFFFF8A18),
                            fontSize: compact ? 22 : 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                            shadows: const [
                              Shadow(
                                color: Color(0xFF3B170C),
                                offset: Offset(1.5, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'LEVEL ${player.currentLevel} SCIENTIST',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color.fromARGB(255, 222, 218, 217),
                            fontSize: compact ? 13 : 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: compact ? 6 : 8),
            SizedBox(
              width: compact ? 72 : 86,
              child: Column(
                children: [_buildCounterPlate('${player.totalXP}', 'XP')],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCounterPlate(String value, String label) {
    return AspectRatio(
      aspectRatio: 1.42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Image.asset(
              Assets.mainMenuTotalExpContainer,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 4, 10, 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFFFF9D1B),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Image.asset(Assets.mainMenuTitle, fit: BoxFit.contain),
        const SizedBox(height: 1),
        const Opacity(
          opacity: 0.01,
          child: Text(
            'Volcano Quest',
            style: TextStyle(fontSize: 1, letterSpacing: 0),
          ),
        ),
      ],
    );
  }

  Widget _buildMissionButton(BuildContext context, PlayerModel player) {
    final missionThreeComplete = AppConstants.missionThreeWordIds.every(
      (id) =>
          player.completedMissionOrbs[AppConstants.missionThreeId]?.contains(
            id,
          ) ??
          false,
    );
    final sideQuestComplete = AppConstants.sideQuestVolcanoStructureQuestionIds
        .every(
          (id) =>
              player
                  .completedMissionOrbs[AppConstants
                      .sideQuestVolcanoStructureId]
                  ?.contains(id) ??
              false,
        );
    final shouldShowSideQuest = missionThreeComplete && !sideQuestComplete;
    final levelEightLessonComplete =
        player.completedMissionOrbs[AppConstants.levelEightLessonId]?.contains(
          AppConstants.levelEightLessonCompleteId,
        ) ??
        false;
    final shouldShowLevelEightLesson =
        !shouldShowSideQuest &&
        player.currentLevel >= 9 &&
        !levelEightLessonComplete;
    final levelName = shouldShowSideQuest
        ? 'Structure of a Volcano'
        : shouldShowLevelEightLesson
        ? 'Advanced Volcano Response'
        : AppConstants.levelNames[(player.currentLevel - 1).clamp(
            0,
            AppConstants.levelNames.length - 1,
          )];
    final actionLabel = shouldShowSideQuest
        ? 'START SIDE QUEST'
        : shouldShowLevelEightLesson
        ? 'READ FIELD LESSON'
        : 'CONTINUE MISSION';
    final badgeLabel = shouldShowSideQuest
        ? 'SIDE QUEST'
        : shouldShowLevelEightLesson
        ? 'BRIEFING'
        : 'LVL ${player.currentLevel}';

    return GestureDetector(
      onTap: () {
        context.push(
          shouldShowSideQuest
              ? AppRoutes.sideQuestVolcanoStructure
              : shouldShowLevelEightLesson
              ? AppRoutes.levelEightLesson
              : AppRoutes.level(player.currentLevel),
        );
      },
      child: SizedBox(
        height: 146,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Image.asset(Assets.mainMenuMission, fit: BoxFit.fill),
            ),
            Positioned(
              left: 117,
              right: 92,
              top: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    actionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFFA51F),
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                      shadows: [
                        Shadow(
                          color: Color(0xFF351709),
                          offset: Offset(1.5, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    levelName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 22,
              child: Container(
                width: 70,
                height: 44,
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      badgeLabel,
                      style: const TextStyle(
                        color: Color(0xFFFF8D17),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(double progress, int missionsDone) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 100,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        Assets.mainMenuProgress,
                        fit: BoxFit.fill,
                      ),
                    ),
                    Positioned(
                      top: 53,
                      left: 61,
                      right: 23,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 18,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF6716),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(PlayerModel player, int missionsDone) {
    return Row(
      children: [
        Expanded(
          child: _buildStatPanel(
            value: '${player.earnedBadges.length}',
            asset: Assets.mainMenuBadgeEarned,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatPanel(
            value: '$missionsDone/${AppConstants.totalLevels}',
            asset: Assets.mainMenuMissionDone,
          ),
        ),
      ],
    );
  }

  Widget _buildStatPanel({required String value, required String asset}) {
    return SizedBox(
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: Image.asset(asset, fit: BoxFit.cover)),
          Positioned(
            left: 101,
            right: 10,
            bottom: 14,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  shadows: [
                    Shadow(color: Color(0xAA000000), offset: Offset(1.5, 2)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required BuildContext context,
    required String asset,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      splashColor: const Color(0x33FF6716),
      child: SizedBox(
        height: 76,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(child: Image.asset(asset, fit: BoxFit.fill)),
            if (badge != null)
              Positioned(
                right: 54,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A211B),
                    border: Border.all(
                      color: const Color(0xFFFF8D17),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Color(0xFFFFA51F),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        '${AppConstants.appVersion} - PHIVOLCS LEARNING LAB',
        style: const TextStyle(
          color: AppColors.textDim,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
