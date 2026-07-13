import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../core/audio/audio_catalog.dart';
import '../../../core/audio/audio_controller.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/assets.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/mission_complete_panel.dart';
import '../../../shared/widgets/mission_screen_background.dart';
import '../../player/application/player_controller.dart';

const _lava = Color(0xFFFF7A1A);
const _lavaDeep = Color(0xFFC74214);
const _ember = Color(0xFFFFB45F);
const _charcoal = Color(0xFF100F0E);

class MissionThreeWordBuilderScreen extends ConsumerStatefulWidget {
  final int levelId;
  final int? randomSeed;
  final bool isReplay;

  const MissionThreeWordBuilderScreen({
    super.key,
    required this.levelId,
    this.randomSeed,
    this.isReplay = false,
  });

  @override
  ConsumerState<MissionThreeWordBuilderScreen> createState() =>
      _MissionThreeWordBuilderScreenState();
}

class _MissionThreeWordBuilderScreenState
    extends ConsumerState<MissionThreeWordBuilderScreen> {
  late final math.Random _random;
  late final List<_MissionThreeWord> _words;
  var _wordIndex = 0;
  var _slotLetters = <int, _LetterTileData>{};
  var _availableLetters = <_LetterTileData>[];
  var _isSaving = false;
  var _showSummary = false;
  var _showCompletionVideo = false;
  var _completionVideoStarted = false;
  var _completionVideoFinished = false;
  VideoPlayerController? _completionVideoController;
  var _feedback = _WordFeedback.none;
  final _replaySolvedIds = <String>[];

  static const _distractorPool = 'BCDFHJKLNOPQRSTUVXYZ';

  @override
  void initState() {
    super.initState();
    _random = math.Random(
      widget.randomSeed ?? DateTime.now().microsecondsSinceEpoch,
    );
    _words = [
      _buildWord(id: AppConstants.missionThreeWordIds[0], hintCount: 2),
      _buildWord(id: AppConstants.missionThreeWordIds[1], hintCount: 1),
      _buildWord(id: AppConstants.missionThreeWordIds[2], hintCount: 1),
      _buildWord(id: AppConstants.missionThreeWordIds[3], hintCount: 3),
    ];
    _resetWordState(_words.first);
  }

  @override
  void dispose() {
    _completionVideoController
      ?..removeListener(_handleCompletionVideoProgress)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final solvedIds = widget.isReplay
        ? _replaySolvedIds
        : player.completedMissionOrbs[AppConstants.missionThreeId] ?? const [];
    final allSolved = AppConstants.missionThreeWordIds.every(
      solvedIds.contains,
    );
    final shouldShowSummary =
        (_showSummary || allSolved) && !_showCompletionVideo;
    final activeIndex = shouldShowSummary
        ? _wordIndex.clamp(0, _words.length - 1)
        : _activeWordIndex(solvedIds);
    final progressCount = shouldShowSummary
        ? _words.length
        : solvedIds.length.clamp(0, _words.length);
    final progress = progressCount / _words.length;

    if (!shouldShowSummary && activeIndex != _wordIndex && !_isSaving) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _wordIndex = activeIndex;
          _resetWordState(_words[activeIndex]);
        });
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: MissionScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
            child: Column(
              children: [
                _WordBuilderTopBar(
                  missionId: widget.levelId,
                  xp: player.totalXP,
                  avatarIndex: player.avatarIndex,
                  onBack: () {
                    if (_showCompletionVideo) {
                      return;
                    }
                    if (context.canPop()) {
                      context.pop();
                      return;
                    }
                    context.go(AppRoutes.menu);
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _WordBuilderPanel(
                    progress: progress,
                    percentComplete: (progress * 100).round(),
                    child: shouldShowSummary
                        ? _MissionThreeSummary(
                            solvedCount: solvedIds.length,
                            totalWords: _words.length,
                            earnedXP: widget.isReplay
                                ? 0
                                : solvedIds.length *
                                      AppConstants.missionThreeXpPerWord,
                            onProceed: () => context.go(AppRoutes.menu),
                          )
                        : _WordBuilderContent(
                            wordIndex: activeIndex,
                            totalWords: _words.length,
                            word: _words[activeIndex],
                            slotLetters: _slotLetters,
                            availableLetters: _availableLetters,
                            bankCount: _availableLetters.length,
                            feedback: _feedback,
                            isSaving: _isSaving || _showCompletionVideo,
                            showCompletionVideo: _showCompletionVideo,
                            completionVideoController:
                                _completionVideoController,
                            onAcceptLetter: _placeLetter,
                            onRemoveLetter: _removeLetter,
                            onTapLetter: _placeLetterInNextBlank,
                            onClear: () {
                              setState(() {
                                _resetWordState(_words[activeIndex]);
                              });
                            },
                            onSubmit: () => _submitWord(_words[activeIndex]),
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

  _MissionThreeWord _buildWord({required String id, required int hintCount}) {
    final chars = id.toUpperCase().split('');
    final indexes = List<int>.generate(chars.length, (index) => index)
      ..shuffle(_random);
    final hintIndexes = indexes.take(hintCount).toSet();
    return _MissionThreeWord(id: id, answer: chars, hintIndexes: hintIndexes);
  }

  int _activeWordIndex(List<String> solvedIds) {
    if (_feedback == _WordFeedback.correct) {
      return _wordIndex.clamp(0, _words.length - 1);
    }

    final currentId = _words[_wordIndex].id;
    if (!solvedIds.contains(currentId)) {
      return _wordIndex;
    }

    final nextOpenIndex = _words.indexWhere(
      (word) => !solvedIds.contains(word.id),
    );
    if (nextOpenIndex == -1) {
      return _words.length - 1;
    }
    return nextOpenIndex;
  }

  void _resetWordState(_MissionThreeWord word) {
    final answerLetters = [
      for (var index = 0; index < word.answer.length; index++)
        if (!word.hintIndexes.contains(index))
          _LetterTileData(id: '${word.id}-$index', letter: word.answer[index]),
    ];
    final distractors = _buildDistractors(
      word,
      math.max(4, word.blankCount + 1),
    );

    _slotLetters = {};
    _availableLetters = [...answerLetters, ...distractors]..shuffle(_random);
    _feedback = _WordFeedback.none;
  }

  List<_LetterTileData> _buildDistractors(
    _MissionThreeWord word,
    int distractorCount,
  ) {
    final answerLetters = word.answer.toSet();
    final candidates =
        _distractorPool
            .split('')
            .where((letter) => !answerLetters.contains(letter))
            .toList()
          ..shuffle(_random);

    return [
      for (var index = 0; index < distractorCount; index++)
        _LetterTileData(
          id: '${word.id}-extra-$index',
          letter: candidates[index % candidates.length],
        ),
    ];
  }

  void _placeLetter(_LetterDropPayload payload) {
    if (_isSaving || _showCompletionVideo) {
      return;
    }

    setState(() {
      final existing = _slotLetters[payload.slotIndex];
      if (existing != null) {
        _availableLetters = [..._availableLetters, existing];
      }
      _slotLetters[payload.slotIndex] = payload.letter;
      _availableLetters = _availableLetters
          .where((letter) => letter.id != payload.letter.id)
          .toList();
      _feedback = _WordFeedback.none;
    });
  }

  void _removeLetter(int slotIndex) {
    if (_isSaving || _showCompletionVideo) {
      return;
    }

    final existing = _slotLetters[slotIndex];
    if (existing == null) {
      return;
    }

    setState(() {
      _slotLetters = Map<int, _LetterTileData>.from(_slotLetters)
        ..remove(slotIndex);
      _availableLetters = [..._availableLetters, existing];
      _feedback = _WordFeedback.none;
    });
  }

  void _placeLetterInNextBlank(_LetterTileData letter) {
    final word = _words[_wordIndex];
    final nextBlank = List<int>.generate(word.answer.length, (index) => index)
        .where((index) => !word.hintIndexes.contains(index))
        .where((index) => !_slotLetters.containsKey(index))
        .firstOrNull;
    if (nextBlank == null) {
      return;
    }
    _placeLetter(_LetterDropPayload(slotIndex: nextBlank, letter: letter));
  }

  Future<void> _submitWord(_MissionThreeWord word) async {
    if (_isSaving ||
        _showCompletionVideo ||
        _slotLetters.length != word.blankCount) {
      return;
    }

    final attempt = [
      for (var index = 0; index < word.answer.length; index++)
        word.hintIndexes.contains(index)
            ? word.answer[index]
            : _slotLetters[index]?.letter ?? '',
    ].join();

    if (attempt != word.id.toUpperCase()) {
      setState(() {
        _feedback = _WordFeedback.wrong;
      });
      unawaited(ref.read(audioControllerProvider).playSfx(SfxCue.wrong));
      showMissionSnackBar(context, 'Wrong sequence - try again', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    if (widget.isReplay) {
      if (!_replaySolvedIds.contains(word.id)) {
        _replaySolvedIds.add(word.id);
      }
    } else {
      await ref.read(playerProvider.notifier).completeMissionThreeWord(word.id);
    }

    if (!mounted) {
      return;
    }

    final solvedIds = widget.isReplay
        ? _replaySolvedIds
        : ref
                  .read(playerProvider)
                  .completedMissionOrbs[AppConstants.missionThreeId] ??
              const [];
    final allSolved = AppConstants.missionThreeWordIds.every(
      solvedIds.contains,
    );
    final nextOpenIndex = _words.indexWhere(
      (candidate) => !solvedIds.contains(candidate.id),
    );

    setState(() {
      _isSaving = false;
      _showSummary = false;
      _showCompletionVideo = allSolved;
      if (!allSolved && nextOpenIndex != -1) {
        _wordIndex = nextOpenIndex;
        _resetWordState(_words[nextOpenIndex]);
      }
      _feedback = _WordFeedback.correct;
    });
    unawaited(ref.read(audioControllerProvider).playSfx(SfxCue.correct));
    showMissionSnackBar(
      context,
      widget.isReplay ? 'Practice word solved' : '+20 XP recorded',
    );

    if (allSolved) {
      unawaited(_playCompletionVideo());
    }
  }

  Future<void> _playCompletionVideo() async {
    final controller = VideoPlayerController.asset(
      Assets.missionThreeCompletionVideo,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _completionVideoController = controller;

    try {
      await controller.initialize().timeout(const Duration(seconds: 5));
      if (!mounted || _completionVideoController != controller) {
        unawaited(controller.dispose());
        return;
      }

      controller.addListener(_handleCompletionVideoProgress);
      await controller.setLooping(false);
      await controller.play();
      _completionVideoStarted = true;
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (_completionVideoController == controller) {
        _completionVideoController = null;
      }
      unawaited(controller.dispose());
      _finishCompletionVideo();
    }
  }

  void _handleCompletionVideoProgress() {
    final controller = _completionVideoController;
    if (controller == null ||
        !_completionVideoStarted ||
        _completionVideoFinished ||
        !controller.value.isInitialized) {
      return;
    }

    final value = controller.value;
    final reachedEnd =
        value.duration > Duration.zero &&
        value.position >= value.duration - const Duration(milliseconds: 100);
    if (reachedEnd) {
      _finishCompletionVideo();
    }
  }

  void _finishCompletionVideo() {
    if (_completionVideoFinished || !mounted) {
      return;
    }
    _completionVideoFinished = true;
    _completionVideoController?.removeListener(_handleCompletionVideoProgress);
    setState(() {
      _showCompletionVideo = false;
      _showSummary = true;
    });
  }
}

class _WordBuilderTopBar extends StatelessWidget {
  final int missionId;
  final int xp;
  final int avatarIndex;
  final VoidCallback onBack;

  const _WordBuilderTopBar({
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

class _WordBuilderPanel extends StatelessWidget {
  final double progress;
  final int percentComplete;
  final Widget child;

  const _WordBuilderPanel({
    required this.progress,
    required this.percentComplete,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: _lavaDeep.withValues(alpha: 0.72), width: 1),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: _lavaDeep.withValues(alpha: 0.16),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          MissionVolcanoProgressBar(value: progress, height: 10),
          Expanded(
            child: Stack(
              children: [
                const Positioned.fill(child: _WordBuilderGrid()),
                Positioned(
                  top: 8,
                  right: 18,
                  child: Text(
                    '$percentComplete% COMPLETE',
                    style: const TextStyle(
                      color: _ember,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
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

class _WordBuilderContent extends StatelessWidget {
  final int wordIndex;
  final int totalWords;
  final _MissionThreeWord word;
  final Map<int, _LetterTileData> slotLetters;
  final List<_LetterTileData> availableLetters;
  final int bankCount;
  final _WordFeedback feedback;
  final bool isSaving;
  final bool showCompletionVideo;
  final VideoPlayerController? completionVideoController;
  final ValueChanged<_LetterDropPayload> onAcceptLetter;
  final ValueChanged<int> onRemoveLetter;
  final ValueChanged<_LetterTileData> onTapLetter;
  final VoidCallback onClear;
  final VoidCallback onSubmit;

  const _WordBuilderContent({
    required this.wordIndex,
    required this.totalWords,
    required this.word,
    required this.slotLetters,
    required this.availableLetters,
    required this.bankCount,
    required this.feedback,
    required this.isSaving,
    required this.showCompletionVideo,
    required this.completionVideoController,
    required this.onAcceptLetter,
    required this.onRemoveLetter,
    required this.onTapLetter,
    required this.onClear,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final canSubmit = slotLetters.length == word.blankCount && !isSaving;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _VolcanoImageCard(
                  showCompletionVideo: showCompletionVideo,
                  completionVideoController: completionVideoController,
                ),
                const SizedBox(height: 12),
                _MissionTelemetryStrip(
                  wordIndex: wordIndex,
                  totalWords: totalWords,
                  hintCount: word.hintIndexes.length,
                  blankCount: word.blankCount,
                  bankCount: bankCount,
                ),
                const SizedBox(height: 14),
                _PuzzleDeck(
                  child: Column(
                    children: [
                      const _SectionHeader(
                        eyebrow: 'IDENTIFY STRUCTURE',
                        title: 'DECODE VOLCANO TERM',
                      ),
                      const SizedBox(height: 16),
                      _WordSlots(
                        word: word,
                        slotLetters: slotLetters,
                        feedback: feedback,
                        onRemoveLetter: onRemoveLetter,
                        onAcceptLetter: onAcceptLetter,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _PuzzleDeck(
                  child: Column(
                    children: [
                      _SectionHeader(
                        eyebrow: '${availableLetters.length} SIGNALS ACTIVE',
                        title: 'LETTER BANK',
                      ),
                      const SizedBox(height: 14),
                      _LetterBank(
                        letters: availableLetters,
                        onTapLetter: onTapLetter,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF3A3A3A), Color(0xFF1A1A1A)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF8A8A8A), width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      offset: Offset(0, 3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: isSaving ? null : onClear,
                    child: const Center(
                      child: Text(
                        'CLEAR',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Container(
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
                              'SUBMIT WORD',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MissionTelemetryStrip extends StatelessWidget {
  final int wordIndex;
  final int totalWords;
  final int hintCount;
  final int blankCount;
  final int bankCount;

  const _MissionTelemetryStrip({
    required this.wordIndex,
    required this.totalWords,
    required this.hintCount,
    required this.blankCount,
    required this.bankCount,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(Assets.missionThreeHintContainer, fit: BoxFit.fill),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      '${wordIndex + 1}/$totalWords',
                      style: const TextStyle(
                        color: _lava,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                        shadows: [Shadow(color: _lavaDeep, blurRadius: 8)],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '$hintCount',
                      style: const TextStyle(
                        color: _lava,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                        shadows: [Shadow(color: _lavaDeep, blurRadius: 8)],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '$blankCount',
                      style: const TextStyle(
                        color: _lava,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                        shadows: [Shadow(color: _lavaDeep, blurRadius: 8)],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '$bankCount',
                      style: const TextStyle(
                        color: _lava,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                        shadows: [Shadow(color: _lavaDeep, blurRadius: 8)],
                      ),
                    ),
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

class _PuzzleDeck extends StatelessWidget {
  final Widget child;

  const _PuzzleDeck({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 24, 24, 24).withValues(alpha: 0.9),
        border: Border.all(color: _lavaDeep.withValues(alpha: 0.58), width: 4),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;

  const _SectionHeader({required this.eyebrow, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          eyebrow,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ember,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _VolcanoImageCard extends StatelessWidget {
  final bool showCompletionVideo;
  final VideoPlayerController? completionVideoController;

  const _VolcanoImageCard({
    required this.showCompletionVideo,
    required this.completionVideoController,
  });

  @override
  Widget build(BuildContext context) {
    final isVideoReady =
        showCompletionVideo &&
        (completionVideoController?.value.isInitialized ?? false);

    return Container(
      height: 206,
      decoration: BoxDecoration(
        color: _charcoal,
        border: Border.all(color: _lavaDeep.withValues(alpha: 0.74), width: 1),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: _lavaDeep.withValues(alpha: 0.18),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isVideoReady)
            Center(
              child: AspectRatio(
                aspectRatio: completionVideoController!.value.aspectRatio,
                child: VideoPlayer(completionVideoController!),
              ),
            )
          else
            Image.asset(Assets.missionThreeVolcanoImage, fit: BoxFit.contain),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.12),
                  Colors.black.withValues(alpha: 0),
                  _lavaDeep.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.42),
                ],
              ),
              border: Border.all(
                color: _ember.withValues(alpha: 0.24),
                width: 1,
              ),
            ),
          ),
          const Positioned(
            right: 10,
            bottom: 10,
            child: _ImageReadout(label: 'SIGNAL', value: 'VOLCANO CORE'),
          ),
          if (showCompletionVideo && !isVideoReady)
            const Center(child: CircularProgressIndicator(color: _lava)),
        ],
      ),
    );
  }
}

class _ImageReadout extends StatelessWidget {
  final String label;
  final String value;

  const _ImageReadout({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.62),
        border: Border.all(color: _ember.withValues(alpha: 0.38)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _lava,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 7,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _WordSlots extends StatelessWidget {
  final _MissionThreeWord word;
  final Map<int, _LetterTileData> slotLetters;
  final _WordFeedback feedback;
  final ValueChanged<int> onRemoveLetter;
  final ValueChanged<_LetterDropPayload> onAcceptLetter;

  const _WordSlots({
    required this.word,
    required this.slotLetters,
    required this.feedback,
    required this.onRemoveLetter,
    required this.onAcceptLetter,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var index = 0; index < word.answer.length; index++)
          _WordSlot(
            key: ValueKey('mission3-slot-$index'),
            index: index,
            hintLetter: word.hintIndexes.contains(index)
                ? word.answer[index]
                : null,
            placedLetter: slotLetters[index],
            feedback: feedback,
            onRemoveLetter: onRemoveLetter,
            onAcceptLetter: onAcceptLetter,
          ),
      ],
    );
  }
}

class _WordSlot extends StatelessWidget {
  final int index;
  final String? hintLetter;
  final _LetterTileData? placedLetter;
  final _WordFeedback feedback;
  final ValueChanged<int> onRemoveLetter;
  final ValueChanged<_LetterDropPayload> onAcceptLetter;

  const _WordSlot({
    super.key,
    required this.index,
    required this.hintLetter,
    required this.placedLetter,
    required this.feedback,
    required this.onRemoveLetter,
    required this.onAcceptLetter,
  });

  @override
  Widget build(BuildContext context) {
    final isHint = hintLetter != null;
    final letter = hintLetter ?? placedLetter?.letter;
    final glowColor = feedback == _WordFeedback.wrong && !isHint
        ? const Color(0xFFFF7A7A)
        : feedback == _WordFeedback.correct || isHint
        ? _lava
        : _lavaDeep;

    return DragTarget<_LetterTileData>(
      onWillAcceptWithDetails: (_) => !isHint,
      onAcceptWithDetails: (details) {
        if (!isHint) {
          onAcceptLetter(
            _LetterDropPayload(slotIndex: index, letter: details.data),
          );
        }
      },
      builder: (context, candidateData, rejectedData) {
        return InkWell(
          onTap: isHint || placedLetter == null
              ? null
              : () => onRemoveLetter(index),
          borderRadius: BorderRadius.circular(4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 55,
            height: 55,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                if (candidateData.isNotEmpty ||
                    feedback == _WordFeedback.correct ||
                    isHint)
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.42),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(Assets.missionThreeLetterSlot, fit: BoxFit.fill),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: candidateData.isNotEmpty
                        ? _lava.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Center(
                  child: Text(
                    letter ?? '',
                    style: TextStyle(
                      color: isHint ? _lava : AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                      shadows: [
                        Shadow(color: glowColor, blurRadius: isHint ? 8 : 3),
                      ],
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

class _LetterBank extends StatelessWidget {
  final List<_LetterTileData> letters;
  final ValueChanged<_LetterTileData> onTapLetter;

  const _LetterBank({required this.letters, required this.onTapLetter});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final letter in letters)
          _LetterTile(
            key: ValueKey('mission3-letter-${letter.id}'),
            data: letter,
            onTap: () => onTapLetter(letter),
          ),
      ],
    );
  }
}

class _LetterTile extends StatelessWidget {
  final _LetterTileData data;
  final VoidCallback onTap;

  const _LetterTile({super.key, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(Assets.missionThreeLetterSlot, fit: BoxFit.fill),
          Center(
            child: Text(
              data.letter,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                shadows: [Shadow(color: Colors.black, blurRadius: 5)],
              ),
            ),
          ),
        ],
      ),
    );

    return Draggable<_LetterTileData>(
      data: data,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.88, child: tile),
      ),
      childWhenDragging: Opacity(opacity: 0.28, child: tile),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: tile,
      ),
    );
  }
}

class _MissionThreeSummary extends StatelessWidget {
  final int solvedCount;
  final int totalWords;
  final int earnedXP;
  final VoidCallback onProceed;

  const _MissionThreeSummary({
    required this.solvedCount,
    required this.totalWords,
    required this.earnedXP,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: MissionCompletePanel(
          title: 'MISSION 3 COMPLETE!',
          badgeName: 'Volcano Vocabulary Badge',
          badgeImagePath: Assets.badgeVolcanoVocabulary,
          fallbackIcon: Icons.abc_outlined,
          message:
              'Congratulations, scientist. You earned the Volcano Vocabulary Badge.',
          metrics: [
            MissionCompleteMetric(
              label: 'SOLVED',
              value: '$solvedCount/$totalWords',
            ),
            MissionCompleteMetric(label: 'EARNED', value: '$earnedXP XP'),
          ],
          onProceed: onProceed,
        ),
      ),
    );
  }
}

class _WordBuilderGrid extends StatelessWidget {
  const _WordBuilderGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _WordBuilderGridPainter());
  }
}

class _WordBuilderGridPainter extends CustomPainter {
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

class _MissionThreeWord {
  final String id;
  final List<String> answer;
  final Set<int> hintIndexes;

  const _MissionThreeWord({
    required this.id,
    required this.answer,
    required this.hintIndexes,
  });

  int get blankCount => answer.length - hintIndexes.length;
}

class _LetterTileData {
  final String id;
  final String letter;

  const _LetterTileData({required this.id, required this.letter});
}

class _LetterDropPayload {
  final int slotIndex;
  final _LetterTileData letter;

  const _LetterDropPayload({required this.slotIndex, required this.letter});
}

enum _WordFeedback { none, correct, wrong }
