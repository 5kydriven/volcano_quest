import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_catalog.dart';
import '../../../core/audio/audio_controller.dart';
import '../../../core/constants/assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/badge_award_image.dart';

class VolcanoMasterCelebration extends ConsumerStatefulWidget {
  final String playerName;
  final int correctCount;
  final int totalQuestions;
  final int earnedXP;
  final VoidCallback onReturn;

  const VolcanoMasterCelebration({
    super.key,
    required this.playerName,
    required this.correctCount,
    required this.totalQuestions,
    required this.earnedXP,
    required this.onReturn,
  });

  @override
  ConsumerState<VolcanoMasterCelebration> createState() =>
      _VolcanoMasterCelebrationState();
}

class _VolcanoMasterCelebrationState
    extends ConsumerState<VolcanoMasterCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _celebrationController;
  late final Animation<double> _badgeScale;
  late final ConfettiController _confettiController;
  late final AudioController _audioController;
  var _started = false;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    _badgeScale = CurvedAnimation(
      parent: _celebrationController,
      curve: const Interval(0, 0.24, curve: Curves.easeOutExpo),
    );
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 2800),
    );
    _audioController = ref.read(audioControllerProvider);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final automatedTest = _isAutomatedTestBinding();
    if (reduceMotion || automatedTest) {
      _celebrationController.value = 1;
    } else {
      unawaited(_celebrationController.repeat());
      _confettiController.play();
    }

    unawaited(_audioController.playSfx(SfxCue.victoryChime));
    unawaited(_audioController.playSfx(SfxCue.victoryCheer));
  }

  bool _isAutomatedTestBinding() {
    final bindingType = WidgetsBinding.instance.runtimeType.toString();
    return bindingType.contains('TestWidgetsFlutterBinding') ||
        bindingType.contains('AutomatedTestWidgetsFlutterBinding');
  }

  @override
  void dispose() {
    unawaited(_audioController.stopSfx(SfxCue.victoryChime));
    unawaited(_audioController.stopSfx(SfxCue.victoryCheer));
    _confettiController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          'All missions cleared. Volcano Master badge unlocked. ${widget.correctCount} out of ${widget.totalQuestions} correct.',
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExcludeSemantics(
            child: AnimatedBuilder(
              animation: _celebrationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _VictoryBackgroundPainter(
                    progress: _celebrationController.value,
                  ),
                );
              },
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'MISSION 9 COMPLETE',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 188,
                      height: 188,
                      child: AnimatedBuilder(
                        animation: _celebrationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _badgeScale.value,
                            child: Transform.rotate(
                              angle: _celebrationController.value * math.pi * 2,
                              child: CustomPaint(
                                painter: _GoldenFlameBorderPainter(
                                  progress: _celebrationController.value,
                                ),
                                child: Transform.rotate(
                                  angle:
                                      -_celebrationController.value *
                                      math.pi *
                                      2,
                                  child: child,
                                ),
                              ),
                            ),
                          );
                        },
                        child: const Center(
                          child: BadgeAwardImage(
                            imagePath: Assets.badgeVolcanoMaster,
                            fallbackIcon: Icons.local_fire_department_outlined,
                            fallbackColor: Color(0xFFFFD27A),
                            size: 132,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'VOLCANO MASTER BADGE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                        shadows: [
                          Shadow(color: Color(0xCCFF6A18), blurRadius: 18),
                          Shadow(color: Colors.black, offset: Offset(0, 3)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '100% COMPLETE • ALL MISSIONS CLEARED!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFFFC56F),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Congratulations, ${widget.playerName}! You completed all missions.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _VictoryMetric(
                            label: 'FINAL SCORE',
                            value:
                                '${widget.correctCount}/${widget.totalQuestions}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _VictoryMetric(
                            label: 'EARNED',
                            value: '${widget.earnedXP} XP',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        key: const ValueKey('volcanoMasterReturnButton'),
                        onPressed: () {
                          unawaited(_audioController.playSfx(SfxCue.button));
                          widget.onReturn();
                        },
                        child: const Text('RETURN TO MENU'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!MediaQuery.disableAnimationsOf(context) &&
              !_isAutomatedTestBinding())
            Align(
              alignment: Alignment.topCenter,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    emissionFrequency: 0.045,
                    numberOfParticles: 18,
                    minBlastForce: 8,
                    maxBlastForce: 18,
                    gravity: 0.18,
                    shouldLoop: true,
                    minimumSize: const Size(5, 3),
                    maximumSize: const Size(11, 7),
                    colors: const [
                      Color(0xFFFFE3A0),
                      Color(0xFFFFB45F),
                      Color(0xFFFF7A1A),
                      Color(0xFFC74214),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VictoryMetric extends StatelessWidget {
  final String label;
  final String value;

  const _VictoryMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xE6190B06),
        border: Border.all(color: const Color(0xFF8A3C1C)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _VictoryBackgroundPainter extends CustomPainter {
  final double progress;

  const _VictoryBackgroundPainter({required this.progress});

  static const _bursts = [
    Offset(0.18, 0.22),
    Offset(0.8, 0.2),
    Offset(0.12, 0.56),
    Offset(0.88, 0.58),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.2),
          radius: 0.86,
          colors: [Color(0x884D1C0B), Color(0x331C0904), Colors.transparent],
          stops: [0, 0.48, 1],
        ).createShader(rect),
    );

    for (var burstIndex = 0; burstIndex < _bursts.length; burstIndex++) {
      final start = 0.04 + (burstIndex * 0.1);
      final localProgress = ((progress - start) / 0.38).clamp(0.0, 1.0);
      if (localProgress <= 0 || localProgress >= 1) {
        continue;
      }
      final center = Offset(
        size.width * _bursts[burstIndex].dx,
        size.height * _bursts[burstIndex].dy,
      );
      final fade = 1 - localProgress;
      for (var ray = 0; ray < 12; ray++) {
        final angle = (math.pi * 2 * ray / 12) + (burstIndex * 0.28);
        final radius = 10 + (localProgress * (44 + burstIndex * 5));
        final startPoint = Offset(
          center.dx + math.cos(angle) * radius * 0.56,
          center.dy + math.sin(angle) * radius * 0.56,
        );
        final endPoint = Offset(
          center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius,
        );
        canvas.drawLine(
          startPoint,
          endPoint,
          Paint()
            ..color = const Color(0xFFFFC96E).withValues(alpha: fade * 0.8)
            ..strokeWidth = 1.4
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _VictoryBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _GoldenFlameBorderPainter extends CustomPainter {
  final double progress;

  const _GoldenFlameBorderPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) * 0.43;
    canvas.drawCircle(
      center,
      radius * 0.82,
      Paint()
        ..color = const Color(0x66FF6A17)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    for (var index = 0; index < 18; index++) {
      final angle = (math.pi * 2 * index / 18) + (progress * math.pi * 2);
      final pulse = 0.5 + 0.5 * math.sin((progress * math.pi * 4) + index);
      final inner = Offset(
        center.dx + math.cos(angle) * radius * 0.78,
        center.dy + math.sin(angle) * radius * 0.78,
      );
      final outer = Offset(
        center.dx + math.cos(angle) * radius * (0.92 + pulse * 0.16),
        center.dy + math.sin(angle) * radius * (0.92 + pulse * 0.16),
      );
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFF0B0), Color(0xFFFF7A1A)],
          ).createShader(Rect.fromPoints(inner, outer))
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GoldenFlameBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
