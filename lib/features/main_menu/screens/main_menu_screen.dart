import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_routes.dart';
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
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyTopBarDelegate(
                    player: player,
                    missionsDone: missionsDone,
                    progress: progress,
                  ),
                ),
                SliverToBoxAdapter(child: _MissionMap(player: player)),
              ],
            ),
            _FloatingMenuRail(player: player),
            Positioned(
              bottom: 32,
              right: 20,
              child: _FooterIconButton(
                icon: Icons.settings_outlined,
                tooltip: 'Settings',
                onTap: () => context.push(AppRoutes.settings),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyTopBarDelegate extends SliverPersistentHeaderDelegate {
  static const extent = 85.0;

  final PlayerModel player;
  final int missionsDone;
  final double progress;

  const _StickyTopBarDelegate({
    required this.player,
    required this.missionsDone,
    required this.progress,
  });

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: overlapsContent
            ? const Border(
                bottom: BorderSide(color: AppColors.border, width: 0.5),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        child: _TopBar(
          player: player,
          missionsDone: missionsDone,
          progress: progress,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTopBarDelegate oldDelegate) {
    return oldDelegate.player != player ||
        oldDelegate.missionsDone != missionsDone ||
        oldDelegate.progress != progress;
  }
}

class _FloatingMenuRail extends StatelessWidget {
  final PlayerModel player;

  const _FloatingMenuRail({required this.player});

  @override
  Widget build(BuildContext context) {
    final earnedBadges = player.earnedBadges.length;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.88),
            border: Border.all(color: AppColors.border, width: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FooterIconButton(
                  icon: Icons.emoji_events_outlined,
                  tooltip: 'Leaderboard',
                  onTap: () => context.push(AppRoutes.leaderboard),
                ),
                const SizedBox(height: 4),
                _FooterIconButton(
                  icon: Icons.military_tech_outlined,
                  tooltip: 'Badge collection',
                  badge: earnedBadges > 0 ? '$earnedBadges' : null,
                  onTap: () => context.push(AppRoutes.badges),
                ),
                const SizedBox(height: 4),
                _FooterIconButton(
                  icon: Icons.switch_account_outlined,
                  tooltip: 'Switch player',
                  onTap: () => context.go(AppRoutes.players),
                ),
              ],
            ),
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

const _menuImageSize = Size(1024, 1536);
const _menuImageAspectRatio = 1024 / 1536;

// Edit these normalized X/Y image coordinates to move level badges on the map.
// Values are measured from the menu background image: 0.0 is left/top, 1.0 is right/bottom.
const _missionPathAnchors = <Offset>[
  Offset(0.20, 0.93), // Level 1
  Offset(0.42, 0.83), // Level 2
  Offset(0.68, 0.79), // Level 3
  Offset(0.72, 0.68), // SQ
  Offset(0.42, 0.64), // level 4
  Offset(0.45, 0.53), // level 5
  Offset(0.73, 0.49), // level 6
  Offset(0.46, 0.43), // level 7
  Offset(0.59, 0.34), // level 8
  Offset(0.50, 0.26), // Level 8.1
  Offset(0.46, 0.20), // Level 9
];

class _TopBar extends StatelessWidget {
  final PlayerModel player;
  final int missionsDone;
  final double progress;

  const _TopBar({
    required this.player,
    required this.missionsDone,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _AvatarSquare(avatarIndex: player.avatarIndex),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'LEVEL ${player.currentLevel} SCIENTIST',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Semantics(
                label: 'Mission progress',
                value: '$missionsDone of ${AppConstants.totalLevels}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.surface,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.teal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HeaderMetric(
              icon: Icons.bolt_outlined,
              value: '${player.totalXP}',
              tooltip: 'Total XP',
            ),
            const SizedBox(width: 8),
            _HeaderMetric(
              icon: Icons.military_tech_outlined,
              value: '${player.earnedBadges.length}',
              tooltip: 'Badges earned',
            ),
            const SizedBox(width: 8),
            _HeaderMetric(
              icon: Icons.bar_chart_outlined,
              value: '$missionsDone',
              tooltip: 'Missions done',
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String tooltip;

  const _HeaderMetric({
    required this.icon,
    required this.value,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: '$tooltip: $value',
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.borderAlt, width: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.teal, size: 15),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
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

class _MissionMap extends StatelessWidget {
  final PlayerModel player;

  const _MissionMap({required this.player});

  @override
  Widget build(BuildContext context) {
    const nodeSize = 44.0;
    final nodes = _missionNodes();
    assert(
      nodes.length == _missionPathAnchors.length,
      'Mission nodes must match the menu background path anchors.',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.sizeOf(context).height;
        final canvasWidth = constraints.maxWidth;
        final imageRatioHeight = canvasWidth / _menuImageAspectRatio;
        final canvasHeight = math.max(
          imageRatioHeight,
          screenHeight - _StickyTopBarDelegate.extent,
        );
        final canvasSize = Size(canvasWidth, canvasHeight);
        final positions = _missionNodePositions(
          canvasSize: canvasSize,
          count: nodes.length,
        );
        final positionedNodes = nodes.take(positions.length).toList();

        return SizedBox(
          height: canvasHeight,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Image.asset(
                  Assets.menuBg,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
              for (var index = positionedNodes.length - 1; index >= 0; index--)
                Positioned(
                  left: positions[index].dx - nodeSize / 2,
                  top: positions[index].dy - nodeSize / 2,
                  child: _MissionNode(
                    node: positionedNodes[index],
                    size: nodeSize,
                    onTap: positionedNodes[index].isUnlocked
                        ? () => _showMissionDialog(
                            context,
                            positionedNodes[index],
                          )
                        : null,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<_MissionMapNode> _missionNodes() {
    final activeLevel = player.currentLevel.clamp(1, AppConstants.totalLevels);
    final sideQuestComplete = AppConstants.sideQuestVolcanoStructureQuestionIds
        .every(
          (id) =>
              player
                  .completedMissionOrbs[AppConstants
                      .sideQuestVolcanoStructureId]
                  ?.contains(id) ??
              false,
        );
    final sideQuestAvailable =
        _isMissionThreeComplete(player) && !sideQuestComplete;
    final levelEightLessonComplete =
        player.completedMissionOrbs[AppConstants.levelEightLessonId]?.contains(
          AppConstants.levelEightLessonCompleteId,
        ) ??
        false;
    final missionNineComplete = AppConstants.missionNineQuestionIds.every(
      (id) =>
          player.completedMissionOrbs[AppConstants.missionNineId]?.contains(
            id,
          ) ??
          false,
    );
    final fieldLessonAvailable =
        !sideQuestAvailable && activeLevel >= 9 && !levelEightLessonComplete;

    final nodes = <_MissionMapNode>[];
    for (var level = 1; level <= AppConstants.totalLevels; level++) {
      if (level == 4) {
        final isUnlocked = _isMissionThreeComplete(player);
        nodes.add(
          _MissionMapNode(
            title: 'Structure of a Volcano',
            eyebrow: 'SIDE QUEST',
            route: sideQuestComplete
                ? AppRoutes.replay(AppRoutes.sideQuestVolcanoStructure)
                : AppRoutes.sideQuestVolcanoStructure,
            primaryIcon: Icons.school_outlined,
            kindIcon: Icons.terrain_outlined,
            rewardLabel:
                '+${AppConstants.sideQuestVolcanoStructureXp.fold<int>(0, (sum, xp) => sum + xp)} XP',
            numberLabel: 'SQ',
            status: sideQuestComplete
                ? _MissionNodeStatus.complete
                : sideQuestAvailable
                ? _MissionNodeStatus.current
                : isUnlocked
                ? _MissionNodeStatus.current
                : _MissionNodeStatus.locked,
            isComplete: sideQuestComplete,
          ),
        );
      }

      if (level == 9) {
        nodes.add(
          _MissionMapNode(
            title: 'Advanced Volcano Response',
            eyebrow: 'FIELD LESSON',
            route: levelEightLessonComplete
                ? AppRoutes.replay(AppRoutes.levelEightLesson)
                : AppRoutes.levelEightLesson,
            primaryIcon: Icons.menu_book_outlined,
            kindIcon: Icons.science_outlined,
            rewardLabel: 'LESSON',
            numberLabel: 'L8',
            status: levelEightLessonComplete
                ? _MissionNodeStatus.complete
                : fieldLessonAvailable
                ? _MissionNodeStatus.current
                : _MissionNodeStatus.locked,
            isComplete: levelEightLessonComplete,
          ),
        );
      }

      final isComplete =
          level < activeLevel ||
          (level == AppConstants.totalLevels && missionNineComplete);
      final isUnlocked = level <= activeLevel;
      nodes.add(
        _MissionMapNode(
          title: AppConstants.levelNames[level - 1],
          eyebrow: 'LEVEL $level',
          route: isComplete
              ? AppRoutes.replayLevel(level)
              : AppRoutes.level(level),
          primaryIcon: Icons.volcano_outlined,
          kindIcon: Icons.terrain_outlined,
          rewardLabel: '${AppConstants.levelXP[level - 1]} XP',
          numberLabel: '$level',
          status: isComplete
              ? _MissionNodeStatus.complete
              : isUnlocked &&
                    !sideQuestAvailable &&
                    !fieldLessonAvailable &&
                    level == activeLevel
              ? _MissionNodeStatus.current
              : _MissionNodeStatus.locked,
          isComplete: isComplete,
        ),
      );
    }

    return nodes;
  }

  bool _isMissionThreeComplete(PlayerModel player) {
    return AppConstants.missionThreeWordIds.every(
      (id) =>
          player.completedMissionOrbs[AppConstants.missionThreeId]?.contains(
            id,
          ) ??
          false,
    );
  }

  List<Offset> _missionNodePositions({
    required Size canvasSize,
    required int count,
  }) {
    final imageRect = _menuImageRect(canvasSize);
    final anchorCount = math.min(count, _missionPathAnchors.length);

    return [
      for (final anchor in _missionPathAnchors.take(anchorCount))
        Offset(
          imageRect.left + imageRect.width * anchor.dx,
          imageRect.top + imageRect.height * anchor.dy,
        ),
    ];
  }

  Rect _menuImageRect(Size canvasSize) {
    final fittedSizes = applyBoxFit(BoxFit.cover, _menuImageSize, canvasSize);
    return Alignment.center.inscribe(
      fittedSizes.destination,
      Offset.zero & canvasSize,
    );
  }

  void _showMissionDialog(BuildContext context, _MissionMapNode node) {
    showDialog<void>(
      context: context,
      builder: (context) => _MissionStartDialog(node: node),
    );
  }
}

enum _MissionNodeStatus { locked, current, complete }

class _MissionMapNode {
  final String title;
  final String eyebrow;
  final String route;
  final IconData primaryIcon;
  final IconData kindIcon;
  final String rewardLabel;
  final String numberLabel;
  final _MissionNodeStatus status;
  final bool isComplete;

  const _MissionMapNode({
    required this.title,
    required this.eyebrow,
    required this.route,
    required this.primaryIcon,
    required this.kindIcon,
    required this.rewardLabel,
    required this.numberLabel,
    required this.status,
    required this.isComplete,
  });

  bool get isUnlocked => status != _MissionNodeStatus.locked;

  bool get isCurrent => status == _MissionNodeStatus.current;

  bool get isReplay => status == _MissionNodeStatus.complete;
}

class _MissionNode extends StatelessWidget {
  final _MissionMapNode node;
  final double size;
  final VoidCallback? onTap;

  const _MissionNode({required this.node, required this.size, this.onTap});

  @override
  Widget build(BuildContext context) {
    final foregroundColor = node.isCurrent
        ? AppColors.teal
        : node.isComplete
        ? AppColors.textMuted
        : AppColors.textDim;
    final borderColor = node.isCurrent ? AppColors.teal : AppColors.borderAlt;
    final backgroundColor = node.isCurrent
        ? AppColors.tealDark.withValues(alpha: 0.94)
        : AppColors.background.withValues(alpha: 0.78);
    final statusIcon = node.isComplete
        ? Icons.check_circle
        : node.isCurrent
        ? Icons.play_circle_fill
        : Icons.lock;

    return Tooltip(
      message: node.isCurrent
          ? 'Open ${node.eyebrow}'
          : node.isComplete
          ? 'Replay ${node.eyebrow}'
          : 'Locked ${node.eyebrow}',
      child: Semantics(
        button: node.isUnlocked,
        enabled: node.isUnlocked,
        label: '${node.eyebrow}, ${node.title}',
        child: InkResponse(
          onTap: onTap,
          radius: size / 2,
          splashColor: AppColors.teal.withValues(alpha: 0.08),
          highlightColor: AppColors.teal.withValues(alpha: 0.04),
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border.all(
                      color: borderColor,
                      width: node.isCurrent ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: node.isCurrent
                        ? [
                            BoxShadow(
                              color: AppColors.teal.withValues(alpha: 0.28),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    node.numberLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: node.numberLabel.length > 1 ? 12 : 16,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
                Positioned(
                  right: -4,
                  top: -4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.9),
                      border: Border.all(color: borderColor, width: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(1.5),
                      child: Icon(statusIcon, color: foregroundColor, size: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MissionStartDialog extends StatelessWidget {
  final _MissionMapNode node;

  const _MissionStartDialog({required this.node});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.teal, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    border: Border.all(color: AppColors.teal, width: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    node.primaryIcon,
                    color: AppColors.teal,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.eyebrow,
                        style: const TextStyle(
                          color: AppColors.teal,
                          fontSize: 11,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        node.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _MissionDialogBadge(
                  icon: Icons.bolt_outlined,
                  value: node.rewardLabel,
                ),
                const SizedBox(width: 8),
                _MissionDialogBadge(icon: node.kindIcon, value: 'VOLCANO'),
                const SizedBox(width: 8),
                const _MissionDialogBadge(
                  icon: Icons.science_outlined,
                  value: 'LAB',
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(node.route);
                },
                icon: Icon(
                  node.isReplay
                      ? Icons.replay_outlined
                      : Icons.play_arrow_outlined,
                  size: 18,
                ),
                label: Text(node.isReplay ? 'REPLAY' : 'START'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionDialogBadge extends StatelessWidget {
  final IconData icon;
  final String value;

  const _MissionDialogBadge({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.tealDark,
          border: Border.all(color: AppColors.borderAlt, width: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.teal, size: 17),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final String? badge;
  final VoidCallback onTap;

  const _FooterIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          splashColor: AppColors.teal.withValues(alpha: 0.08),
          highlightColor: AppColors.teal.withValues(alpha: 0.04),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.borderAlt, width: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.teal, size: 20),
                ),
                if (badge != null)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.tealDark,
                        border: Border.all(color: AppColors.teal, width: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: AppColors.teal,
                          fontSize: 9,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
