import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../player/application/player_controller.dart';

class MissionSixVolcanoBuilderScreen extends ConsumerStatefulWidget {
  final int levelId;

  const MissionSixVolcanoBuilderScreen({super.key, required this.levelId});

  @override
  ConsumerState<MissionSixVolcanoBuilderScreen> createState() =>
      _MissionSixVolcanoBuilderScreenState();
}

class _MissionSixVolcanoBuilderScreenState
    extends ConsumerState<MissionSixVolcanoBuilderScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dropController;
  int? _selectedOptionIndex;
  String? _feedback;
  var _builtTileCount = 0;
  int? _droppingTileIndex;
  var _isSaving = false;
  var _showSummary = false;

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
    final completedParts =
        player.completedMissionOrbs[AppConstants.missionSixId] ?? const [];
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
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
                          earnedXP:
                              AppConstants.missionSixXp * _questions.length,
                          onProceed: () => context.push(AppRoutes.level(7)),
                        )
                      : _BuilderContent(
                          questionIndex: questionIndex,
                          totalQuestions: _questions.length,
                          question: _questions[questionIndex],
                          selectedOptionIndex: _selectedOptionIndex,
                          feedback: _feedback,
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
                                    _feedback = null;
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
    );
  }

  Future<void> _submitAnswer() async {
    final selected = _selectedOptionIndex;
    if (selected == null || _isSaving || _droppingTileIndex != null) {
      return;
    }

    final player = ref.read(playerProvider);
    final completedParts =
        player.completedMissionOrbs[AppConstants.missionSixId] ?? const [];
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
        _feedback = 'TYPE MISMATCH - TRY AGAIN';
      });
      return;
    }

    final tileIndex = builtTileCount;
    setState(() {
      _isSaving = true;
      _builtTileCount = tileIndex + 1;
      _droppingTileIndex = tileIndex;
      _selectedOptionIndex = null;
      _feedback = tileIndex == _questions.length - 1
          ? 'FINAL TILE LOCKED'
          : '+${AppConstants.missionSixXp} XP - VOLCANO PART LOCKED';
    });

    await ref
        .read(playerProvider.notifier)
        .completeMissionSixVolcanoBuilderPart(question.id);

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
  final String? feedback;
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
    required this.feedback,
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
                  letter: String.fromCharCode(65 + index),
                  text: answerOptions[index],
                  isSelected: selectedOptionIndex == index,
                  onTap: onSelect == null ? null : () => onSelect!(index),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        if (feedback != null) ...[
          const SizedBox(height: 8),
          _BuilderFeedback(text: feedback!),
        ],
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: selectedOptionIndex == null || isSaving
                ? null
                : onSubmit,
            child: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.teal,
                    ),
                  )
                : const Text('LOCK VOLCANO TYPE'),
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
  final String letter;
  final String text;
  final bool isSelected;
  final VoidCallback? onTap;

  const _BuilderAnswerTile({
    required this.letter,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? AppColors.teal : AppColors.borderAlt;
    final backgroundColor = isSelected
        ? AppColors.surfaceAlt.withValues(alpha: 0.88)
        : const Color(0xFF1B2A36);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: borderColor, width: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                letter,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuilderFeedback extends StatelessWidget {
  final String text;

  const _BuilderFeedback({required this.text});

  @override
  Widget build(BuildContext context) {
    final isError = text.contains('MISMATCH');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
          letterSpacing: 0.6,
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
                child: const Icon(
                  Icons.construction_outlined,
                  color: AppColors.teal,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'MISSION 6 COMPLETE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'VOLCANO ARCHITECT BADGE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.teal,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: _SummaryMetric(label: 'TILES', value: '5/5'),
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
                  child: const Text('PROCEED TO MISSION 7'),
                ),
              ),
            ],
          ),
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
