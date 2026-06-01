import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../player/application/player_controller.dart';

class VolcanoStructureSideQuestScreen extends ConsumerStatefulWidget {
  const VolcanoStructureSideQuestScreen({super.key});

  @override
  ConsumerState<VolcanoStructureSideQuestScreen> createState() =>
      _VolcanoStructureSideQuestScreenState();
}

class _VolcanoStructureSideQuestScreenState
    extends ConsumerState<VolcanoStructureSideQuestScreen> {
  var _pageIndex = 0;
  var _questionIndex = 0;
  int? _selectedOptionIndex;
  var _submitted = false;
  var _isSaving = false;
  var _lastAnswerCorrect = false;

  static final _lessonPages = [
    _LessonPage(
      title: 'Structure of a Volcano',
      paragraphs: const [
        'A volcano is a cone-shaped mountain or hill with an opening where lava, gases, hot vapor, and rock fragments erupt from Earth\'s crust.',
        'These materials come from molten rock called magma beneath the Earth\'s surface. The movement of magma toward or onto the surface is known as volcanism.',
      ],
      imageLabels: const ['VOLCANO STRUCTURE DIAGRAM'],
    ),
    _LessonPage(
      title: 'The Parts of a Volcano',
      bullets: const [
        'Summit is the highest point or apex of the volcano. At the summit, you have an opening called a vent.',
        'Slopes are the sides or flanks of a volcano that radiate from the main or central vent.',
        'Base is the lower outer part of the volcano.',
      ],
    ),
    _LessonPage(
      title: 'Other Geologic Features',
      bullets: const [
        'Magma chamber is a region beneath the vent where molten rock is stored before eruption.',
        'Main vent is the main opening that emits lava, gases, ash, or other volcanic materials.',
        'Conduit is an underground tube-like structure that connects the magma chamber to the crater.',
        'Side vent is a smaller outlet through which magma escapes.',
        'Crater is the funnel-shaped or bowl-shaped hollow at the top of the vent.',
        'Lava is molten rock given off onto Earth\'s surface when a volcano erupts.',
        'Ash and gas cloud is a mixture of rock, minerals, glass particles, and gases expelled during eruption.',
      ],
    ),
    _LessonPage(
      title: 'Classification by Structure',
      paragraphs: const [
        'There are several ways volcanoes can be classified. They can be classified based on structure and activity.',
        'One way to classify different types of volcanoes is through the structure characterized by their shape, parts, and formation.',
      ],
      imageLabels: const ['TYPES BASED ON STRUCTURE'],
    ),
    _LessonPage(
      title: 'Classification by Activity',
      paragraphs: const [
        'According to the Philippine Institute of Volcanology and Seismology (PHIVOLCS), volcanoes are classified based on activity and eruption history.',
      ],
      bullets: const [
        'Active volcanoes erupted within the last 10,000 years and still show signs of activity like ash, gas, or lava release.',
        'Inactive volcanoes have not erupted for over 10,000 years and show no signs of activity.',
        'Potentially active volcanoes have no recorded eruption but still appear young in structure.',
        'The Philippines has more than 100 volcanoes, and 24 of them are active.',
      ],
      imageLabels: const ['PHIVOLCS ACTIVITY CLASSIFICATION'],
    ),
    _LessonPage(
      title: 'Types of Volcanic Eruptions',
      paragraphs: const [
        'Different types of volcanoes erupt differently. They are generally classified as wet or dry depending on the magma\'s water content.',
      ],
      bullets: const [
        'Phreatic or hydrothermal is a steam-driven eruption as hot rocks come in contact with water. It is short lived and characterized by ash columns.',
        'Phreatomagmatic is a violent eruption caused by contact between water and magma. Fine ash columns and fast base surges may be observed.',
        'Strombolian is a periodic, weak to violent eruption characterized by lava fountains, like Irazu Volcano in Costa Rica.',
        'Vulcanian is characterized by tall eruption columns that can reach up to 20 km high with pyroclastic flow and ash fall tephra.',
      ],
      imageLabels: const [
        'PHREATIC ERUPTION',
        'PHREATOMAGMATIC ERUPTION',
        'STROMBOLIAN ERUPTION',
        'VULCANIAN ERUPTION',
      ],
    ),
    _LessonPage(
      title: 'Signs of an Impending Eruption',
      paragraphs: const [
        'PHIVOLCS is the government agency tasked with monitoring earthquakes and volcanoes in the Philippines.',
        'Based on their findings, scientists watch for commonly observed signs when a volcano is about to erupt.',
      ],
      imageLabels: const ['IMPENDING ERUPTION WARNING SIGNS'],
    ),
  ];

  static final _questions = [
    _SideQuestQuestion(
      id: AppConstants.sideQuestVolcanoStructureQuestionIds[0],
      tag: 'VOLCANO STRUCTURE',
      xp: AppConstants.sideQuestVolcanoStructureXp[0],
      question:
          'Which part of a volcano stores molten rock before an eruption?',
      options: const ['Crater', 'Magma chamber', 'Side vent', 'Base'],
      correctOptionIndex: 1,
    ),
    _SideQuestQuestion(
      id: AppConstants.sideQuestVolcanoStructureQuestionIds[1],
      tag: 'PHIVOLCS ACTIVITY',
      xp: AppConstants.sideQuestVolcanoStructureXp[1],
      question:
          'According to PHIVOLCS, which volcanoes erupted within the last 10,000 years and may still show activity?',
      options: const [
        'Inactive volcanoes',
        'Potentially active volcanoes',
        'Active volcanoes',
        'Shield volcanoes',
      ],
      correctOptionIndex: 2,
    ),
    _SideQuestQuestion(
      id: AppConstants.sideQuestVolcanoStructureQuestionIds[2],
      tag: 'ERUPTION TYPE',
      xp: AppConstants.sideQuestVolcanoStructureXp[2],
      question:
          'Which eruption is steam-driven when hot rocks come in contact with water?',
      options: const [
        'Strombolian',
        'Vulcanian',
        'Phreatic or hydrothermal',
        'Phreatomagmatic',
      ],
      correctOptionIndex: 2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final answeredIds =
        player.completedMissionOrbs[AppConstants.sideQuestVolcanoStructureId] ??
        const [];
    final correctIds =
        player.completedMissionOrbs[AppConstants
            .sideQuestVolcanoStructureCorrectAnswersId] ??
        const [];
    final allAnswered = AppConstants.sideQuestVolcanoStructureQuestionIds.every(
      answeredIds.contains,
    );
    final showingLesson = _pageIndex < _lessonPages.length && !allAnswered;
    final activeQuestionIndex = allAnswered
        ? _questionIndex.clamp(0, _questions.length - 1)
        : _activeQuestionIndex(answeredIds);
    final completedSteps = allAnswered
        ? _lessonPages.length + _questions.length
        : showingLesson
        ? _pageIndex
        : _lessonPages.length + answeredIds.length.clamp(0, _questions.length);
    final totalSteps = _lessonPages.length + _questions.length;
    final progress = completedSteps / totalSteps;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: Column(
            children: [
              _SideQuestTopBar(
                xp: player.totalXP,
                avatarIndex: player.avatarIndex,
                onBack: _handleBack,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _SideQuestPanel(
                  progress: progress,
                  percentComplete: (progress * 100).round(),
                  child: allAnswered
                      ? _SideQuestSummary(
                          correctCount: correctIds.length,
                          totalQuestions: _questions.length,
                          earnedXP: _earnedSideQuestXP(correctIds),
                          onProceed: () => context.push(AppRoutes.level(4)),
                        )
                      : showingLesson
                      ? _LessonContent(
                          page: _lessonPages[_pageIndex],
                          pageNumber: _pageIndex + 1,
                          totalPages: _lessonPages.length,
                          onPrevious: _pageIndex == 0
                              ? null
                              : () {
                                  setState(() {
                                    _pageIndex--;
                                  });
                                },
                          onNext: () {
                            setState(() {
                              _pageIndex++;
                              _questionIndex = _activeQuestionIndex(
                                answeredIds,
                              );
                            });
                          },
                        )
                      : _QuestionContent(
                          questionIndex: activeQuestionIndex,
                          totalQuestions: _questions.length,
                          question: _questions[activeQuestionIndex],
                          selectedOptionIndex: _selectedOptionIndex,
                          submitted: _submitted,
                          isSaving: _isSaving,
                          lastAnswerCorrect: _lastAnswerCorrect,
                          onPrevious: _submitted || _isSaving
                              ? null
                              : () {
                                  setState(() {
                                    if (activeQuestionIndex == 0) {
                                      _pageIndex = _lessonPages.length - 1;
                                    } else {
                                      _questionIndex = activeQuestionIndex - 1;
                                    }
                                    _selectedOptionIndex = null;
                                  });
                                },
                          onSelect: _submitted || _isSaving
                              ? null
                              : (index) {
                                  setState(() {
                                    _selectedOptionIndex = index;
                                  });
                                },
                          onAction: () => _handleQuestionAction(
                            _questions[activeQuestionIndex],
                            activeQuestionIndex,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBack() {
    if (_pageIndex > 0 && !_submitted && !_isSaving) {
      setState(() {
        _pageIndex--;
        _selectedOptionIndex = null;
      });
      return;
    }

    final context = this.context;
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.menu);
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

  int _earnedSideQuestXP(List<String> correctIds) {
    var xp = 0;
    for (var index = 0; index < _questions.length; index++) {
      if (correctIds.contains(_questions[index].id)) {
        xp += _questions[index].xp;
      }
    }
    return xp;
  }

  Future<void> _handleQuestionAction(
    _SideQuestQuestion question,
    int displayIndex,
  ) async {
    if (_submitted) {
      final isLastQuestion = displayIndex >= _questions.length - 1;
      setState(() {
        if (isLastQuestion) {
          _questionIndex = displayIndex;
        } else {
          _questionIndex = displayIndex + 1;
          _selectedOptionIndex = null;
          _submitted = false;
          _lastAnswerCorrect = false;
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
        .submitSideQuestVolcanoStructureAnswer(
          questionId: question.id,
          isCorrect: isCorrect,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _questionIndex = displayIndex;
      _submitted = true;
      _lastAnswerCorrect = isCorrect;
      _isSaving = false;
    });
  }
}

class _SideQuestTopBar extends StatelessWidget {
  final int xp;
  final int avatarIndex;
  final VoidCallback onBack;

  const _SideQuestTopBar({
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
        const Text(
          'SIDE QUEST',
          style: TextStyle(
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

class _SideQuestPanel extends StatelessWidget {
  final double progress;
  final int percentComplete;
  final Widget child;

  const _SideQuestPanel({
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                const Text(
                  'STRUCTURE LESSON',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const Spacer(),
                Text(
                  '$percentComplete%',
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: progress,
            minHeight: 3,
            backgroundColor: AppColors.surface,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _LessonContent extends StatelessWidget {
  final _LessonPage page;
  final int pageNumber;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;

  const _LessonContent({
    required this.page,
    required this.pageNumber,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAGE $pageNumber/$totalPages',
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  page.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 14),
                for (final paragraph in page.paragraphs) ...[
                  Text(
                    paragraph,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.45,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                for (final bullet in page.bullets) ...[
                  _LessonBullet(text: bullet),
                  const SizedBox(height: 8),
                ],
                for (final label in page.imageLabels) ...[
                  const SizedBox(height: 10),
                  _ImagePlaceholder(label: label),
                ],
              ],
            ),
          ),
        ),
        _BottomActions(
          leadingLabel: 'BACK',
          trailingLabel: pageNumber == totalPages ? 'START CHECK' : 'NEXT',
          onLeading: onPrevious,
          onTrailing: onNext,
        ),
      ],
    );
  }
}

class _QuestionContent extends StatelessWidget {
  final int questionIndex;
  final int totalQuestions;
  final _SideQuestQuestion question;
  final int? selectedOptionIndex;
  final bool submitted;
  final bool isSaving;
  final bool lastAnswerCorrect;
  final VoidCallback? onPrevious;
  final ValueChanged<int>? onSelect;
  final VoidCallback onAction;

  const _QuestionContent({
    required this.questionIndex,
    required this.totalQuestions,
    required this.question,
    required this.selectedOptionIndex,
    required this.submitted,
    required this.isSaving,
    required this.lastAnswerCorrect,
    required this.onPrevious,
    required this.onSelect,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final canSubmit = selectedOptionIndex != null && !isSaving;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHECK ${questionIndex + 1}/$totalQuestions - ${question.xp} XP',
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  question.tag,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  question.question,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 18),
                for (var index = 0; index < question.options.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OptionTile(
                      letter: String.fromCharCode(65 + index),
                      text: question.options[index],
                      isSelected: selectedOptionIndex == index,
                      isSubmitted: submitted,
                      isCorrect: question.correctOptionIndex == index,
                      onTap: onSelect == null ? null : () => onSelect!(index),
                    ),
                  ),
                if (submitted) ...[
                  const SizedBox(height: 4),
                  _AnswerFeedback(
                    xp: question.xp,
                    isCorrect: lastAnswerCorrect,
                    correctAnswer:
                        question.options[question.correctOptionIndex],
                  ),
                ],
              ],
            ),
          ),
        ),
        _BottomActions(
          leadingLabel: 'BACK',
          trailingLabel: submitted
              ? questionIndex == totalQuestions - 1
                    ? 'VIEW RESULTS'
                    : 'NEXT'
              : 'SUBMIT',
          onLeading: onPrevious,
          onTrailing: canSubmit || submitted ? onAction : null,
          isLoading: isSaving,
        ),
      ],
    );
  }
}

class _SideQuestSummary extends StatelessWidget {
  final int correctCount;
  final int totalQuestions;
  final int earnedXP;
  final VoidCallback onProceed;

  const _SideQuestSummary({
    required this.correctCount,
    required this.totalQuestions,
    required this.earnedXP,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                  Icons.menu_book_outlined,
                  color: AppColors.teal,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'SIDE QUEST COMPLETE',
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
                'LEVEL 4 ACCESS UNLOCKED',
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
                  Expanded(
                    child: _SummaryMetric(
                      label: 'SCORE',
                      value: '$correctCount/$totalQuestions',
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
                  child: const Text('PROCEED TO MISSION 4'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final String leadingLabel;
  final String trailingLabel;
  final VoidCallback? onLeading;
  final VoidCallback? onTrailing;
  final bool isLoading;

  const _BottomActions({
    required this.leadingLabel,
    required this.trailingLabel,
    required this.onLeading,
    required this.onTrailing,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderAlt, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onLeading,
              child: Text(leadingLabel),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: isLoading ? null : onTrailing,
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: AppColors.teal,
                        strokeWidth: 1.5,
                      ),
                    )
                  : Text(trailingLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonBullet extends StatelessWidget {
  final String text;

  const _LessonBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(top: 8),
          decoration: const BoxDecoration(
            color: AppColors.teal,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final String label;

  const _ImagePlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.borderAlt, width: 1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.image_outlined,
              color: AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 8),
            const Text(
              'IMAGE PLACEHOLDER',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDim,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String letter;
  final String text;
  final bool isSelected;
  final bool isSubmitted;
  final bool isCorrect;
  final VoidCallback? onTap;

  const _OptionTile({
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

class _AnswerFeedback extends StatelessWidget {
  final int xp;
  final bool isCorrect;
  final String correctAnswer;

  const _AnswerFeedback({
    required this.xp,
    required this.isCorrect,
    required this.correctAnswer,
  });

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
        isCorrect ? '+$xp XP RECORDED' : 'Correct answer: $correctAnswer',
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

class _LessonPage {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
  final List<String> imageLabels;

  const _LessonPage({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
    this.imageLabels = const [],
  });
}

class _SideQuestQuestion {
  final String id;
  final String tag;
  final int xp;
  final String question;
  final List<String> options;
  final int correctOptionIndex;

  const _SideQuestQuestion({
    required this.id,
    required this.tag,
    required this.xp,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
  });
}
