import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/assets.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../player/application/player_controller.dart';

class MissionThreeWordBuilderScreen extends ConsumerStatefulWidget {
  final int levelId;
  final int? randomSeed;

  const MissionThreeWordBuilderScreen({
    super.key,
    required this.levelId,
    this.randomSeed,
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
  var _feedback = _WordFeedback.none;

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
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final solvedIds =
        player.completedMissionOrbs[AppConstants.missionThreeId] ?? const [];
    final allSolved = AppConstants.missionThreeWordIds.every(
      solvedIds.contains,
    );
    final shouldShowSummary = _showSummary || allSolved;
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: Column(
            children: [
              _WordBuilderTopBar(
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
                child: _WordBuilderPanel(
                  progress: progress,
                  percentComplete: (progress * 100).round(),
                  child: shouldShowSummary
                      ? _MissionThreeSummary(
                          solvedCount: solvedIds.length,
                          totalWords: _words.length,
                          earnedXP:
                              solvedIds.length *
                              AppConstants.missionThreeXpPerWord,
                          onProceed: () => context.push(AppRoutes.level(4)),
                        )
                      : _WordBuilderContent(
                          wordIndex: activeIndex,
                          totalWords: _words.length,
                          word: _words[activeIndex],
                          slotLetters: _slotLetters,
                          availableLetters: _availableLetters,
                          bankCount: _availableLetters.length,
                          feedback: _feedback,
                          isSaving: _isSaving,
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
    if (_isSaving) {
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
    if (_isSaving) {
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
    if (_isSaving || _slotLetters.length != word.blankCount) {
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
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await ref.read(playerProvider.notifier).completeMissionThreeWord(word.id);

    if (!mounted) {
      return;
    }

    final solvedIds =
        ref
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
      _showSummary = allSolved;
      if (!allSolved && nextOpenIndex != -1) {
        _wordIndex = nextOpenIndex;
        _resetWordState(_words[nextOpenIndex]);
      }
      _feedback = _WordFeedback.correct;
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
                const Positioned.fill(child: _WordBuilderGrid()),
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

class _WordBuilderContent extends StatelessWidget {
  final int wordIndex;
  final int totalWords;
  final _MissionThreeWord word;
  final Map<int, _LetterTileData> slotLetters;
  final List<_LetterTileData> availableLetters;
  final int bankCount;
  final _WordFeedback feedback;
  final bool isSaving;
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
                const Align(
                  alignment: Alignment.centerLeft,
                  child: _ScannerLabel(text: 'GEOTHERMAL SCAN'),
                ),
                const SizedBox(height: 14),
                _VolcanoImageCard(),
                const SizedBox(height: 14),
                _MissionTelemetryStrip(
                  wordIndex: wordIndex,
                  totalWords: totalWords,
                  hintCount: word.hintIndexes.length,
                  blankCount: word.blankCount,
                  bankCount: bankCount,
                ),
                const SizedBox(height: 18),
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
                const SizedBox(height: 18),
                if (feedback != _WordFeedback.none) ...[
                  _WordFeedbackBanner(feedback: feedback),
                  const SizedBox(height: 14),
                ],
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
              child: OutlinedButton(
                onPressed: isSaving ? null : onClear,
                child: const Text('CLEAR'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: canSubmit ? onSubmit : null,
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppColors.teal,
                        ),
                      )
                    : const Text('SUBMIT WORD'),
              ),
            ),
          ],
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.84),
        border: Border.all(color: AppColors.borderAlt, width: 0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TelemetryCell(
              label: 'WORD',
              value: '${wordIndex + 1}/$totalWords',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TelemetryCell(label: 'HINTS', value: '$hintCount'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TelemetryCell(label: 'BLANKS', value: '$blankCount'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TelemetryCell(label: 'BANK', value: '$bankCount'),
          ),
        ],
      ),
    );
  }
}

class _TelemetryCell extends StatelessWidget {
  final String label;
  final String value;

  const _TelemetryCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF061625),
        border: Border.all(color: AppColors.border, width: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF071A2A).withValues(alpha: 0.92),
        border: Border.all(color: AppColors.borderAlt, width: 0.8),
        borderRadius: BorderRadius.circular(6),
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
            color: AppColors.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _VolcanoImageCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 194,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.borderAlt, width: 1),
        borderRadius: BorderRadius.circular(7),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(Assets.volcanoCutaway, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0),
                  Colors.black.withValues(alpha: 0.28),
                ],
              ),
              border: Border.all(
                color: AppColors.teal.withValues(alpha: 0.28),
                width: 1,
              ),
            ),
          ),
          const Positioned(
            left: 10,
            top: 10,
            child: _ImageReadout(label: 'ZENITH', value: 'LAVA SCAN'),
          ),
          const Positioned(
            right: 10,
            bottom: 10,
            child: _ImageReadout(label: 'SIGNAL', value: 'VOLCANO CORE'),
          ),
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
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.teal,
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
      spacing: 9,
      runSpacing: 9,
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
    final borderColor = feedback == _WordFeedback.wrong && !isHint
        ? const Color(0xFFFF7A7A)
        : feedback == _WordFeedback.correct
        ? AppColors.teal
        : isHint
        ? AppColors.tealDim
        : AppColors.borderAlt;

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
            width: 42,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: candidateData.isNotEmpty
                  ? AppColors.teal.withValues(alpha: 0.16)
                  : isHint
                  ? AppColors.tealDark
                  : const Color(0xFF0A1C2D),
              border: Border.all(color: borderColor, width: isHint ? 1 : 0.8),
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                if (candidateData.isNotEmpty ||
                    feedback == _WordFeedback.correct)
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.22),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
              ],
            ),
            foregroundDecoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: borderColor,
                  width: isHint ? 2.2 : 1.6,
                ),
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              letter ?? '',
              style: TextStyle(
                color: isHint ? AppColors.teal : AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
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
      spacing: 9,
      runSpacing: 9,
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
      width: 47,
      height: 45,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF304258), Color(0xFF1E2D3C)],
        ),
        border: Border.all(color: AppColors.borderAlt, width: 0.9),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        data.letter,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
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

class _WordFeedbackBanner extends StatelessWidget {
  final _WordFeedback feedback;

  const _WordFeedbackBanner({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final isCorrect = feedback == _WordFeedback.correct;
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
        isCorrect ? '+20 XP RECORDED' : 'WRONG SEQUENCE - TRY AGAIN',
        textAlign: TextAlign.center,
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
    return Center(
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
                Icons.abc_outlined,
                color: AppColors.teal,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'MISSION 3 COMPLETE',
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
              'VOLCANO VOCABULARY BADGE',
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
                    label: 'SOLVED',
                    value: '$solvedCount/$totalWords',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryMetric(label: 'EARNED', value: '$earnedXP XP'),
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
