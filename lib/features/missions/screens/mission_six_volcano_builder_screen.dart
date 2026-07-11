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
import '../../../shared/widgets/mission_answer_container.dart';
import '../../../shared/widgets/mission_complete_panel.dart';
import '../../../shared/widgets/mission_screen_background.dart';
import '../../player/application/player_controller.dart';

class MissionSixVolcanoBuilderScreen extends ConsumerStatefulWidget {
  final int levelId;
  final bool isReplay;

  const MissionSixVolcanoBuilderScreen({
    super.key,
    required this.levelId,
    this.isReplay = false,
  });

  @override
  ConsumerState<MissionSixVolcanoBuilderScreen> createState() =>
      _MissionSixVolcanoBuilderScreenState();
}

class _MissionSixVolcanoBuilderScreenState
    extends ConsumerState<MissionSixVolcanoBuilderScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dropController;
  int? _selectedOptionIndex;
  var _builtTileCount = 0;
  int? _droppingTileIndex;
  var _isSaving = false;
  var _showSummary = false;
  final _replayCompletedParts = <String>[];

  static const _answerOptions = [
    'CINDER CONE',
    'SHIELD VOLCANO',
    'COMPOSITE VOLCANO',
  ];

  static final _questions = [
    _BuilderQuestion(
      id: AppConstants.missionSixBuilderPartIds[0],
      text: 'It is the most abundant and the simplest type of volcano.',
      correctAnswer: _VolcanoType.cinderCone,
    ),
    _BuilderQuestion(
      id: AppConstants.missionSixBuilderPartIds[1],
      text: 'It is built almost entirely of fluid lava flows.',
      correctAnswer: _VolcanoType.shieldVolcano,
    ),
    _BuilderQuestion(
      id: AppConstants.missionSixBuilderPartIds[2],
      text: "It is slightly domed structure that resembles a warrior's shield.",
      correctAnswer: _VolcanoType.shieldVolcano,
    ),
    _BuilderQuestion(
      id: AppConstants.missionSixBuilderPartIds[3],
      text: 'Mayon Volcano is an example of this type of volcano.',
      correctAnswer: _VolcanoType.compositeVolcano,
    ),
    _BuilderQuestion(
      id: AppConstants.missionSixBuilderPartIds[4],
      text: 'It has a steep slope and wide crater.',
      correctAnswer: _VolcanoType.cinderCone,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _dropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
  }

  @override
  void dispose() {
    _dropController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final completedParts = widget.isReplay
        ? _replayCompletedParts
        : player.completedMissionOrbs[AppConstants.missionSixId] ?? const [];
    final alreadyCompleted = AppConstants.missionSixBuilderPartIds.every(
      completedParts.contains,
    );
    final shouldShowSummary = _showSummary || alreadyCompleted;
    final savedTileCount = completedParts.length.clamp(0, _questions.length);
    final builtTileCount = alreadyCompleted
        ? _questions.length
        : _builtTileCount.clamp(savedTileCount, _questions.length);
    final questionIndex = builtTileCount.clamp(0, _questions.length - 1);
    final placedCount = shouldShowSummary
        ? _questions.length
        : builtTileCount.clamp(0, _questions.length);
    final progress = placedCount / _questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: MissionScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
            child: Column(
              children: [
                _BuilderTopBar(
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
                  child: _BuilderPanel(
                    progress: progress,
                    percentComplete: (progress * 100).round(),
                    child: shouldShowSummary
                        ? _BuilderSummary(
                            earnedXP: widget.isReplay
                                ? 0
                                : AppConstants.missionSixXp * _questions.length,
                            onProceed: () => context.go(AppRoutes.menu),
                          )
                        : _BuilderContent(
                            questionIndex: questionIndex,
                            totalQuestions: _questions.length,
                            question: _questions[questionIndex],
                            selectedOptionIndex: _selectedOptionIndex,
                            isSaving: _isSaving,
                            builtTileCount: builtTileCount,
                            droppingTileIndex: _droppingTileIndex,
                            dropAnimation: _dropController,
                            answerOptions: _answerOptions,
                            onSelect: _isSaving
                                ? null
                                : (index) {
                                    setState(() {
                                      _selectedOptionIndex = index;
                                    });
                                  },
                            onSubmit: _submitAnswer,
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

  Future<void> _submitAnswer() async {
    final selected = _selectedOptionIndex;
    if (selected == null || _isSaving || _droppingTileIndex != null) {
      return;
    }

    final player = ref.read(playerProvider);
    final completedParts = widget.isReplay
        ? _replayCompletedParts
        : player.completedMissionOrbs[AppConstants.missionSixId] ?? const [];
    final builtTileCount = _builtTileCount.clamp(
      completedParts.length.clamp(0, _questions.length),
      _questions.length,
    );
    final questionIndex = builtTileCount.clamp(0, _questions.length - 1);
    final question = _questions[questionIndex];
    final selectedType = _VolcanoType.values[selected];
    if (selectedType != question.correctAnswer) {
      setState(() {
        _selectedOptionIndex = null;
      });
      unawaited(ref.read(audioControllerProvider).playSfx(SfxCue.wrong));
      showMissionSnackBar(context, 'Type mismatch - try again', isError: true);
      return;
    }

    final tileIndex = builtTileCount;
    setState(() {
      _isSaving = true;
      _builtTileCount = tileIndex + 1;
      _droppingTileIndex = tileIndex;
      _selectedOptionIndex = null;
    });
    unawaited(ref.read(audioControllerProvider).playSfx(SfxCue.falling));
    showMissionSnackBar(
      context,
      widget.isReplay
          ? tileIndex == _questions.length - 1
                ? 'Practice volcano complete'
                : 'Practice tile locked'
          : tileIndex == _questions.length - 1
          ? 'Final tile locked'
          : '+${AppConstants.missionSixXp} XP - volcano part locked',
    );

    if (widget.isReplay) {
      if (!_replayCompletedParts.contains(question.id)) {
        _replayCompletedParts.add(question.id);
      }
    } else {
      await ref
          .read(playerProvider.notifier)
          .completeMissionSixVolcanoBuilderPart(question.id);
    }

    if (!mounted) {
      return;
    }

    await _dropController.forward(from: 0).orCancel;

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
      _droppingTileIndex = null;
    });

    final completed = tileIndex + 1 >= _questions.length;
    if (completed) {
      setState(() {
        _showSummary = true;
      });
      return;
    }

    setState(() {});
  }
}

class _BuilderContent extends StatelessWidget {
  final int questionIndex;
  final int totalQuestions;
  final _BuilderQuestion question;
  final int? selectedOptionIndex;
  final bool isSaving;
  final int builtTileCount;
  final int? droppingTileIndex;
  final Animation<double> dropAnimation;
  final List<String> answerOptions;
  final ValueChanged<int>? onSelect;
  final VoidCallback onSubmit;

  const _BuilderContent({
    required this.questionIndex,
    required this.totalQuestions,
    required this.question,
    required this.selectedOptionIndex,
    required this.isSaving,
    required this.builtTileCount,
    required this.droppingTileIndex,
    required this.dropAnimation,
    required this.answerOptions,
    required this.onSelect,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final canSubmit = selectedOptionIndex != null && !isSaving;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ScannerLabel(text: 'VOLCANO CONSTRUCTION SIMULATOR'),
        const SizedBox(height: 10),
        Expanded(
          flex: 5,
          child: _VolcanoBuildStage(
            builtTileCount: builtTileCount,
            droppingTileIndex: droppingTileIndex,
            dropAnimation: dropAnimation,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          flex: 6,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Text(
                question.text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  height: 1.28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'BUILD STEP ${questionIndex + 1}/$totalQuestions',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 14),
              for (var index = 0; index < answerOptions.length; index++) ...[
                _BuilderAnswerTile(
                  optionIndex: index,
                  text: answerOptions[index],
                  isSelected: selectedOptionIndex == index,
                  onTap: onSelect == null ? null : () => onSelect!(index),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Opacity(
          opacity: canSubmit || isSaving ? 1 : 0.48,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFB347), Color(0xFFFF6A00)],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF8F2D00), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66FF6A00),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: canSubmit ? onSubmit : null,
                child: Center(
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'LOCK VOLCANO TYPE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                            shadows: [
                              Shadow(color: Colors.black, offset: Offset(1, 1)),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VolcanoBuildStage extends StatelessWidget {
  final int builtTileCount;
  final int? droppingTileIndex;
  final Animation<double> dropAnimation;

  const _VolcanoBuildStage({
    required this.builtTileCount,
    required this.droppingTileIndex,
    required this.dropAnimation,
  });

  static const _slots = [
    _TileSlot(x: 0.25, y: 0.72, width: 0.28, height: 0.22),
    _TileSlot(x: 0.48, y: 0.72, width: 0.28, height: 0.22),
    _TileSlot(x: 0.34, y: 0.48, width: 0.22, height: 0.25),
    _TileSlot(x: 0.50, y: 0.48, width: 0.22, height: 0.25),
    _TileSlot(x: 0.42, y: 0.24, width: 0.20, height: 0.24),
  ];

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
              const Positioned.fill(child: _BuilderGrid()),
              Positioned(
                left: 12,
                top: 10,
                child: Text(
                  'PUZZLE TILES ${builtTileCount.clamp(0, _slots.length)}/${_slots.length}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              for (var index = 0; index < _slots.length; index++)
                _PositionedVolcanoTile(
                  key: ValueKey('mission6-tile-$index'),
                  slot: _slots[index],
                  stageWidth: width,
                  stageHeight: height,
                  index: index,
                  isVisible: index < builtTileCount,
                  isDropping: droppingTileIndex == index,
                  dropAnimation: dropAnimation,
                ),
              Positioned(
                left: width * 0.32,
                right: width * 0.32,
                bottom: 8,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.32),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PositionedVolcanoTile extends StatelessWidget {
  final _TileSlot slot;
  final double stageWidth;
  final double stageHeight;
  final int index;
  final bool isVisible;
  final bool isDropping;
  final Animation<double> dropAnimation;

  const _PositionedVolcanoTile({
    super.key,
    required this.slot,
    required this.stageWidth,
    required this.stageHeight,
    required this.index,
    required this.isVisible,
    required this.isDropping,
    required this.dropAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final tileWidth = stageWidth * slot.width;
    final tileHeight = stageHeight * slot.height;
    final left = stageWidth * slot.x;
    final targetTop = stageHeight * slot.y;

    if (!isVisible) {
      return Positioned(
        left: left,
        top: targetTop,
        child: Opacity(
          opacity: 0.16,
          child: _CrackedVolcanoTile(
            width: tileWidth,
            height: tileHeight,
            index: index,
            isGhost: true,
          ),
        ),
      );
    }

    if (!isDropping) {
      return Positioned(
        left: left,
        top: targetTop,
        child: _CrackedVolcanoTile(
          width: tileWidth,
          height: tileHeight,
          index: index,
        ),
      );
    }

    final curve = CurvedAnimation(
      parent: dropAnimation,
      curve: Curves.easeOutBack,
    );

    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) {
        final top = targetTop - stageHeight * 0.68 * (1 - curve.value);
        return Positioned(left: left, top: top, child: child!);
      },
      child: _CrackedVolcanoTile(
        width: tileWidth,
        height: tileHeight,
        index: index,
        isDropping: true,
      ),
    );
  }
}

class _CrackedVolcanoTile extends StatelessWidget {
  final double width;
  final double height;
  final int index;
  final bool isGhost;
  final bool isDropping;

  const _CrackedVolcanoTile({
    required this.width,
    required this.height,
    required this.index,
    this.isGhost = false,
    this.isDropping = false,
  });

  @override
  Widget build(BuildContext context) {
    final tileColors = [
      const Color(0xFF26333A),
      const Color(0xFF303A3C),
      const Color(0xFF405049),
      const Color(0xFF465650),
      const Color(0xFF5A3A35),
    ];
    final borderColor = isDropping ? const Color(0xFFFFC857) : AppColors.teal;

    return CustomPaint(
      painter: _CrackedTilePainter(
        fillColor: isGhost
            ? AppColors.surface
            : tileColors[index.clamp(0, tileColors.length - 1)],
        borderColor: isGhost ? AppColors.borderAlt : borderColor,
        crackColor: isGhost ? AppColors.border : const Color(0xFFFF8A4C),
        isGhost: isGhost,
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}

class _CrackedTilePainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final Color crackColor;
  final bool isGhost;

  const _CrackedTilePainter({
    required this.fillColor,
    required this.borderColor,
    required this.crackColor,
    required this.isGhost,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..color = fillColor.withValues(alpha: 0.94);
    final borderPaint = Paint()
      ..color = borderColor.withValues(alpha: isGhost ? 0.44 : 0.86)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final crackPaint = Paint()
      ..color = crackColor.withValues(alpha: isGhost ? 0.24 : 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.16)
      ..lineTo(size.width * 0.92, size.height * 0.08)
      ..lineTo(size.width * 0.86, size.height * 0.88)
      ..lineTo(size.width * 0.14, size.height * 0.94)
      ..close();
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);

    final crack = Path()
      ..moveTo(size.width * 0.24, size.height * 0.18)
      ..lineTo(size.width * 0.48, size.height * 0.42)
      ..lineTo(size.width * 0.40, size.height * 0.62)
      ..lineTo(size.width * 0.62, size.height * 0.86);
    canvas.drawPath(crack, crackPaint);
    canvas.drawLine(
      Offset(size.width * 0.48, size.height * 0.42),
      Offset(size.width * 0.70, size.height * 0.34),
      crackPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.40, size.height * 0.62),
      Offset(size.width * 0.18, size.height * 0.72),
      crackPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CrackedTilePainter oldDelegate) {
    return fillColor != oldDelegate.fillColor ||
        borderColor != oldDelegate.borderColor ||
        crackColor != oldDelegate.crackColor ||
        isGhost != oldDelegate.isGhost;
  }
}

class _BuilderAnswerTile extends StatelessWidget {
  final int optionIndex;
  final String text;
  final bool isSelected;
  final VoidCallback? onTap;

  const _BuilderAnswerTile({
    required this.optionIndex,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 50,
        decoration: const BoxDecoration(),
        clipBehavior: Clip.none,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            MissionAnswerContainer(
              letter: String.fromCharCode(65 + optionIndex),
              isSelected: isSelected,
            ),
            Positioned(
              left: 92,
              right: 22,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF351305),
                    fontSize: 17,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    shadows: [
                      Shadow(
                        color: Color(0x99FFF0C9),
                        offset: Offset(0, 1),
                        blurRadius: 0,
                      ),
                      Shadow(
                        color: Color(0x33000000),
                        offset: Offset(1, 1),
                        blurRadius: 1,
                      ),
                    ],
                  ),
                  strutStyle: const StrutStyle(
                    fontSize: 17,
                    height: 1,
                    forceStrutHeight: true,
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

class _BuilderSummary extends StatelessWidget {
  final int earnedXP;
  final VoidCallback onProceed;

  const _BuilderSummary({required this.earnedXP, required this.onProceed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: MissionCompletePanel(
          title: 'MISSION 6 COMPLETE!',
          badgeName: 'Volcano Architect Badge',
          badgeImagePath: Assets.badgeVolcanoArchitect,
          fallbackIcon: Icons.construction_outlined,
          message:
              'Congratulations, scientist. You earned the Volcano Architect Badge.',
          metrics: [
            const MissionCompleteMetric(label: 'TILES', value: '5/5'),
            MissionCompleteMetric(label: 'EARNED', value: '$earnedXP XP'),
          ],
          onProceed: onProceed,
        ),
      ),
    );
  }
}

class _BuilderTopBar extends StatelessWidget {
  final int missionId;
  final int xp;
  final int avatarIndex;
  final VoidCallback onBack;

  const _BuilderTopBar({
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

class _BuilderPanel extends StatelessWidget {
  final double progress;
  final int percentComplete;
  final Widget child;

  const _BuilderPanel({
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
                const Positioned.fill(child: _BuilderGrid()),
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

class _BuilderGrid extends StatelessWidget {
  const _BuilderGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BuilderGridPainter());
  }
}

class _BuilderGridPainter extends CustomPainter {
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

class _BuilderQuestion {
  final String id;
  final String text;
  final _VolcanoType correctAnswer;

  const _BuilderQuestion({
    required this.id,
    required this.text,
    required this.correctAnswer,
  });
}

class _TileSlot {
  final double x;
  final double y;
  final double width;
  final double height;

  const _TileSlot({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

enum _VolcanoType { cinderCone, shieldVolcano, compositeVolcano }
