import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/assets.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/mission_complete_panel.dart';
import '../../../shared/widgets/mission_screen_background.dart';
import '../../player/application/player_controller.dart';

class MissionSevenInvestigationCenterScreen extends ConsumerStatefulWidget {
  final int levelId;
  final bool isReplay;

  const MissionSevenInvestigationCenterScreen({
    super.key,
    required this.levelId,
    this.isReplay = false,
  });

  @override
  ConsumerState<MissionSevenInvestigationCenterScreen> createState() =>
      _MissionSevenInvestigationCenterScreenState();
}

class _MissionSevenInvestigationCenterScreenState
    extends ConsumerState<MissionSevenInvestigationCenterScreen> {
  _VolcanoClassification? _selectedClassification;
  var _isSaving = false;
  var _showCorrectEffects = false;
  final _replayCompletedVolcanoes = <String>[];
  final _replayCorrectVolcanoes = <String>[];

  static final _volcanoes = [
    _InvestigationVolcano(
      id: AppConstants.missionSevenVolcanoIds[0],
      name: 'Mayon Volcano',
      tag: 'ALBAY MONITOR',
      imagePath: Assets.missionSevenMayon,
      correctClassification: _VolcanoClassification.active,
      eruptionRecord: 'Recent historical eruptions recorded',
      gasEmission: 'Elevated sulfur output',
      seismicActivity: 'Frequent volcanic tremors',
    ),
    _InvestigationVolcano(
      id: AppConstants.missionSevenVolcanoIds[1],
      name: 'Taal Volcano',
      tag: 'BATANGAS MONITOR',
      imagePath: Assets.missionSevenTaal,
      correctClassification: _VolcanoClassification.active,
      eruptionRecord: 'Recent historical eruptions recorded',
      gasEmission: 'Persistent gas release',
      seismicActivity: 'Volcanic earthquakes detected',
    ),
    _InvestigationVolcano(
      id: AppConstants.missionSevenVolcanoIds[2],
      name: 'Mount Arayat',
      tag: 'PAMPANGA MONITOR',
      imagePath: Assets.missionSevenArayat,
      correctClassification: _VolcanoClassification.inactive,
      eruptionRecord: 'No confirmed historical eruption',
      gasEmission: 'No active gas plume',
      seismicActivity: 'No volcanic quake cluster',
    ),
    _InvestigationVolcano(
      id: AppConstants.missionSevenVolcanoIds[3],
      name: 'Mount Makiling',
      tag: 'LAGUNA MONITOR',
      imagePath: Assets.missionSevenMakiling,
      correctClassification: _VolcanoClassification.inactive,
      eruptionRecord: 'No confirmed historical eruption',
      gasEmission: 'Low background gas readings',
      seismicActivity: 'No active unrest signal',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final completedVolcanoes = widget.isReplay
        ? _replayCompletedVolcanoes
        : player.completedMissionOrbs[AppConstants.missionSevenId] ?? const [];
    final correctVolcanoes = widget.isReplay
        ? _replayCorrectVolcanoes
        : player.completedMissionOrbs[AppConstants
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
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
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
                            earnedXP: widget.isReplay
                                ? 0
                                : _earnedXP(correctVolcanoes.length),
                            isPerfect:
                                correctVolcanoes.length == _volcanoes.length,
                            onProceed: () => context.go(AppRoutes.menu),
                          )
                        : _InvestigationContent(
                            volcano: currentVolcano!,
                            completedCount: completedCount,
                            totalCount: _volcanoes.length,
                            selectedClassification: _selectedClassification,
                            isSaving: _isSaving,
                            showCorrectEffects: _showCorrectEffects,
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
      _showCorrectEffects = isCorrect;
    });

    if (isCorrect) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) {
        return;
      }
    }

    if (widget.isReplay) {
      if (!_replayCompletedVolcanoes.contains(volcano.id)) {
        _replayCompletedVolcanoes.add(volcano.id);
      }
      if (isCorrect && !_replayCorrectVolcanoes.contains(volcano.id)) {
        _replayCorrectVolcanoes.add(volcano.id);
      }
    } else {
      await ref
          .read(playerProvider.notifier)
          .submitMissionSevenVolcano(
            volcanoId: volcano.id,
            isCorrect: isCorrect,
          );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedClassification = null;
      _isSaving = false;
      _showCorrectEffects = false;
    });
    showMissionSnackBar(
      context,
      widget.isReplay
          ? isCorrect
                ? 'Practice classification recorded'
                : 'Incorrect classification - correct answer: $correctAnswer'
          : isCorrect
          ? '+${AppConstants.missionSevenXpPerCorrect} XP recorded'
          : 'Incorrect classification - correct answer: $correctAnswer',
      isError: !isCorrect,
    );
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
  final bool isSaving;
  final bool showCorrectEffects;
  final ValueChanged<_VolcanoClassification> onSelect;
  final VoidCallback? onSubmit;

  const _InvestigationContent({
    required this.volcano,
    required this.completedCount,
    required this.totalCount,
    required this.selectedClassification,
    required this.isSaving,
    required this.showCorrectEffects,
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
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _VolcanoInvestigationCard(
                volcano: volcano,
                selectedClassification: selectedClassification,
                isSaving: isSaving,
                showCorrectEffects: showCorrectEffects,
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
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              side: BorderSide.none,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: onSubmit == null && !isSaving ? 0.45 : 1,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    Assets.missionAnalyzeVolcanoButton,
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                    filterQuality: FilterQuality.high,
                    excludeFromSemantics: true,
                  ),
                  if (isSaving)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  const Opacity(opacity: 0, child: Text('ANALYZE VOLCANO')),
                ],
              ),
            ),
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
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _TelemetryCell(
                    label: 'CLASSIFIED',
                    value: '$completedCount/$totalCount',
                  ),
                ),
                const Expanded(
                  child: _TelemetryCell(label: 'EACH', value: '10 XP'),
                ),
                const Expanded(
                  child: _TelemetryCell(label: 'TOTAL', value: '60 XP'),
                ),
              ],
            ),
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
  final bool showCorrectEffects;
  final ValueChanged<_VolcanoClassification> onSelect;

  const _VolcanoInvestigationCard({
    required this.volcano,
    required this.selectedClassification,
    required this.isSaving,
    required this.showCorrectEffects,
    required this.onSelect,
  });

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
                  _VolcanoImage(
                    imagePath: volcano.imagePath,
                    semanticLabel: volcano.name,
                    showRadar: showCorrectEffects,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.tealDim,
                            width: 0.8,
                          ),
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
                    isGlowing: showCorrectEffects,
                  ),
                  const SizedBox(height: 5),
                  _MonitoringRow(
                    icon: Icons.air_outlined,
                    label: 'GAS EMISSIONS',
                    value: volcano.gasEmission,
                    isGlowing: showCorrectEffects,
                  ),
                  const SizedBox(height: 5),
                  _MonitoringRow(
                    icon: Icons.graphic_eq_outlined,
                    label: 'SEISMIC ACTIVITY',
                    value: volcano.seismicActivity,
                    isGlowing: showCorrectEffects,
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: _ClassificationButton(
                          key: ValueKey('mission7-${volcano.id}-active'),
                          label: 'ACTIVE',
                          isSelected:
                              selectedClassification ==
                              _VolcanoClassification.active,
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
                              selectedClassification ==
                              _VolcanoClassification.inactive,
                          isEnabled: !isSaving,
                          onTap: () =>
                              onSelect(_VolcanoClassification.inactive),
                        ),
                      ),
                    ],
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

class _VolcanoImage extends StatelessWidget {
  final String imagePath;
  final String semanticLabel;
  final bool showRadar;

  const _VolcanoImage({
    required this.imagePath,
    required this.semanticLabel,
    required this.showRadar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('mission7-volcano-image-placeholder'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.borderAlt, width: 3),
        borderRadius: BorderRadius.circular(7),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Image.asset(
            imagePath,
            width: double.infinity,
            fit: BoxFit.fitWidth,
            filterQuality: FilterQuality.high,
            semanticLabel: semanticLabel,
          ),
          if (showRadar)
            const Positioned.fill(
              child: _VolcanoRadarEffect(
                key: ValueKey('mission7-volcano-radar-effect'),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonitoringRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isGlowing;

  const _MonitoringRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isGlowing,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      key: ValueKey('mission7-monitor-$label'),
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: isGlowing
            ? AppColors.teal.withValues(alpha: 0.12)
            : Colors.transparent,
        border: Border.all(
          color: isGlowing
              ? AppColors.teal.withValues(alpha: 0.82)
              : Colors.transparent,
        ),
        boxShadow: isGlowing
            ? [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.42),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: isGlowing ? AppColors.teal : AppColors.tealDim,
            size: 14,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: TextStyle(
                color: isGlowing ? AppColors.teal : AppColors.textMuted,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isGlowing
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VolcanoRadarEffect extends StatelessWidget {
  const _VolcanoRadarEffect({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) {
        return CustomPaint(
          painter: _VolcanoRadarPainter(progress),
          child: child,
        );
      },
      child: const SizedBox.expand(),
    );
  }
}

class _VolcanoRadarPainter extends CustomPainter {
  final double progress;

  const _VolcanoRadarPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.52);
    final radius = size.shortestSide * 0.36;
    final glowPaint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.22 * (1 - progress * 0.35))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * progress, glowPaint);

    final ringPaint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.9 * (1 - progress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius * progress, ringPaint);
    canvas.drawCircle(center, radius * progress * 0.66, ringPaint);

    final sweepPaint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.82)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final angle = progress * 6.283185307179586;
    canvas.drawLine(
      center,
      center + Offset.fromDirection(angle, radius),
      sweepPaint,
    );
    canvas.drawCircle(
      center,
      4,
      Paint()..color = AppColors.textPrimary.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _VolcanoRadarPainter oldDelegate) {
    return oldDelegate.progress != progress;
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
    final imagePath = label == _VolcanoClassification.active.label
        ? Assets.missionActiveButton
        : Assets.missionInactiveButton;
    final opacity = !isEnabled
        ? 0.45
        : isSelected
        ? 1.0
        : 0.72;

    return InkWell(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.65),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : const [],
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: opacity,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Image.asset(
                imagePath,
                width: double.infinity,
                fit: BoxFit.fitWidth,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true,
              ),
              if (isSelected)
                Positioned(
                  top: 2,
                  right: 4,
                  child: Container(
                    key: ValueKey(
                      'mission7-${label.toLowerCase()}-selected-indicator',
                    ),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.textPrimary,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.teal.withValues(alpha: 0.7),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.background,
                      size: 16,
                    ),
                  ),
                ),
              Opacity(opacity: 0, child: Text(label)),
            ],
          ),
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
        child: MissionCompletePanel(
          title: 'MISSION 7 COMPLETE!',
          badgeName: isPerfect
              ? 'Lava Bridge Champion Badge'
              : 'Investigation Review Complete',
          badgeImagePath: isPerfect ? Assets.badgeLavaBridgeChampion : null,
          fallbackIcon: Icons.analytics_outlined,
          message: isPerfect
              ? 'Congratulations, scientist. You earned the Lava Bridge Champion Badge.'
              : 'Investigation complete. No special badge earned this run.',
          metrics: [
            MissionCompleteMetric(
              label: 'SCORE',
              value: '$correctCount/$totalVolcanoes',
            ),
            MissionCompleteMetric(label: 'EARNED', value: '$earnedXP XP'),
          ],
          onProceed: onProceed,
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
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(0)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            minHeight: 6,
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
  final String imagePath;
  final _VolcanoClassification correctClassification;
  final String eruptionRecord;
  final String gasEmission;
  final String seismicActivity;

  const _InvestigationVolcano({
    required this.id,
    required this.name,
    required this.tag,
    required this.imagePath,
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
