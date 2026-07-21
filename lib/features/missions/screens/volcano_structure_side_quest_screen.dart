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

class VolcanoStructureSideQuestScreen extends ConsumerStatefulWidget {
  final bool isReplay;

  const VolcanoStructureSideQuestScreen({super.key, this.isReplay = false});

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
  final _replayAnsweredIds = <String>[];
  final _replayCorrectIds = <String>[];

  static final _lessonPages = [
    _LessonPage(
      title: 'Structure of a Volcano',
      paragraphs: const [
        'A volcano is a cone-shaped mountain or hill with an opening where lava, gases, hot vapor, and rock fragments erupt from Earth\'s crust.',
        'These materials come from molten rock called magma beneath the Earth\'s surface. The movement of magma toward or onto the surface is known as volcanism.',
      ],
      images: const [
        _LessonImage(
          assetPath: Assets.volcanoParts,
          label: 'VOLCANO STRUCTURE DIAGRAM',
        ),
      ],
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
      images: const [
        _LessonImage(assetPath: Assets.cinderCone, label: 'CINDER CONE'),
        _LessonImage(
          assetPath: Assets.compositeVolcano,
          label: 'COMPOSITE VOLCANO',
        ),
        _LessonImage(assetPath: Assets.shieldVolcano, label: 'SHIELD VOLCANO'),
      ],
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
      images: const [
        _LessonImage(
          assetPath: Assets.mountains,
          label: 'PHIVOLCS ACTIVITY CLASSIFICATION',
        ),
      ],
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
      images: const [
        _LessonImage(assetPath: Assets.phreatic, label: 'PHREATIC ERUPTION'),
        _LessonImage(
          assetPath: Assets.phreatomagmatic,
          label: 'PHREATOMAGMATIC ERUPTION',
        ),
        _LessonImage(
          assetPath: Assets.strombolian,
          label: 'STROMBOLIAN ERUPTION',
        ),
        _LessonImage(assetPath: Assets.vulcanian, label: 'VULCANIAN ERUPTION'),
      ],
    ),
    _LessonPage(
      title: 'Signs of an Impending Eruption',
      paragraphs: const [
        'PHIVOLCS is the government agency tasked with monitoring earthquakes and volcanoes in the Philippines.',
        'Based on their findings, scientists watch for commonly observed signs when a volcano is about to erupt.',
      ],
      images: const [
        _LessonImage(
          assetPath: Assets.impendingEruptions,
          label: 'IMPENDING ERUPTION WARNING SIGNS',
        ),
      ],
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
    final answeredIds = widget.isReplay
        ? _replayAnsweredIds
        : player.completedMissionOrbs[AppConstants
                  .sideQuestVolcanoStructureId] ??
              const [];
    final correctIds = widget.isReplay
        ? _replayCorrectIds
        : player.completedMissionOrbs[AppConstants
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
      body: MissionScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
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
                            earnedXP: widget.isReplay
                                ? 0
                                : _earnedSideQuestXP(correctIds),
                            onProceed: () => context.go(AppRoutes.menu),
                          )
                        : showingLesson
                        ? _LessonContent(
                            page: _lessonPages[_pageIndex],
                            pageNumber: _pageIndex + 1,
                            totalPages: _lessonPages.length,
                            onNext: () {
                              _playButtonSfx();
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
                            onSelect: _submitted || _isSaving
                                ? null
                                : (index) {
                                    _playButtonSfx();
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

  void _playButtonSfx() {
    unawaited(ref.read(audioControllerProvider).playSfx(SfxCue.button));
  }

  Future<void> _handleQuestionAction(
    _SideQuestQuestion question,
    int displayIndex,
  ) async {
    if (_submitted) {
      _playButtonSfx();
      final isLastQuestion = displayIndex >= _questions.length - 1;
      setState(() {
        if (isLastQuestion) {
          _questionIndex = displayIndex;
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
          .submitSideQuestVolcanoStructureAnswer(
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
          ? '+${question.xp} XP recorded'
          : 'Correct answer: ${question.options[question.correctOptionIndex]}',
      isError: !isCorrect,
    );
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

  @override
  Widget build(BuildContext context) {
    return MissionResearchTopBar(
      title: 'SIDE QUEST',
      xp: xp,
      avatarIndex: avatarIndex,
      onBack: onBack,
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
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(0)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          MissionVolcanoProgressBar(value: progress),
          Expanded(
            child: Stack(
              children: [
                const Positioned.fill(child: _SideQuestGrid()),
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

class _SideQuestGrid extends StatelessWidget {
  const _SideQuestGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SideQuestGridPainter());
  }
}

class _SideQuestGridPainter extends CustomPainter {
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

class _LessonContent extends StatelessWidget {
  final _LessonPage page;
  final int pageNumber;
  final int totalPages;
  final VoidCallback onNext;

  const _LessonContent({
    required this.page,
    required this.pageNumber,
    required this.totalPages,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ScannerLabel(text: 'STRUCTURE LESSON'),
                    const SizedBox(height: 14),
                    Text(
                      page.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.16,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PAGE $pageNumber/$totalPages',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LessonDataSection(page: page),
                    for (final image in page.images) ...[
                      const SizedBox(height: 12),
                      _VolcanoScanFrame(image: image),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
        _SideQuestActionButton(
          assetPath: Assets.missionOneButtonContainer,
          semanticLabel: 'NEXT',
          visibleLabel: 'NEXT',
          onPressed: onNext,
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
  final ValueChanged<int>? onSelect;
  final VoidCallback onAction;

  const _QuestionContent({
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
            fontWeight: FontWeight.w900,
            height: 1.28,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'CHECK ${questionIndex + 1}/$totalQuestions - ${question.xp} XP',
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
              for (var index = 0; index < question.options.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SideQuestAnswerOption(
                    letter: String.fromCharCode(65 + index),
                    text: question.options[index],
                    isSelected: selectedOptionIndex == index,
                    isSubmitted: submitted,
                    isCorrect: question.correctOptionIndex == index,
                    onTap: onSelect == null ? null : () => onSelect!(index),
                  ),
                ),
            ],
          ),
        ),
        _SideQuestActionButton(
          assetPath: submitted
              ? Assets.missionNextQuestionButton
              : Assets.missionSubmitAnswerButton,
          semanticLabel: submitted ? 'NEXT QUESTION' : 'SUBMIT ANSWER',
          onPressed: submitted || canSubmit ? onAction : null,
          opacity: submitted || canSubmit || isSaving ? 1 : 0.45,
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
        ),
      ],
    );
  }
}

class _SideQuestAnswerOption extends StatelessWidget {
  final String letter;
  final String text;
  final bool isSelected;
  final bool isSubmitted;
  final bool isCorrect;
  final VoidCallback? onTap;

  const _SideQuestAnswerOption({
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

    return InkWell(
      onTap: onTap,
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
              letter: letter,
              isSelected: isSelected && !isSubmitted,
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
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
            if (showCorrect || showWrong)
              Positioned(
                right: 18,
                top: 0,
                bottom: 0,
                child: Icon(
                  showCorrect ? Icons.check : Icons.close,
                  color: showCorrect ? AppColors.teal : const Color(0xFFFF7A7A),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
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
        child: MissionCompletePanel(
          title: 'SIDE QUEST COMPLETE!',
          badgeName: 'Level 4 Access Unlocked',
          fallbackIcon: Icons.menu_book_outlined,
          message:
              'Volcano structure review complete. Level 4 access is unlocked.',
          metrics: [
            MissionCompleteMetric(
              label: 'SCORE',
              value: '$correctCount/$totalQuestions',
            ),
            MissionCompleteMetric(label: 'EARNED', value: '$earnedXP XP'),
          ],
          onProceed: onProceed,
        ),
      ),
    );
  }
}

class _SideQuestActionButton extends StatelessWidget {
  final String assetPath;
  final String semanticLabel;
  final String? visibleLabel;
  final VoidCallback? onPressed;
  final double opacity;
  final Widget? child;

  const _SideQuestActionButton({
    required this.assetPath,
    required this.semanticLabel,
    required this.onPressed,
    this.visibleLabel,
    this.opacity = 1,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 70,
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
          disabledForegroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          side: BorderSide.none,
          overlayColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Opacity(
          opacity: opacity,
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
                if (visibleLabel != null)
                  Center(
                    child: Text(
                      visibleLabel!,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (child != null) Center(child: child),
                if (visibleLabel == null)
                  Center(
                    child: Opacity(opacity: 0, child: Text(semanticLabel)),
                  ),
              ],
            ),
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

class _LessonDataSection extends StatelessWidget {
  final _LessonPage page;

  const _LessonDataSection({required this.page});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.82),
        border: Border.all(color: AppColors.borderAlt, width: 1),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 12)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
          ],
        ),
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

class _VolcanoScanFrame extends StatelessWidget {
  final _LessonImage image;

  const _VolcanoScanFrame({required this.image});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 11),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF21140F), Color(0xFF0F0D0B)],
              ),
              border: Border.all(color: AppColors.borderAlt, width: 1.2),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(color: Color(0x55100000), blurRadius: 14),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  const Positioned.fill(child: _SideQuestGrid()),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                    child: Image.asset(
                      image.assetPath,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(top: 0, child: _ScanImageLabel(text: image.label)),
      ],
    );
  }
}

class _ScanImageLabel extends StatelessWidget {
  final String text;

  const _ScanImageLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.86),
        border: Border.all(color: AppColors.tealDim, width: 1),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
      ),
    );
  }
}

class _LessonPage {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
  final List<_LessonImage> images;

  const _LessonPage({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
    this.images = const [],
  });
}

class _LessonImage {
  final String assetPath;
  final String label;

  const _LessonImage({required this.assetPath, required this.label});
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
