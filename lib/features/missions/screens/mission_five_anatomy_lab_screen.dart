import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
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

final missionFiveModelPreviewProvider = Provider<Widget?>((ref) => null);

class MissionFiveAnatomyLabScreen extends ConsumerStatefulWidget {
  final int levelId;
  final Widget? modelPreview;
  final bool isReplay;

  const MissionFiveAnatomyLabScreen({
    super.key,
    required this.levelId,
    this.modelPreview,
    this.isReplay = false,
  });

  @override
  ConsumerState<MissionFiveAnatomyLabScreen> createState() =>
      _MissionFiveAnatomyLabScreenState();
}

class _MissionFiveAnatomyLabScreenState
    extends ConsumerState<MissionFiveAnatomyLabScreen> {
  final _placedLabels = <String, String>{};
  String? _selectedLabelId;
  var _isSaving = false;
  var _showSummary = false;
  final _replayCompletedParts = <String>[];

  static const _parts = [
    _AnatomyPart(
      id: 'ash_cloud',
      label: 'ash cloud',
      x: 0.52,
      y: 0.09,
      icon: Icons.cloud_outlined,
    ),
    _AnatomyPart(
      id: 'crater',
      label: 'crater',
      x: 0.51,
      y: 0.23,
      icon: Icons.radio_button_unchecked,
    ),
    _AnatomyPart(
      id: 'main_vent',
      label: 'main vent',
      x: 0.51,
      y: 0.48,
      icon: Icons.arrow_upward,
    ),
    _AnatomyPart(
      id: 'secondary_vent',
      label: 'secondary vent',
      x: 0.69,
      y: 0.42,
      icon: Icons.call_split_outlined,
    ),
    _AnatomyPart(
      id: 'lava_flow',
      label: 'lava flow',
      x: 0.73,
      y: 0.30,
      icon: Icons.local_fire_department_outlined,
    ),
    _AnatomyPart(
      id: 'magma_chamber',
      label: 'magma chamber',
      x: 0.49,
      y: 0.76,
      icon: Icons.bubble_chart_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final completedParts = widget.isReplay
        ? _replayCompletedParts
        : player.completedMissionOrbs[AppConstants.missionFiveId] ?? const [];
    final alreadyCompleted = AppConstants.missionFiveAnatomyPartIds.every(
      completedParts.contains,
    );
    final shouldShowSummary = _showSummary || alreadyCompleted;
    final modelPreview =
        widget.modelPreview ?? ref.watch(missionFiveModelPreviewProvider);
    final placedCount = shouldShowSummary
        ? _parts.length
        : _placedLabels.length.clamp(0, _parts.length);
    final progress = placedCount / _parts.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: MissionScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
            child: Column(
              children: [
                _AnatomyTopBar(
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
                  child: _AnatomyPanel(
                    progress: progress,
                    percentComplete: (progress * 100).round(),
                    child: shouldShowSummary
                        ? _MissionFiveSummary(
                            earnedXP: widget.isReplay
                                ? 0
                                : AppConstants.missionFiveXp,
                            onProceed: () => context.go(AppRoutes.menu),
                          )
                        : _AnatomyLabContent(
                            parts: _parts,
                            placedLabels: _placedLabels,
                            selectedLabelId: _selectedLabelId,
                            isSaving: _isSaving,
                            modelPreview:
                                modelPreview ?? const _VolcanoModelView(),
                            onSelectLabel: _selectLabel,
                            onTryPlaceLabel: _tryPlaceLabel,
                            onClear: _clearPlacements,
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

  void _selectLabel(String labelId) {
    if (_isSaving || _placedLabels.containsValue(labelId)) {
      return;
    }

    setState(() {
      _selectedLabelId = _selectedLabelId == labelId ? null : labelId;
    });
  }

  void _clearPlacements() {
    if (_isSaving) {
      return;
    }

    setState(() {
      _placedLabels.clear();
      _selectedLabelId = null;
    });
  }

  void _tryPlaceLabel({required String targetId, String? labelId}) {
    if (_isSaving || _placedLabels.containsKey(targetId)) {
      return;
    }

    final activeLabelId = labelId ?? _selectedLabelId;
    if (activeLabelId == null || _placedLabels.containsValue(activeLabelId)) {
      return;
    }

    final target = _parts.firstWhere((part) => part.id == targetId);
    final label = _parts.firstWhere((part) => part.id == activeLabelId);

    if (target.id != label.id) {
      setState(() {
        _selectedLabelId = null;
      });
      unawaited(ref.read(audioControllerProvider).playSfx(SfxCue.wrong));
      showMissionSnackBar(
        context,
        '${label.label} does not match ${target.label}',
        isError: true,
      );
      return;
    }

    final completed = _placedLabels.length + 1 == _parts.length;
    setState(() {
      _placedLabels[targetId] = activeLabelId;
      _selectedLabelId = null;
    });
    unawaited(ref.read(audioControllerProvider).playSfx(SfxCue.correct));
    showMissionSnackBar(
      context,
      completed ? 'Anatomy scan complete' : '${target.label} locked',
    );

    if (completed) {
      _completeMission();
    }
  }

  Future<void> _completeMission() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    if (widget.isReplay) {
      _replayCompletedParts
        ..clear()
        ..addAll(AppConstants.missionFiveAnatomyPartIds);
    } else {
      await ref.read(playerProvider.notifier).completeMissionFiveAnatomyLab();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
      _showSummary = true;
    });
  }
}

class _VolcanoModelView extends StatefulWidget {
  const _VolcanoModelView();

  @override
  State<_VolcanoModelView> createState() => _VolcanoModelViewState();
}

class _VolcanoModelViewState extends State<_VolcanoModelView> {
  final _controller = Flutter3DController();

  @override
  Widget build(BuildContext context) {
    return Flutter3DViewer(
      activeGestureInterceptor: true,
      enableTouch: true,
      progressBarColor: AppColors.teal,
      controller: _controller,
      src: Assets.volcano3dSection,
      onLoad: (_) {
        _controller.setCameraOrbit(0, 72, 2.65);
        _controller.setCameraTarget(0, 0, 0);
      },
    );
  }
}

class _AnatomyLabContent extends StatelessWidget {
  final List<_AnatomyPart> parts;
  final Map<String, String> placedLabels;
  final String? selectedLabelId;
  final bool isSaving;
  final Widget modelPreview;
  final ValueChanged<String> onSelectLabel;
  final void Function({required String targetId, String? labelId})
  onTryPlaceLabel;
  final VoidCallback onClear;

  const _AnatomyLabContent({
    required this.parts,
    required this.placedLabels,
    required this.selectedLabelId,
    required this.isSaving,
    required this.modelPreview,
    required this.onSelectLabel,
    required this.onTryPlaceLabel,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final remainingParts = parts
        .where((part) => !placedLabels.containsValue(part.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ScannerLabel(text: 'VOLCANO ANATOMY SCAN'),
        const SizedBox(height: 10),
        Expanded(
          child: _ModelDropZone(
            parts: parts,
            placedLabels: placedLabels,
            modelPreview: modelPreview,
            onTryPlaceLabel: onTryPlaceLabel,
          ),
        ),
        const SizedBox(height: 12),
        _TelemetryStrip(
          placedCount: placedLabels.length,
          totalCount: parts.length,
          selectedPart: selectedLabelId == null
              ? null
              : parts.firstWhere((part) => part.id == selectedLabelId),
        ),
        const SizedBox(height: 12),
        _LabelBank(
          labels: remainingParts,
          selectedLabelId: selectedLabelId,
          isSaving: isSaving,
          onSelectLabel: onSelectLabel,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _ClearPlacementsButton(
            isEnabled: placedLabels.isNotEmpty && !isSaving,
            onPressed: onClear,
          ),
        ),
      ],
    );
  }
}

class _ModelDropZone extends StatelessWidget {
  final List<_AnatomyPart> parts;
  final Map<String, String> placedLabels;
  final Widget modelPreview;
  final void Function({required String targetId, String? labelId})
  onTryPlaceLabel;

  const _ModelDropZone({
    required this.parts,
    required this.placedLabels,
    required this.modelPreview,
    required this.onTryPlaceLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.borderAlt, width: 1),
        borderRadius: BorderRadius.circular(7),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return Stack(
            children: [
              Positioned.fill(child: modelPreview),
              const Positioned.fill(child: _ModelShade()),
              for (final part in parts)
                Positioned(
                  left: (width * part.x - 52).clamp(6, width - 110),
                  top: (height * part.y - 20).clamp(6, height - 48),
                  child: _AnatomyDropTarget(
                    part: part,
                    isPlaced: placedLabels.containsKey(part.id),
                    onTryPlaceLabel: onTryPlaceLabel,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AnatomyDropTarget extends StatelessWidget {
  final _AnatomyPart part;
  final bool isPlaced;
  final void Function({required String targetId, String? labelId})
  onTryPlaceLabel;

  const _AnatomyDropTarget({
    required this.part,
    required this.isPlaced,
    required this.onTryPlaceLabel,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => !isPlaced,
      onAcceptWithDetails: (details) {
        onTryPlaceLabel(targetId: part.id, labelId: details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final borderColor = isPlaced
            ? AppColors.teal
            : isHovering
            ? const Color(0xFFFFC857)
            : AppColors.tealDim;

        return InkWell(
          key: ValueKey('mission5-target-${part.id}'),
          onTap: isPlaced ? null : () => onTryPlaceLabel(targetId: part.id),
          borderRadius: BorderRadius.circular(5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 104,
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: isPlaced
                  ? AppColors.tealDark.withValues(alpha: 0.9)
                  : AppColors.background.withValues(alpha: 0.68),
              border: Border.all(color: borderColor, width: 1),
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                if (isHovering || isPlaced)
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.24),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPlaced ? Icons.check_circle_outline : part.icon,
                  color: borderColor,
                  size: 13,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    isPlaced ? part.label : 'drop',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isPlaced
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LabelBank extends StatelessWidget {
  final List<_AnatomyPart> labels;
  final String? selectedLabelId;
  final bool isSaving;
  final ValueChanged<String> onSelectLabel;

  const _LabelBank({
    required this.labels,
    required this.selectedLabelId,
    required this.isSaving,
    required this.onSelectLabel,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _LabContainerPainter(),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 112),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          children: [
            Text(
              '${labels.length} LABELS READY',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final label in labels)
                  _LabelChip(
                    key: ValueKey('mission5-label-${label.id}'),
                    part: label,
                    isSelected: selectedLabelId == label.id,
                    isEnabled: !isSaving,
                    onTap: () => onSelectLabel(label.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClearPlacementsButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onPressed;

  const _ClearPlacementsButton({
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = isEnabled ? AppColors.teal : AppColors.textDim;
    final iconColor = isEnabled ? AppColors.textMuted : AppColors.textDim;

    return Opacity(
      opacity: isEnabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt.withValues(alpha: 0.72),
              image: const DecorationImage(
                image: AssetImage(Assets.missionOneButtonContainer),
                fit: BoxFit.fill,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restart_alt, color: iconColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  'CLEAR PLACEMENTS',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
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

class _LabelChip extends StatelessWidget {
  final _AnatomyPart part;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _LabelChip({
    super.key,
    required this.part,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color labelColor;
    if (!isEnabled) {
      labelColor = AppColors.textDim;
    } else if (isSelected) {
      labelColor = const Color(0xFFFFC857);
    } else {
      labelColor = AppColors.textPrimary;
    }

    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      constraints: const BoxConstraints(minWidth: 132),
      child: CustomPaint(
        painter: _LabelChipPainter(isSelected: isSelected),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Text(
            part.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: labelColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );

    return Draggable<String>(
      data: part.id,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.9, child: chip),
      ),
      childWhenDragging: Opacity(opacity: 0.28, child: chip),
      child: InkWell(onTap: isEnabled ? onTap : null, child: chip),
    );
  }
}

class _TelemetryStrip extends StatelessWidget {
  final int placedCount;
  final int totalCount;
  final _AnatomyPart? selectedPart;

  const _TelemetryStrip({
    required this.placedCount,
    required this.totalCount,
    required this.selectedPart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(Assets.missionFiveSelectedContainer),
          fit: BoxFit.fill,
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _TelemetryCell(value: '$placedCount/$totalCount')),
          const SizedBox(width: 8),
          Expanded(child: _TelemetryCell(value: selectedPart?.label ?? 'none')),
          const SizedBox(width: 8),
          const Expanded(child: _TelemetryCell(value: '40 XP')),
        ],
      ),
    );
  }
}

class _LabContainerPainter extends CustomPainter {
  const _LabContainerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.background, Color(0xFF1B100B)],
      ).createShader(rect);
    final border = Paint()
      ..color = AppColors.borderAlt
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final accent = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.72)
      ..strokeWidth = 1.2;

    canvas.drawRect(rect, fill);
    canvas.drawRect(rect.deflate(2), border);
    canvas.drawLine(const Offset(12, 10), const Offset(54, 10), accent);
    canvas.drawLine(
      Offset(size.width - 54, size.height - 10),
      Offset(size.width - 12, size.height - 10),
      accent,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LabelChipPainter extends CustomPainter {
  final bool isSelected;

  const _LabelChipPainter({required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()
      ..moveTo(8, 0)
      ..lineTo(size.width - 8, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width - 8, size.height)
      ..lineTo(8, size.height)
      ..lineTo(0, size.height / 2)
      ..close();
    final borderColor = isSelected ? const Color(0xFFFFC857) : AppColors.teal;
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.surfaceAlt.withValues(alpha: 0.88),
          AppColors.tealDark.withValues(alpha: 0.94),
        ],
      ).createShader(rect);
    final border = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 1.8 : 1.1;

    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);
    canvas.drawLine(
      const Offset(14, 4),
      Offset(size.width - 14, 4),
      Paint()
        ..color = borderColor.withValues(alpha: 0.35)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _LabelChipPainter oldDelegate) {
    return oldDelegate.isSelected != isSelected;
  }
}

class _TelemetryCell extends StatelessWidget {
  final String value;

  const _TelemetryCell({required this.value});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _MissionFiveSummary extends StatelessWidget {
  final int earnedXP;
  final VoidCallback onProceed;

  const _MissionFiveSummary({required this.earnedXP, required this.onProceed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: MissionCompletePanel(
          title: 'MISSION 5 COMPLETE!',
          badgeName: 'Magma Analyst Badge',
          badgeImagePath: Assets.badgeMagmaAnalyst,
          fallbackIcon: Icons.account_tree_outlined,
          message:
              'Congratulations, scientist. You earned the Magma Analyst Badge.',
          metrics: [
            const MissionCompleteMetric(label: 'LABELS', value: '6/6'),
            MissionCompleteMetric(label: 'EARNED', value: '$earnedXP XP'),
          ],
          onProceed: onProceed,
        ),
      ),
    );
  }
}

class _AnatomyTopBar extends StatelessWidget {
  final int missionId;
  final int xp;
  final int avatarIndex;
  final VoidCallback onBack;

  const _AnatomyTopBar({
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

class _AnatomyPanel extends StatelessWidget {
  final double progress;
  final int percentComplete;
  final Widget child;

  const _AnatomyPanel({
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
                const Positioned.fill(child: _AnatomyGrid()),
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

class _ModelShade extends StatelessWidget {
  const _ModelShade();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.1),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.34),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnatomyGrid extends StatelessWidget {
  const _AnatomyGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _AnatomyGridPainter());
  }
}

class _AnatomyGridPainter extends CustomPainter {
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

class _AnatomyPart {
  final String id;
  final String label;
  final double x;
  final double y;
  final IconData icon;

  const _AnatomyPart({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    required this.icon,
  });
}
