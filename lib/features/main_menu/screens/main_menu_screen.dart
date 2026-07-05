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
            kind: _MissionKind.sideQuest,
            objective:
                'Review volcano parts before entering the explorer route.',
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
            kind: _MissionKind.fieldLesson,
            objective:
                'Study response steps before the final assessment mission.',
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
          kind: _missionKindForLevel(level),
          objective: _missionObjectiveForLevel(level),
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

  _MissionKind _missionKindForLevel(int level) {
    return switch (level) {
      1 => _MissionKind.research,
      2 || 4 || 7 || 8 || 9 => _MissionKind.quiz,
      3 => _MissionKind.wordBuilder,
      5 => _MissionKind.lab,
      6 => _MissionKind.builder,
      _ => _MissionKind.research,
    };
  }

  String _missionObjectiveForLevel(int level) {
    return switch (level) {
      1 => 'Collect the core research orbs inside the volcano base.',
      2 => 'Scan each question and confirm the correct volcano fact.',
      3 => 'Build volcano vocabulary from the active letter tiles.',
      4 => 'Identify Philippine volcanoes and map their key traits.',
      5 => 'Place each anatomy label on the correct volcano structure.',
      6 => 'Assemble the volcano model one stable layer at a time.',
      7 => 'Investigate real volcano profiles and classify your evidence.',
      8 => 'Read warning signs and choose the safest response.',
      9 => 'Complete the final assessment across the full mission file.',
      _ => 'Open the mission file and continue the volcano quest.',
    };
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

enum _MissionKind {
  research,
  quiz,
  wordBuilder,
  sideQuest,
  lab,
  builder,
  fieldLesson,
}

class _MissionMapNode {
  final String title;
  final String eyebrow;
  final String route;
  final IconData primaryIcon;
  final IconData kindIcon;
  final String rewardLabel;
  final String numberLabel;
  final _MissionKind kind;
  final String objective;
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
    required this.kind,
    required this.objective,
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
    final style = _MissionBriefingStyle.fromKind(node.kind);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: CustomPaint(
        painter: _MissionStartDialogPainter(style: style),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MissionBriefingSeal(node: node, style: style),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            node.eyebrow,
                            style: TextStyle(
                              color: style.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            node.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            style.kindLabel.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _MissionDialogCloseButton(style: style),
                ],
              ),
              const SizedBox(height: 18),
              _MissionBriefingObjective(
                icon: style.objectiveIcon,
                label: style.objectiveLabel,
                value: node.objective,
                style: style,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _MissionDialogBadge(
                    icon: Icons.bolt_outlined,
                    label: 'REWARD',
                    value: node.rewardLabel,
                    style: style,
                  ),
                  const SizedBox(width: 8),
                  _MissionDialogBadge(
                    icon: style.kindIcon,
                    label: 'MISSION',
                    value: style.shortLabel,
                    style: style,
                  ),
                  const SizedBox(width: 8),
                  _MissionDialogBadge(
                    icon: node.isReplay
                        ? Icons.history_outlined
                        : Icons.play_circle_outline,
                    label: 'MODE',
                    value: node.isReplay ? 'REVIEW' : 'ACTIVE',
                    style: style,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _MenuLevelImageButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(node.route);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      node.isReplay
                          ? Icons.replay_outlined
                          : Icons.play_arrow_outlined,
                      color: AppColors.textPrimary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(node.isReplay ? 'REPLAY' : 'START'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionBriefingStyle {
  final Color accent;
  final Color deep;
  final IconData kindIcon;
  final IconData objectiveIcon;
  final String kindLabel;
  final String shortLabel;
  final String objectiveLabel;

  const _MissionBriefingStyle({
    required this.accent,
    required this.deep,
    required this.kindIcon,
    required this.objectiveIcon,
    required this.kindLabel,
    required this.shortLabel,
    required this.objectiveLabel,
  });

  factory _MissionBriefingStyle.fromKind(_MissionKind kind) {
    return switch (kind) {
      _MissionKind.research => const _MissionBriefingStyle(
        accent: Color(0xFFFFB45F),
        deep: Color(0xFF3A1A10),
        kindIcon: Icons.travel_explore_outlined,
        objectiveIcon: Icons.radar_outlined,
        kindLabel: 'Research briefing',
        shortLabel: 'RESEARCH',
        objectiveLabel: 'Field objective',
      ),
      _MissionKind.quiz => const _MissionBriefingStyle(
        accent: Color(0xFFFF7A1A),
        deep: Color(0xFF3A1A10),
        kindIcon: Icons.fact_check_outlined,
        objectiveIcon: Icons.quiz_outlined,
        kindLabel: 'Knowledge scan',
        shortLabel: 'SCAN',
        objectiveLabel: 'Answer target',
      ),
      _MissionKind.wordBuilder => const _MissionBriefingStyle(
        accent: Color(0xFFFFC66D),
        deep: Color(0xFF332010),
        kindIcon: Icons.abc_outlined,
        objectiveIcon: Icons.grid_view_outlined,
        kindLabel: 'Word builder',
        shortLabel: 'WORDS',
        objectiveLabel: 'Build target',
      ),
      _MissionKind.sideQuest => const _MissionBriefingStyle(
        accent: Color(0xFFFFD184),
        deep: Color(0xFF2E1D0C),
        kindIcon: Icons.route_outlined,
        objectiveIcon: Icons.school_outlined,
        kindLabel: 'Side quest file',
        shortLabel: 'SIDE',
        objectiveLabel: 'Unlock target',
      ),
      _MissionKind.lab => const _MissionBriefingStyle(
        accent: Color(0xFFFF9B45),
        deep: Color(0xFF351408),
        kindIcon: Icons.science_outlined,
        objectiveIcon: Icons.biotech_outlined,
        kindLabel: 'Lab operation',
        shortLabel: 'LAB',
        objectiveLabel: 'Lab objective',
      ),
      _MissionKind.builder => const _MissionBriefingStyle(
        accent: Color(0xFFFFA85A),
        deep: Color(0xFF2F170B),
        kindIcon: Icons.construction_outlined,
        objectiveIcon: Icons.architecture_outlined,
        kindLabel: 'Builder mission',
        shortLabel: 'BUILD',
        objectiveLabel: 'Assembly target',
      ),
      _MissionKind.fieldLesson => const _MissionBriefingStyle(
        accent: Color(0xFFFFC06A),
        deep: Color(0xFF2B180E),
        kindIcon: Icons.menu_book_outlined,
        objectiveIcon: Icons.local_fire_department_outlined,
        kindLabel: 'Field lesson',
        shortLabel: 'LESSON',
        objectiveLabel: 'Lesson target',
      ),
    };
  }
}

class _MissionBriefingSeal extends StatelessWidget {
  final _MissionMapNode node;
  final _MissionBriefingStyle style;

  const _MissionBriefingSeal({required this.node, required this.style});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 68,
      child: CustomPaint(
        painter: _MissionSealPainter(style: style),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(node.primaryIcon, color: style.accent, size: 26),
              const SizedBox(height: 3),
              Text(
                node.numberLabel,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionDialogCloseButton extends StatelessWidget {
  final _MissionBriefingStyle style;

  const _MissionDialogCloseButton({required this.style});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Close',
      child: InkResponse(
        onTap: () => Navigator.of(context).pop(),
        radius: 20,
        child: SizedBox(
          width: 36,
          height: 36,
          child: CustomPaint(
            painter: _MissionCloseButtonPainter(style: style),
            child: Icon(Icons.close, color: style.accent, size: 18),
          ),
        ),
      ),
    );
  }
}

class _MissionBriefingObjective extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final _MissionBriefingStyle style;

  const _MissionBriefingObjective({
    required this.icon,
    required this.label,
    required this.value,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: style.deep.withValues(alpha: 0.54),
        border: Border.all(color: style.accent.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: style.accent, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: style.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
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
}

class _MissionStartDialogPainter extends CustomPainter {
  final _MissionBriefingStyle style;

  const _MissionStartDialogPainter({required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final panel = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    canvas.drawRRect(
      panel,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xF20F0E0D), style.deep.withValues(alpha: 0.96)],
        ).createShader(rect),
    );

    canvas.drawRRect(
      panel,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.22, -0.75),
          radius: 0.86,
          colors: [
            style.accent.withValues(alpha: 0.22),
            style.deep.withValues(alpha: 0.1),
            Colors.transparent,
          ],
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );

    final ridgePath = Path()
      ..moveTo(0, size.height * 0.77)
      ..lineTo(size.width * 0.16, size.height * 0.68)
      ..lineTo(size.width * 0.31, size.height * 0.73)
      ..lineTo(size.width * 0.48, size.height * 0.6)
      ..lineTo(size.width * 0.66, size.height * 0.75)
      ..lineTo(size.width * 0.82, size.height * 0.67)
      ..lineTo(size.width, size.height * 0.75)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      ridgePath,
      Paint()..color = const Color(0xFF160A05).withValues(alpha: 0.68),
    );

    final fissurePath = Path()
      ..moveTo(size.width * 0.48, size.height * 0.59)
      ..lineTo(size.width * 0.53, size.height * 0.69)
      ..lineTo(size.width * 0.5, size.height * 0.8)
      ..lineTo(size.width * 0.56, size.height * 0.94)
      ..lineTo(size.width * 0.54, size.height)
      ..lineTo(size.width * 0.61, size.height)
      ..lineTo(size.width * 0.63, size.height * 0.91)
      ..lineTo(size.width * 0.56, size.height * 0.78)
      ..lineTo(size.width * 0.59, size.height * 0.68)
      ..lineTo(size.width * 0.52, size.height * 0.58)
      ..close();
    canvas.drawPath(
      fissurePath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            style.accent.withValues(alpha: 0.34),
            style.accent.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );

    final scanPaint = Paint()
      ..color = style.accent.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (var y = 14.0; y < size.height; y += 15) {
      canvas.drawLine(Offset(14, y), Offset(size.width - 14, y), scanPaint);
    }

    canvas.drawRRect(
      panel.deflate(0.5),
      Paint()
        ..color = style.accent.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final cornerPaint = Paint()
      ..color = style.accent.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square;
    const inset = 13.0;
    const corner = 28.0;
    canvas
      ..drawLine(
        const Offset(inset, inset),
        const Offset(inset + corner, inset),
        cornerPaint,
      )
      ..drawLine(
        const Offset(inset, inset),
        const Offset(inset, inset + corner),
        cornerPaint,
      )
      ..drawLine(
        Offset(size.width - inset - corner, inset),
        Offset(size.width - inset, inset),
        cornerPaint,
      )
      ..drawLine(
        Offset(size.width - inset, inset),
        Offset(size.width - inset, inset + corner),
        cornerPaint,
      )
      ..drawLine(
        Offset(inset, size.height - inset - corner),
        Offset(inset, size.height - inset),
        cornerPaint,
      )
      ..drawLine(
        Offset(inset, size.height - inset),
        Offset(inset + corner, size.height - inset),
        cornerPaint,
      )
      ..drawLine(
        Offset(size.width - inset - corner, size.height - inset),
        Offset(size.width - inset, size.height - inset),
        cornerPaint,
      )
      ..drawLine(
        Offset(size.width - inset, size.height - inset - corner),
        Offset(size.width - inset, size.height - inset),
        cornerPaint,
      );
  }

  @override
  bool shouldRepaint(covariant _MissionStartDialogPainter oldDelegate) {
    return oldDelegate.style != style;
  }
}

class _MissionSealPainter extends CustomPainter {
  final _MissionBriefingStyle style;

  const _MissionSealPainter({required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    final outer = Rect.fromCircle(center: center, radius: radius - 1);

    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..shader = RadialGradient(
          colors: [
            style.accent.withValues(alpha: 0.24),
            style.deep.withValues(alpha: 0.92),
          ],
        ).createShader(outer),
    );
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..color = style.accent.withValues(alpha: 0.66)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      center,
      radius - 8,
      Paint()
        ..color = style.accent.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final tickPaint = Paint()
      ..color = style.accent.withValues(alpha: 0.44)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 10; index++) {
      final angle = math.pi * 2 * index / 10;
      final start = Offset(
        center.dx + math.cos(angle) * (radius - 5),
        center.dy + math.sin(angle) * (radius - 5),
      );
      final end = Offset(
        center.dx + math.cos(angle) * (radius - 1),
        center.dy + math.sin(angle) * (radius - 1),
      );
      canvas.drawLine(start, end, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MissionSealPainter oldDelegate) {
    return oldDelegate.style != style;
  }
}

class _MissionCloseButtonPainter extends CustomPainter {
  final _MissionBriefingStyle style;

  const _MissionCloseButtonPainter({required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(rrect, Paint()..color = style.deep.withValues(alpha: 0.5));
    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..color = style.accent.withValues(alpha: 0.42)
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _MissionCloseButtonPainter oldDelegate) {
    return oldDelegate.style != style;
  }
}

class _MenuLevelImageButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const _MenuLevelImageButton({required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Opacity(
        opacity: isEnabled ? 1 : 0.55,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(Assets.missionOneButtonContainer, fit: BoxFit.fill),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                child: Center(
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                    child: child,
                  ),
                ),
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
  final String label;
  final String value;
  final _MissionBriefingStyle style;

  const _MissionDialogBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: style.deep.withValues(alpha: 0.62),
          border: Border.all(
            color: style.accent.withValues(alpha: 0.32),
            width: 0.7,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: style.accent, size: 17),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
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
