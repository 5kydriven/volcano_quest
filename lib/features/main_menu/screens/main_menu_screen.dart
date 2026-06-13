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
      backgroundColor: AppColors.background,
      bottomNavigationBar: const _SettingsFooter(),
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
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MissionMap(player: player),
                        const SizedBox(height: 32),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            _FloatingMenuRail(player: player),
          ],
        ),
      ),
    );
  }
}

class _StickyTopBarDelegate extends SliverPersistentHeaderDelegate {
  final PlayerModel player;
  final int missionsDone;
  final double progress;

  const _StickyTopBarDelegate({
    required this.player,
    required this.missionsDone,
    required this.progress,
  });

  @override
  double get minExtent => 85;

  @override
  double get maxExtent => 85;

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
    const nodeSize = 58.0;
    const topInset = 8.0;
    const step = 82.0;
    final nodes = _missionNodes();
    final height = topInset * 2 + step * (nodes.length - 1) + nodeSize;

    return LayoutBuilder(
      builder: (context, constraints) {
        final positions = _missionNodePositions(
          count: nodes.length,
          width: constraints.maxWidth,
          nodeSize: nodeSize,
          topInset: topInset,
          step: step,
        );

        return SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _MissionConnectorPainter(
                    nodes: nodes,
                    positions: positions,
                  ),
                ),
              ),
              for (var index = nodes.length - 1; index >= 0; index--)
                Positioned(
                  left: positions[index].dx - nodeSize / 2,
                  top: positions[index].dy - nodeSize / 2,
                  child: _MissionNode(
                    node: nodes[index],
                    size: nodeSize,
                    onTap: nodes[index].isActive
                        ? () => _showMissionDialog(context, nodes[index])
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
    final fieldLessonAvailable =
        !sideQuestAvailable && activeLevel >= 9 && !levelEightLessonComplete;

    final nodes = <_MissionMapNode>[];
    for (var level = 1; level <= AppConstants.totalLevels; level++) {
      if (level == 4) {
        nodes.add(
          _MissionMapNode(
            title: 'Structure of a Volcano',
            eyebrow: 'SIDE QUEST',
            route: AppRoutes.sideQuestVolcanoStructure,
            primaryIcon: Icons.school_outlined,
            kindIcon: Icons.terrain_outlined,
            rewardLabel:
                '+${AppConstants.sideQuestVolcanoStructureXp.fold<int>(0, (sum, xp) => sum + xp)} XP',
            numberLabel: 'SQ',
            isActive: sideQuestAvailable,
            isComplete: sideQuestComplete,
          ),
        );
      }

      if (level == 9) {
        nodes.add(
          _MissionMapNode(
            title: 'Advanced Volcano Response',
            eyebrow: 'FIELD LESSON',
            route: AppRoutes.levelEightLesson,
            primaryIcon: Icons.menu_book_outlined,
            kindIcon: Icons.science_outlined,
            rewardLabel: 'LESSON',
            numberLabel: 'L8',
            isActive: fieldLessonAvailable,
            isComplete: levelEightLessonComplete,
          ),
        );
      }

      nodes.add(
        _MissionMapNode(
          title: AppConstants.levelNames[level - 1],
          eyebrow: 'LEVEL $level',
          route: AppRoutes.level(level),
          primaryIcon: Icons.volcano_outlined,
          kindIcon: Icons.terrain_outlined,
          rewardLabel: '${AppConstants.levelXP[level - 1]} XP',
          numberLabel: '$level',
          isActive:
              !sideQuestAvailable &&
              !fieldLessonAvailable &&
              level == activeLevel,
          isComplete: level < activeLevel,
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
    required int count,
    required double width,
    required double nodeSize,
    required double topInset,
    required double step,
  }) {
    final safeWidth = width - nodeSize;
    final xFactors = [
      0.30,
      0.66,
      0.42,
      0.74,
      0.28,
      0.60,
      0.36,
      0.70,
      0.48,
      0.76,
      0.34,
    ];
    final positions = <Offset>[];

    for (var index = 0; index < count; index++) {
      final topIndex = count - index - 1;
      final x = nodeSize / 2 + safeWidth * xFactors[topIndex];
      final y = topInset + nodeSize / 2 + step * topIndex;
      positions.add(Offset(x, y));
    }

    return positions;
  }

  void _showMissionDialog(BuildContext context, _MissionMapNode node) {
    showDialog<void>(
      context: context,
      builder: (context) => _MissionStartDialog(node: node),
    );
  }
}

class _MissionMapNode {
  final String title;
  final String eyebrow;
  final String route;
  final IconData primaryIcon;
  final IconData kindIcon;
  final String rewardLabel;
  final String numberLabel;
  final bool isActive;
  final bool isComplete;

  const _MissionMapNode({
    required this.title,
    required this.eyebrow,
    required this.route,
    required this.primaryIcon,
    required this.kindIcon,
    required this.rewardLabel,
    required this.numberLabel,
    required this.isActive,
    required this.isComplete,
  });
}

class _MissionNode extends StatelessWidget {
  final _MissionMapNode node;
  final double size;
  final VoidCallback? onTap;

  const _MissionNode({required this.node, required this.size, this.onTap});

  @override
  Widget build(BuildContext context) {
    final foregroundColor = node.isActive
        ? AppColors.teal
        : node.isComplete
        ? AppColors.textMuted
        : AppColors.textDim;
    final borderColor = node.isActive ? AppColors.teal : AppColors.borderAlt;
    final backgroundColor = node.isActive
        ? AppColors.surfaceAlt
        : AppColors.surface;

    return Tooltip(
      message: node.isActive
          ? 'Open ${node.eyebrow}'
          : node.isComplete
          ? 'Completed ${node.eyebrow}'
          : 'Locked ${node.eyebrow}',
      child: Semantics(
        button: node.isActive,
        enabled: node.isActive,
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
                      width: node.isActive ? 1 : 0.5,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    node.primaryIcon,
                    color: foregroundColor,
                    size: 30,
                  ),
                ),
                Positioned(
                  bottom: -4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 22),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tealDark,
                      border: Border.all(color: borderColor, width: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      node.numberLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 10,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                if (!node.isActive)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Icon(
                      node.isComplete
                          ? Icons.check_circle_outline
                          : Icons.lock_outline,
                      color: foregroundColor,
                      size: 17,
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

class _MissionConnectorPainter extends CustomPainter {
  final List<_MissionMapNode> nodes;
  final List<Offset> positions;

  const _MissionConnectorPainter({
    required this.nodes,
    required this.positions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < positions.length - 1; index++) {
      final start = positions[index];
      final end = positions[index + 1];
      final isOpenPath =
          nodes[index].isComplete &&
          (nodes[index + 1].isComplete || nodes[index + 1].isActive);
      final paint = Paint()
        ..color = isOpenPath ? AppColors.tealDim : AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = isOpenPath ? 2 : 1.2
        ..strokeCap = StrokeCap.round;
      final midY = (start.dy + end.dy) / 2;
      final controlOffset = start.dx < end.dx ? 42.0 : -42.0;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          start.dx + controlOffset,
          midY,
          end.dx - controlOffset,
          midY,
          end.dx,
          end.dy,
        );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MissionConnectorPainter oldDelegate) {
    return oldDelegate.positions != positions || oldDelegate.nodes != nodes;
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
                icon: const Icon(Icons.play_arrow_outlined, size: 18),
                label: const Text('START'),
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

class _SettingsFooter extends StatelessWidget {
  const _SettingsFooter();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.background),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _FooterIconButton(
                icon: Icons.settings_outlined,
                tooltip: 'Settings',
                onTap: () => context.push(AppRoutes.settings),
              ),
            ],
          ),
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
