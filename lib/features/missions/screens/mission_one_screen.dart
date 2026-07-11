import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/audio_catalog.dart';
import '../../../core/audio/audio_controller.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/assets.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/mission_screen_background.dart';
import '../../player/application/player_controller.dart';

class MissionOneScreen extends ConsumerStatefulWidget {
  final int levelId;
  final bool isReplay;

  const MissionOneScreen({
    super.key,
    required this.levelId,
    this.isReplay = false,
  });

  @override
  ConsumerState<MissionOneScreen> createState() => _MissionOneScreenState();
}

class MissionUnlockedScreen extends StatelessWidget {
  final int levelId;

  const MissionUnlockedScreen({super.key, required this.levelId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: MissionScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: Column(
              children: [
                Row(
                  children: [
                    MissionBackButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                          return;
                        }
                        context.go(AppRoutes.menu);
                      },
                    ),
                    const Spacer(),
                    Text(
                      'MISSION $levelId',
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(
                          color: AppColors.borderAlt,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_open_outlined,
                            color: AppColors.teal,
                            size: 34,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'MISSION $levelId UNLOCKED',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'NEW RESEARCH BRIEFING AVAILABLE SOON',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.teal,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => context.go(AppRoutes.menu),
                            child: const Text('RETURN TO MENU'),
                          ),
                        ],
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

class _MissionOneScreenState extends ConsumerState<MissionOneScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  final _replayCompletedOrbs = <String>{};

  static const _cores = [
    _MagmaCoreData(x: 0.84, y: 0.56, sizeFactor: 0.19, phase: 2.1),
    _MagmaCoreData(x: 0.44, y: 0.63, sizeFactor: 0.20, phase: 4.2),
    _MagmaCoreData(x: 0.27, y: 0.38, sizeFactor: 0.20, phase: 0),
  ];

  static final _missionOrbs = [
    _MissionOrbContent(
      id: AppConstants.missionOneOrbIds[0],
      title: 'Types of Volcanoes',
      subtitle: 'Identify the three basic volcano forms.',
      icon: Icons.terrain_outlined,
      facts: [
        'Cinder cone volcanoes are the simplest type of volcano. They are built from particles and blobs of solidified lava ejected from a single vent.',
        'Composite volcanoes, or stratovolcanoes, are large, steep-sided cones formed from alternating layers of lava flows, volcanic ash, cinders, blocks, and pyroclastic materials.',
        'Shield volcanoes are broad volcanoes that look similar to shields from above. They are built almost entirely of fluid lava flow and are not steep.',
      ],
    ),
    _MissionOrbContent(
      id: AppConstants.missionOneOrbIds[1],
      title: 'Volcano Structure',
      subtitle: 'Review the parts that make up a volcano.',
      icon: Icons.account_tree_outlined,
      facts: [
        'The summit is the highest point of the volcano. At the summit, there is an opening called a vent.',
        'Slopes are the sides or flanks of a volcano that radiate from the main or central vent.',
        'The main vent emits lava, gases, ash, or other volcanic materials.',
        'The magma chamber stores molten rock beneath the vent before eruption.',
        'Lava is molten rock released onto Earth surface during an eruption.',
        'A side vent is a smaller outlet through which magma escapes.',
        'The crater is the mouth of the volcano, a bowl-shaped hollow where magma, ash, and gas come out.',
      ],
    ),
    _MissionOrbContent(
      id: AppConstants.missionOneOrbIds[2],
      title: 'Types of Eruptions',
      subtitle: 'Learn eruption behavior and warning signs.',
      icon: Icons.local_fire_department_outlined,
      facts: [
        'Phreatic, or hydrothermal, eruptions are steam-driven when hot rocks come in contact with water.',
        'Phreatomagmatic eruptions are violent events caused by contact between water and magma.',
        'Strombolian eruptions are periodic, weak to violent eruptions characterized by lava fountains.',
        'Vulcanian eruptions produce tall eruption columns that can reach up to 20 km high, with pyroclastic flow and ash fall tephra.',
        'Warning signs include ground swells, crater glow, volcanic tremors, summit landslides, increased steaming, and hotter wells or crater lakes near the volcano.',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final initializedCores = widget.isReplay
        ? _replayCompletedOrbs
        : (player.completedMissionOrbs[AppConstants.missionOneId] ?? const [])
              .toSet();
    final isComplete = _missionOrbs.every(
      (orb) => initializedCores.contains(orb.id),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: MissionScreenBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = _MissionOneLayout.fromWidth(constraints.maxWidth);

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  layout.horizontalPadding,
                  layout.topPadding,
                  layout.horizontalPadding,
                  layout.bottomPadding,
                ),
                child: Column(
                  children: [
                    MissionResearchTopBar(
                      title: 'RESEARCH BASE',
                      xp: player.totalXP,
                      avatarIndex: player.avatarIndex,
                      onBack: () {
                        if (context.canPop()) {
                          context.pop();
                          return;
                        }
                        context.go(AppRoutes.menu);
                      },
                    ),
                    SizedBox(height: layout.headerGap),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: layout.panelMaxWidth,
                          ),
                          child: _ResearchBasePanel(
                            missionId: widget.levelId,
                            progress: initializedCores.length,
                            total: _missionOrbs.length,
                            isComplete: isComplete,
                            animation: _floatController,
                            cores: _cores,
                            missionOrbs: _missionOrbs,
                            initializedCores: initializedCores,
                            onCoreTap: (index) {
                              _showMissionOrbSheet(_missionOrbs[index]);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showMissionOrbSheet(_MissionOrbContent orb) async {
    final completedOrbs = widget.isReplay
        ? _replayCompletedOrbs
        : (ref
                      .read(playerProvider)
                      .completedMissionOrbs[AppConstants.missionOneId] ??
                  const [])
              .toSet();
    final isCompleted = completedOrbs.contains(orb.id);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      isScrollControlled: true,
      builder: (sheetContext) {
        return _MissionOrbSheet(
          orb: orb,
          isCompleted: isCompleted,
          isReplay: widget.isReplay,
          onComplete: () async {
            if (widget.isReplay) {
              setState(() {
                _replayCompletedOrbs.add(orb.id);
              });
            } else {
              await ref
                  .read(playerProvider.notifier)
                  .completeMissionOneOrb(orb.id);
            }
            if (sheetContext.mounted) {
              sheetContext.pop();
            }
            if (mounted) {
              unawaited(
                ref.read(audioControllerProvider).playSfx(SfxCue.correct),
              );
              showMissionSnackBar(
                context,
                widget.isReplay
                    ? 'Practice core synchronized'
                    : '+10 XP recorded',
              );
            }
          },
        );
      },
    );
  }
}

class _MissionOneLayout {
  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final double headerGap;
  final double panelMaxWidth;

  const _MissionOneLayout({
    required this.horizontalPadding,
    required this.topPadding,
    required this.bottomPadding,
    required this.headerGap,
    required this.panelMaxWidth,
  });

  factory _MissionOneLayout.fromWidth(double width) {
    if (width >= 720) {
      return const _MissionOneLayout(
        horizontalPadding: 32,
        topPadding: 14,
        bottomPadding: 24,
        headerGap: 12,
        panelMaxWidth: 760,
      );
    }

    if (width < 380) {
      return const _MissionOneLayout(
        horizontalPadding: 12,
        topPadding: 8,
        bottomPadding: 12,
        headerGap: 7,
        panelMaxWidth: double.infinity,
      );
    }

    return const _MissionOneLayout(
      horizontalPadding: 20,
      topPadding: 10,
      bottomPadding: 15,
      headerGap: 8,
      panelMaxWidth: double.infinity,
    );
  }
}

class _ResearchBasePanel extends StatelessWidget {
  static const _labBackgroundAspectRatio = 1058 / 1487;

  final int missionId;
  final int progress;
  final int total;
  final bool isComplete;
  final Animation<double> animation;
  final List<_MagmaCoreData> cores;
  final List<_MissionOrbContent> missionOrbs;
  final Set<String> initializedCores;
  final ValueChanged<int> onCoreTap;

  const _ResearchBasePanel({
    required this.missionId,
    required this.progress,
    required this.total,
    required this.isComplete,
    required this.animation,
    required this.cores,
    required this.missionOrbs,
    required this.initializedCores,
    required this.onCoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactHeight = constraints.maxHeight < 430;
        final edgeInset = compactHeight ? 10.0 : 16.0;

        return Center(
          child: AspectRatio(
            aspectRatio: _labBackgroundAspectRatio,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(Assets.missionOneLabBackground),
                  fit: BoxFit.fill,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, panelConstraints) {
                  final promptTop = (panelConstraints.maxHeight * 0.035)
                      .clamp(12.0, 20.0)
                      .toDouble();

                  return Stack(
                    children: [
                      const Positioned.fill(child: _LabGrid()),
                      Positioned(
                        top: promptTop,
                        left: 10,
                        right: 10,
                        child: _MissionPrompt(
                          missionId: missionId,
                          progress: progress,
                          total: total,
                          isComplete: isComplete,
                        ),
                      ),
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: animation,
                          builder: (context, _) {
                            return Stack(
                              children: [
                                for (
                                  var index = 0;
                                  index < cores.length;
                                  index++
                                )
                                  _FixedMagmaCore(
                                    data: cores[index],
                                    orb: missionOrbs[index],
                                    size: panelConstraints.biggest,
                                    floatProgress: animation.value,
                                    isInitialized: initializedCores.contains(
                                      missionOrbs[index].id,
                                    ),
                                    onTap: () => onCoreTap(index),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      if (isComplete)
                        Positioned(
                          left: edgeInset,
                          right: edgeInset,
                          bottom: edgeInset,
                          child: _ProceedButton(),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MissionOneImageSheetFrame extends StatelessWidget {
  final Widget child;

  const _MissionOneImageSheetFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(Assets.missionOneVolcanoTypeContainer),
              fit: BoxFit.fill,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MissionPrompt extends StatelessWidget {
  final int missionId;
  final int progress;
  final int total;
  final bool isComplete;

  const _MissionPrompt({
    required this.missionId,
    required this.progress,
    required this.total,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isComplete
                ? 'MISSION $missionId: CORE INITIALIZED'
                : 'MISSION $missionId: CORE INITIALIZATION',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isComplete ? 'RESEARCH BASE ONLINE' : 'TAP THE GLOWING MAGMA CORES',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.teal,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$progress/$total CORES SYNCHRONIZED',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 7),
          MissionVolcanoProgressBar(
            value: total == 0 ? 0 : progress / total,
            height: 10,
          ),
        ],
      ),
    );
  }
}

class _FixedMagmaCore extends StatelessWidget {
  final _MagmaCoreData data;
  final _MissionOrbContent orb;
  final Size size;
  final double floatProgress;
  final bool isInitialized;
  final VoidCallback onTap;

  const _FixedMagmaCore({
    required this.data,
    required this.orb,
    required this.size,
    required this.floatProgress,
    required this.isInitialized,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveBasis = math.min(size.width, size.height);
    final coreSize = (responsiveBasis * data.sizeFactor)
        .clamp(64.0, 104.0)
        .toDouble();
    final x = (size.width * data.x) - (coreSize / 2);
    final floatOffset =
        math.sin((floatProgress * math.pi * 2) + data.phase) * 6;
    final y = (size.height * data.y) - (coreSize / 2) + floatOffset;

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onTap: onTap,
        child: _MagmaCore(
          size: coreSize,
          icon: orb.icon,
          isInitialized: isInitialized,
        ),
      ),
    );
  }
}

class _MagmaCore extends StatelessWidget {
  final double size;
  final IconData icon;
  final bool isInitialized;

  const _MagmaCore({
    required this.size,
    required this.icon,
    required this.isInitialized,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFFFF6A00,
                  ).withValues(alpha: isInitialized ? 0.72 : 0.58),
                  blurRadius: size * 0.34,
                  spreadRadius: size * 0.08,
                  offset: Offset(0, size * 0.09),
                ),
                BoxShadow(
                  color: const Color(0xFFFFB000).withValues(alpha: 0.28),
                  blurRadius: size * 0.5,
                  spreadRadius: size * 0.03,
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: Image.asset(
              Assets.missionOneGlowingBall,
              fit: BoxFit.contain,
            ),
          ),
          Icon(
            isInitialized ? Icons.check : icon,
            color: const Color(0xFF19120B),
            size: size * 0.31,
          ),
        ],
      ),
    );
  }
}

class _MissionOrbSheet extends StatelessWidget {
  final _MissionOrbContent orb;
  final bool isCompleted;
  final bool isReplay;
  final Future<void> Function() onComplete;

  const _MissionOrbSheet({
    required this.orb,
    required this.isCompleted,
    required this.isReplay,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 380
                  ? 24.0
                  : 38.0;

              return _MissionOneImageSheetFrame(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    42,
                    horizontalPadding,
                    34,
                  ),
                  children: [
                    _MissionOneOrbHeader(orb: orb),
                    const SizedBox(height: 26),
                    for (final fact in orb.facts)
                      _MissionOneOrbFactRow(text: fact),
                    const SizedBox(height: 18),
                    _CompleteOrbButton(
                      isCompleted: isCompleted,
                      isReplay: isReplay,
                      onComplete: onComplete,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MissionOneOrbHeader extends StatelessWidget {
  static const _orange = Color(0xFFFF7A00);

  final _MissionOrbContent orb;

  const _MissionOneOrbHeader({required this.orb});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.12),
                border: Border.all(
                  color: _orange.withValues(alpha: 0.72),
                  width: 1,
                ),
              ),
              child: Icon(orb.icon, color: _orange, size: 25),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                orb.title.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          orb.subtitle.toUpperCase(),
          style: const TextStyle(
            color: _orange,
            fontSize: 10,
            height: 1.35,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_orange, _orange.withValues(alpha: 0)],
            ),
          ),
        ),
      ],
    );
  }
}

class _MissionOneOrbFactRow extends StatelessWidget {
  static const _orange = Color(0xFFFF7A00);

  final String text;

  const _MissionOneOrbFactRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _orange.withValues(alpha: 0.22),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            transform: Matrix4.rotationZ(math.pi / 4),
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.18),
              border: Border.all(color: _orange, width: 1),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFE7E1D8),
                fontSize: 12,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompleteOrbButton extends StatefulWidget {
  final bool isCompleted;
  final bool isReplay;
  final Future<void> Function() onComplete;

  const _CompleteOrbButton({
    required this.isCompleted,
    required this.isReplay,
    required this.onComplete,
  });

  @override
  State<_CompleteOrbButton> createState() => _CompleteOrbButtonState();
}

class _CompleteOrbButtonState extends State<_CompleteOrbButton> {
  var _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return _MissionOneImageButton(
      onPressed: widget.isCompleted || _isSaving
          ? null
          : () async {
              setState(() {
                _isSaving = true;
              });
              await widget.onComplete();
              if (mounted) {
                setState(() {
                  _isSaving = false;
                });
              }
            },
      child: _isSaving
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.textPrimary,
              ),
            )
          : Text(
              widget.isCompleted
                  ? 'COMPLETED'
                  : widget.isReplay
                  ? 'COMPLETE PRACTICE'
                  : 'COMPLETE +10 XP',
            ),
    );
  }
}

class _ProceedButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _MissionOneImageButton(
      onPressed: () => context.go(AppRoutes.menu),
      child: const Text('RETURN TO MENU'),
    );
  }
}

class _MissionOneImageButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const _MissionOneImageButton({required this.onPressed, required this.child});

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

class _LabGrid extends StatelessWidget {
  const _LabGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _LabGridPainter());
  }
}

class _LabGridPainter extends CustomPainter {
  static const _gridColor = Color(0x181E4A5A);
  static const _crossColor = Color(0x101E4A5A);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = _gridColor
      ..strokeWidth = 0.6;
    const spacing = 18.0;

    for (var x = 0.0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final crossPaint = Paint()
      ..color = _crossColor
      ..strokeWidth = 1;
    for (var x = spacing / 2; x <= size.width; x += spacing) {
      for (var y = spacing / 2; y <= size.height; y += spacing) {
        canvas.drawLine(Offset(x - 1, y), Offset(x + 1, y), crossPaint);
        canvas.drawLine(Offset(x, y - 1), Offset(x, y + 1), crossPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MagmaCoreData {
  final double x;
  final double y;
  final double sizeFactor;
  final double phase;

  const _MagmaCoreData({
    required this.x,
    required this.y,
    required this.sizeFactor,
    required this.phase,
  });
}

class _MissionOrbContent {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> facts;

  const _MissionOrbContent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.facts,
  });
}
