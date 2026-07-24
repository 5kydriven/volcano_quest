import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/audio_catalog.dart';
import '../../../core/audio/audio_controller.dart';
import '../../../core/constants/assets.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/mission_screen_background.dart';
import '../../player/application/player_controller.dart';

class StarterKnowledgeScreen extends ConsumerStatefulWidget {
  final bool requireCompletion;

  const StarterKnowledgeScreen({super.key, this.requireCompletion = false});

  @override
  ConsumerState<StarterKnowledgeScreen> createState() =>
      _StarterKnowledgeScreenState();
}

class _StarterKnowledgeScreenState
    extends ConsumerState<StarterKnowledgeScreen> {
  var _pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.requireCompletion,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: MissionScreenBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
                  child: widget.requireCompletion
                      ? const _GuideTopBar()
                      : _GuideTopBar(onBack: _returnToMenu),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: _GuideBook(
                          pageIndex: _pageIndex,
                          pageCount: _guidePages.length,
                          page: _guidePages[_pageIndex],
                          onPrevious: _pageIndex == 0
                              ? null
                              : () => _goToPage(_pageIndex - 1),
                          onNext: _pageIndex == _guidePages.length - 1
                              ? _finishGuide
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
      ),
    );
  }

  void _goToPage(int nextPage) {
    if (nextPage < 0 || nextPage >= _guidePages.length) {
      return;
    }

    _playButtonSfx();
    setState(() {
      _pageIndex = nextPage;
    });
  }

  void _returnToMenu() {
    _playButtonSfx();
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.menu);
  }

  Future<void> _finishGuide() async {
    _playButtonSfx();
    if (widget.requireCompletion) {
      await ref.read(playerProvider.notifier).completeStarterKnowledge();
      if (!mounted) {
        return;
      }
    }
    context.go(AppRoutes.menu);
  }

  void _playButtonSfx() {
    unawaited(ref.read(audioControllerProvider).playSfx(SfxCue.button));
  }
}

class _GuideTopBar extends StatelessWidget {
  final VoidCallback? onBack;

  const _GuideTopBar({this.onBack});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: compact ? 42 : 48,
            child: onBack == null ? null : MissionBackButton(onPressed: onBack),
          ),
          Expanded(
            child: Text(
              'Learning Objectives',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 20 : 24,
                fontWeight: FontWeight.w900,
                letterSpacing: compact ? 1 : 2,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [Color(0xFFFFA726), Color(0xFFE65100)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(Rect.fromLTWH(0, 0, 300, 70)),
                shadows: const [
                  Shadow(
                    color: Colors.black,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                  Shadow(
                    color: Color(0xFF5D2A00),
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _guidePages = [
  _GuidePage(
    icon: Icons.school_outlined,
    label: 'LEARNING TARGET',
    title: 'Volcano Starter Knowledge',
    paragraphs: [],
    bullets: [
      'Explain the structure of a volcano.',
      'Differentiate volcanoes based on structure and activity.',
      'Identify examples of volcano types found in the Philippines.',
      'Compare the different types of volcanic eruptions.',
    ],
  ),
  _GuidePage(
    icon: Icons.account_tree_outlined,
    label: 'STRUCTURE',
    title: 'Parts of a Volcano',
    paragraphs: [
      'A volcano is a cone-shaped mountain or hill with an opening where lava, gases, hot vapor, and rock fragments erupt from Earth\'s crust.',
      'Magma beneath the surface moves toward or onto the surface through volcanism.',
    ],
    bullets: [
      'Summit, slopes, and base describe the outer shape of a volcano.',
      'Magma chamber stores molten rock before an eruption.',
      'Main vent, conduit, and side vent are pathways where magma travels.',
      'Crater, lava, and ash-gas clouds are visible eruption features.',
    ],
    images: [
      _GuideImage(assetPath: Assets.volcanoParts, label: 'VOLCANO PARTS'),
    ],
  ),
  _GuidePage(
    icon: Icons.terrain_outlined,
    label: 'STRUCTURE TYPES',
    title: 'Types Based on Shape',
    paragraphs: [
      'Volcanoes can be classified by structure: their shape, parts, and how they form over time.',
    ],
    facts: [
      _GuideFact(
        title: 'Cinder Cone',
        body: 'Small, steep-sided volcano built from loose cinders and ash.',
        image: Assets.cinderCone,
      ),
      _GuideFact(
        title: 'Composite',
        body: 'Tall, layered volcano built from lava, ash, and rock fragments.',
        image: Assets.compositeVolcano,
      ),
      _GuideFact(
        title: 'Shield',
        body: 'Wide, gently sloping volcano formed by thin lava flows.',
        image: Assets.shieldVolcano,
      ),
    ],
  ),
  _GuidePage(
    icon: Icons.radar_outlined,
    label: 'ACTIVITY TYPES',
    title: 'Types Based on Activity',
    paragraphs: [
      'PHIVOLCS classifies volcanoes based on activity and eruption history.',
    ],
    bullets: [
      'Active volcanoes erupted within the last 10,000 years and may still show activity such as ash, gas, or lava release.',
      'Inactive volcanoes have not erupted for over 10,000 years and show no signs of activity.',
      'Potentially active volcanoes have no recorded eruption but still appear young in structure.',
      'The Philippines has more than 100 volcanoes, and 24 of them are active.',
    ],
    images: [
      _GuideImage(
        assetPath: Assets.mountains,
        label: 'VOLCANO ACTIVITY CLASSIFICATION',
      ),
    ],
  ),
  _GuidePage(
    icon: Icons.location_on_outlined,
    label: 'PHILIPPINE EXAMPLES',
    title: 'Local Volcano Profiles',
    facts: [
      _GuideFact(
        title: 'Mayon Volcano',
        body:
            'Active volcano in Albay, Luzon, famous for its perfect cone shape.',
        image: Assets.missionSevenMayon,
      ),
      _GuideFact(
        title: 'Taal Volcano',
        body:
            'One of the most active volcanoes in the Philippines, located in Batangas.',
        image: Assets.missionSevenTaal,
      ),
      _GuideFact(
        title: 'Mount Arayat',
        body:
            'A Philippine volcano profile used in the investigation center mission.',
        image: Assets.missionSevenArayat,
      ),
      _GuideFact(
        title: 'Mount Makiling',
        body:
            'Inactive volcano in Laguna, known for hot springs and forested slopes.',
        image: Assets.missionSevenMakiling,
      ),
    ],
  ),
  _GuidePage(
    icon: Icons.local_fire_department_outlined,
    label: 'ERUPTIONS',
    title: 'Types of Volcanic Eruptions',
    paragraphs: [
      'Volcanic eruptions may be wet or dry depending on water content and magma behavior.',
    ],
    facts: [
      _GuideFact(
        title: 'Phreatic',
        body: 'Steam-driven eruption caused when hot rocks contact water.',
        image: Assets.phreatic,
      ),
      _GuideFact(
        title: 'Phreatomagmatic',
        body: 'Violent eruption caused by contact between water and magma.',
        image: Assets.phreatomagmatic,
      ),
      _GuideFact(
        title: 'Strombolian',
        body: 'Periodic weak-to-violent eruption with lava fountains.',
        image: Assets.strombolian,
      ),
      _GuideFact(
        title: 'Vulcanian',
        body:
            'Explosive eruption with tall ash columns and pyroclastic material.',
        image: Assets.vulcanian,
      ),
    ],
  ),
  _GuidePage(
    icon: Icons.check_circle_outline,
    label: 'WRAP-UP',
    title: 'Ready for the Mission Map',
    paragraphs: [
      'You should now be ready to describe volcano parts, classify volcanoes, identify Philippine examples, and compare eruption styles.',
      'Use this guide anytime before starting or replaying missions on the map.',
    ],
    bullets: [
      'Structure tells what parts make up a volcano.',
      'Classification explains volcano shape and activity.',
      'Examples connect the lesson to Philippine volcanoes.',
      'Eruption types help compare how volcanoes release materials.',
    ],
  ),
];

class _GuideBook extends StatelessWidget {
  final int pageIndex;
  final int pageCount;
  final _GuidePage page;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _GuideBook({
    required this.pageIndex,
    required this.pageCount,
    required this.page,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.78),
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
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _GuidePageView(key: ValueKey(pageIndex), page: page),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _GuideNavButton(label: 'PREVIOUS', onTap: onPrevious),
            ),
            const SizedBox(width: 12),
            _GuideProgress(currentPage: pageIndex + 1, pageCount: pageCount),
            const SizedBox(width: 12),
            Expanded(
              child: _GuideNavButton(
                label: pageIndex == pageCount - 1 ? 'DONE' : 'NEXT',
                onTap: onNext,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GuidePageView extends StatelessWidget {
  final _GuidePage page;

  const _GuidePageView({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surface.withValues(alpha: 0.32),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GuideHeader(page: page),
            if (page.paragraphs.isNotEmpty) ...[
              const SizedBox(height: 14),
              ...page.paragraphs.map(_GuideParagraph.new),
            ],
            if (page.bullets.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...page.bullets.map(_GuideBullet.new),
            ],
            if (page.images.isNotEmpty) ...[
              const SizedBox(height: 14),
              _GuideImageGrid(images: page.images),
            ],
            if (page.facts.isNotEmpty) ...[
              const SizedBox(height: 14),
              _GuideFactGrid(facts: page.facts),
            ],
          ],
        ),
      ),
    );
  }
}

class _GuideHeader extends StatelessWidget {
  final _GuidePage page;

  const _GuideHeader({required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xE61A0E08),
        border: Border.all(color: AppColors.borderAlt, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(page.icon, color: AppColors.teal, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  page.label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  page.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
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

class _GuideParagraph extends StatelessWidget {
  final String text;

  const _GuideParagraph(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.35,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _GuideBullet extends StatelessWidget {
  final String text;

  const _GuideBullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 5),
            decoration: const BoxDecoration(
              color: AppColors.teal,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.tealDim, blurRadius: 5)],
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.32,
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

class _GuideImageGrid extends StatelessWidget {
  final List<_GuideImage> images;

  const _GuideImageGrid({required this.images});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 620 ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: images.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: columns == 1 ? 1.7 : 1.45,
          ),
          itemBuilder: (context, index) {
            final image = images[index];
            return _GuideImageCard(
              assetPath: image.assetPath,
              label: image.label,
            );
          },
        );
      },
    );
  }
}

class _GuideFactGrid extends StatelessWidget {
  final List<_GuideFact> facts;

  const _GuideFactGrid({required this.facts});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 620 ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: facts.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: columns == 1 ? 2.25 : 1.55,
          ),
          itemBuilder: (context, index) => _GuideFactCard(fact: facts[index]),
        );
      },
    );
  }
}

class _GuideFactCard extends StatelessWidget {
  final _GuideFact fact;

  const _GuideFactCard({required this.fact});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.72),
        border: Border.all(color: AppColors.borderAlt.withValues(alpha: 0.72)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Image.asset(fact.image, fit: BoxFit.cover),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fact.title.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 11,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    fact.body,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideImageCard extends StatelessWidget {
  final String assetPath;
  final String label;

  const _GuideImageCard({required this.assetPath, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.72),
        border: Border.all(color: AppColors.borderAlt.withValues(alpha: 0.72)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(assetPath, fit: BoxFit.contain),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              color: AppColors.background.withValues(alpha: 0.78),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.9,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideProgress extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const _GuideProgress({required this.currentPage, required this.pageCount});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$currentPage / $pageCount',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 5),
          MissionVolcanoProgressBar(value: currentPage / pageCount, height: 8),
        ],
      ),
    );
  }
}

class _GuideNavButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _GuideNavButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: SizedBox(
        height: 46,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xE61A0E08),
            border: Border.all(color: const Color(0xFFD0733C), width: 1.1),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66030201),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onTap,
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFFE8C4),
                    fontSize: 12,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    shadows: [
                      Shadow(color: Color(0xFF000000), offset: Offset(0, 1)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuidePage {
  final IconData icon;
  final String label;
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
  final List<_GuideImage> images;
  final List<_GuideFact> facts;

  const _GuidePage({
    required this.icon,
    required this.label,
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
    this.images = const [],
    this.facts = const [],
  });
}

class _GuideImage {
  final String assetPath;
  final String label;

  const _GuideImage({required this.assetPath, required this.label});
}

class _GuideFact {
  final String title;
  final String body;
  final String image;

  const _GuideFact({
    required this.title,
    required this.body,
    required this.image,
  });
}
