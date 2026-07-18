import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class MissionNineAssessmentScreen extends ConsumerStatefulWidget {
  final int levelId;
  final bool isReplay;

  const MissionNineAssessmentScreen({
    super.key,
    required this.levelId,
    this.isReplay = false,
  });

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
  final _replayAnsweredIds = <String>[];
  final _replayCorrectIds = <String>[];

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
    final answeredIds = widget.isReplay
        ? _replayAnsweredIds
        : player.completedMissionOrbs[AppConstants.missionNineId] ?? const [];
    final correctIds = widget.isReplay
        ? _replayCorrectIds
        : player.completedMissionOrbs[AppConstants
                  .missionNineCorrectAnswersId] ??
              const [];
    final allAnswered = AppConstants.missionNineQuestionIds.every(
      answeredIds.contains,
    );
    final shouldShowSummary = _showSummary || allAnswered;
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
                            correctCount: correctIds.length,
                            totalQuestions: _questions.length,
                            earnedXP: widget.isReplay
                                ? 0
                                : AppConstants.missionNineXp,
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

    if (widget.isReplay) {
      if (!_replayAnsweredIds.contains(question.id)) {
        _replayAnsweredIds.add(question.id);
      }
      if (isCorrect && !_replayCorrectIds.contains(question.id)) {
        _replayCorrectIds.add(question.id);
      }
    } else {
      await ref
          .read(playerProvider.notifier)
          .submitMissionNineAnswer(
            questionId: question.id,
            isCorrect: isCorrect,
          );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _questionIndex = displayIndex;
      _submitted = true;
      _isSaving = false;
    });
    unawaited(
      ref
          .read(audioControllerProvider)
          .playSfx(isCorrect ? SfxCue.correct : SfxCue.wrong),
    );
    if (!isCorrect) {
      unawaited(HapticFeedback.vibrate());
    }
    showMissionSnackBar(
      context,
      widget.isReplay
          ? isCorrect
                ? 'Practice answer recorded'
                : 'Correct answer: ${question.options[question.correctOptionIndex]}'
          : isCorrect
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
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(0)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          MissionVolcanoProgressBar(value: progress),
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
                    padding: const EdgeInsets.fromLTRB(0, 26, 0, 18),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ScannerLabel(text: question.tag),
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
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 20),
              for (var index = 0; index < question.options.length; index++) ...[
                Builder(
                  builder: (context) {
                    final isSelected = selectedOptionIndex == index;
                    final isCorrect = question.correctOptionIndex == index;
                    final showCorrect = submitted && isCorrect;
                    final showWrong = submitted && isSelected && !isCorrect;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: onSelect == null ? null : () => onSelect!(index),
                        borderRadius: BorderRadius.zero,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: double.infinity,
                          height: 55,
                          clipBehavior: Clip.none,
                          child: Stack(
                            fit: StackFit.expand,
                            clipBehavior: Clip.none,
                            children: [
                              MissionAnswerContainer(
                                letter: String.fromCharCode(65 + index),
                                isSelected: isSelected && !submitted,
                                feedback: showCorrect
                                    ? MissionAnswerFeedback.correct
                                    : showWrong
                                    ? MissionAnswerFeedback.wrong
                                    : MissionAnswerFeedback.none,
                              ),
                              Positioned.fill(
                                child: FractionallySizedBox(
                                  widthFactor: 0.72,
                                  alignment: Alignment.centerRight,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      question.options[index],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.left,
                                      style: const TextStyle(
                                        color: Color(0xFF292828),
                                        fontSize: 18,
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
                                        fontSize: 18,
                                        height: 1,
                                        forceStrutHeight: true,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        _QuizActionButton(
          submitted: submitted,
          canSubmit: canSubmit,
          isSaving: isSaving,
          isLastQuestion: isLastQuestion,
          onPressed: submitted || canSubmit ? onAction : null,
        ),
      ],
    );
  }
}

class _QuizActionButton extends StatelessWidget {
  final bool submitted;
  final bool canSubmit;
  final bool isSaving;
  final bool isLastQuestion;
  final VoidCallback? onPressed;

  const _QuizActionButton({
    required this.submitted,
    required this.canSubmit,
    required this.isSaving,
    required this.isLastQuestion,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (submitted) {
      return _MissionImageActionButton(
        assetPath: isLastQuestion
            ? Assets.missionViewResultsButton
            : Assets.missionNextQuestionButton,
        semanticLabel: isLastQuestion ? 'VIEW RESULTS' : 'NEXT QUESTION',
        onPressed: onPressed,
      );
    }

    return _MissionImageActionButton(
      assetPath: Assets.missionSubmitAnswerButton,
      semanticLabel: 'SUBMIT ANSWER',
      onPressed: onPressed,
      opacity: canSubmit || isSaving ? 1 : 0.45,
      child: isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: AppColors.textPrimary,
              ),
            )
          : null,
    );
  }
}

class _MissionImageActionButton extends StatelessWidget {
  final String assetPath;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final double opacity;
  final Widget? child;

  const _MissionImageActionButton({
    required this.assetPath,
    required this.semanticLabel,
    required this.onPressed,
    this.opacity = 1,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          elevation: 0,
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          side: BorderSide.none,
          disabledForegroundColor: Colors.transparent,
          overlayColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Opacity(
          opacity: opacity,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
              ?child,
              Opacity(opacity: 0, child: Text(semanticLabel)),
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

class _AssessmentSummary extends StatelessWidget {
  final int correctCount;
  final int totalQuestions;
  final int earnedXP;
  final VoidCallback onReturn;

  const _AssessmentSummary({
    required this.correctCount,
    required this.totalQuestions,
    required this.earnedXP,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: MissionCompletePanel(
          title: 'MISSION 9 COMPLETE!',
          badgeName: 'Volcano Master Badge',
          badgeImagePath: Assets.badgeVolcanoMaster,
          fallbackIcon: Icons.local_fire_department_outlined,
          message:
              'Congratulations, scientist. You earned the Volcano Master Badge.',
          metrics: [
            MissionCompleteMetric(
              label: 'SCORE',
              value: '$correctCount/$totalQuestions',
            ),
            MissionCompleteMetric(label: 'EARNED', value: '$earnedXP XP'),
          ],
          onProceed: onReturn,
        ),
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
