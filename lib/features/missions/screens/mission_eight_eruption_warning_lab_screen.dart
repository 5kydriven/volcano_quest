import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/audio_catalog.dart';
import '../../../core/audio/audio_controller.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/assets.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/mission_complete_panel.dart';
import '../../../shared/widgets/mission_screen_background.dart';
import '../../player/application/player_controller.dart';

class MissionEightEruptionWarningLabScreen extends ConsumerStatefulWidget {
  final int levelId;
  final bool isReplay;

  const MissionEightEruptionWarningLabScreen({
    super.key,
    required this.levelId,
    this.isReplay = false,
  });

  @override
  ConsumerState<MissionEightEruptionWarningLabScreen> createState() =>
      _MissionEightEruptionWarningLabScreenState();
}

class _MissionEightEruptionWarningLabScreenState
    extends ConsumerState<MissionEightEruptionWarningLabScreen> {
  var _isSaving = false;
  _WarningAnswer? _selectedAnswer;
  var _selectedAnswerIsCorrect = false;
  final _replayAttemptedSigns = <String>[];
  final _replayCorrectSigns = <String>[];

  static final _warningSigns = [
    _WarningSign(
      id: AppConstants.missionEightWarningSignIds[0],
      title: 'Shaking ground',
      monitorLabel: 'SEISMIC FLOOR SENSOR',
      correctAnswer: _WarningAnswer.tremors,
      detail: 'The ground shakes as magma movement creates volcanic tremors.',
      icon: Icons.vibration_outlined,
    ),
    _WarningSign(
      id: AppConstants.missionEightWarningSignIds[1],
      title: 'Red glowing crater',
      monitorLabel: 'CRATER CAMERA FEED',
      correctAnswer: _WarningAnswer.craterGlow,
      detail: 'A red glow near the crater can signal hot material rising.',
      icon: Icons.local_fire_department_outlined,
    ),
    _WarningSign(
      id: AppConstants.missionEightWarningSignIds[2],
      title: 'Smoke coming out',
      monitorLabel: 'GAS VENT OBSERVER',
      correctAnswer: _WarningAnswer.steaming,
      detail: 'Steam or smoke rising from vents can show volcanic unrest.',
      icon: Icons.air_outlined,
    ),
    _WarningSign(
      id: AppConstants.missionEightWarningSignIds[3],
      title: 'Bulging ground',
      monitorLabel: 'GROUND DEFORMATION GRID',
      correctAnswer: _WarningAnswer.groundSwelling,
      detail: 'Swelling slopes may mean magma is pushing upward underground.',
      icon: Icons.expand_less_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final attemptedSigns = widget.isReplay
        ? _replayAttemptedSigns
        : player.completedMissionOrbs[AppConstants.missionEightId] ?? const [];
    final correctSigns = widget.isReplay
        ? _replayCorrectSigns
        : player.completedMissionOrbs[AppConstants
                  .missionEightCorrectAnswersId] ??
              const [];
    final completedCount = attemptedSigns.length.clamp(0, _warningSigns.length);
    final alreadyCompleted = AppConstants.missionEightWarningSignIds.every(
      attemptedSigns.contains,
    );
    final currentSign = alreadyCompleted
        ? null
        : _warningSigns.firstWhere((sign) => !attemptedSigns.contains(sign.id));
    final progress = completedCount / _warningSigns.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: MissionScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
            child: Column(
              children: [
                _WarningTopBar(
                  missionId: widget.levelId,
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
                  child: _WarningPanel(
                    progress: progress,
                    percentComplete: (progress * 100).round(),
                    child: alreadyCompleted
                        ? _MissionEightSummary(
                            correctCount: correctSigns.length,
                            totalSigns: _warningSigns.length,
                            earnedXP: widget.isReplay
                                ? 0
                                : _earnedXP(correctSigns),
                            isPerfect:
                                correctSigns.length == _warningSigns.length,
                            onProceed: () => context.go(AppRoutes.menu),
                          )
                        : _WarningContent(
                            sign: currentSign!,
                            completedCount: completedCount,
                            totalCount: _warningSigns.length,
                            isSaving: _isSaving,
                            selectedAnswer: _selectedAnswer,
                            selectedAnswerIsCorrect: _selectedAnswerIsCorrect,
                            onAnswer: (answer) => _submitAnswer(
                              sign: currentSign,
                              answer: answer,
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

  Future<void> _submitAnswer({
    required _WarningSign sign,
    required _WarningAnswer answer,
  }) async {
    if (_isSaving) {
      return;
    }

    final isCorrect = answer == sign.correctAnswer;
    setState(() {
      _isSaving = true;
      _selectedAnswer = answer;
      _selectedAnswerIsCorrect = isCorrect;
    });
    unawaited(
      ref
          .read(audioControllerProvider)
          .playSfx(isCorrect ? SfxCue.correct : SfxCue.wrong),
    );

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) {
      return;
    }

    if (widget.isReplay) {
      if (!_replayAttemptedSigns.contains(sign.id)) {
        _replayAttemptedSigns.add(sign.id);
      }
      if (isCorrect && !_replayCorrectSigns.contains(sign.id)) {
        _replayCorrectSigns.add(sign.id);
      }
    } else {
      await ref
          .read(playerProvider.notifier)
          .submitMissionEightWarningSign(signId: sign.id, isCorrect: isCorrect);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
      _selectedAnswer = null;
      _selectedAnswerIsCorrect = false;
    });
    showMissionSnackBar(
      context,
      widget.isReplay
          ? isCorrect
                ? 'Practice warning recorded'
                : 'Correct warning sign: ${sign.correctAnswer.label}'
          : isCorrect
          ? '+${AppConstants.missionEightXpDisplayPerCorrect} XP recorded'
          : 'Correct warning sign: ${sign.correctAnswer.label}',
      isError: !isCorrect,
    );
  }

  static int _earnedXP(List<String> correctSigns) {
    var xp = 0;
    for (final signId in correctSigns) {
      final index = AppConstants.missionEightWarningSignIds.indexOf(signId);
      if (index != -1) {
        xp += AppConstants.missionEightXpPerCorrect[index];
      }
    }
    if (correctSigns.length == _warningSigns.length) {
      xp += AppConstants.missionEightPerfectBonusXp;
    }
    return xp;
  }
}

class _WarningContent extends StatelessWidget {
  final _WarningSign sign;
  final int completedCount;
  final int totalCount;
  final bool isSaving;
  final _WarningAnswer? selectedAnswer;
  final bool selectedAnswerIsCorrect;
  final ValueChanged<_WarningAnswer> onAnswer;

  const _WarningContent({
    required this.sign,
    required this.completedCount,
    required this.totalCount,
    required this.isSaving,
    required this.selectedAnswer,
    required this.selectedAnswerIsCorrect,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ScannerLabel(text: 'ERUPTION WARNING LAB'),
        const SizedBox(height: 10),
        _SignalStrip(completedCount: completedCount, totalCount: totalCount),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _WarningSignCard(
                sign: sign,
                showCorrectAlarm: selectedAnswerIsCorrect,
              ),
              const SizedBox(height: 12),
              _AnswerGrid(
                signId: sign.id,
                isSaving: isSaving,
                selectedAnswer: selectedAnswer,
                selectedAnswerIsCorrect: selectedAnswerIsCorrect,
                onAnswer: onAnswer,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SignalStrip extends StatelessWidget {
  final int completedCount;
  final int totalCount;

  const _SignalStrip({required this.completedCount, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(1.1, 2.2, 1),
              child: Image.asset(
                Assets.missionSevenStatsContainer,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _TelemetryCell(
                    label: 'DETECTED',
                    value: '$completedCount/$totalCount',
                  ),
                ),
                const Expanded(
                  child: _TelemetryCell(
                    label: 'EACH',
                    value: '${AppConstants.missionEightXpDisplayPerCorrect} XP',
                  ),
                ),
                const Expanded(
                  child: _TelemetryCell(label: 'PERFECT', value: '70 XP'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningSignCard extends StatelessWidget {
  final _WarningSign sign;
  final bool showCorrectAlarm;

  const _WarningSignCard({required this.sign, required this.showCorrectAlarm});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: Transform.scale(
                scale: 1.1,
                child: Image.asset(
                  Assets.squareContainer,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(33),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WarningImage(sign: sign, showAlarm: showCorrectAlarm),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.tealDim,
                            width: 0.8,
                          ),
                        ),
                        child: Icon(sign.icon, color: AppColors.teal, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sign.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 17,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sign.monitorLabel,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    sign.detail,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningImage extends StatelessWidget {
  final _WarningSign sign;
  final bool showAlarm;

  const _WarningImage({required this.sign, required this.showAlarm});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('mission8-warning-image-placeholder'),
      height: 128,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.borderAlt, width: 0.8),
        borderRadius: BorderRadius.circular(7),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _WarningImagePainter(sign)),
          ),
          Positioned(
            left: 12,
            top: 10,
            child: Text(
              'MONITOR IMAGE',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.84),
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 10,
            child: Icon(
              sign.icon,
              color: AppColors.teal.withValues(alpha: 0.68),
              size: 16,
            ),
          ),
          if (showAlarm)
            const Positioned.fill(
              child: _FlashingWarningAlarm(
                key: ValueKey('mission8-correct-warning-alarm'),
              ),
            ),
        ],
      ),
    );
  }
}

class _FlashingWarningAlarm extends StatefulWidget {
  const _FlashingWarningAlarm({super.key});

  @override
  State<_FlashingWarningAlarm> createState() => _FlashingWarningAlarmState();
}

class _FlashingWarningAlarmState extends State<_FlashingWarningAlarm>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      lowerBound: 0.25,
      upperBound: 1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            color: const Color(
              0xFFFF3B30,
            ).withValues(alpha: 0.12 * _controller.value),
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 10),
            child: Opacity(
              opacity: _controller.value,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                color: const Color(0xFF9C1C16),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFFD166),
                      size: 15,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'WARNING SIGNAL CONFIRMED',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WarningImagePainter extends CustomPainter {
  final _WarningSign sign;

  const _WarningImagePainter(this.sign);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.tealDim.withValues(alpha: 0.08)
      ..strokeWidth = 0.6;
    const spacing = 18.0;
    for (var x = 0.0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    _drawVolcano(canvas, size);
    switch (sign.correctAnswer) {
      case _WarningAnswer.tremors:
        _drawTremors(canvas, size);
      case _WarningAnswer.craterGlow:
        _drawCraterGlow(canvas, size);
      case _WarningAnswer.steaming:
        _drawSteaming(canvas, size);
      case _WarningAnswer.groundSwelling:
        _drawGroundSwelling(canvas, size);
    }
  }

  void _drawVolcano(Canvas canvas, Size size) {
    final baseY = size.height * 0.82;
    final peak = Offset(size.width * 0.5, size.height * 0.28);
    final mountain = Path()
      ..moveTo(size.width * 0.16, baseY)
      ..quadraticBezierTo(
        size.width * 0.32,
        size.height * 0.56,
        peak.dx - 22,
        peak.dy + 15,
      )
      ..quadraticBezierTo(peak.dx, peak.dy, peak.dx + 22, peak.dy + 15)
      ..quadraticBezierTo(
        size.width * 0.68,
        size.height * 0.56,
        size.width * 0.84,
        baseY,
      )
      ..close();
    canvas.drawPath(
      mountain,
      Paint()
        ..color = const Color(0xFF29363D).withValues(alpha: 0.96)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      mountain,
      Paint()
        ..color = AppColors.teal.withValues(alpha: 0.36)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawTremors(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFC857).withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var row = 0; row < 3; row++) {
      final y = size.height * (0.72 + row * 0.08);
      final path = Path()..moveTo(size.width * 0.16, y);
      for (var x = size.width * 0.22; x <= size.width * 0.86; x += 22) {
        path.lineTo(x, y + (x % 44 == 0 ? -7 : 7));
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawCraterGlow(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = const Color(0xFFFF6B35).withValues(alpha: 0.82)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.36),
        width: 82,
        height: 24,
      ),
      glowPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.36),
        width: 58,
        height: 14,
      ),
      Paint()..color = const Color(0xFFFFA24C),
    );
  }

  void _drawSteaming(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(size.width * 0.34, 12, 42, 48),
      2.3,
      2.5,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.width * 0.46, 4, 58, 62),
      2.5,
      2.3,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.width * 0.22, 24, 52, 48),
      2.1,
      2.2,
      false,
      paint,
    );
  }

  void _drawGroundSwelling(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final y = size.height * 0.78;
    final path = Path()
      ..moveTo(size.width * 0.12, y)
      ..quadraticBezierTo(size.width * 0.5, y - 44, size.width * 0.88, y);
    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(size.width * 0.5, y - 42),
      Offset(size.width * 0.5, y - 70),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, y - 70),
      Offset(size.width * 0.46, y - 62),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, y - 70),
      Offset(size.width * 0.54, y - 62),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _WarningImagePainter oldDelegate) {
    return oldDelegate.sign != sign;
  }
}

class _AnswerGrid extends StatelessWidget {
  final String signId;
  final bool isSaving;
  final _WarningAnswer? selectedAnswer;
  final bool selectedAnswerIsCorrect;
  final ValueChanged<_WarningAnswer> onAnswer;

  const _AnswerGrid({
    required this.signId,
    required this.isSaving,
    required this.selectedAnswer,
    required this.selectedAnswerIsCorrect,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: [
        for (final answer in _WarningAnswer.values)
          _AnswerButton(
            key: ValueKey('mission8-$signId-${answer.id}'),
            answer: answer,
            isSelected: selectedAnswer == answer,
            showCorrectCheck:
                selectedAnswer == answer && selectedAnswerIsCorrect,
            isEnabled: !isSaving,
            onTap: () => onAnswer(answer),
          ),
      ],
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final _WarningAnswer answer;
  final bool isSelected;
  final bool showCorrectCheck;
  final bool isEnabled;
  final VoidCallback onTap;

  const _AnswerButton({
    super.key,
    required this.answer,
    required this.isSelected,
    required this.showCorrectCheck,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: isEnabled || isSelected ? 1 : 0.45,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(1.15, 1.3, 1),
                child: Image.asset(
                  Assets.rectangleContainer,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                  excludeFromSemantics: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Center(
                  child: Text(
                    answer.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isEnabled || isSelected
                          ? AppColors.textPrimary
                          : AppColors.textDim,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              if (showCorrectCheck)
                Positioned(
                  top: 4,
                  right: 6,
                  child: Container(
                    key: ValueKey('mission8-${answer.id}-selected-indicator'),
                    width: 21,
                    height: 21,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF42D77D),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF42D77D).withValues(alpha: 0.7),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF42D77D),
                      size: 15,
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

class _MissionEightSummary extends StatelessWidget {
  final int correctCount;
  final int totalSigns;
  final int earnedXP;
  final bool isPerfect;
  final VoidCallback onProceed;

  const _MissionEightSummary({
    required this.correctCount,
    required this.totalSigns,
    required this.earnedXP,
    required this.isPerfect,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: MissionCompletePanel(
          title: 'MISSION 8 COMPLETE!',
          badgeName: isPerfect
              ? 'Eruption Warning Specialist Badge'
              : 'Warning Lab Review Complete',
          badgeImagePath: isPerfect
              ? Assets.badgeEruptionWarningSpecialist
              : null,
          fallbackIcon: Icons.fact_check_outlined,
          message: isPerfect
              ? 'Congratulations, scientist. You earned the Eruption Warning Specialist Badge.'
              : 'Warning lab review complete. No special badge earned this run.',
          metrics: [
            MissionCompleteMetric(
              label: 'SCORE',
              value: '$correctCount/$totalSigns',
            ),
            MissionCompleteMetric(label: 'EARNED', value: '$earnedXP XP'),
          ],
          onProceed: onProceed,
        ),
      ),
    );
  }
}

class _WarningTopBar extends StatelessWidget {
  final int missionId;
  final int xp;
  final int avatarIndex;
  final VoidCallback onBack;

  const _WarningTopBar({
    required this.missionId,
    required this.xp,
    required this.avatarIndex,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return MissionResearchTopBar(
      title: 'MISSION $missionId',
      xp: xp,
      avatarIndex: avatarIndex,
      onBack: onBack,
    );
  }
}

class _WarningPanel extends StatelessWidget {
  final double progress;
  final int percentComplete;
  final Widget child;

  const _WarningPanel({
    required this.progress,
    required this.percentComplete,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(0)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          MissionVolcanoProgressBar(value: progress),
          Expanded(
            child: Stack(
              children: [
                const Positioned.fill(child: _WarningGrid()),
                Positioned(
                  top: 8,
                  right: 18,
                  child: Text(
                    '$percentComplete% COMPLETE',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 26, 14, 18),
                    child: child,
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

class _ScannerLabel extends StatelessWidget {
  final String text;

  const _ScannerLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.sensors_outlined, color: AppColors.teal, size: 12),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.teal,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _TelemetryCell extends StatelessWidget {
  final String label;
  final String value;

  const _TelemetryCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningGrid extends StatelessWidget {
  const _WarningGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _WarningGridPainter());
  }
}

class _WarningGridPainter extends CustomPainter {
  static const _gridColor = Color(0x151E4A5A);
  static const _crossColor = Color(0x0F1E4A5A);

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

class _WarningSign {
  final String id;
  final String title;
  final String monitorLabel;
  final _WarningAnswer correctAnswer;
  final String detail;
  final IconData icon;

  const _WarningSign({
    required this.id,
    required this.title,
    required this.monitorLabel,
    required this.correctAnswer,
    required this.detail,
    required this.icon,
  });
}

enum _WarningAnswer {
  tremors('tremors', 'TREMORS'),
  craterGlow('crater_glow', 'CRATER GLOW'),
  steaming('steaming', 'STEAMING'),
  groundSwelling('ground_swelling', 'GROUND SWELLING');

  final String id;
  final String label;

  const _WarningAnswer(this.id, this.label);
}
