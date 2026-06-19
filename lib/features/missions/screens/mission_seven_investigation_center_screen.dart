import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/mission_screen_background.dart';
import '../../player/application/player_controller.dart';

class MissionSevenInvestigationCenterScreen extends ConsumerStatefulWidget {
  final int levelId;

  const MissionSevenInvestigationCenterScreen({
    super.key,
    required this.levelId,
  });

  @override
  ConsumerState<MissionSevenInvestigationCenterScreen> createState() =>
      _MissionSevenInvestigationCenterScreenState();
}

class _MissionSevenInvestigationCenterScreenState
    extends ConsumerState<MissionSevenInvestigationCenterScreen> {
  _VolcanoClassification? _selectedClassification;
  String? _feedback;
  var _isSaving = false;

  static final _volcanoes = [
    _InvestigationVolcano(
      id: AppConstants.missionSevenVolcanoIds[0],
      name: 'Mayon Volcano',
      tag: 'ALBAY MONITOR',
      correctClassification: _VolcanoClassification.active,
      eruptionRecord: 'Recent historical eruptions recorded',
      gasEmission: 'Elevated sulfur output',
      seismicActivity: 'Frequent volcanic tremors',
    ),
    _InvestigationVolcano(
      id: AppConstants.missionSevenVolcanoIds[1],
      name: 'Taal Volcano',
      tag: 'BATANGAS MONITOR',
      correctClassification: _VolcanoClassification.active,
      eruptionRecord: 'Recent historical eruptions recorded',
      gasEmission: 'Persistent gas release',
      seismicActivity: 'Volcanic earthquakes detected',
    ),
    _InvestigationVolcano(
      id: AppConstants.missionSevenVolcanoIds[2],
      name: 'Mount Arayat',
      tag: 'PAMPANGA MONITOR',
      correctClassification: _VolcanoClassification.inactive,
      eruptionRecord: 'No confirmed historical eruption',
      gasEmission: 'No active gas plume',
      seismicActivity: 'No volcanic quake cluster',
    ),
    _InvestigationVolcano(
      id: AppConstants.missionSevenVolcanoIds[3],
      name: 'Mount Makiling',
      tag: 'LAGUNA MONITOR',
      correctClassification: _VolcanoClassification.inactive,
      eruptionRecord: 'No confirmed historical eruption',
      gasEmission: 'Low background gas readings',
      seismicActivity: 'No active unrest signal',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final completedVolcanoes =
        player.completedMissionOrbs[AppConstants.missionSevenId] ?? const [];
    final correctVolcanoes =
        player.completedMissionOrbs[AppConstants
            .missionSevenCorrectAnswersId] ??
        const [];
    final completedCount = completedVolcanoes.length.clamp(
      0,
      _volcanoes.length,
    );
    final alreadyCompleted = AppConstants.missionSevenVolcanoIds.every(
      completedVolcanoes.contains,
    );
    final currentVolcano = alreadyCompleted
        ? null
        : _volcanoes.firstWhere(
            (volcano) => !completedVolcanoes.contains(volcano.id),
          );
    final progress = completedCount / _volcanoes.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: MissionScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
            child: Column(
              children: [
                _InvestigationTopBar(
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
                  child: _InvestigationPanel(
                    progress: progress,
                    percentComplete: (progress * 100).round(),
                    child: alreadyCompleted
                        ? _MissionSevenSummary(
                            correctCount: correctVolcanoes.length,
                            totalVolcanoes: _volcanoes.length,
                            earnedXP: _earnedXP(correctVolcanoes.length),
                            isPerfect:
                                correctVolcanoes.length == _volcanoes.length,
                            onProceed: () => context.push(AppRoutes.level(8)),
                          )
                        : _InvestigationContent(
                            volcano: currentVolcano!,
                            completedCount: completedCount,
                            totalCount: _volcanoes.length,
                            selectedClassification: _selectedClassification,
                            feedback: _feedback,
                            isSaving: _isSaving,
                            onSelect: _selectClassification,
                            onSubmit: _selectedClassification == null
                                ? null
                                : () => _submitClassification(currentVolcano),
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

  void _selectClassification(_VolcanoClassification classification) {
    if (_isSaving) {
      return;
    }

    setState(() {
      _selectedClassification = classification;
      _feedback = null;
    });
  }

  Future<void> _submitClassification(_InvestigationVolcano volcano) async {
    final selected = _selectedClassification;
    if (_isSaving || selected == null) {
      return;
    }

    final isCorrect = selected == volcano.correctClassification;
    final correctAnswer = volcano.correctClassification.label;

    setState(() {
      _isSaving = true;
      _feedback = isCorrect
          ? '+${AppConstants.missionSevenXpPerCorrect} XP RECORDED'
          : 'INCORRECT CLASSIFICATION - CORRECT ANSWER: $correctAnswer';
    });

    await ref
        .read(playerProvider.notifier)
        .submitMissionSevenVolcano(volcanoId: volcano.id, isCorrect: isCorrect);

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedClassification = null;
      _isSaving = false;
    });
  }

  static int _earnedXP(int correctCount) {
    return correctCount * AppConstants.missionSevenXpPerCorrect +
        (correctCount == _volcanoes.length
            ? AppConstants.missionSevenPerfectBonusXp
            : 0);
  }
}

class _InvestigationContent extends StatelessWidget {
  final _InvestigationVolcano volcano;
  final int completedCount;
  final int totalCount;
  final _VolcanoClassification? selectedClassification;
  final String? feedback;
  final bool isSaving;
  final ValueChanged<_VolcanoClassification> onSelect;
  final VoidCallback? onSubmit;

  const _InvestigationContent({
    required this.volcano,
    required this.completedCount,
    required this.totalCount,
    required this.selectedClassification,
    required this.feedback,
    required this.isSaving,
    required this.onSelect,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ScannerLabel(text: 'VOLCANO INVESTIGATION CENTER'),
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
              _VolcanoInvestigationCard(
                volcano: volcano,
                selectedClassification: selectedClassification,
                isSaving: isSaving,
                onSelect: onSelect,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isSaving ? null : onSubmit,
            child: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.teal,
                    ),
                  )
                : const Text('ANALYZE VOLCANO'),
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
              label: 'CLASSIFIED',
              value: '$completedCount/$totalCount',
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: _TelemetryCell(label: 'EACH', value: '10 XP'),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: _TelemetryCell(label: 'TOTAL', value: '60 XP'),
          ),
        ],
      ),
    );
  }
}

class _VolcanoInvestigationCard extends StatelessWidget {
  final _InvestigationVolcano volcano;
  final _VolcanoClassification? selectedClassification;
  final bool isSaving;
  final ValueChanged<_VolcanoClassification> onSelect;

  const _VolcanoInvestigationCard({
    required this.volcano,
    required this.selectedClassification,
    required this.isSaving,
    required this.onSelect,
  });

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
          const _VolcanoImagePlaceholder(),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.tealDim, width: 0.8),
                ),
                child: Icon(
                  Icons.terrain_outlined,
                  color: AppColors.teal,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      volcano.name,
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
                      volcano.tag,
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
          const SizedBox(height: 9),
          _MonitoringRow(
            icon: Icons.history_toggle_off_outlined,
            label: 'ERUPTION RECORDS',
            value: volcano.eruptionRecord,
          ),
          const SizedBox(height: 5),
          _MonitoringRow(
            icon: Icons.air_outlined,
            label: 'GAS EMISSIONS',
            value: volcano.gasEmission,
          ),
          const SizedBox(height: 5),
          _MonitoringRow(
            icon: Icons.graphic_eq_outlined,
            label: 'SEISMIC ACTIVITY',
            value: volcano.seismicActivity,
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _ClassificationButton(
                  key: ValueKey('mission7-${volcano.id}-active'),
                  label: 'ACTIVE',
                  isSelected:
                      selectedClassification == _VolcanoClassification.active,
                  isEnabled: !isSaving,
                  onTap: () => onSelect(_VolcanoClassification.active),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ClassificationButton(
                  key: ValueKey('mission7-${volcano.id}-inactive'),
                  label: 'INACTIVE',
                  isSelected:
                      selectedClassification == _VolcanoClassification.inactive,
                  isEnabled: !isSaving,
                  onTap: () => onSelect(_VolcanoClassification.inactive),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VolcanoImagePlaceholder extends StatelessWidget {
  const _VolcanoImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('mission7-volcano-image-placeholder'),
      height: 54,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.borderAlt, width: 0.8),
        borderRadius: BorderRadius.circular(7),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: _VolcanoPlaceholderPainterView()),
          Positioned(
            left: 12,
            top: 10,
            child: Text(
              'VOLCANO IMAGE',
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
              Icons.image_search_outlined,
              color: AppColors.teal.withValues(alpha: 0.62),
              size: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _VolcanoPlaceholderPainterView extends StatelessWidget {
  const _VolcanoPlaceholderPainterView();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _VolcanoPlaceholderPainter());
  }
}

class _VolcanoPlaceholderPainter extends CustomPainter {
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

    final mountainPaint = Paint()
      ..color = const Color(0xFF2C3A3E).withValues(alpha: 0.96)
      ..style = PaintingStyle.fill;
    final highlightPaint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final lavaPaint = Paint()
      ..color = const Color(0xFFFF8A4C).withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final rimPaint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final baseY = size.height * 0.88;
    final peak = Offset(size.width * 0.5, size.height * 0.28);
    final mountain = Path()
      ..moveTo(size.width * 0.12, baseY)
      ..quadraticBezierTo(
        size.width * 0.29,
        size.height * 0.58,
        peak.dx - 20,
        peak.dy + 16,
      )
      ..quadraticBezierTo(peak.dx, peak.dy, peak.dx + 20, peak.dy + 16)
      ..quadraticBezierTo(
        size.width * 0.70,
        size.height * 0.58,
        size.width * 0.88,
        baseY,
      )
      ..close();
    canvas.drawPath(mountain, mountainPaint);
    canvas.drawPath(mountain, rimPaint);

    final shadow = Path()
      ..moveTo(peak.dx, peak.dy + 5)
      ..lineTo(size.width * 0.66, baseY)
      ..lineTo(size.width * 0.88, baseY)
      ..quadraticBezierTo(
        size.width * 0.70,
        size.height * 0.58,
        peak.dx + 20,
        peak.dy + 16,
      )
      ..close();
    canvas.drawPath(shadow, highlightPaint);

    final crater = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(peak.dx, peak.dy + 14),
        width: 54,
        height: 14,
      ),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      crater,
      Paint()
        ..color = AppColors.background.withValues(alpha: 0.96)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(crater, rimPaint);

    final lava = Path()
      ..moveTo(peak.dx, peak.dy + 22)
      ..cubicTo(
        peak.dx - 8,
        size.height * 0.48,
        peak.dx + 14,
        size.height * 0.58,
        peak.dx + 4,
        size.height * 0.72,
      )
      ..cubicTo(
        peak.dx,
        size.height * 0.78,
        peak.dx + 18,
        size.height * 0.82,
        peak.dx + 12,
        baseY - 8,
      );
    canvas.drawPath(lava, lavaPaint);

    final plumePaint = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(peak.dx - 28, 10, 40, 32),
      2.5,
      2.4,
      false,
      plumePaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(peak.dx - 2, 4, 54, 38),
      2.7,
      2.1,
      false,
      plumePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MonitoringRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MonitoringRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.tealDim, size: 14),
        const SizedBox(width: 8),
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _ClassificationButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _ClassificationButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? AppColors.teal : AppColors.borderAlt;
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.teal.withValues(alpha: 0.16)
              : const Color(0xFF1B2A36),
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isEnabled ? AppColors.textPrimary : AppColors.textDim,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
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
    final isError = text.contains('INCORRECT');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        border: Border.all(
          color: isError ? const Color(0xFFFF7A7A) : AppColors.teal,
          width: 0.8,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isError ? const Color(0xFFFFB3B3) : AppColors.teal,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _MissionSevenSummary extends StatelessWidget {
  final int correctCount;
  final int totalVolcanoes;
  final int earnedXP;
  final bool isPerfect;
  final VoidCallback onProceed;

  const _MissionSevenSummary({
    required this.correctCount,
    required this.totalVolcanoes,
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
                      : Icons.analytics_outlined,
                  color: AppColors.teal,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'MISSION 7 COMPLETE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              if (isPerfect) ...[
                const SizedBox(height: 8),
                const Text(
                  'LAVA BRIDGE CHAMPION',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.teal,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                const Text(
                  'INVESTIGATION REVIEW COMPLETE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFFC857),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _SummaryMetric(
                      label: 'SCORE',
                      value: '$correctCount/$totalVolcanoes',
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
                  child: const Text('PROCEED TO MISSION 8'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvestigationTopBar extends StatelessWidget {
  final int missionId;
  final int xp;
  final int avatarIndex;
  final VoidCallback onBack;

  const _InvestigationTopBar({
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

class _InvestigationPanel extends StatelessWidget {
  final double progress;
  final int percentComplete;
  final Widget child;

  const _InvestigationPanel({
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
                const Positioned.fill(child: _InvestigationGrid()),
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
        const Icon(Icons.radar_outlined, color: AppColors.teal, size: 12),
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

class _InvestigationGrid extends StatelessWidget {
  const _InvestigationGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _InvestigationGridPainter());
  }
}

class _InvestigationGridPainter extends CustomPainter {
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

class _InvestigationVolcano {
  final String id;
  final String name;
  final String tag;
  final _VolcanoClassification correctClassification;
  final String eruptionRecord;
  final String gasEmission;
  final String seismicActivity;

  const _InvestigationVolcano({
    required this.id,
    required this.name,
    required this.tag,
    required this.correctClassification,
    required this.eruptionRecord,
    required this.gasEmission,
    required this.seismicActivity,
  });
}

enum _VolcanoClassification {
  active('ACTIVE'),
  inactive('INACTIVE');

  final String label;

  const _VolcanoClassification(this.label);
}
