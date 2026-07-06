import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/assets.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/mission_screen_background.dart';
import '../../player/application/player_controller.dart';

class LevelEightFieldLessonScreen extends ConsumerStatefulWidget {
  final bool isReplay;

  const LevelEightFieldLessonScreen({super.key, this.isReplay = false});

  @override
  ConsumerState<LevelEightFieldLessonScreen> createState() =>
      _LevelEightFieldLessonScreenState();
}

class _LevelEightFieldLessonScreenState
    extends ConsumerState<LevelEightFieldLessonScreen> {
  var _isSaving = false;
  var _pageIndex = 0;
  var _turningForward = true;

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final isComplete =
        !widget.isReplay &&
        (player.completedMissionOrbs[AppConstants.levelEightLessonId]?.contains(
              AppConstants.levelEightLessonCompleteId,
            ) ??
            false);
    final pages = _lessonPages(isComplete);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: MissionScreenBackground(
        child: SafeArea(
          child: Column(
            children: [
              _LessonTopBar(
                xp: player.totalXP,
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }
                  context.go(AppRoutes.menu);
                },
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: _LessonBook(
                        pageIndex: _pageIndex,
                        pageCount: pages.length,
                        turningForward: _turningForward,
                        page: pages[_pageIndex],
                        onPrevious: _pageIndex == 0 || _isSaving
                            ? null
                            : () => _goToPage(_pageIndex - 1),
                        onNext: _pageIndex == pages.length - 1 || _isSaving
                            ? null
                            : () => _goToPage(_pageIndex + 1),
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
  }

  List<Widget> _lessonPages(bool isComplete) {
    return [
      const _DebriefHero(),
      const _LessonSection(
        icon: Icons.public_outlined,
        title: "What's New",
        subtitle: 'Facts About Volcanoes',
        bullets: [
          'More than 80% of the Earth surface is volcanic in origin.',
          'Mountains and seafloors were formed by volcanic eruptions.',
          'Volcanic gas emissions helped form the Earth atmosphere.',
          'A volcano danger zone can cover about a 32.187 km radius.',
        ],
      ),
      const _LessonSection(
        icon: Icons.public_outlined,
        title: "What's New",
        subtitle: 'More field notes',
        bullets: [
          'Volcanic lightning is caused by friction between ash particles moving rapidly to the surface.',
          'Volcanic eruptions can trigger earthquakes, mudflows, rockfalls, flash floods, and tsunamis.',
          'Volcanic ash is made of rock fragments, glass particles, and minerals. It is acidic and has sharp edges.',
        ],
      ),
      const _LessonSection(
        icon: Icons.location_on_outlined,
        title: 'Taal Volcano Eruption',
        subtitle: '2020 field reference',
        facts: [
          _Fact(label: 'Location', value: 'Batangas, Taal'),
          _Fact(
            label: 'Status',
            value: 'Second most active volcano in the Philippines',
          ),
          _Fact(
            label: 'Feature',
            value: 'Caldera with water, often described as a lake within a lake',
          ),
          _Fact(
            label: 'Eruption period',
            value: 'January 12, 2020 to January 22, 2020',
          ),
          _Fact(label: 'Previous eruption', value: '1977'),
          _Fact(
            label: 'Eruption type',
            value: 'Phreatomagmatic eruption from the main crater',
          ),
        ],
      ),
      const _LessonSection(
        icon: Icons.science_outlined,
        title: 'Magma and Its Composition',
        paragraphs: [
          'Magma is molten rock found beneath volcanoes. It forms at destructive plate boundaries and contains silica-rich materials.',
          'As magma cools, minerals begin to crystallize. High-temperature minerals form first, followed by low-temperature minerals.',
          'Viscosity is the resistance of magma to flow. Low-silica magma flows easily, while high-silica magma is thicker and more viscous.',
        ],
      ),
      const _LessonSection(
        icon: Icons.science_outlined,
        title: 'Magma Behavior',
        subtitle: 'Temperature and gas pressure',
        paragraphs: [
          'Temperature also affects viscosity. Hot magma flows faster, while cooler magma flows slowly.',
          'Magma contains dissolved gases such as water vapor, carbon dioxide, and sulfur dioxide. When pressure decreases, gases form bubbles. In thick magma, trapped gases build pressure and can cause explosive eruptions.',
        ],
      ),
      const _MagmaTableSection(),
      const _LessonSection(
        icon: Icons.auto_graph_outlined,
        title: 'Process of Volcanic Eruption',
        paragraphs: [
          'High temperature inside the Earth melts solid rocks in the mantle and turns them into magma. The continuous melting and accumulation of magma push it into the magma chamber of a volcano.',
          'As gases are released from magma, bubbles form through vesiculation. This can happen by decompression or crystallization.',
          'Decompression happens when pressure lowers as magma rises, similar to opening a soda bottle. Crystallization can also increase vapor pressure and lead to vesiculation.',
          'Both decompression and crystallization can trigger an explosive eruption. As magma reaches the Earth surface, it can explode because of dissolved gases. The explosion type depends on magma composition.',
        ],
      ),
      const _LessonSection(
        icon: Icons.warning_amber_outlined,
        title: 'Volcanic Hazards',
        paragraphs: [
          'Volcanic hazards are phenomena from volcanic activity that pose potential threats to people and property.',
          'During major explosive eruptions, large amounts of volcanic gas, aerosol droplets, and ash are injected into the atmosphere.',
          'Tephra, or fragmented volcanic debris, can be violently ejected and extend tens of kilometers above the volcano.',
          'Carbon dioxide can contribute to global warming, while sulfur dioxide can cause global cooling, ozone destruction, and air pollution.',
        ],
      ),
      const _LessonSection(
        icon: Icons.warning_amber_outlined,
        title: 'Hazard Types',
        subtitle: 'Field identification',
        facts: [
          _Fact(
            label: 'Ash fall',
            value:
                'Pulverized rocks, sand, and gritty glass particles ejected into the air.',
          ),
          _Fact(
            label: 'Mudflow',
            value:
                'Water, volcanic material, and debris flowing down the volcano. Also called lahar.',
          ),
          _Fact(
            label: 'Lava flow',
            value:
                'Streams of molten rock and fragmented materials emitted by an eruption.',
          ),
          _Fact(
            label: 'Pyroclastic flow',
            value:
                'Fast-moving hot mixtures of gas, ash, and molten rocks moving away from the volcano.',
          ),
        ],
      ),
      const _PeopleNearVolcanoesSection(),
      const _PrecautionSection(),
      _CompletionConsole(
        label: isComplete
            ? 'RETURN TO MENU'
            : widget.isReplay
            ? 'COMPLETE PRACTICE'
            : 'COMPLETE LESSON',
        isLoading: _isSaving,
        onTap: isComplete ? _continueToLevelNine : _completeLesson,
      ),
    ];
  }

  void _goToPage(int nextPage) {
    if (nextPage < 0 || nextPage >= _lessonPages(false).length) {
      return;
    }

    if (nextPage == _pageIndex) {
      return;
    }

    setState(() {
      _turningForward = nextPage > _pageIndex;
      _pageIndex = nextPage;
    });
  }

  Future<void> _completeLesson() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    if (!widget.isReplay) {
      await ref.read(playerProvider.notifier).completeLevelEightLesson();
    }

    if (!mounted) {
      return;
    }

    showMissionSnackBar(
      context,
      widget.isReplay ? 'Practice lesson complete' : 'Field lesson complete',
    );
    context.go(AppRoutes.menu);
  }

  void _continueToLevelNine() {
    context.go(AppRoutes.menu);
  }
}

class _LessonTopBar extends StatelessWidget {
  final int xp;
  final VoidCallback onBack;

  const _LessonTopBar({required this.xp, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: MissionResearchTopBar(
        title: 'LEVEL 8 DEBRIEF',
        xp: xp,
        onBack: onBack,
      ),
    );
  }
}

class _LessonBook extends StatelessWidget {
  final int pageIndex;
  final int pageCount;
  final bool turningForward;
  final Widget page;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _LessonBook({
    required this.pageIndex,
    required this.pageCount,
    required this.turningForward,
    required this.page,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _BookPageSurface(
            pageIndex: pageIndex,
            turningForward: turningForward,
            child: page,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _LessonImageButton(
                label: 'PREV',
                isLoading: false,
                onTap: onPrevious,
              ),
            ),
            const SizedBox(width: 12),
            _BookProgress(currentPage: pageIndex + 1, pageCount: pageCount),
            const SizedBox(width: 12),
            Expanded(
              child: _LessonImageButton(
                label: pageIndex == pageCount - 1 ? 'DONE' : 'NEXT',
                isLoading: false,
                onTap: onNext,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BookPageSurface extends StatelessWidget {
  final int pageIndex;
  final bool turningForward;
  final Widget child;

  const _BookPageSurface({
    required this.pageIndex,
    required this.turningForward,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.72),
        border: Border.all(color: AppColors.borderAlt, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.7),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 520),
          switchInCurve: Curves.easeOutQuart,
          switchOutCurve: Curves.easeOutQuart,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              fit: StackFit.expand,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (child, animation) {
            final isIncoming = child.key == ValueKey(pageIndex);
            final turn = turningForward ? 1.0 : -1.0;

            return AnimatedBuilder(
              animation: animation,
              child: child,
              builder: (context, child) {
                final progress = animation.value;
                final angle = isIncoming
                    ? (1 - progress) * math.pi / 2 * turn
                    : -progress * math.pi / 2 * turn;

                return Transform(
                  alignment: turningForward
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0014)
                    ..rotateY(angle),
                  child: Opacity(
                    opacity: 0.35 + (progress * 0.65),
                    child: child,
                  ),
                );
              },
            );
          },
          child: _BookPageContent(key: ValueKey(pageIndex), child: child),
        ),
      ),
    );
  }
}

class _BookPageContent extends StatelessWidget {
  final Widget child;

  const _BookPageContent({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
          color: AppColors.surface.withValues(alpha: 0.28),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(width: constraints.maxWidth, child: child),
          ),
        );
      },
    );
  }
}

class _BookProgress extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const _BookProgress({required this.currentPage, required this.pageCount});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'FIELD NOTES',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            minHeight: 3,
            value: currentPage / pageCount,
            color: AppColors.teal,
            backgroundColor: AppColors.tealDark,
          ),
        ],
      ),
    );
  }
}

class _DebriefHero extends StatelessWidget {
  const _DebriefHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.88),
        border: Border.all(color: AppColors.borderAlt, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.12),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            top: -18,
            child: Icon(
              Icons.terrain_outlined,
              color: AppColors.teal.withValues(alpha: 0.08),
              size: 142,
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DossierLabel(text: 'FIELD LESSON  /  RESEARCH DOSSIER'),
              SizedBox(height: 18),
              Text(
                'Advanced\nVolcano Response',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 31,
                  height: 0.98,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.1,
                ),
              ),
              SizedBox(height: 14),
              SizedBox(
                width: 520,
                child: Text(
                  'Review magma behavior, eruption hazards, and safety measures before the next mission opens.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                    letterSpacing: 0,
                  ),
                ),
              ),
              SizedBox(height: 18),
              Row(
                children: [
                  _HeroReadout(value: '08', label: 'RESEARCH FILES'),
                  SizedBox(width: 22),
                  _HeroReadout(value: 'L8', label: 'CLEARANCE'),
                  SizedBox(width: 22),
                  _HeroReadout(value: 'READY', label: 'STATUS'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DossierLabel extends StatelessWidget {
  final String text;

  const _DossierLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.radar_outlined, color: AppColors.teal, size: 13),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.teal,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _HeroReadout extends StatelessWidget {
  final String value;
  final String label;

  const _HeroReadout({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 7,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _LessonSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<String> paragraphs;
  final List<String> bullets;
  final List<_Fact> facts;

  const _LessonSection({
    required this.icon,
    required this.title,
    this.subtitle,
    this.paragraphs = const [],
    this.bullets = const [],
    this.facts = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _DossierPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionIcon(icon: icon),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (paragraphs.isNotEmpty) ...[
              const SizedBox(height: 18),
              for (var i = 0; i < paragraphs.length; i++)
                _Paragraph(text: paragraphs[i]),
            ],
            if (bullets.isNotEmpty) ...[
              const SizedBox(height: 18),
              for (var i = 0; i < bullets.length; i++)
                _Bullet(text: bullets[i]),
            ],
            if (facts.isNotEmpty) ...[
              const SizedBox(height: 18),
              for (var i = 0; i < facts.length; i++) _FactRow(fact: facts[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _DossierPanel extends StatelessWidget {
  final Widget child;

  const _DossierPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        border: Border.all(color: AppColors.borderAlt, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.65),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.07),
            blurRadius: 18,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 0,
            right: 0,
            child: SizedBox(
              width: 28,
              child: Divider(
                height: 1,
                thickness: 1,
                color: AppColors.teal,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _SectionIcon extends StatelessWidget {
  final IconData icon;

  const _SectionIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.tealDark,
          border: Border.all(color: AppColors.borderAlt, width: 1),
        ),
        child: Icon(icon, color: AppColors.teal, size: 19),
      ),
    );
  }
}

class _MagmaTableSection extends StatelessWidget {
  const _MagmaTableSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _DossierPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionIcon(icon: Icons.table_chart_outlined),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Classifications of Magma',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _ReferencePlate(
              assetPath: Assets.missionEightMagmaClassification,
              semanticLabel: 'Magma classification table',
              caption: 'MAGMA COMPOSITION AND CHARACTERISTICS',
            ),
          ],
        ),
      ),
    );
  }
}

class _PeopleNearVolcanoesSection extends StatelessWidget {
  const _PeopleNearVolcanoesSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _DossierPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionIcon(icon: Icons.groups_outlined),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Why People Live Near Volcanoes',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _ReferencePlate(
              assetPath: Assets.missionEightWhyLiveNearVolcanoes,
              semanticLabel: 'Reasons people live near volcanoes',
              caption: 'SETTLEMENT BENEFITS AND LIVELIHOODS',
            ),
          ],
        ),
      ),
    );
  }
}

class _PrecautionSection extends StatelessWidget {
  const _PrecautionSection();

  @override
  Widget build(BuildContext context) {
    return const _LessonSection(
      icon: Icons.health_and_safety_outlined,
      title: 'Precautionary Measures',
      subtitle: 'Before, during, and after an eruption',
      facts: [
        _Fact(
          label: 'Before',
          value:
              'Know volcano facts, danger zones, eruption history, evacuation sites, authority announcements, and prepare clean water and food supplies.',
        ),
        _Fact(
          label: 'During',
          value:
              'Stay indoors, close doors and windows, secure water and food, wear a mask and eye protection if going out, avoid danger zones, follow news, and obey evacuation orders.',
        ),
        _Fact(
          label: 'After',
          value:
              'Assess if it is safe to go out, check house damage, remove ash from roofs, gutters, and windows, replace contaminated supplies, and stay updated with authorities.',
        ),
      ],
    );
  }
}

class _Paragraph extends StatelessWidget {
  final String text;

  const _Paragraph({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ReadingMarker(),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.5,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ReadingMarker(),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  final _Fact fact;

  const _FactRow({required this.fact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 11),
      color: AppColors.background.withValues(alpha: 0.7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ReadingMarker(),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fact.label.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fact.value,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                    letterSpacing: 0,
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

class _ReferencePlate extends StatelessWidget {
  final String assetPath;
  final String semanticLabel;
  final String caption;

  const _ReferencePlate({
    required this.assetPath,
    required this.semanticLabel,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF2E7D9),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Column(
        children: [
          Image.asset(
            assetPath,
            width: double.infinity,
            fit: BoxFit.fitWidth,
            filterQuality: FilterQuality.high,
            semanticLabel: semanticLabel,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              caption,
              style: const TextStyle(
                color: Color(0xFF4B2B1B),
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingMarker extends StatelessWidget {
  const _ReadingMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 25,
      height: 25,
      alignment: Alignment.center,
      color: AppColors.tealDark,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.teal,
          shape: BoxShape.circle,
        ),
        child: SizedBox(width: 5, height: 5),
      ),
    );
  }
}

class _CompletionConsole extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _CompletionConsole({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      color: AppColors.background.withValues(alpha: 0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DossierLabel(text: 'DOSSIER REVIEW COMPLETE'),
          const SizedBox(height: 9),
          const Text(
            'Confirm field readiness',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your research notes are ready for mission deployment.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _LessonImageButton(label: label, isLoading: isLoading, onTap: onTap),
        ],
      ),
    );
  }
}

class _LessonImageButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  const _LessonImageButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null && !isLoading;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Opacity(
        opacity: isEnabled ? 1 : 0.55,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(Assets.missionOneButtonContainer, fit: BoxFit.fill),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isEnabled ? onTap : null,
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.teal,
                          ),
                        )
                      : Text(
                          label,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact {
  final String label;
  final String value;

  const _Fact({required this.label, required this.value});
}
