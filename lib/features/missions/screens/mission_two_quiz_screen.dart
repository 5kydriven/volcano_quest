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

class MissionTwoQuizScreen extends ConsumerStatefulWidget {
  final int levelId;
  final bool isReplay;

  const MissionTwoQuizScreen({
    super.key,
    required this.levelId,
    this.isReplay = false,
  });

  @override
  ConsumerState<MissionTwoQuizScreen> createState() =>
      _MissionTwoQuizScreenState();
}

class _MissionTwoQuizScreenState extends ConsumerState<MissionTwoQuizScreen> {
  var _questionIndex = 0;
  int? _selectedOptionIndex;
  var _submitted = false;
  var _isSaving = false;
  var _showSummary = false;
  final _replayAnsweredIds = <String>[];
  final _replayCorrectIds = <String>[];

  static final _questions = [
    _MissionTwoQuestion(
      id: AppConstants.missionTwoQuestionIds[0],
      tag: 'VOLCANO STRUCTURE',
      question:
          "Which part of the volcano stores molten rock beneath the Earth's surface?",
      options: const ['Crater', 'Main vent', 'Magma chamber', 'Lava flow'],
      correctOptionIndex: 2,
      answerFeedback: const [
        'Incorrect. A crater is a bowl-shaped depression found at or near the top of a volcano. It is an opening where volcanic materials may be released during an eruption. It does not store molten rock beneath the Earth\'s surface.\n\nCorrect Answer: Magma Chamber.',
        'Incorrect. The main vent is the passage through which magma and volcanic materials travel toward the Earth\'s surface. It is not the underground storage area for molten rock.\n\nCorrect Answer: Magma Chamber.',
        'Correct! The magma chamber is an underground reservoir where molten rock, called magma, accumulates beneath a volcano. When pressure builds up, magma may move toward the surface and contribute to a volcanic eruption.',
        'Incorrect. A lava flow is molten rock that has erupted onto the Earth\'s surface and moves away from the volcano. It is not a storage area beneath the surface.\n\nCorrect Answer: Magma Chamber.',
      ],
    ),
    _MissionTwoQuestion(
      id: AppConstants.missionTwoQuestionIds[1],
      tag: 'VOLCANO TYPES',
      question:
          'Which type of volcano is formed from wide, thin layers of lava?',
      options: const [
        'Cinder cone',
        'Composite volcano',
        'Lava dome',
        'Shield volcano',
      ],
      correctOptionIndex: 3,
      answerFeedback: const [
        'Incorrect. A cinder cone is a small, steep-sided volcano formed mainly from loose volcanic fragments, such as cinders and ash, that accumulate around a volcanic vent.\n\nCorrect Answer: Shield Volcano.',
        'Incorrect. A composite volcano, also called a stratovolcano, is a steep-sided volcano made of alternating layers of lava, ash, and other volcanic materials.\n\nCorrect Answer: Shield Volcano.',
        'Incorrect. A lava dome forms when thick, sticky lava accumulates near a volcanic vent instead of flowing far from the volcano.\n\nCorrect Answer: Shield Volcano.',
        'Correct! A shield volcano is a broad, gently sloping volcano formed by repeated eruptions of fluid lava. Because the lava can flow over large distances, it builds up wide and relatively thin layers.',
      ],
    ),
    _MissionTwoQuestion(
      id: AppConstants.missionTwoQuestionIds[2],
      tag: 'BICOL REGION',
      question:
          'Which volcano in the Bicol Region is considered the most active?',
      options: const ['Isarog', 'Bulusan', 'Iriga', 'Mayon'],
      correctOptionIndex: 3,
      answerFeedback: const [
        'Incorrect. Mount Isarog is a volcano in Camarines Sur, but it is not considered the most active volcano in the Bicol Region.\n\nCorrect Answer: Mayon.',
        'Incorrect. Bulusan Volcano is an active volcano in Sorsogon and has experienced eruptions, but the expected answer to this question is Mayon Volcano, which is recognized for its frequent activity.\n\nCorrect Answer: Mayon.',
        'Incorrect. Mount Iriga, also known as Asog, is a volcanic mountain in Camarines Sur. It is not the volcano identified as the most active in the Bicol Region.\n\nCorrect Answer: Mayon.',
        'Correct! Mayon Volcano is located in Albay, Bicol Region, and is known for its frequent volcanic activity. It is also famous for its symmetrical cone shape. Its activity makes it an important volcano to monitor for possible eruptions.',
      ],
    ),
    _MissionTwoQuestion(
      id: AppConstants.missionTwoQuestionIds[3],
      tag: 'ERUPTION TYPES',
      question: 'Which volcanic eruption is characterized by lava fountains?',
      options: const [
        'Phreatic eruption',
        'Vulcanian eruption',
        'Strombolian eruption',
        'Plinian eruption',
      ],
      correctOptionIndex: 2,
      answerFeedback: const [
        'Incorrect. A phreatic eruption occurs when groundwater or surface water is heated rapidly by hot rock or magma, causing an explosive release of steam and fragmented rock. It is not primarily characterized by lava fountains.\n\nCorrect Answer: Strombolian Eruption.',
        'Incorrect. A Vulcanian eruption involves short, relatively powerful explosions that eject ash, rock fragments, and volcanic gases. Although lava may be involved, lava fountains are more characteristic of Strombolian eruptions.\n\nCorrect Answer: Strombolian Eruption.',
        'Correct! A Strombolian eruption is a type of volcanic eruption characterized by relatively short, explosive bursts that can produce lava fountains and eject volcanic materials into the air. The activity is commonly caused by gas bubbles rising through magma.',
        'Incorrect. A Plinian eruption is a highly explosive eruption that produces a tall column of ash and volcanic gases. It is not primarily characterized by lava fountains.\n\nCorrect Answer: Strombolian Eruption.',
      ],
    ),
    _MissionTwoQuestion(
      id: AppConstants.missionTwoQuestionIds[4],
      tag: 'ERUPTION WARNING',
      question:
          'Which of the following is a sign of an impending volcanic eruption?',
      options: const [
        'Occurrence of thunderstorms',
        'Volcanic tremors',
        'Calm weather',
        'Decrease in steam activity',
      ],
      correctOptionIndex: 1,
      answerFeedback: const [
        'Incorrect. Thunderstorms are weather phenomena caused by atmospheric conditions and are not, by themselves, a reliable sign that a volcanic eruption is about to occur.\n\nCorrect Answer: Volcanic Tremors.',
        'Correct! Volcanic tremors are continuous or repeated ground vibrations associated with the movement of magma and volcanic fluids beneath a volcano. An increase in volcanic tremors can be an important warning sign of possible volcanic activity.',
        'Incorrect. Calm weather describes relatively stable atmospheric conditions. It is not considered a warning sign of an impending volcanic eruption.\n\nCorrect Answer: Volcanic Tremors.',
        'Incorrect. A decrease in steam activity is not generally presented as a warning sign of an impending eruption. Changes or increases in volcanic gas and steam activity can provide information about changes occurring within a volcano.\n\nCorrect Answer: Volcanic Tremors.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final answeredIds = widget.isReplay
        ? _replayAnsweredIds
        : player.completedMissionOrbs[AppConstants.missionTwoId] ?? const [];
    final correctIds = widget.isReplay
        ? _replayCorrectIds
        : player.completedMissionOrbs[AppConstants
                  .missionTwoCorrectAnswersId] ??
              const [];
    final allAnswered = AppConstants.missionTwoQuestionIds.every(
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
                _QuizTopBar(
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
                  child: _QuizPanel(
                    progress: progress,
                    percentComplete: (progress * 100).round(),
                    child: shouldShowSummary
                        ? _QuizSummary(
                            correctCount: correctIds.length,
                            totalQuestions: _questions.length,
                            earnedXP: widget.isReplay
                                ? 0
                                : correctIds.length *
                                      AppConstants.missionTwoXpPerCorrect,
                            onProceed: () => context.go(AppRoutes.menu),
                          )
                        : _QuizContent(
                            questionIndex: displayIndex,
                            totalQuestions: _questions.length,
                            question: _questions[displayIndex],
                            selectedOptionIndex: _selectedOptionIndex,
                            submitted: _submitted,
                            isSaving: _isSaving,
                            onSelect: _submitted || _isSaving
                                ? null
                                : (index) {
                                    _playButtonSfx();
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

  void _playButtonSfx() {
    unawaited(ref.read(audioControllerProvider).playSfx(SfxCue.button));
  }

  Future<void> _handleAction(
    _MissionTwoQuestion question,
    int displayIndex,
  ) async {
    if (_submitted) {
      _playButtonSfx();
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

    _playButtonSfx();
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
          .submitMissionTwoAnswer(
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
          ? '+15 XP recorded'
          : 'Correct answer: ${question.options[question.correctOptionIndex]}',
      isError: !isCorrect,
    );
  }
}

class _QuizTopBar extends StatelessWidget {
  final int missionId;
  final int xp;
  final int avatarIndex;
  final VoidCallback onBack;

  const _QuizTopBar({
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

class _QuizPanel extends StatelessWidget {
  final double progress;
  final int percentComplete;
  final Widget child;

  const _QuizPanel({
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
                const Positioned.fill(child: _QuizGrid()),
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

class _QuizContent extends StatelessWidget {
  final int questionIndex;
  final int totalQuestions;
  final _MissionTwoQuestion question;
  final int? selectedOptionIndex;
  final bool submitted;
  final bool isSaving;
  final ValueChanged<int>? onSelect;
  final VoidCallback onAction;

  const _QuizContent({
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
    final feedbackOptions = question.answerFeedback;
    final selectedFeedback =
        submitted && selectedOptionIndex != null && feedbackOptions != null
        ? feedbackOptions[selectedOptionIndex!]
        : null;
    final selectedIsCorrect =
        selectedOptionIndex == question.correctOptionIndex;

    return Column(
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
                          height: 50,
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
                              Positioned(
                                left: 92,
                                right: showCorrect || showWrong ? 48 : 22,
                                top: 0,
                                bottom: 0,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    question.options[index],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF351305),
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

                              if (showCorrect || showWrong)
                                Positioned(
                                  right: 18,
                                  top: 0,
                                  bottom: 0,
                                  child: Icon(
                                    showCorrect ? Icons.check : Icons.close,
                                    color: showCorrect
                                        ? AppColors.teal
                                        : const Color(0xFFFF7A7A),
                                    size: 20,
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
              if (selectedFeedback != null) ...[
                const SizedBox(height: 4),
                _AnswerFeedbackPanel(
                  isCorrect: selectedIsCorrect,
                  feedback: selectedFeedback,
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        // Expanded(
        //   child: ListView(
        //     padding: EdgeInsets.zero,
        //     children: [
        //       const SizedBox(height: 20),
        //       for (var index = 0; index < question.options.length; index++) ...[
        //         _AnswerOptionTile(
        //           letter: String.fromCharCode(65 + index),
        //           text: question.options[index],
        //           isSelected: selectedOptionIndex == index,
        //           isSubmitted: submitted,
        //           isCorrect: question.correctOptionIndex == index,
        //           onTap: onSelect == null ? null : () => onSelect!(index),
        //         ),
        //       ],
        //     ],
        //   ),
        // ),
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

class _AnswerFeedbackPanel extends StatelessWidget {
  final bool isCorrect;
  final String feedback;

  const _AnswerFeedbackPanel({required this.isCorrect, required this.feedback});

  @override
  Widget build(BuildContext context) {
    final accent = isCorrect ? AppColors.teal : const Color(0xFFFF7A7A);
    final background = isCorrect
        ? AppColors.teal.withValues(alpha: 0.1)
        : const Color(0xFFFF7A7A).withValues(alpha: 0.1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: accent.withValues(alpha: 0.85), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              feedback,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
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

class _QuizSummary extends StatelessWidget {
  final int correctCount;
  final int totalQuestions;
  final int earnedXP;
  final VoidCallback onProceed;

  const _QuizSummary({
    required this.correctCount,
    required this.totalQuestions,
    required this.earnedXP,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: MissionCompletePanel(
        title: 'MISSION 2 COMPLETE!',
        badgeName: 'Lava Investigator Badge',
        badgeImagePath: Assets.badgeLavaInvestigator,
        fallbackIcon: Icons.local_fire_department_outlined,
        message:
            'Congratulations, scientist. You earned the Lava Investigator Badge.',
        metrics: [
          MissionCompleteMetric(
            label: 'SCORE',
            value: '$correctCount/$totalQuestions',
          ),
          MissionCompleteMetric(label: 'EARNED', value: '$earnedXP XP'),
        ],
        onProceed: onProceed,
      ),
    );
  }
}

class _QuizGrid extends StatelessWidget {
  const _QuizGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _QuizGridPainter());
  }
}

class _QuizGridPainter extends CustomPainter {
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

class _MissionTwoQuestion {
  final String id;
  final String tag;
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final List<String>? answerFeedback;

  const _MissionTwoQuestion({
    required this.id,
    required this.tag,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    this.answerFeedback,
  });
}
