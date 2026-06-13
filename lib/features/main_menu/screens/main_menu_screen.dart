import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_routes.dart';
import '../../../data/models/player_model.dart';
import '../../player/application/player_controller.dart';
import '../../../shared/widgets/lab_widgets.dart';

class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final missionsDone = _completedMissionCount(player);
    final progress = missionsDone / AppConstants.totalLevels;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(player: player),
              const SizedBox(height: 20),
              const Text(
                'Volcano Quest',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'VOLCANO RESEARCH LAB · ACTIVE',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              const ScanLine(),
              const SizedBox(height: 16),
              _MissionButton(player: player),
              const SizedBox(height: 12),
              _ProgressSection(
                progress: progress,
                missionsDone: missionsDone,
                player: player,
              ),
              const SizedBox(height: 16),
              _StatsRow(player: player, missionsDone: missionsDone),
              const SizedBox(height: 20),
              _Divider(),
              _NavRow(
                icon: Icons.emoji_events_outlined,
                label: 'Leaderboard',
                onTap: () => context.push(AppRoutes.leaderboard),
              ),
              _Divider(),
              _NavRow(
                icon: Icons.military_tech_outlined,
                label: 'Badge collection',
                badge: player.earnedBadges.isNotEmpty
                    ? '${player.earnedBadges.length}'
                    : null,
                onTap: () => context.push(AppRoutes.badges),
              ),
              _Divider(),
              _NavRow(
                icon: Icons.switch_account_outlined,
                label: 'Switch player',
                onTap: () => context.go(AppRoutes.players),
              ),
              _Divider(),
              _NavRow(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () => context.push(AppRoutes.settings),
              ),
              _Divider(),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  '${AppConstants.appVersion} · PHIVOLCS LEARNING LAB',
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

int _completedMissionCount(PlayerModel player) {
  final missionNineComplete = AppConstants.missionNineQuestionIds.every(
    (id) =>
        player.completedMissionOrbs[AppConstants.missionNineId]?.contains(id) ??
        false,
  );
  if (missionNineComplete) {
    return AppConstants.totalLevels;
  }
  return (player.currentLevel - 1).clamp(0, AppConstants.totalLevels);
}

class _TopBar extends StatelessWidget {
  final PlayerModel player;
  const _TopBar({required this.player});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AvatarSquare(avatarIndex: player.avatarIndex),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              player.name.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'LEVEL ${player.currentLevel} SCIENTIST',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${player.totalXP} XP',
              style: const TextStyle(
                color: AppColors.teal,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
            const Text(
              'TOTAL',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AvatarSquare extends StatelessWidget {
  final int avatarIndex;
  const _AvatarSquare({required this.avatarIndex});

  @override
  Widget build(BuildContext context) {
    final avatarAsset = Assets
        .avatars[avatarIndex.clamp(0, Assets.avatars.length - 1)]
        .imagePath;

    return Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border.all(color: AppColors.teal, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Image.asset(avatarAsset, fit: BoxFit.cover),
      ),
    );
  }
}

class _MissionButton extends StatelessWidget {
  final PlayerModel player;
  const _MissionButton({required this.player});

  @override
  Widget build(BuildContext context) {
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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          border: Border.all(color: AppColors.teal, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actionLabel,
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  levelName,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.tealDark,
                border: Border.all(color: AppColors.teal, width: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badgeLabel,
                style: const TextStyle(
                  color: AppColors.teal,
                  fontSize: 9,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final double progress;
  final int missionsDone;
  final PlayerModel player;
  const _ProgressSection({
    required this.progress,
    required this.missionsDone,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'MISSION PROGRESS',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              '$missionsDone/${AppConstants.totalLevels} COMPLETE',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.surface,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final PlayerModel player;
  final int missionsDone;
  const _StatsRow({required this.player, required this.missionsDone});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.military_tech_outlined,
            label: 'BADGES EARNED',
            value: '${player.earnedBadges.length}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.bar_chart_outlined,
            label: 'MISSIONS DONE',
            value: '$missionsDone/${AppConstants.totalLevels}',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderAlt, width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.teal, size: 18),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 22),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(color: AppColors.border, thickness: 0.5, height: 0);
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  const _NavRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: AppColors.teal.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.teal, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  border: Border.all(color: AppColors.teal, width: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(color: AppColors.teal, fontSize: 9),
                ),
              ),
            ],
            const Spacer(),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
