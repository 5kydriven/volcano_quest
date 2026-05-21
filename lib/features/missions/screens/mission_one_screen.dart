import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../player/application/player_controller.dart';

class MissionOneScreen extends ConsumerStatefulWidget {
  final int levelId;

  const MissionOneScreen({super.key, required this.levelId});

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.teal,
                      size: 18,
                    ),
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
                      border: Border.all(color: AppColors.borderAlt, width: 1),
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
    );
  }
}

class _MissionOneScreenState extends ConsumerState<MissionOneScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final List<_MagmaCoreData> _cores;

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
      duration: const Duration(milliseconds: 3600),
    )..repeat();

    final random = math.Random(DateTime.now().millisecondsSinceEpoch);
    _cores = List.generate(3, (index) {
      return _MagmaCoreData(
        x: 0.13 + random.nextDouble() * 0.72,
        y: 0.28 + random.nextDouble() * 0.58,
        size: 36 + random.nextDouble() * 22,
        phase: random.nextDouble() * math.pi * 2,
        drift: 5 + random.nextDouble() * 7,
      );
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final completedOrbs =
        player.completedMissionOrbs[AppConstants.missionOneId] ?? const [];
    final initializedCores = completedOrbs.toSet();
    final isComplete = _missionOrbs.every(
      (orb) => initializedCores.contains(orb.id),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: Column(
            children: [
              _ResearchTopBar(
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
              const SizedBox(height: 8),
              Expanded(
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMissionOrbSheet(_MissionOrbContent orb) async {
    final completedOrbs =
        ref
            .read(playerProvider)
            .completedMissionOrbs[AppConstants.missionOneId] ??
        const [];
    final isCompleted = completedOrbs.contains(orb.id);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      isScrollControlled: true,
      builder: (context) {
        return _MissionOrbSheet(
          orb: orb,
          isCompleted: isCompleted,
          onComplete: () async {
            await ref
                .read(playerProvider.notifier)
                .completeMissionOneOrb(orb.id);
            if (context.mounted) {
              context.pop();
            }
          },
        );
      },
    );
  }
}

class _ResearchTopBar extends StatelessWidget {
  final int xp;
  final int avatarIndex;
  final VoidCallback onBack;

  const _ResearchTopBar({
    required this.xp,
    required this.avatarIndex,
    required this.onBack,
  });

  static const _avatarIcons = [
    Icons.person_outline,
    Icons.biotech_outlined,
    Icons.rocket_launch_outlined,
    Icons.hub_outlined,
    Icons.science_outlined,
    Icons.public_outlined,
    Icons.travel_explore_outlined,
    Icons.psychology_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.teal, size: 18),
          onPressed: onBack,
        ),
        const Spacer(),
        const Text(
          'RESEARCH BASE',
          style: TextStyle(
            color: AppColors.teal,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$xp XP',
              style: const TextStyle(
                color: AppColors.teal,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderAlt, width: 1),
                color: AppColors.surface,
              ),
              child: Icon(
                _avatarIcons[avatarIndex.clamp(0, _avatarIcons.length - 1)],
                color: AppColors.teal,
                size: 14,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _ResearchBasePanel extends StatelessWidget {
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF061625),
        border: Border.all(color: AppColors.borderAlt, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: _LabGrid()),
          Positioned(
            top: 24,
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
            child: Padding(
              padding: const EdgeInsets.only(top: 104, bottom: 18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, _) {
                      return Stack(
                        children: [
                          for (var index = 0; index < cores.length; index++)
                            _AnimatedMagmaCore(
                              data: cores[index],
                              orb: missionOrbs[index],
                              size: constraints.biggest,
                              progress: animation.value,
                              isInitialized: initializedCores.contains(
                                missionOrbs[index].id,
                              ),
                              onTap: () => onCoreTap(index),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
          if (isComplete)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _ProceedButton(),
            ),
        ],
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
      decoration: BoxDecoration(
        color: const Color(0xFF172D40),
        border: Border.all(color: AppColors.border, width: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
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
        ],
      ),
    );
  }
}

class _AnimatedMagmaCore extends StatelessWidget {
  final _MagmaCoreData data;
  final _MissionOrbContent orb;
  final Size size;
  final double progress;
  final bool isInitialized;
  final VoidCallback onTap;

  const _AnimatedMagmaCore({
    required this.data,
    required this.orb,
    required this.size,
    required this.progress,
    required this.isInitialized,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final phase = progress * math.pi * 2 + data.phase;
    final x = (size.width * data.x) - (data.size / 2);
    final y = (size.height * data.y) - (data.size / 2);
    final dy = math.sin(phase) * data.drift;
    final dx = math.cos(phase * 0.7) * 3;

    return Positioned(
      left: x + dx,
      top: y + dy,
      child: GestureDetector(
        onTap: onTap,
        child: _MagmaCore(
          size: data.size,
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.32, -0.42),
          radius: 0.9,
          colors: [
            Colors.white.withValues(alpha: isInitialized ? 0.96 : 0.86),
            const Color(0xFF9CF7E8),
            AppColors.teal,
            const Color(0xFF31AFA4),
          ],
          stops: const [0, 0.22, 0.64, 1],
        ),
        border: isInitialized
            ? Border.all(color: AppColors.textPrimary, width: 1.4)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: isInitialized ? 0.72 : 0.5),
            blurRadius: isInitialized ? 30 : 24,
            spreadRadius: isInitialized ? 8 : 5,
          ),
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.22),
            blurRadius: 52,
            spreadRadius: 12,
          ),
        ],
      ),
      child: Icon(
        isInitialized ? Icons.check : icon,
        color: AppColors.background,
        size: isInitialized ? 18 : 19,
      ),
    );
  }
}

class _MissionOrbSheet extends StatelessWidget {
  final _MissionOrbContent orb;
  final bool isCompleted;
  final Future<void> Function() onComplete;

  const _MissionOrbSheet({
    required this.orb,
    required this.isCompleted,
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
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.borderAlt, width: 1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.teal, width: 1),
                      ),
                      child: Icon(orb.icon, color: AppColors.teal, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orb.title.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            orb.subtitle.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.teal,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                for (final fact in orb.facts) _FactRow(text: fact),
                const SizedBox(height: 12),
                _CompleteOrbButton(
                  isCompleted: isCompleted,
                  onComplete: onComplete,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  final String text;

  const _FactRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 7),
            decoration: const BoxDecoration(
              color: AppColors.teal,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.45,
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
  final Future<void> Function() onComplete;

  const _CompleteOrbButton({
    required this.isCompleted,
    required this.onComplete,
  });

  @override
  State<_CompleteOrbButton> createState() => _CompleteOrbButtonState();
}

class _CompleteOrbButtonState extends State<_CompleteOrbButton> {
  var _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
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
                  color: AppColors.teal,
                ),
              )
            : Text(widget.isCompleted ? 'COMPLETED' : 'COMPLETE +10 XP'),
      ),
    );
  }
}

class _ProceedButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => context.push(AppRoutes.level(2)),
      child: const Text('PROCEED TO MISSION 2'),
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
  final double size;
  final double phase;
  final double drift;

  const _MagmaCoreData({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
    required this.drift,
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
