import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../core/audio/audio_catalog.dart';
import '../../../core/audio/audio_controller.dart';
import '../../../core/constants/assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_route_observer.dart';
import '../../../core/routing/app_routes.dart';
import '../../../data/models/player_model.dart';
import '../../player/application/player_controller.dart';

const _topBarExtent = 120.0;

class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final missionsDone = _completedMissionCount(player);
    final progress = missionsDone / AppConstants.totalLevels;
    void playButtonSfx() {
      unawaited(ref.read(audioControllerProvider).playSfx(SfxCue.button));
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _MissionMap(
                  player: player,
                  playButtonSfx: playButtonSfx,
                ),
              ),
            ],
          ),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: _topBarExtent,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: _TopBar(
                      player: player,
                      missionsDone: missionsDone,
                      progress: progress,
                      playButtonSfx: playButtonSfx,
                    ),
                  ),
                ),
                _FloatingMenuRail(player: player, playButtonSfx: playButtonSfx),
                Positioned(
                  bottom: 32,
                  right: 20,
                  child: _FooterIconButton(
                    iconAsset: Assets.menuSettingIcon,
                    tooltip: 'Settings',
                    onTap: () {
                      playButtonSfx();
                      context.push(AppRoutes.settings);
                    },
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

class _LoopingMenuBackground extends StatefulWidget {
  const _LoopingMenuBackground();

  @override
  State<_LoopingMenuBackground> createState() => _LoopingMenuBackgroundState();
}

class _LoopingMenuBackgroundState extends State<_LoopingMenuBackground>
    with WidgetsBindingObserver, RouteAware {
  late final VideoPlayerController _controller;
  ModalRoute<dynamic>? _route;
  var _isReady = false;
  var _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = VideoPlayerController.asset(
      Assets.menuBgAnimated,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    unawaited(_initializeVideo());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (!identical(_route, route)) {
      if (_route != null) {
        appRouteObserver.unsubscribe(this);
      }
      _route = route;
      if (route != null) {
        appRouteObserver.subscribe(this, route);
      }
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) {
      return;
    }
    _reduceMotion = reduceMotion;
    _syncPlayback();
  }

  Future<void> _initializeVideo() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.setVolume(0);
      if (!mounted) {
        return;
      }
      setState(() => _isReady = true);
      _syncPlayback();
    } catch (_) {
      // The static map remains visible when video initialization is unavailable.
    }
  }

  void _syncPlayback() {
    if (!_isReady) {
      return;
    }
    if (_reduceMotion) {
      unawaited(_controller.pause());
    } else {
      unawaited(_controller.play());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isReady) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _syncPlayback();
    } else {
      unawaited(_controller.pause());
    }
  }

  @override
  void didPopNext() {
    _syncPlayback();
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            Assets.menuBg,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          if (_isReady)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
        ],
      ),
    );
  }
}

class _FloatingMenuRail extends StatelessWidget {
  final PlayerModel player;
  final VoidCallback playButtonSfx;

  const _FloatingMenuRail({required this.player, required this.playButtonSfx});

  @override
  Widget build(BuildContext context) {
    final earnedBadges = player.earnedBadges.length;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FooterIconButton(
              iconAsset: Assets.menuLeaderboardIcon,
              tooltip: 'Leaderboard',
              onTap: () {
                playButtonSfx();
                context.push(AppRoutes.leaderboard);
              },
            ),
            const SizedBox(height: 7),
            _FooterIconButton(
              iconAsset: Assets.menuBadgeIcon,
              tooltip: 'Badge collection',
              badge: earnedBadges > 0 ? '$earnedBadges' : null,
              onTap: () {
                playButtonSfx();
                context.push(AppRoutes.badges);
              },
            ),
            const SizedBox(height: 7),
            _FooterIconButton(
              iconAsset: Assets.menuSwitchIcon,
              tooltip: 'Switch player',
              onTap: () {
                playButtonSfx();
                context.push(AppRoutes.playersFromMenu);
              },
            ),
          ],
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
  final VoidCallback playButtonSfx;

  const _TopBar({
    required this.player,
    required this.missionsDone,
    required this.progress,
    required this.playButtonSfx,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PlayerIdentityPlate(
                player: player,
                missionsDone: missionsDone,
                progress: progress,
              ),
              const SizedBox(height: 7),
              _ProfileLabelButton(
                onPressed: () {
                  playButtonSfx();
                  context.push(AppRoutes.starterKnowledge);
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _HeaderStats(
          totalXp: player.totalXP,
          badges: player.earnedBadges.length,
          missions: missionsDone,
        ),
      ],
    );
  }
}

class _ProfileLabelButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ProfileLabelButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xE61A0E08),
          border: Border.all(color: const Color(0xFFD0733C), width: 1.1),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66030201),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onPressed,
            child: const Center(
              child: Text(
                'Learning Objectives',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFFFFE8C4),
                  fontSize: 11,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  shadows: [
                    Shadow(color: Color(0xFF000000), offset: Offset(0, 1)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerIdentityPlate extends StatelessWidget {
  final PlayerModel player;
  final int missionsDone;
  final double progress;

  const _PlayerIdentityPlate({
    required this.player,
    required this.missionsDone,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _PlayerIdentityPlatePainter(),
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(7, 6, 22, 6),
          child: Row(
            children: [
              _AvatarSquare(avatarIndex: player.avatarIndex),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFFF0D5),
                        fontSize: 14,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        shadows: [
                          Shadow(
                            color: Color(0xFF130603),
                            offset: Offset(0, 2),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF7A1A),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFFF5E16),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'LEVEL ${player.currentLevel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFFFB45F),
                              fontSize: 8,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.9,
                              shadows: [
                                Shadow(
                                  color: Color(0xFF0A0302),
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Semantics(
                      label: 'Mission progress',
                      value: '$missionsDone of ${AppConstants.totalLevels}',
                      child: SizedBox(
                        height: 7,
                        child: CustomPaint(
                          painter: _MoltenProgressPainter(value: progress),
                        ),
                      ),
                    ),
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

class _PlayerIdentityPlatePainter extends CustomPainter {
  const _PlayerIdentityPlatePainter();

  Path _platePath(Size size) {
    return Path()
      ..moveTo(10, 0)
      ..lineTo(size.width * 0.42, 0)
      ..lineTo(size.width * 0.47, 5)
      ..lineTo(size.width * 0.52, 0)
      ..lineTo(size.width - 19, 0)
      ..lineTo(size.width - 7, 9)
      ..lineTo(size.width, size.height * 0.48)
      ..lineTo(size.width - 11, size.height)
      ..lineTo(8, size.height)
      ..lineTo(0, size.height - 9)
      ..lineTo(0, 10)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final plate = _platePath(size);
    final bounds = Offset.zero & size;

    canvas.drawPath(
      plate.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0xB3050201)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      plate,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF2352118), Color(0xF21C100C), Color(0xF20C0705)],
        ).createShader(bounds),
    );
    canvas.drawPath(
      plate,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD0733C), Color(0xFF6A321F), Color(0xFF26110C)],
        ).createShader(bounds),
    );

    final lavaSeam = Path()
      ..moveTo(9, size.height - 2)
      ..lineTo(size.width * 0.58, size.height - 2)
      ..lineTo(size.width * 0.64, size.height - 5)
      ..lineTo(size.width - 16, size.height - 5);
    canvas.drawPath(
      lavaSeam,
      Paint()
        ..color = const Color(0x99FF6B20)
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MoltenProgressPainter extends CustomPainter {
  final double value;

  const _MoltenProgressPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final track = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    canvas.drawRRect(track, Paint()..color = const Color(0xFF0A0503));
    canvas.drawRRect(
      track.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF69321E),
    );

    final fillWidth = size.width * value.clamp(0.0, 1.0);
    if (fillWidth <= 0) {
      return;
    }
    final fillRect = Rect.fromLTWH(1, 1, fillWidth.clamp(0, size.width - 2), 6);
    final fill = RRect.fromRectAndRadius(fillRect, const Radius.circular(3));
    canvas.drawRRect(
      fill.inflate(1),
      Paint()
        ..color = const Color(0x66FF5D17)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawRRect(
      fill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFD483), Color(0xFFFF781C), Color(0xFFB93412)],
        ).createShader(fillRect),
    );
    canvas.drawLine(
      Offset(fillRect.left + 3, fillRect.top + 1.5),
      Offset(
        math.max(fillRect.left + 3, fillRect.right - 3),
        fillRect.top + 1.5,
      ),
      Paint()
        ..color = const Color(0xAAFFF1C2)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MoltenProgressPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

class _HeaderStats extends StatelessWidget {
  final int totalXp;
  final int badges;
  final int missions;

  const _HeaderStats({
    required this.totalXp,
    required this.badges,
    required this.missions,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '$totalXp total XP, $badges badges earned, $missions missions done',
      child: CustomPaint(
        painter: const _HeaderStatsPainter(),
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeaderStat(
                  icon: Icons.bolt_rounded,
                  value: '$totalXp',
                  tooltip: 'Total XP',
                ),
                const _HeaderStatDivider(),
                _HeaderStat(
                  icon: Icons.military_tech_rounded,
                  value: '$badges',
                  tooltip: 'Badges earned',
                ),
                const _HeaderStatDivider(),
                _HeaderStat(
                  icon: Icons.flag_rounded,
                  value: '$missions',
                  tooltip: 'Missions done',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String tooltip;

  const _HeaderStat({
    required this.icon,
    required this.value,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 31,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: const Color(0xFFFFA24A),
              size: 13,
              shadows: const [
                Shadow(color: Color(0xFF000000), blurRadius: 2),
                Shadow(color: Color(0x77FF5E16), blurRadius: 4),
              ],
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFFFFE8C4),
                  fontSize: 10,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                  shadows: [
                    Shadow(color: Color(0xFF000000), offset: Offset(0, 1)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStatDivider extends StatelessWidget {
  const _HeaderStatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: const Color(0xFF6D321E),
    );
  }
}

class _HeaderStatsPainter extends CustomPainter {
  const _HeaderStatsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final face = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.drawRRect(
      face.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0xBB050201)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawRRect(
      face,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF22F1C13), Color(0xF21A0E0A), Color(0xF20C0604)],
        ).createShader(rect),
    );
    canvas.drawRRect(
      face.deflate(0.7),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFCE6A32), Color(0xFF572719), Color(0xFF160906)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFA554), Color(0xFF6A2B17), Color(0xFF1C0B07)],
        ),
        border: Border.all(color: const Color(0xFFFFB766), width: 1),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            offset: Offset(0, 3),
            blurRadius: 3,
          ),
          BoxShadow(color: Color(0x55FF6718), blurRadius: 7),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Image.asset(avatarAsset, fit: BoxFit.cover),
      ),
    );
  }
}

class _MissionMap extends StatefulWidget {
  final PlayerModel player;
  final VoidCallback playButtonSfx;

  const _MissionMap({required this.player, required this.playButtonSfx});

  @override
  State<_MissionMap> createState() => _MissionMapState();
}

class _MissionMapState extends State<_MissionMap> {
  final _activeNodeKey = GlobalKey();
  String? _selectedNodeId;
  String? _eruptingNodeId;
  String? _pendingEruptionNodeId;
  String? _lastAutoScrolledRoute;
  int _teleportToken = 0;
  var _pendingStartScheduled = false;

  @override
  void didUpdateWidget(covariant _MissionMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player.currentLevel != widget.player.currentLevel ||
        oldWidget.player.completedMissionOrbs !=
            widget.player.completedMissionOrbs) {
      final oldActiveNode = _firstNodeWhere(
        _missionNodes(oldWidget.player),
        (node) => node.isCurrent,
      );
      if (oldActiveNode != null) {
        final completedNodeId = _nodeId(oldActiveNode);
        if (_isCurrentRoute) {
          _beginCompletionTransition(completedNodeId);
        } else {
          _pendingEruptionNodeId = completedNodeId;
        }
      } else {
        _selectedNodeId = null;
        _eruptingNodeId = null;
        _pendingEruptionNodeId = null;
        _lastAutoScrolledRoute = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const nodeSize = 58.0;
    final nodes = _missionNodes(widget.player);
    final pinnedNodeId = _pinnedNodeId(nodes);
    final activeRoute = _activeRoute(nodes);
    _startPendingEruptionWhenVisible();
    _scrollToActiveRoute(activeRoute);
    assert(
      nodes.length == _missionPathAnchors.length,
      'Mission nodes must match the menu background path anchors.',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.sizeOf(context).height;
        final canvasWidth = constraints.maxWidth;
        final imageRatioHeight = canvasWidth / _menuImageAspectRatio;
        final canvasHeight = math.max(imageRatioHeight, screenHeight);
        final positions = _missionNodePositions(
          backgroundSize: MediaQuery.sizeOf(context),
          contentTop: 0,
          count: nodes.length,
        );
        final positionedNodes = nodes.take(positions.length).toList();

        return SizedBox(
          height: canvasHeight,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(child: _LoopingMenuBackground()),
              for (var index = positionedNodes.length - 1; index >= 0; index--)
                Positioned(
                  left: positions[index].dx - nodeSize / 2,
                  top: positions[index].dy - nodeSize / 2,
                  child: _MissionNode(
                    key: positionedNodes[index].route == activeRoute
                        ? _activeNodeKey
                        : null,
                    avatarIndex: widget.player.avatarIndex,
                    node: positionedNodes[index],
                    isPinned: _nodeId(positionedNodes[index]) == pinnedNodeId,
                    isErupting:
                        _nodeId(positionedNodes[index]) == _eruptingNodeId,
                    size: nodeSize,
                    onTap: positionedNodes[index].isUnlocked
                        ? () {
                            widget.playButtonSfx();
                            setState(() {
                              _selectedNodeId = _nodeId(positionedNodes[index]);
                              _eruptingNodeId = null;
                            });
                            _showMissionDialog(context, positionedNodes[index]);
                          }
                        : null,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String? _activeRoute(List<_MissionMapNode> nodes) {
    return _firstNodeWhere(nodes, (node) => node.isCurrent)?.route;
  }

  String? _pinnedNodeId(List<_MissionMapNode> nodes) {
    final selectedNode = _firstNodeWhere(
      nodes,
      (node) => node.isUnlocked && _nodeId(node) == _selectedNodeId,
    );
    if (selectedNode != null) {
      return _nodeId(selectedNode);
    }

    final currentNode = _firstNodeWhere(nodes, (node) => node.isCurrent);
    return currentNode == null ? null : _nodeId(currentNode);
  }

  String _nodeId(_MissionMapNode node) => '${node.eyebrow}|${node.title}';

  bool get _isCurrentRoute => ModalRoute.of(context)?.isCurrent ?? true;

  _MissionMapNode? _firstNodeWhere(
    List<_MissionMapNode> nodes,
    bool Function(_MissionMapNode node) test,
  ) {
    for (final node in nodes) {
      if (test(node)) {
        return node;
      }
    }
    return null;
  }

  void _scrollToActiveRoute(String? activeRoute) {
    if (activeRoute == null || activeRoute == _lastAutoScrolledRoute) {
      return;
    }
    _lastAutoScrolledRoute = activeRoute;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final activeContext = _activeNodeKey.currentContext;
      if (activeContext == null) {
        return;
      }
      Scrollable.ensureVisible(
        activeContext,
        alignment: 0.55,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _schedulePinTeleport() {
    final token = ++_teleportToken;
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted || token != _teleportToken) {
        return;
      }
      setState(() {
        _selectedNodeId = null;
        _eruptingNodeId = null;
        _lastAutoScrolledRoute = null;
      });
    });
  }

  void _beginCompletionTransition(String completedNodeId) {
    _selectedNodeId = completedNodeId;
    _eruptingNodeId = completedNodeId;
    _pendingEruptionNodeId = null;
    _lastAutoScrolledRoute = null;
    _schedulePinTeleport();
  }

  void _startPendingEruptionWhenVisible() {
    if (!_isCurrentRoute ||
        _pendingEruptionNodeId == null ||
        _pendingStartScheduled) {
      return;
    }
    _pendingStartScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isCurrentRoute || _pendingEruptionNodeId == null) {
        _pendingStartScheduled = false;
        return;
      }
      setState(() {
        _pendingStartScheduled = false;
        _beginCompletionTransition(_pendingEruptionNodeId!);
      });
    });
  }

  List<_MissionMapNode> _missionNodes(PlayerModel player) {
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
          (level == 3 && _isMissionThreeComplete(player)) ||
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
    required Size backgroundSize,
    required double contentTop,
    required int count,
  }) {
    final imageRect = _menuImageRect(backgroundSize);
    final anchorCount = math.min(count, _missionPathAnchors.length);

    return [
      for (final anchor in _missionPathAnchors.take(anchorCount))
        Offset(
          imageRect.left + imageRect.width * anchor.dx,
          imageRect.top + imageRect.height * anchor.dy - contentTop,
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
      builder: (context) =>
          _MissionStartDialog(node: node, playButtonSfx: widget.playButtonSfx),
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
  final int avatarIndex;
  final _MissionMapNode node;
  final bool isPinned;
  final bool isErupting;
  final double size;
  final VoidCallback? onTap;

  const _MissionNode({
    super.key,
    required this.avatarIndex,
    required this.node,
    required this.isPinned,
    required this.isErupting,
    required this.size,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = _MissionBriefingStyle.fromKind(node.kind);

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
                _MissionVolcanoMarker(
                  kind: node.kind,
                  status: node.status,
                  accent: style.accent,
                  size: size * 0.92,
                  isHighlighted: isPinned,
                  isErupting: isErupting,
                ),
                if (isPinned)
                  Positioned(
                    top: -34,
                    child: _ActiveMissionAvatarPin(
                      avatarIndex: avatarIndex,
                      accent: style.accent,
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

class _MissionVolcanoMarker extends StatefulWidget {
  final _MissionKind kind;
  final _MissionNodeStatus status;
  final Color accent;
  final double size;
  final bool isHighlighted;
  final bool isErupting;

  const _MissionVolcanoMarker({
    required this.kind,
    required this.status,
    required this.accent,
    required this.size,
    this.isHighlighted = false,
    this.isErupting = false,
  });

  @override
  State<_MissionVolcanoMarker> createState() => _MissionVolcanoMarkerState();
}

class _MissionVolcanoMarkerState extends State<_MissionVolcanoMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _eruptionController;

  @override
  void initState() {
    super.initState();
    _eruptionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );
    _syncEruption();
  }

  @override
  void didUpdateWidget(covariant _MissionVolcanoMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncEruption();
  }

  void _syncEruption() {
    if (widget.isErupting) {
      _eruptionController.forward(from: 0);
    } else {
      _eruptionController.stop();
      _eruptionController.value = 0;
    }
  }

  @override
  void dispose() {
    _eruptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.status == _MissionNodeStatus.locked;

    return AnimatedBuilder(
      animation: _eruptionController,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Opacity(
            opacity: isLocked ? 0.46 : 1,
            child: CustomPaint(
              foregroundPainter: _MissionVolcanoMarkerPainter(
                kind: widget.kind,
                accent: isLocked ? AppColors.textDim : widget.accent,
                isComplete: widget.status == _MissionNodeStatus.complete,
                isCurrent: widget.status == _MissionNodeStatus.current,
                isHighlighted: widget.isHighlighted,
                isErupting: widget.isErupting,
                isLocked: isLocked,
                eruptionProgress: _eruptionController.value,
              ),
              child: Image.asset(
                Assets.menuMissionVolcanoItem,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MissionVolcanoMarkerPainter extends CustomPainter {
  final _MissionKind kind;
  final Color accent;
  final bool isComplete;
  final bool isCurrent;
  final bool isHighlighted;
  final bool isErupting;
  final bool isLocked;
  final double eruptionProgress;

  const _MissionVolcanoMarkerPainter({
    required this.kind,
    required this.accent,
    required this.isComplete,
    required this.isCurrent,
    required this.isHighlighted,
    required this.isErupting,
    required this.isLocked,
    required this.eruptionProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 32;
    final centerX = size.width / 2;
    final baseY = size.height * 0.84;

    if (isErupting) {
      _paintEruption(canvas, size, scale, eruptionProgress);
    }

    if (isHighlighted) {
      canvas.drawCircle(
        Offset(centerX, size.height * 0.55),
        size.shortestSide * 0.48,
        Paint()
          ..shader = RadialGradient(
            colors: [
              accent.withValues(alpha: 0.14),
              accent.withValues(alpha: 0),
            ],
          ).createShader(Offset.zero & size),
      );
    }

    final glowRect = Rect.fromCenter(
      center: Offset(centerX, baseY + 1.8 * scale),
      width: size.width * 0.82,
      height: 8 * scale,
    );
    canvas.drawOval(
      glowRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(
              alpha: isLocked
                  ? 0.06
                  : isHighlighted
                  ? 0.38
                  : 0.2,
            ),
            accent.withValues(alpha: 0),
          ],
        ).createShader(glowRect),
    );

    final shadowRect = Rect.fromCenter(
      center: Offset(centerX, baseY + 2 * scale),
      width: size.width * 0.96,
      height: 7 * scale,
    );
    canvas.drawOval(
      shadowRect,
      Paint()..color = const Color(0xFF050403).withValues(alpha: 0.42),
    );

    if (isComplete) {
      final checkPaint = Paint()
        ..color = const Color(0xFFE9FFF9).withValues(alpha: 0.86)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.1 * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final check = Path()
        ..moveTo(size.width * 0.66, size.height * 0.22)
        ..lineTo(size.width * 0.74, size.height * 0.3)
        ..lineTo(size.width * 0.88, size.height * 0.14);
      canvas.drawPath(check, checkPaint);
    }
  }

  void _paintEruption(Canvas canvas, Size size, double scale, double phase) {
    final centerX = size.width / 2;
    final craterY = size.height * 0.2;
    final pulse = math.sin(phase * math.pi * 2) * 0.5 + 0.5;
    final smokePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE7D0B5).withValues(alpha: 0.2 + pulse * 0.16),
          const Color(0xFF5B4336).withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);

    canvas.drawCircle(
      Offset(centerX - 5 * scale, craterY - (8 + pulse * 4) * scale),
      (4.2 + pulse * 1.6) * scale,
      smokePaint,
    );
    canvas.drawCircle(
      Offset(centerX + 4 * scale, craterY - (11 - pulse * 2) * scale),
      (3.4 + (1 - pulse) * 1.4) * scale,
      smokePaint,
    );

    final emberPaint = Paint()
      ..color = accent.withValues(alpha: 0.48 + pulse * 0.28)
      ..strokeWidth = 1.4 * scale
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 4; index++) {
      final angle = -math.pi / 2 + (index - 1.5) * 0.34;
      final distance = (8 + ((phase * 18 + index * 5) % 7)) * scale;
      final start = Offset(centerX, craterY - 1 * scale);
      final end = Offset(
        centerX + math.cos(angle) * distance,
        craterY + math.sin(angle) * distance,
      );
      canvas.drawLine(start, end, emberPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MissionVolcanoMarkerPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.accent != accent ||
        oldDelegate.isComplete != isComplete ||
        oldDelegate.isCurrent != isCurrent ||
        oldDelegate.isHighlighted != isHighlighted ||
        oldDelegate.isErupting != isErupting ||
        oldDelegate.isLocked != isLocked ||
        oldDelegate.eruptionProgress != eruptionProgress;
  }
}

class _ActiveMissionAvatarPin extends StatefulWidget {
  final int avatarIndex;
  final Color accent;

  const _ActiveMissionAvatarPin({
    required this.avatarIndex,
    required this.accent,
  });

  @override
  State<_ActiveMissionAvatarPin> createState() =>
      _ActiveMissionAvatarPinState();
}

class _ActiveMissionAvatarPinState extends State<_ActiveMissionAvatarPin> {
  late VideoPlayerController _controller;
  var _isReady = false;

  AvatarAsset get _avatar {
    return Assets.avatars[widget.avatarIndex.clamp(
      0,
      Assets.avatars.length - 1,
    )];
  }

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.asset(
            _avatar.animatedPath,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          )
          ..setLooping(true)
          ..setVolume(0);
    _controller.addListener(_keepAvatarLooping);
    _initialize();
  }

  @override
  void didUpdateWidget(covariant _ActiveMissionAvatarPin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarIndex != widget.avatarIndex) {
      _controller.removeListener(_keepAvatarLooping);
      _controller.dispose();
      _isReady = false;
      _controller =
          VideoPlayerController.asset(
              _avatar.animatedPath,
              videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
            )
            ..setLooping(true)
            ..setVolume(0);
      _controller.addListener(_keepAvatarLooping);
      _initialize();
    }
  }

  void _keepAvatarLooping() {
    final value = _controller.value;
    if (!value.isInitialized || value.isPlaying) {
      return;
    }
    if (value.position >= value.duration) {
      _controller.seekTo(Duration.zero);
      _controller.play();
    }
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
    } catch (_) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _isReady = true);
    try {
      await _controller.play();
    } catch (_) {
      // The static avatar remains visible if playback is unavailable.
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_keepAvatarLooping);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 35,
      height: 44,
      child: CustomPaint(
        painter: _LocationPinPainter(accent: widget.accent),
        child: Align(
          alignment: const Alignment(0, -0.38),
          child: ClipOval(
            child: SizedBox(
              width: 24,
              height: 24,
              child: _isReady
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    )
                  : Image.asset(_avatar.imagePath, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationPinPainter extends CustomPainter {
  final Color accent;

  const _LocationPinPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = Offset(size.width / 2, size.height * 0.34);
    final radius = size.width * 0.42;
    final pinPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..moveTo(center.dx - radius * 0.48, center.dy + radius * 0.56)
      ..quadraticBezierTo(
        center.dx,
        size.height * 0.98,
        center.dx + radius * 0.48,
        center.dy + radius * 0.56,
      )
      ..close();

    canvas.drawShadow(pinPath, const Color(0xFF050403), 8, false);
    canvas.drawPath(
      pinPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent.withValues(alpha: 0.9), const Color(0xFF22110A)],
        ).createShader(rect),
    );
    canvas.drawPath(
      pinPath,
      Paint()
        ..color = const Color(0xFFFFD7A0).withValues(alpha: 0.36)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _LocationPinPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

class _MissionStartDialog extends StatelessWidget {
  final _MissionMapNode node;
  final VoidCallback playButtonSfx;

  const _MissionStartDialog({required this.node, required this.playButtonSfx});

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
                  _MissionDialogCloseButton(
                    style: style,
                    onTap: () {
                      playButtonSfx();
                      Navigator.of(context).pop();
                    },
                  ),
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
                  playButtonSfx();
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
              _MissionVolcanoMarker(
                kind: node.kind,
                status: node.status,
                accent: style.accent,
                size: 42,
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
  final VoidCallback onTap;

  const _MissionDialogCloseButton({required this.style, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Close',
      child: InkResponse(
        onTap: onTap,
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
  final String iconAsset;
  final String tooltip;
  final String? badge;
  final VoidCallback onTap;

  const _FooterIconButton({
    required this.iconAsset,
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
          radius: 31,
          splashColor: const Color(0xFFFF9B45).withValues(alpha: 0.1),
          highlightColor: const Color(0xFFFF9B45).withValues(alpha: 0.05),
          child: SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                const SizedBox.expand(
                  child: CustomPaint(painter: _MenuControlWellPainter()),
                ),
                Image.asset(
                  iconAsset,
                  width: 44,
                  height: 44,
                  fit: BoxFit.contain,
                ),
                if (badge != null)
                  Positioned(
                    top: 0,
                    right: 1,
                    child: CustomPaint(
                      painter: const _VolcanoBadgePainter(
                        accent: Color(0xFFFFD184),
                      ),
                      child: SizedBox(
                        width: 20,
                        height: 18,
                        child: Center(
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: Color(0xFFFFE0AC),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
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

class _MenuControlWellPainter extends CustomPainter {
  const _MenuControlWellPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      center + const Offset(0, 3),
      size.width * 0.46,
      Paint()
        ..color = const Color(0xCC030201)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      center,
      size.width * 0.45,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF3A2117), Color(0xFF170D09), Color(0xFF080403)],
          stops: [0, 0.7, 1],
        ).createShader(Offset.zero & size),
    );
    canvas.drawCircle(
      center,
      size.width * 0.44,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD5743B), Color(0xFF5C2918), Color(0xFF160906)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * 0.38),
      math.pi * 1.08,
      math.pi * 0.78,
      false,
      Paint()
        ..color = const Color(0x66FFD08B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VolcanoBadgePainter extends CustomPainter {
  final Color accent;

  const _VolcanoBadgePainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(7));
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent.withValues(alpha: 0.92), const Color(0xFF351409)],
        ).createShader(rect),
    );
    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..color = const Color(0xFFFFE0AC).withValues(alpha: 0.42)
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _VolcanoBadgePainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}
