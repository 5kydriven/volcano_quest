import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/mission_screen_background.dart';
import '../../player/application/player_controller.dart';

class MissionNineAssessmentScreen extends ConsumerStatefulWidget {
  final int levelId;

  const MissionNineAssessmentScreen({super.key, required this.levelId});

  @override
  ConsumerState<MissionNineAssessmentScreen> createState() =>
      _MissionNineAssessmentScreenState();
}

class _MissionNineAssessmentScreenState
    extends ConsumerState<MissionNineAssessmentScreen> {
  var _questionIndex = 0;
  int? _selectedOptionIndex;
  var _submitted = false;
  var _isSaving = false;
  var _showSummary = false;

  static final _questions = [
    _AssessmentQuestion(
      id: AppConstants.missionNineQuestionIds[0],
      tag: 'VOLCANO SAFETY',
      question: 'Which statement is INCORRECT?',
      options: const [
        'Volcanoes give information about inner Earth.',
        'Volcanoes can be found on land and ocean floor.',
        'Volcanoes show precursory signs before eruption.',
        'Volcanoes that do not produce lava is not dangerous.',
      ],
      correctOptionIndex: 3,
    ),
    _AssessmentQuestion(
      id: AppConstants.missionNineQuestionIds[1],
      tag: 'VOLCANO PARTS',
      question:
          'What is the term used to represent the opening of the volcano where magma comes out?',
      options: const ['Chamber', 'Crater', 'Summit', 'Vent'],
      correctOptionIndex: 3,
    ),
    _AssessmentQuestion(
      id: AppConstants.missionNineQuestionIds[2],
      tag: 'VOLCANO TYPES',
      question:
          'Which type of volcano is formed from viscous or sticky lava that does not flow easily?',
      options: const [
        'Cinder cones',
        'Composite volcanoes',
        'Lava domes',
        'Shield volcanoes',
      ],
      correctOptionIndex: 2,
    ),
    _AssessmentQuestion(
      id: AppConstants.missionNineQuestionIds[3],
      tag: 'ACTIVE VOLCANOES',
      question:
          'Which of the following statements is CORRECT about active volcanoes?',
      options: const [
        'Active volcanoes do not have magma supply.',
        'Active volcanoes have no record of eruption.',
        'Active volcanoes erupted within the last 10,000 years.',
        'Active volcanoes show no volcanic activity at all.',
      ],
      correctOptionIndex: 2,
    ),
    _AssessmentQuestion(
      id: AppConstants.missionNineQuestionIds[4],
      tag: 'ERUPTION TYPES',
      question:
          'What type of eruption is characterized by extremely explosive gas and pyroclastic activity, like Mt. Pinatubo (1991)?',
      options: const ['Phreatic', 'Phreatomagmatic', 'Plinian', 'Strombolian'],
      correctOptionIndex: 2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final answeredIds =
        player.completedMissionOrbs[AppConstants.missionNineId] ?? const [];
    final correctIds =
        player.completedMissionOrbs[AppConstants.missionNineCorrectAnswersId] ??
        const [];
    final allAnswered = AppConstants.missionNineQuestionIds.every(
      answeredIds.contains,
    );
    final shouldShowSummary = _showSummary || (allAnswered && !_submitted);
    final displayIndex = shouldShowSummary
        ? _questionIndex.clamp(0, _questions.length - 1)
        : _activeQuestionIndex(answeredIds);
    final progressCount = shouldShowSummary
        ? _questions.length
        : answeredIds.length.clamp(0, _questions.length);
    final progress = progressCount / _questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: MissionScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
            child: Column(
              children: [
                _AssessmentTopBar(
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
                  child: _AssessmentPanel(
                    progress: progress,
                    percentComplete: (progress * 100).round(),
                    child: shouldShowSummary
                        ? _AssessmentSummary(
                            playerName: player.name,
                            correctCount: correctIds.length,
                            totalQuestions: _questions.length,
                            onReturn: () => context.go(AppRoutes.menu),
                          )
                        : _AssessmentContent(
                            questionIndex: displayIndex,
                            totalQuestions: _questions.length,
                            question: _questions[displayIndex],
                            selectedOptionIndex: _selectedOptionIndex,
                            submitted: _submitted,
                            isSaving: _isSaving,
                            onSelect: _submitted || _isSaving
                                ? null
                                : (index) {
                                    setState(() {
                                      _selectedOptionIndex = index;
                                    });
                                  },
                            onAction: () => _handleAction(
                              _questions[displayIndex],
                              displayIndex,
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

  int _activeQuestionIndex(List<String> answeredIds) {
    if (_submitted) {
      return _questionIndex.clamp(0, _questions.length - 1);
    }

    final currentId = _questions[_questionIndex].id;
    if (!answeredIds.contains(currentId)) {
      return _questionIndex;
    }

    final nextOpenIndex = _questions.indexWhere(
      (question) => !answeredIds.contains(question.id),
    );
    if (nextOpenIndex == -1) {
      return _questions.length - 1;
    }
    return nextOpenIndex;
  }

  Future<void> _handleAction(
    _AssessmentQuestion question,
    int displayIndex,
  ) async {
    if (_submitted) {
      final isLastQuestion = displayIndex >= _questions.length - 1;
      setState(() {
        if (isLastQuestion) {
          _showSummary = true;
        } else {
          _questionIndex = displayIndex + 1;
          _selectedOptionIndex = null;
          _submitted = false;
        }
      });
      return;
    }

    final selected = _selectedOptionIndex;
    if (selected == null || _isSaving) {
      return;
    }

    final isCorrect = selected == question.correctOptionIndex;
    setState(() {
      _isSaving = true;
    });

    await ref
        .read(playerProvider.notifier)
        .submitMissionNineAnswer(questionId: question.id, isCorrect: isCorrect);

    if (!mounted) {
      return;
    }

    setState(() {
      _questionIndex = displayIndex;
      _submitted = true;
      _isSaving = false;
    });
    showMissionSnackBar(
      context,
      isCorrect
          ? 'Answer recorded'
          : 'Correct answer: ${question.options[question.correctOptionIndex]}',
      isError: !isCorrect,
    );
  }
}

class _AssessmentTopBar extends StatelessWidget {
  final int missionId;
  final int xp;
  final int avatarIndex;
  final VoidCallback onBack;

  const _AssessmentTopBar({
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

class _AssessmentPanel extends StatelessWidget {
  final double progress;
  final int percentComplete;
  final Widget child;

  const _AssessmentPanel({
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
                const Positioned.fill(child: _AssessmentGrid()),
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

class _AssessmentContent extends StatelessWidget {
  final int questionIndex;
  final int totalQuestions;
  final _AssessmentQuestion question;
  final int? selectedOptionIndex;
  final bool submitted;
  final bool isSaving;
  final ValueChanged<int>? onSelect;
  final VoidCallback onAction;

  const _AssessmentContent({
    required this.questionIndex,
    required this.totalQuestions,
    required this.question,
    required this.selectedOptionIndex,
    required this.submitted,
    required this.isSaving,
    required this.onSelect,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final canSubmit = selectedOptionIndex != null && !isSaving;
    final isLastQuestion = questionIndex >= totalQuestions - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const _ScannerLabel(text: 'FINAL ASSESSMENT'),
              const SizedBox(height: 8),
              _QuestionTag(text: question.tag),
              const SizedBox(height: 14),
              Text(
                question.question,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  height: 1.28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'QUESTION ${questionIndex + 1}/$totalQuestions',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 20),
              for (var index = 0; index < question.options.length; index++) ...[
                _AnswerOptionTile(
                  key: ValueKey('mission9-${question.id}-$index'),
                  letter: String.fromCharCode(65 + index),
                  text: question.options[index],
                  isSelected: selectedOptionIndex == index,
                  isSubmitted: submitted,
                  isCorrect: question.correctOptionIndex == index,
                  onTap: onSelect == null ? null : () => onSelect!(index),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: submitted || canSubmit ? onAction : null,
            child: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.teal,
                    ),
                  )
                : Text(
                    submitted
                        ? isLastQuestion
                              ? 'VIEW RESULTS'
                              : 'NEXT QUESTION'
                        : 'SUBMIT ANSWER',
                  ),
          ),
        ),
      ],
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
        const Icon(Icons.fact_check_outlined, color: AppColors.teal, size: 12),
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

class _QuestionTag extends StatelessWidget {
  final String text;

  const _QuestionTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.teal.withValues(alpha: 0.12),
          border: Border.all(color: AppColors.tealDim, width: 0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.teal,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
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
    super.key,
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
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.25,
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

class _AssessmentSummary extends StatelessWidget {
  final String playerName;
  final int correctCount;
  final int totalQuestions;
  final VoidCallback onReturn;

  const _AssessmentSummary({
    required this.playerName,
    required this.correctCount,
    required this.totalQuestions,
    required this.onReturn,
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
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.teal, width: 1),
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: AppColors.teal,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'MISSION 9 COMPLETE',
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
                'VOLCANO MASTER BADGE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.teal,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Congratulations, $playerName! You completed all missions.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _SummaryMetric(
                      label: 'SCORE',
                      value: '$correctCount/$totalQuestions',
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: _SummaryMetric(
                      label: 'EARNED',
                      value: '${AppConstants.missionNineXp} XP',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onReturn,
                  child: const Text('RETURN TO MENU'),
                ),
              ),
            ],
          ),
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

class _AssessmentGrid extends StatelessWidget {
  const _AssessmentGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _AssessmentGridPainter());
  }
}

class _AssessmentGridPainter extends CustomPainter {
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

class _AssessmentQuestion {
  final String id;
  final String tag;
  final String question;
  final List<String> options;
  final int correctOptionIndex;

  const _AssessmentQuestion({
    required this.id,
    required this.tag,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
  });
}
