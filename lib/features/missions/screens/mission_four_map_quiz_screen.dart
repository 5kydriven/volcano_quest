import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../player/application/player_controller.dart';

class MissionFourMapQuizScreen extends ConsumerStatefulWidget {
  final int levelId;

  const MissionFourMapQuizScreen({super.key, required this.levelId});

  @override
  ConsumerState<MissionFourMapQuizScreen> createState() =>
      _MissionFourMapQuizScreenState();
}

class _MissionFourMapQuizScreenState
    extends ConsumerState<MissionFourMapQuizScreen> {
  _MissionFourVolcano? _selectedVolcano;
  var _showQuestion = false;
  int? _selectedOptionIndex;
  var _submitted = false;
  var _isSaving = false;
  var _lastAnswerCorrect = false;

  static final _volcanoes = [
    _MissionFourVolcano(
      id: AppConstants.missionFourVolcanoIds[0],
      name: 'Mayon Volcano',
      tag: 'ALBAY, LUZON',
      mapX: 0.57,
      mapY: 0.31,
      facts: const [
        'Active volcano',
        'Located in Albay, Luzon',
        'Famous for its perfect cone shape',
      ],
      question: 'Why is Mayon Volcano famous?',
      options: const [
        'Tallest volcano',
        'Perfect cone shape',
        'Biggest crater',
      ],
      correctOptionIndex: 1,
    ),
    _MissionFourVolcano(
      id: AppConstants.missionFourVolcanoIds[1],
      name: 'Mount Apo',
      tag: 'MINDANAO',
      mapX: 0.63,
      mapY: 0.78,
      facts: const [
        'Highest mountain in the Philippines',
        'Located in Mindanao',
        'Dormant stratovolcano',
      ],
      question: 'What is the highest mountain in the Philippines?',
      options: const ['Mount Apo', 'Mount Makiling', 'Taal Volcano'],
      correctOptionIndex: 0,
    ),
    _MissionFourVolcano(
      id: AppConstants.missionFourVolcanoIds[2],
      name: 'Mount Makiling',
      tag: 'LAGUNA',
      mapX: 0.47,
      mapY: 0.25,
      facts: const ['Inactive volcano', 'Located in Laguna', 'Has hot springs'],
      question: 'Is Mount Makiling active or inactive?',
      options: const ['Active', 'Inactive', 'Extinct'],
      correctOptionIndex: 1,
    ),
    _MissionFourVolcano(
      id: AppConstants.missionFourVolcanoIds[3],
      name: 'Taal Volcano',
      tag: 'BATANGAS',
      mapX: 0.38,
      mapY: 0.36,
      facts: const [
        'Located in Batangas',
        'One of the most active volcanoes',
        'Known as a danger zone',
      ],
      question: 'Where is Taal Volcano located?',
      options: const ['Albay', 'Batangas', 'Davao'],
      correctOptionIndex: 1,
    ),
    _MissionFourVolcano(
      id: AppConstants.missionFourVolcanoIds[4],
      name: 'Mount Pinatubo',
      tag: 'ZAMBALES AREA',
      mapX: 0.34,
      mapY: 0.17,
      facts: const [
        'Active stratovolcano',
        'Located in Zambales area',
        'Popular trekking site',
      ],
      question: 'What activity is Mount Pinatubo popular for?',
      options: const ['Swimming', 'Trekking', 'Fishing'],
      correctOptionIndex: 1,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final answeredIds =
        player.completedMissionOrbs[AppConstants.missionFourId] ?? const [];
    final correctIds =
        player.completedMissionOrbs[AppConstants.missionFourCorrectAnswersId] ??
        const [];
    final allAnswered = AppConstants.missionFourVolcanoIds.every(
      answeredIds.contains,
    );
    final progress =
        answeredIds.length.clamp(0, _volcanoes.length) / _volcanoes.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: Column(
            children: [
              _MissionFourTopBar(
                missionId: widget.levelId,
                xp: player.totalXP,
                avatarIndex: player.avatarIndex,
                onBack: _handleBack,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _MissionFourPanel(
                  progress: allAnswered ? 1 : progress,
                  percentComplete: allAnswered ? 100 : (progress * 100).round(),
                  child: allAnswered
                      ? _MissionFourSummary(
                          correctCount: correctIds.length,
                          totalVolcanoes: _volcanoes.length,
                          earnedXP:
                              correctIds.length *
                              AppConstants.missionFourXpPerCorrect,
                          isPerfect: correctIds.length == _volcanoes.length,
                          onProceed: () => context.push(AppRoutes.level(5)),
                        )
                      : _selectedVolcano == null
                      ? _VolcanoMapContent(
                          volcanoes: _volcanoes,
                          answeredIds: answeredIds,
                          correctIds: correctIds,
                          onSelect: _selectVolcano,
                        )
                      : _showQuestion
                      ? _VolcanoQuestionContent(
                          volcano: _selectedVolcano!,
                          selectedOptionIndex: _selectedOptionIndex,
                          submitted: _submitted,
                          isSaving: _isSaving,
                          lastAnswerCorrect: _lastAnswerCorrect,
                          onSelect: _submitted || _isSaving
                              ? null
                              : (index) {
                                  setState(() {
                                    _selectedOptionIndex = index;
                                  });
                                },
                          onSubmit: _submitAnswer,
                          onBackToMap: _returnToMap,
                        )
                      : _VolcanoFactContent(
                          volcano: _selectedVolcano!,
                          onNext: () {
                            setState(() {
                              _showQuestion = true;
                              _selectedOptionIndex = null;
                            });
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectVolcano(_MissionFourVolcano volcano) {
    setState(() {
      _selectedVolcano = volcano;
      _showQuestion = false;
      _selectedOptionIndex = null;
      _submitted = false;
      _lastAnswerCorrect = false;
    });
  }

  void _returnToMap() {
    setState(() {
      _selectedVolcano = null;
      _showQuestion = false;
      _selectedOptionIndex = null;
      _submitted = false;
      _lastAnswerCorrect = false;
    });
  }

  void _handleBack() {
    if (_selectedVolcano != null && !_isSaving) {
      _returnToMap();
      return;
    }

    final context = this.context;
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.menu);
  }

  Future<void> _submitAnswer() async {
    final volcano = _selectedVolcano;
    final selected = _selectedOptionIndex;
    if (volcano == null || selected == null || _submitted || _isSaving) {
      return;
    }

    final isCorrect = selected == volcano.correctOptionIndex;
    setState(() {
      _isSaving = true;
    });

    await ref
        .read(playerProvider.notifier)
        .submitMissionFourAnswer(volcanoId: volcano.id, isCorrect: isCorrect);

    if (!mounted) {
      return;
    }

    setState(() {
      _submitted = true;
      _lastAnswerCorrect = isCorrect;
      _isSaving = false;
    });
  }
}

class _MissionFourTopBar extends StatelessWidget {
  final int missionId;
  final int xp;
  final int avatarIndex;
  final VoidCallback onBack;

  const _MissionFourTopBar({
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

class _MissionFourPanel extends StatelessWidget {
  final double progress;
  final int percentComplete;
  final Widget child;

  const _MissionFourPanel({
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
                const Positioned.fill(child: _MissionFourGrid()),
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

class _VolcanoMapContent extends StatelessWidget {
  final List<_MissionFourVolcano> volcanoes;
  final List<String> answeredIds;
  final List<String> correctIds;
  final ValueChanged<_MissionFourVolcano> onSelect;

  const _VolcanoMapContent({
    required this.volcanoes,
    required this.answeredIds,
    required this.correctIds,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ScannerLabel(text: 'PHILIPPINE VOLCANO MAP'),
        const SizedBox(height: 10),
        const Text(
          'Tap a volcano marker to inspect its field notes.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.35,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: _PhilippineMapPlaceholder(
            volcanoes: volcanoes,
            answeredIds: answeredIds,
            correctIds: correctIds,
            onSelect: onSelect,
          ),
        ),
        const SizedBox(height: 12),
        _MapLegend(answeredCount: answeredIds.length, total: volcanoes.length),
      ],
    );
  }
}

class _PhilippineMapPlaceholder extends StatelessWidget {
  final List<_MissionFourVolcano> volcanoes;
  final List<String> answeredIds;
  final List<String> correctIds;
  final ValueChanged<_MissionFourVolcano> onSelect;

  const _PhilippineMapPlaceholder({
    required this.volcanoes,
    required this.answeredIds,
    required this.correctIds,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.92),
            border: Border.all(color: AppColors.borderAlt, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _MapShapePainter())),
              const Positioned(
                left: 14,
                top: 12,
                child: Text(
                  'PHILIPPINE MAP',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              for (final volcano in volcanoes)
                Positioned(
                  left: (width * volcano.mapX - 28).clamp(6, width - 62),
                  top: (height * volcano.mapY - 28).clamp(32, height - 70),
                  child: _VolcanoMarker(
                    volcano: volcano,
                    isAnswered: answeredIds.contains(volcano.id),
                    isCorrect: correctIds.contains(volcano.id),
                    onTap: answeredIds.contains(volcano.id)
                        ? null
                        : () => onSelect(volcano),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _VolcanoMarker extends StatelessWidget {
  final _MissionFourVolcano volcano;
  final bool isAnswered;
  final bool isCorrect;
  final VoidCallback? onTap;

  const _VolcanoMarker({
    required this.volcano,
    required this.isAnswered,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAnswered
        ? isCorrect
              ? AppColors.teal
              : const Color(0xFFFFB3B3)
        : const Color(0xFFFFC857);

    return InkWell(
      key: ValueKey('mission4-volcano-${volcano.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isAnswered ? 0.14 : 0.18),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                isAnswered
                    ? isCorrect
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined
                    : Icons.terrain_outlined,
                color: color,
                size: 21,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              volcano.name.replaceFirst(' Volcano', ''),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  final int answeredCount;
  final int total;

  const _MapLegend({required this.answeredCount, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.terrain_outlined, color: Color(0xFFFFC857), size: 15),
        const SizedBox(width: 8),
        Text(
          '$answeredCount/$total VOLCANOES CHECKED',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _VolcanoFactContent extends StatelessWidget {
  final _MissionFourVolcano volcano;
  final VoidCallback onNext;

  const _VolcanoFactContent({required this.volcano, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _ScannerLabel(text: volcano.tag),
              const SizedBox(height: 14),
              Text(
                volcano.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  height: 1.18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'FACTS',
                style: TextStyle(
                  color: AppColors.teal,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              for (final fact in volcano.facts) ...[
                _FactBullet(text: fact),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(onPressed: onNext, child: const Text('NEXT')),
        ),
      ],
    );
  }
}

class _VolcanoQuestionContent extends StatelessWidget {
  final _MissionFourVolcano volcano;
  final int? selectedOptionIndex;
  final bool submitted;
  final bool isSaving;
  final bool lastAnswerCorrect;
  final ValueChanged<int>? onSelect;
  final VoidCallback onSubmit;
  final VoidCallback onBackToMap;

  const _VolcanoQuestionContent({
    required this.volcano,
    required this.selectedOptionIndex,
    required this.submitted,
    required this.isSaving,
    required this.lastAnswerCorrect,
    required this.onSelect,
    required this.onSubmit,
    required this.onBackToMap,
  });

  @override
  Widget build(BuildContext context) {
    final canSubmit = selectedOptionIndex != null && !isSaving;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _ScannerLabel(text: 'FIELD QUESTION'),
              const SizedBox(height: 14),
              Text(
                volcano.question,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 21,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${volcano.name.toUpperCase()} - ${AppConstants.missionFourXpPerCorrect} XP',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 20),
              for (var index = 0; index < volcano.options.length; index++) ...[
                _AnswerOptionTile(
                  letter: String.fromCharCode(65 + index),
                  text: volcano.options[index],
                  isSelected: selectedOptionIndex == index,
                  isSubmitted: submitted,
                  isCorrect: volcano.correctOptionIndex == index,
                  onTap: onSelect == null ? null : () => onSelect!(index),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        if (submitted) ...[
          const SizedBox(height: 10),
          _AnswerFeedback(
            isCorrect: lastAnswerCorrect,
            correctAnswer: volcano.options[volcano.correctOptionIndex],
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: submitted
                ? onBackToMap
                : canSubmit
                ? onSubmit
                : null,
            child: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.teal,
                    ),
                  )
                : Text(submitted ? 'BACK TO MAP' : 'SUBMIT ANSWER'),
          ),
        ),
      ],
    );
  }
}

class _AnswerOptionTile extends StatelessWidget {
  final String letter;
  final String text;
  final bool isSelected;
  final bool isSubmitted;
  final bool isCorrect;
  final VoidCallback? onTap;

  const _AnswerOptionTile({
    required this.letter,
    required this.text,
    required this.isSelected,
    required this.isSubmitted,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showCorrect = isSubmitted && isCorrect;
    final showWrong = isSubmitted && isSelected && !isCorrect;
    final borderColor = showCorrect
        ? AppColors.teal
        : showWrong
        ? const Color(0xFFFF7A7A)
        : isSelected
        ? AppColors.tealDim
        : AppColors.borderAlt;
    final backgroundColor = showCorrect
        ? AppColors.teal.withValues(alpha: 0.18)
        : showWrong
        ? const Color(0xFFFF7A7A).withValues(alpha: 0.12)
        : isSelected
        ? AppColors.surfaceAlt.withValues(alpha: 0.88)
        : const Color(0xFF1B2A36);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (showCorrect)
              const Icon(Icons.check, color: AppColors.teal, size: 18)
            else if (showWrong)
              const Icon(Icons.close, color: Color(0xFFFF7A7A), size: 18),
          ],
        ),
      ),
    );
  }
}

class _MissionFourSummary extends StatelessWidget {
  final int correctCount;
  final int totalVolcanoes;
  final int earnedXP;
  final bool isPerfect;
  final VoidCallback onProceed;

  const _MissionFourSummary({
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
                child: const Icon(
                  Icons.public_outlined,
                  color: AppColors.teal,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'MISSION 4 COMPLETE',
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
                'PHILIPPINE VOLCANO EXPLORER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.teal,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              if (isPerfect) ...[
                const SizedBox(height: 6),
                const Text(
                  'VOLCANO EXPLORER CHAMPION',
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
                  child: const Text('PROCEED TO MISSION 5'),
                ),
              ),
            ],
          ),
        ),
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

class _FactBullet extends StatelessWidget {
  final String text;

  const _FactBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 7),
          child: Icon(Icons.circle, color: AppColors.teal, size: 6),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.42,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnswerFeedback extends StatelessWidget {
  final bool isCorrect;
  final String correctAnswer;

  const _AnswerFeedback({required this.isCorrect, required this.correctAnswer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        border: Border.all(
          color: isCorrect ? AppColors.teal : const Color(0xFFFF7A7A),
          width: 0.8,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isCorrect
            ? '+${AppConstants.missionFourXpPerCorrect} XP RECORDED'
            : 'Correct answer: $correctAnswer',
        style: TextStyle(
          color: isCorrect ? AppColors.teal : const Color(0xFFFFB3B3),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
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

class _MissionFourGrid extends StatelessWidget {
  const _MissionFourGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MissionFourGridPainter());
  }
}

class _MissionFourGridPainter extends CustomPainter {
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

class _MapShapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final islandPaint = Paint()
      ..color = AppColors.surfaceAlt.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = AppColors.tealDim.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final luzon = Path()
      ..moveTo(size.width * 0.36, size.height * 0.08)
      ..quadraticBezierTo(
        size.width * 0.57,
        size.height * 0.08,
        size.width * 0.55,
        size.height * 0.28,
      )
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.44,
        size.width * 0.37,
        size.height * 0.39,
      )
      ..quadraticBezierTo(
        size.width * 0.24,
        size.height * 0.27,
        size.width * 0.36,
        size.height * 0.08,
      );
    final visayas = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.35,
            size.height * 0.45,
            size.width * 0.24,
            size.height * 0.13,
          ),
          const Radius.circular(24),
        ),
      );
    final mindanao = Path()
      ..moveTo(size.width * 0.49, size.height * 0.66)
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.61,
        size.width * 0.75,
        size.height * 0.82,
      )
      ..quadraticBezierTo(
        size.width * 0.59,
        size.height * 0.94,
        size.width * 0.43,
        size.height * 0.85,
      )
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.73,
        size.width * 0.49,
        size.height * 0.66,
      );

    for (final path in [luzon, visayas, mindanao]) {
      canvas.drawPath(path, islandPaint);
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MissionFourVolcano {
  final String id;
  final String name;
  final String tag;
  final double mapX;
  final double mapY;
  final List<String> facts;
  final String question;
  final List<String> options;
  final int correctOptionIndex;

  const _MissionFourVolcano({
    required this.id,
    required this.name,
    required this.tag,
    required this.mapX,
    required this.mapY,
    required this.facts,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
  });
}
