import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/lab_widgets.dart';
import '../../../shared/widgets/mission_screen_background.dart';
import '../../player/application/player_controller.dart';

class LevelEightFieldLessonScreen extends ConsumerStatefulWidget {
  const LevelEightFieldLessonScreen({super.key});

  @override
  ConsumerState<LevelEightFieldLessonScreen> createState() =>
      _LevelEightFieldLessonScreenState();
}

class _LevelEightFieldLessonScreenState
    extends ConsumerState<LevelEightFieldLessonScreen> {
  var _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final isComplete =
        player.completedMissionOrbs[AppConstants.levelEightLessonId]?.contains(
          AppConstants.levelEightLessonCompleteId,
        ) ??
        false;

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
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
                  children: [
                    const LabBadge(text: 'FIELD LESSON'),
                    const SizedBox(height: 14),
                    const Text(
                      'Advanced Volcano Response',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Review magma behavior, eruption hazards, and safety measures before the next mission opens.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.45,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const ScanLine(),
                    const SizedBox(height: 14),
                    const _LessonSection(
                      icon: Icons.public_outlined,
                      title: "What's New",
                      subtitle: 'Facts About Volcanoes',
                      bullets: [
                        'More than 80% of the Earth surface is volcanic in origin.',
                        'Mountains and seafloors were formed by volcanic eruptions.',
                        'Volcanic gas emissions helped form the Earth atmosphere.',
                        'A volcano danger zone can cover about a 32.187 km radius.',
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
                          value:
                              'Second most active volcano in the Philippines',
                        ),
                        _Fact(
                          label: 'Feature',
                          value:
                              'Caldera with water, often described as a lake within a lake',
                        ),
                        _Fact(
                          label: 'Eruption period',
                          value: 'January 12, 2020 to January 22, 2020',
                        ),
                        _Fact(label: 'Previous eruption', value: '1977'),
                        _Fact(
                          label: 'Eruption type',
                          value:
                              'Phreatomagmatic eruption from the main crater',
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
                    const SizedBox(height: 8),
                    LabButton(
                      label: isComplete
                          ? 'CONTINUE TO LEVEL 9'
                          : 'COMPLETE LESSON',
                      isLoading: _isSaving,
                      onTap: isComplete
                          ? _continueToLevelNine
                          : _completeLesson,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeLesson() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await ref.read(playerProvider.notifier).completeLevelEightLesson();

    if (!mounted) {
      return;
    }

    showMissionSnackBar(context, 'Field lesson complete');
    context.go(AppRoutes.level(9));
  }

  void _continueToLevelNine() {
    context.go(AppRoutes.level(9));
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderAlt, width: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.teal, size: 18),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
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
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (paragraphs.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final paragraph in paragraphs) _Paragraph(text: paragraph),
          ],
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final bullet in bullets) _Bullet(text: bullet),
          ],
          if (facts.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final fact in facts) _FactRow(fact: fact),
          ],
        ],
      ),
    );
  }
}

class _MagmaTableSection extends StatelessWidget {
  const _MagmaTableSection();

  static const _rows = [
    _MagmaRow(
      type: 'Basaltic',
      silica: 'Low',
      viscosity: 'Low',
      behavior: 'Hot, flows easily, usually less explosive',
    ),
    _MagmaRow(
      type: 'Andesitic',
      silica: 'Medium',
      viscosity: 'Medium',
      behavior: 'Moderate temperature with mixed eruption behavior',
    ),
    _MagmaRow(
      type: 'Rhyolitic',
      silica: 'High',
      viscosity: 'High',
      behavior: 'Cooler, traps gases, often explosive',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderAlt, width: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.table_chart_outlined, color: AppColors.teal, size: 18),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Classifications of Magma',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final row in _rows) _MagmaRowCard(row: row),
        ],
      ),
    );
  }
}

class _PeopleNearVolcanoesSection extends StatelessWidget {
  const _PeopleNearVolcanoesSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderAlt, width: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 118,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF061625),
              border: Border.all(color: AppColors.borderAlt, width: 0.8),
              borderRadius: BorderRadius.circular(7),
            ),
            child: CustomPaint(painter: _SettlementPainter()),
          ),
          const SizedBox(height: 12),
          const Text(
            'Why People Live Near Volcanoes',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          const _Paragraph(
            text:
                'People may live near volcanoes because volcanic soil can be fertile, communities and livelihoods are already established nearby, and volcanic areas can support tourism, energy, and research.',
          ),
        ],
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          height: 1.45,
          letterSpacing: 0,
        ),
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
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, color: AppColors.teal, size: 5),
          ),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF061625),
        border: Border.all(color: AppColors.border, width: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fact.label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.teal,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fact.value,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _MagmaRowCard extends StatelessWidget {
  final _MagmaRow row;

  const _MagmaRowCard({required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF061625),
        border: Border.all(color: AppColors.border, width: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.type.toUpperCase(),
            style: const TextStyle(
              color: AppColors.teal,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Silica: ${row.silica}  |  Viscosity: ${row.viscosity}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            row.behavior,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettlementPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.tealDim.withValues(alpha: 0.08)
      ..strokeWidth = 0.6;
    for (var x = 0.0; x <= size.width; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y <= size.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final volcano = Path()
      ..moveTo(size.width * 0.08, size.height * 0.84)
      ..lineTo(size.width * 0.36, size.height * 0.24)
      ..lineTo(size.width * 0.62, size.height * 0.84)
      ..close();
    canvas.drawPath(
      volcano,
      Paint()..color = const Color(0xFF29363D).withValues(alpha: 0.95),
    );
    canvas.drawPath(
      volcano,
      Paint()
        ..color = AppColors.teal.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final soilPaint = Paint()..color = const Color(0xFF36513E);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.82, size.width, size.height * 0.18),
      soilPaint,
    );

    final housePaint = Paint()..color = const Color(0xFFFFC857);
    for (final dx in [0.68, 0.8]) {
      final left = size.width * dx;
      final top = size.height * 0.62;
      canvas.drawRect(Rect.fromLTWH(left, top, 22, 18), housePaint);
      final roof = Path()
        ..moveTo(left - 2, top)
        ..lineTo(left + 11, top - 12)
        ..lineTo(left + 24, top)
        ..close();
      canvas.drawPath(roof, Paint()..color = const Color(0xFFFF6B35));
    }

    final plumePaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(size.width * 0.34, 6, 54, 58),
      2.3,
      2.4,
      false,
      plumePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Fact {
  final String label;
  final String value;

  const _Fact({required this.label, required this.value});
}

class _MagmaRow {
  final String type;
  final String silica;
  final String viscosity;
  final String behavior;

  const _MagmaRow({
    required this.type,
    required this.silica,
    required this.viscosity,
    required this.behavior,
  });
}
