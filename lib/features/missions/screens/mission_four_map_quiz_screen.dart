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

class _MissionFourPalette {
  static const obsidian = Color(0xFF120D0A);
  static const basalt = Color(0xFF211712);
  static const magma = Color(0xFFFF8A24);
  static const sulfur = Color(0xFFFFC857);
  static const parchment = Color(0xFFFFE8C2);
  static const ash = Color(0xFFD8B493);
  static const fault = Color(0xFF7B3B1E);
  static const danger = Color(0xFFFF7A7A);
}

class MissionFourMapQuizScreen extends ConsumerStatefulWidget {
  final int levelId;
  final bool isReplay;

  const MissionFourMapQuizScreen({
    super.key,
    required this.levelId,
    this.isReplay = false,
  });

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
  final _replayAnsweredIds = <String>[];
  final _replayCorrectIds = <String>[];

  static final _volcanoes = [
    _MissionFourVolcano(
      id: AppConstants.missionFourVolcanoIds[0],
      name: 'Mayon Volcano',
      tag: 'ALBAY, LUZON',
      normalizedPosition: Offset(0.56, 0.30),
      facts: const [
        'Mayon Volcano is an active stratovolcano in Albay Province.',
        'It has a height of 2,463 meters (8,081 ft).',
        'Mayon is famous for its near-perfect cone shape.',
        'It is considered the most active volcano in the Philippines.',
        'The volcano has recorded more than 50 eruptions.',
        'Mayon is part of the Bicol Volcanic Arc.',
        'Its eruptions produce lava flows, pyroclastic flows, and ashfall.',
        'Thousands of residents are evacuated whenever volcanic activity increases.',
        'It is one of the Philippines\' most famous tourist attractions.',
        'Mayon symbolizes both the beauty and danger of volcanic activity.',
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
      normalizedPosition: Offset(0.62, 0.74),
      facts: const [
        'Mount Apo is the highest mountain in the Philippines.',
        'It has an elevation of 2,954 meters (9,692 ft).',
        'It is a potentially active stratovolcano located in Mindanao.',
        'The mountain lies between Davao del Sur and Cotabato provinces.',
        'Mount Apo is part of Mount Apo Natural Park, a protected area.',
        'It is home to the endangered Philippine Eagle.',
        'The mountain contains sulfur vents, hot springs, and small volcanic craters.',
        'It is one of the country\'s most popular mountain-climbing destinations.',
        'It supports diverse ecosystems ranging from tropical forests to mossy forests.',
        'Mount Apo is an important source of water and biodiversity in Mindanao.',
      ],
      question: 'What is the highest mountain in the Philippines?',
      options: const ['Mount Apo', 'Mount Makiling', 'Taal Volcano'],
      correctOptionIndex: 0,
    ),
    _MissionFourVolcano(
      id: AppConstants.missionFourVolcanoIds[2],
      name: 'Mount Makiling',
      tag: 'LAGUNA',
      normalizedPosition: Offset(0.45, 0.24),
      facts: const [
        'Mount Makiling is a potentially active stratovolcano located between the provinces of Laguna and Batangas.',
        'It stands 1,090 meters (3,576 ft) above sea level.',
        'The mountain is part of the Makiling Forest Reserve, a protected area rich in biodiversity.',
        'It is managed by the University of the Philippines Los Baños (UPLB).',
        'Mount Makiling is known for its hot springs and volcanic geothermal activity.',
        'It is home to hundreds of species of plants, birds, mammals, and insects.',
        'The mountain is a popular destination for hiking, nature walks, and scientific research.',
        'It is associated with the Philippine legend of Maria Makiling, a mythical forest guardian.',
        'Although it has no recorded historical eruptions, it is classified as potentially active because of its geothermal features.',
        'Mount Makiling plays an important role in environmental conservation and watershed protection.',
      ],
      question: 'Is Mount Makiling active or inactive?',
      options: const ['Active', 'Inactive', 'Extinct'],
      correctOptionIndex: 1,
    ),
    _MissionFourVolcano(
      id: AppConstants.missionFourVolcanoIds[3],
      name: 'Taal Volcano',
      tag: 'BATANGAS',
      normalizedPosition: Offset(0.37, 0.33),
      facts: const [
        'Taal Volcano is an active complex volcano located in Batangas.',
        'It has an elevation of 311 meters (1,020 ft).',
        'It is located on Volcano Island within Taal Lake.',
        'Taal is one of the smallest active volcanoes in the world.',
        'It has erupted more than 30 times in recorded history.',
        'The volcano has multiple craters formed by previous eruptions.',
        'It is monitored closely by PHIVOLCS because of its frequent activity.',
        'The 2020 eruption caused widespread ashfall across nearby provinces and Metro Manila.',
        'Taal\'s eruptions can produce ashfall, lava, and volcanic gases.',
        'It is a major tourist attraction despite its volcanic hazards.',
      ],
      question: 'Where is Taal Volcano located?',
      options: const ['Albay', 'Batangas', 'Davao'],
      correctOptionIndex: 1,
    ),
    _MissionFourVolcano(
      id: AppConstants.missionFourVolcanoIds[4],
      name: 'Mount Pinatubo',
      tag: 'ZAMBALES AREA',
      normalizedPosition: Offset(0.34, 0.18),
      facts: const [
        'Mount Pinatubo is an active stratovolcano in Central Luzon.',
        'It has a current elevation of 1,486 meters (4,875 ft).',
        'It is located on the borders of Zambales, Tarlac, and Pampanga.',
        'The volcano erupted catastrophically in 1991.',
        'The 1991 eruption was one of the largest volcanic eruptions of the 20th century.',
        'The eruption produced massive lahars that affected nearby communities.',
        'Volcanic ash from Pinatubo temporarily cooled the Earth\'s climate.',
        'A crater lake formed after the 1991 eruption.',
        'The volcano is continuously monitored for signs of renewed activity.',
        'Today, Mount Pinatubo is a popular ecotourism and trekking destination.',
      ],
      question: 'What activity is Mount Pinatubo popular for?',
      options: const ['Swimming', 'Trekking', 'Fishing'],
      correctOptionIndex: 1,
    ),
    _MissionFourVolcano(
      id: AppConstants.missionFourVolcanoIds[5],
      name: 'Mount Kanlaon',
      tag: 'Negros AREA',
      normalizedPosition: Offset(0.54, 0.60),
      facts: const [
        'Mount Kanlaon is an active stratovolcano on Negros Island.',
        'It has an elevation of 2,435 meters (7,989 ft).',
        'It is the highest mountain on Negros Island.',
        'The volcano lies within Mount Kanlaon Natural Park.',
        'Kanlaon has numerous craters and volcanic vents.',
        'It has experienced many historical eruptions, mostly explosive.',
        'PHIVOLCS closely monitors the volcano because of its active status.',
        'The mountain is home to many endemic plants and wildlife.',
        'It is a popular hiking destination for experienced climbers.',
        'Mount Kanlaon is an important watershed and ecological reserve for Negros Island.',
      ],
      question:
          'What type of volcano is Mount Kanlaon, and where is it located?',
      options: const [
        ' Mount Kanlaon is an active stratovolcano in Albay Province',
        'Mount Kanlaon is an active stratovolcano on Negros Island',
        'Mount Kanlaon is an active complex volcano located in Bukidnon',
      ],
      correctOptionIndex: 1,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final answeredIds = widget.isReplay
        ? _replayAnsweredIds
        : player.completedMissionOrbs[AppConstants.missionFourId] ?? const [];
    final correctIds = widget.isReplay
        ? _replayCorrectIds
        : player.completedMissionOrbs[AppConstants
                  .missionFourCorrectAnswersId] ??
              const [];
    final allAnswered = AppConstants.missionFourVolcanoIds.every(
      answeredIds.contains,
    );
    final progress =
        answeredIds.length.clamp(0, _volcanoes.length) / _volcanoes.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: MissionScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
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
                    percentComplete: allAnswered
                        ? 100
                        : (progress * 100).round(),
                    child: allAnswered
                        ? _MissionFourSummary(
                            correctCount: correctIds.length,
                            totalVolcanoes: _volcanoes.length,
                            earnedXP: widget.isReplay
                                ? 0
                                : correctIds.length *
                                      AppConstants.missionFourXpPerCorrect,
                            isPerfect: correctIds.length == _volcanoes.length,
                            onProceed: () => context.go(AppRoutes.menu),
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
                            onSelect: _submitted || _isSaving
                                ? null
                                : (index) {
                                    _playButtonSfx();
                                    setState(() {
                                      _selectedOptionIndex = index;
                                    });
                                  },
                            onSubmit: _submitAnswer,
                            onBackToMap: () {
                              _playButtonSfx();
                              _returnToMap();
                            },
                          )
                        : _VolcanoFactContent(
                            volcano: _selectedVolcano!,
                            onNext: () {
                              _playButtonSfx();
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
      ),
    );
  }

  void _playButtonSfx() {
    unawaited(ref.read(audioControllerProvider).playSfx(SfxCue.button));
  }

  void _selectVolcano(_MissionFourVolcano volcano) {
    _playButtonSfx();
    setState(() {
      _selectedVolcano = volcano;
      _showQuestion = false;
      _selectedOptionIndex = null;
      _submitted = false;
    });
  }

  void _returnToMap() {
    setState(() {
      _selectedVolcano = null;
      _showQuestion = false;
      _selectedOptionIndex = null;
      _submitted = false;
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

    _playButtonSfx();
    final isCorrect = selected == volcano.correctOptionIndex;
    setState(() {
      _isSaving = true;
    });

    if (widget.isReplay) {
      if (!_replayAnsweredIds.contains(volcano.id)) {
        _replayAnsweredIds.add(volcano.id);
      }
      if (isCorrect && !_replayCorrectIds.contains(volcano.id)) {
        _replayCorrectIds.add(volcano.id);
      }
    } else {
      await ref
          .read(playerProvider.notifier)
          .submitMissionFourAnswer(volcanoId: volcano.id, isCorrect: isCorrect);
    }

    if (!mounted) {
      return;
    }

    setState(() {
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
    _showMissionFourSnackBar(
      context,
      widget.isReplay
          ? isCorrect
                ? 'Practice answer recorded'
                : 'Correct answer: ${volcano.options[volcano.correctOptionIndex]}'
          : isCorrect
          ? '+${AppConstants.missionFourXpPerCorrect} XP recorded'
          : 'Correct answer: ${volcano.options[volcano.correctOptionIndex]}',
      isError: !isCorrect,
    );
  }
}

void _showMissionFourSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message.toUpperCase(),
        style: const TextStyle(
          color: _MissionFourPalette.parchment,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
      backgroundColor: isError
          ? const Color(0xFF4A1F24)
          : _MissionFourPalette.basalt,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 1800),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isError
              ? _MissionFourPalette.danger
              : _MissionFourPalette.magma,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
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
        color: _MissionFourPalette.obsidian.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          MissionVolcanoProgressBar(value: progress),
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  right: 18,
                  child: Text(
                    '$percentComplete% COMPLETE',
                    style: const TextStyle(
                      color: _MissionFourPalette.sulfur,
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
            color: _MissionFourPalette.ash,
            fontSize: 13,
            height: 1.35,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: PhilippinesMap(
            volcanoes: volcanoes,
            answeredIds: answeredIds,
            correctIds: correctIds,
            onSelect: (volcano) => onSelect(volcano as _MissionFourVolcano),
          ),
        ),
        const SizedBox(height: 12),
        _MapLegend(answeredCount: answeredIds.length, total: volcanoes.length),
      ],
    );
  }
}

class PhilippinesMap extends StatelessWidget {
  final List<Volcano> volcanoes;
  final List<String> answeredIds;
  final List<String> correctIds;
  final ValueChanged<Volcano> onSelect;

  static const _mapAspectRatio = 2 / 3;
  static const _markerWidth = 82.0;
  static const _markerAnchor = 18.0;

  const PhilippinesMap({
    super.key,
    required this.volcanoes,
    required this.answeredIds,
    required this.correctIds,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSize = _coverImageSize(constraints);

        return Container(
          decoration: BoxDecoration(
            color: _MissionFourPalette.basalt.withValues(alpha: 0.84),
            border: Border.all(color: _MissionFourPalette.fault, width: 1.2),
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x661A0802),
                offset: Offset(0, 8),
                blurRadius: 14,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SizedBox(
                width: imageSize.width,
                height: imageSize.height,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        Assets.missionFourPhilippinesMap,
                        fit: BoxFit.fill,
                      ),
                    ),
                    for (final volcano in volcanoes)
                      Positioned(
                        left:
                            volcano.normalizedPosition.dx * imageSize.width -
                            _markerWidth / 2,
                        top:
                            volcano.normalizedPosition.dy * imageSize.height -
                            _markerAnchor,
                        child: VolcanoMarker(
                          volcano: volcano,
                          isAnswered: answeredIds.contains(_volcanoId(volcano)),
                          isCorrect: correctIds.contains(_volcanoId(volcano)),
                          onTap: answeredIds.contains(_volcanoId(volcano))
                              ? null
                              : () => onSelect(volcano),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Size _coverImageSize(BoxConstraints constraints) {
    final maxWidth = constraints.maxWidth;
    final maxHeight = constraints.maxHeight;
    final heightFromWidth = maxWidth / _mapAspectRatio;
    final widthFromHeight = maxHeight * _mapAspectRatio;

    if (heightFromWidth >= maxHeight) {
      return Size(maxWidth, heightFromWidth);
    }

    return Size(widthFromHeight, maxHeight);
  }

  String _volcanoId(Volcano volcano) {
    if (volcano is _MissionFourVolcano) {
      return volcano.id;
    }
    return volcano.name;
  }
}

class VolcanoMarker extends StatelessWidget {
  final Volcano volcano;
  final bool isAnswered;
  final bool isCorrect;
  final VoidCallback? onTap;

  const VolcanoMarker({
    super.key,
    required this.volcano,
    required this.isAnswered,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAnswered
        ? isCorrect
              ? _MissionFourPalette.sulfur
              : _MissionFourPalette.danger
        : _MissionFourPalette.magma;
    final markerKey = volcano is _MissionFourVolcano
        ? ValueKey('mission4-volcano-${(volcano as _MissionFourVolcano).id}')
        : ValueKey('volcano-${volcano.name}');

    return SizedBox(
      width: 82,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            key: markerKey,
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 52,
              height: 36,
              child: Icon(
                isAnswered
                    ? isCorrect
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined
                    : Icons.terrain_outlined,
                color: color,
                size: 30,
                shadows: [
                  Shadow(
                    color: _MissionFourPalette.obsidian.withValues(alpha: 0.95),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            volcano.name.replaceFirst(' Volcano', ''),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
              shadows: [
                Shadow(
                  color: _MissionFourPalette.obsidian,
                  blurRadius: 6,
                  offset: Offset(0, 1),
                ),
                Shadow(color: _MissionFourPalette.obsidian, blurRadius: 10),
              ],
            ),
          ),
        ],
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
        const Icon(
          Icons.terrain_outlined,
          color: _MissionFourPalette.magma,
          size: 15,
        ),
        const SizedBox(width: 8),
        Text(
          '$answeredCount/$total VOLCANOES CHECKED',
          style: const TextStyle(
            color: _MissionFourPalette.sulfur,
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
                  color: _MissionFourPalette.parchment,
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
                  color: _MissionFourPalette.sulfur,
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
        _MissionImageActionButton(
          assetPath: Assets.missionOneButtonContainer,
          semanticLabel: 'NEXT',
          onPressed: onNext,
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
  final ValueChanged<int>? onSelect;
  final VoidCallback onSubmit;
  final VoidCallback onBackToMap;

  const _VolcanoQuestionContent({
    required this.volcano,
    required this.selectedOptionIndex,
    required this.submitted,
    required this.isSaving,
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
                  color: _MissionFourPalette.parchment,
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
                  color: _MissionFourPalette.sulfur,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 20),
              for (var index = 0; index < volcano.options.length; index++) ...[
                _AnswerOptionTile(
                  optionIndex: index,
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
        const SizedBox(height: 12),
        _MissionImageActionButton(
          assetPath: Assets.missionOneButtonContainer,
          semanticLabel: submitted ? 'BACK TO MAP' : 'SUBMIT ANSWER',
          onPressed: submitted
              ? onBackToMap
              : canSubmit
              ? onSubmit
              : null,
          opacity: submitted || canSubmit || isSaving ? 1 : 0.45,
          child: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: _MissionFourPalette.parchment,
                  ),
                )
              : null,
        ),
      ],
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
                  fit: BoxFit.fill,
                  alignment: Alignment.center,
                ),
              ),
              ?child,
              if (child == null)
                Text(
                  semanticLabel,
                  style: const TextStyle(
                    color: Color(0xFFFFD08A),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    shadows: [
                      Shadow(color: Color(0xFFFF5A00), blurRadius: 8),
                      Shadow(
                        color: Color(0x99000000),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                )
              else
                Opacity(opacity: 0, child: Text(semanticLabel)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerOptionTile extends StatelessWidget {
  final int optionIndex;
  final String text;
  final bool isSelected;
  final bool isSubmitted;
  final bool isCorrect;
  final VoidCallback? onTap;

  const _AnswerOptionTile({
    required this.optionIndex,
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
        height: 86,
        clipBehavior: Clip.none,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            MissionAnswerContainer(
              letter: String.fromCharCode(65 + optionIndex),
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
                  maxLines: 4,
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
            if (showCorrect)
              const Positioned(
                right: 18,
                top: 0,
                bottom: 0,
                child: Icon(
                  Icons.check,
                  color: _MissionFourPalette.sulfur,
                  size: 20,
                ),
              )
            else if (showWrong)
              const Positioned(
                right: 18,
                top: 0,
                bottom: 0,
                child: Icon(
                  Icons.close,
                  color: _MissionFourPalette.danger,
                  size: 20,
                ),
              ),
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
        child: MissionCompletePanel(
          title: 'MISSION 4 COMPLETE!',
          badgeName: isPerfect
              ? 'Philippine Volcano Explorer + Champion'
              : 'Philippine Volcano Explorer Badge',
          badgeImagePath: Assets.badgePhilippineVolcanoExplorer,
          secondaryBadgeImagePath: isPerfect
              ? Assets.badgeVolcanoExplorerChampion
              : null,
          fallbackIcon: Icons.public_outlined,
          message: isPerfect
              ? 'Congratulations, scientist. You earned the Philippine Volcano Explorer Badge and Volcano Explorer Champion Badge.'
              : 'Congratulations, scientist. You earned the Philippine Volcano Explorer Badge.',
          metrics: [
            MissionCompleteMetric(
              label: 'SCORE',
              value: '$correctCount/$totalVolcanoes',
            ),
            MissionCompleteMetric(label: 'EARNED', value: '$earnedXP XP'),
          ],
          onProceed: onProceed,
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
        const Icon(
          Icons.travel_explore_outlined,
          color: _MissionFourPalette.sulfur,
          size: 12,
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            color: _MissionFourPalette.sulfur,
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
          child: Icon(Icons.circle, color: _MissionFourPalette.magma, size: 6),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _MissionFourPalette.ash,
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

class Volcano {
  final String name;
  final Offset normalizedPosition;

  const Volcano({required this.name, required this.normalizedPosition});
}

class _MissionFourVolcano extends Volcano {
  final String id;
  final String tag;
  final List<String> facts;
  final String question;
  final List<String> options;
  final int correctOptionIndex;

  const _MissionFourVolcano({
    required this.id,
    required super.name,
    required this.tag,
    required super.normalizedPosition,
    required this.facts,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
  });
}
