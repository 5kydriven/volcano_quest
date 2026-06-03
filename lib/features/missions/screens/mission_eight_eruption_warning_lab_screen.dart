import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../player/application/player_controller.dart';

class MissionEightEruptionWarningLabScreen extends ConsumerStatefulWidget {
  final int levelId;

  const MissionEightEruptionWarningLabScreen({
    super.key,
    required this.levelId,
  });

  @override
  ConsumerState<MissionEightEruptionWarningLabScreen> createState() =>
      _MissionEightEruptionWarningLabScreenState();
}

class _MissionEightEruptionWarningLabScreenState
    extends ConsumerState<MissionEightEruptionWarningLabScreen> {
  String? _feedback;
  var _isSaving = false;

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
    final attemptedSigns =
        player.completedMissionOrbs[AppConstants.missionEightId] ?? const [];
    final correctSigns =
        player.completedMissionOrbs[AppConstants
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
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
                          earnedXP: _earnedXP(correctSigns),
                          isPerfect:
                              correctSigns.length == _warningSigns.length,
                          onProceed: () => context.push(AppRoutes.level(9)),
                        )
                      : _WarningContent(
                          sign: currentSign!,
                          completedCount: completedCount,
                          totalCount: _warningSigns.length,
                          feedback: _feedback,
                          isSaving: _isSaving,
                          onAnswer: (answer) =>
                              _submitAnswer(sign: currentSign, answer: answer),
                        ),
                ),
              ),
            ],
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
      _feedback = isCorrect
          ? '+${AppConstants.missionEightXpDisplayPerCorrect} XP RECORDED'
          : 'CORRECT WARNING SIGN: ${sign.correctAnswer.label}';
    });

    await ref
        .read(playerProvider.notifier)
        .submitMissionEightWarningSign(signId: sign.id, isCorrect: isCorrect);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });
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
  final String? feedback;
  final bool isSaving;
  final ValueChanged<_WarningAnswer> onAnswer;

  const _WarningContent({
    required this.sign,
    required this.completedCount,
    required this.totalCount,
    required this.feedback,
    required this.isSaving,
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
        if (feedback != null) ...[
          const SizedBox(height: 6),
          _FeedbackBanner(text: feedback!),
        ],
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _WarningSignCard(sign: sign),
              const SizedBox(height: 12),
              _AnswerGrid(
                signId: sign.id,
                isSaving: isSaving,
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.84),
        border: Border.all(color: AppColors.borderAlt, width: 0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TelemetryCell(
              label: 'DETECTED',
              value: '$completedCount/$totalCount',
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: _TelemetryCell(
              label: 'EACH',
              value: '${AppConstants.missionEightXpDisplayPerCorrect} XP',
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: _TelemetryCell(label: 'PERFECT', value: '70 XP'),
          ),
        ],
      ),
    );
  }
}

class _WarningSignCard extends StatelessWidget {
  final _WarningSign sign;

  const _WarningSignCard({required this.sign});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF071A2A).withValues(alpha: 0.92),
        border: Border.all(color: AppColors.borderAlt, width: 0.8),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WarningImage(sign: sign),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.tealDim, width: 0.8),
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
    );
  }
}

class _WarningImage extends StatelessWidget {
  final _WarningSign sign;

  const _WarningImage({required this.sign});

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
        ],
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
  final ValueChanged<_WarningAnswer> onAnswer;

  const _AnswerGrid({
    required this.signId,
    required this.isSaving,
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
            isEnabled: !isSaving,
            onTap: () => onAnswer(answer),
          ),
      ],
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final _WarningAnswer answer;
  final bool isEnabled;
  final VoidCallback onTap;

  const _AnswerButton({
    super.key,
    required this.answer,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1B2A36),
          border: Border.all(color: AppColors.borderAlt, width: 1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          answer.label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isEnabled ? AppColors.textPrimary : AppColors.textDim,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final String text;

  const _FeedbackBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    final isCorrect = text.startsWith('+');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        border: Border.all(
          color: isCorrect ? AppColors.teal : const Color(0xFFFF7A7A),
          width: 0.8,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isCorrect ? AppColors.teal : const Color(0xFFFFB3B3),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
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
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.borderAlt, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.teal, width: 1),
                ),
                child: Icon(
                  isPerfect
                      ? Icons.workspace_premium_outlined
                      : Icons.fact_check_outlined,
                  color: AppColors.teal,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'MISSION 8 COMPLETE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isPerfect
                    ? 'ERUPTION WARNING SPECIALIST BADGE'
                    : 'WARNING LAB REVIEW COMPLETE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isPerfect ? AppColors.teal : const Color(0xFFFFC857),
                  fontSize: isPerfect ? 10 : 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _SummaryMetric(
                      label: 'SCORE',
                      value: '$correctCount/$totalSigns',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryMetric(
                      label: 'EARNED',
                      value: '$earnedXP XP',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onProceed,
                  child: const Text('PROCEED TO MISSION 9'),
                ),
              ),
            ],
          ),
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
        Text(
          'MISSION $missionId',
          style: const TextStyle(
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
      decoration: BoxDecoration(
        color: const Color(0xFF061625),
        border: Border.all(color: AppColors.borderAlt, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            minHeight: 3,
            backgroundColor: AppColors.surface,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
          ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF061625),
        border: Border.all(color: AppColors.border, width: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
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

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF061625),
        border: Border.all(color: AppColors.borderAlt, width: 0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
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
