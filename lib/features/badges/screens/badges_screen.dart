import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/badge_award_image.dart';
import '../../../shared/widgets/mission_screen_background.dart';
import '../application/badges_controller.dart';

const _totalBadges = 10;

class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badges = ref.watch(badgesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: MissionScreenBackground(
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _BadgesTopBar(earnedCount: badges.length),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 36),
                sliver: badges.isEmpty
                    ? const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyBadgesState(),
                      )
                    : SliverGrid.builder(
                        itemCount: badges.length,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 220,
                              mainAxisExtent: 252,
                              mainAxisSpacing: 18,
                              crossAxisSpacing: 14,
                            ),
                        itemBuilder: (context, index) =>
                            _BadgeTile(badge: badges[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgesTopBar extends StatelessWidget {
  final int earnedCount;

  const _BadgesTopBar({required this.earnedCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 44,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: MissionBackButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                        return;
                      }
                      context.go(AppRoutes.menu);
                    },
                  ),
                ),
              ),
              const Expanded(
                child: Column(
                  children: [
                    Text(
                      'FIELD COLLECTION',
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFFFB45F),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.1,
                      ),
                    ),
                    SizedBox(height: 2),
                    SizedBox(
                      height: 28,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _EmbossedTitle('VOLCANO BADGES'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 44),
            ],
          ),
          const SizedBox(height: 20),
          _CollectionHeader(earnedCount: earnedCount),
        ],
      ),
    );
  }
}

class _EmbossedTitle extends StatelessWidget {
  final String text;

  const _EmbossedTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: const Offset(0, 2.5),
          child: Text(
            text,
            maxLines: 1,
            style: const TextStyle(
              color: Color(0xFF5A1D0C),
              fontSize: 23,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Text(
          text,
          maxLines: 1,
          style: const TextStyle(
            color: Color(0xFFFFD58A),
            fontSize: 23,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            shadows: [
              Shadow(color: Color(0xFFFF6A19), blurRadius: 8),
              Shadow(color: Color(0xFF1A0702), offset: Offset(1, 1)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CollectionHeader extends StatelessWidget {
  final int earnedCount;

  const _CollectionHeader({required this.earnedCount});

  @override
  Widget build(BuildContext context) {
    final progress = (earnedCount / _totalBadges).clamp(0.0, 1.0);

    return SizedBox(
      height: 116,
      width: double.infinity,
      child: CustomPaint(
        painter: const _VolcanicHeaderPainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Row(
            children: [
              const SizedBox(
                width: 78,
                height: 78,
                child: CustomPaint(painter: _VolcanoSealPainter()),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$earnedCount',
                          style: const TextStyle(
                            color: Color(0xFFFFE3AE),
                            fontSize: 28,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 2),
                          child: Text(
                            ' / $_totalBadges RECOVERED',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 9,
                        color: const Color(0xFF130806),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progress,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFFFD37B),
                                  Color(0xFFFF7018),
                                  Color(0xFFB72E11),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x99FF5C16),
                                  blurRadius: 7,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      earnedCount == _totalBadges
                          ? 'COLLECTION COMPLETE'
                          : 'COMPLETE MISSIONS TO EXTRACT MORE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFF9B4A),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
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
}

class _EmptyBadgesState extends StatelessWidget {
  const _EmptyBadgesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 310),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 132,
              height: 132,
              child: CustomPaint(painter: _DormantCraterPainter()),
            ),
            const SizedBox(height: 20),
            const Text(
              'THE CRATER IS QUIET',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete your first field mission to recover a volcano badge.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'NO BADGES EARNED',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.teal,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final BadgeCollectionItem badge;

  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${badge.name} badge',
      excludeSemantics: true,
      child: CustomPaint(
        painter: _ObsidianBadgeCardPainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 20),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 132,
                    height: 132,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const SizedBox.expand(
                          child: CustomPaint(painter: _MedalWellPainter()),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -3),
                          child: BadgeAwardImage(
                            imagePath: badge.imagePath,
                            size: 112,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 34,
                child: Center(
                  child: Text(
                    badge.name.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFE6C3),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.65,
                      height: 1.2,
                      shadows: [
                        Shadow(color: Color(0xFF000000), offset: Offset(0, 2)),
                      ],
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
}

class _VolcanicHeaderPainter extends CustomPainter {
  const _VolcanicHeaderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 7, size.width - 4, size.height - 7),
      const Radius.circular(15),
    );
    canvas.drawRRect(
      shadow,
      Paint()
        ..color = const Color(0xCC050201)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    final face = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height - 8),
      const Radius.circular(15),
    );
    canvas.drawRRect(
      face,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A2318), Color(0xFF1B100C), Color(0xFF0D0806)],
          stops: [0, 0.55, 1],
        ).createShader(face.outerRect),
    );
    canvas.drawRRect(
      face.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFB765), Color(0xFF6E321D), Color(0xFF1A0B07)],
        ).createShader(face.outerRect),
    );

    final seam = Path()
      ..moveTo(size.width * 0.62, 0)
      ..lineTo(size.width * 0.58, 19)
      ..lineTo(size.width * 0.66, 33)
      ..lineTo(size.width * 0.61, 51);
    canvas.drawPath(
      seam,
      Paint()
        ..color = const Color(0x55FF6C18)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      seam,
      Paint()
        ..color = const Color(0xFFFF7A1A)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VolcanoSealPainter extends CustomPainter {
  const _VolcanoSealPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      center + const Offset(0, 3),
      size.width * 0.46,
      Paint()..color = const Color(0xFF080403),
    );
    canvas.drawCircle(
      center,
      size.width * 0.45,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF4C2113), Color(0xFF190B08)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawCircle(
      center,
      size.width * 0.42,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF8A3C1C),
    );

    final volcano = Path()
      ..moveTo(size.width * 0.16, size.height * 0.72)
      ..lineTo(size.width * 0.37, size.height * 0.43)
      ..lineTo(size.width * 0.47, size.height * 0.48)
      ..lineTo(size.width * 0.56, size.height * 0.39)
      ..lineTo(size.width * 0.84, size.height * 0.72)
      ..close();
    canvas.drawPath(
      volcano,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF71402C), Color(0xFF1B0E0A)],
        ).createShader(Offset.zero & size),
    );
    final lava = Path()
      ..moveTo(size.width * 0.47, size.height * 0.48)
      ..quadraticBezierTo(
        size.width * 0.49,
        size.height * 0.58,
        size.width * 0.43,
        size.height * 0.68,
      )
      ..moveTo(size.width * 0.53, size.height * 0.47)
      ..quadraticBezierTo(
        size.width * 0.57,
        size.height * 0.55,
        size.width * 0.61,
        size.height * 0.66,
      );
    canvas.drawPath(
      lava,
      Paint()
        ..color = const Color(0xFFFF7A19)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.28),
      4,
      Paint()..color = const Color(0xFFFFD179),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ObsidianBadgeCardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final facePath = Path()
      ..moveTo(11, 0)
      ..lineTo(size.width - 7, 0)
      ..lineTo(size.width, 10)
      ..lineTo(size.width - 4, size.height - 18)
      ..lineTo(size.width - 14, size.height - 8)
      ..lineTo(8, size.height - 8)
      ..lineTo(0, size.height - 18)
      ..lineTo(3, 10)
      ..close();

    canvas.drawPath(
      facePath.shift(const Offset(0, 8)),
      Paint()
        ..color = const Color(0xEE050302)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      facePath.shift(const Offset(0, 6)),
      Paint()..color = const Color(0xFF5A2111),
    );
    canvas.drawPath(
      facePath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF35241C), Color(0xFF17100D), Color(0xFF090605)],
          stops: [0, 0.48, 1],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      facePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD07B43), Color(0xFF5D2D1C), Color(0xFF160A06)],
        ).createShader(Offset.zero & size),
    );

    final lavaSeam = Path()
      ..moveTo(4, size.height * 0.68)
      ..lineTo(18, size.height * 0.64)
      ..lineTo(26, size.height * 0.69)
      ..lineTo(39, size.height * 0.66);
    canvas.drawPath(
      lavaSeam,
      Paint()
        ..color = const Color(0x55FF6517)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      lavaSeam,
      Paint()
        ..color = const Color(0xFFFF6B18)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MedalWellPainter extends CustomPainter {
  const _MedalWellPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      center,
      size.width * 0.43,
      Paint()
        ..color = const Color(0x66FF5E16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawCircle(
      center + const Offset(0, 4),
      size.width * 0.43,
      Paint()..color = const Color(0xFF050302),
    );
    canvas.drawCircle(
      center,
      size.width * 0.42,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF38150D), Color(0xFF0B0504)],
          stops: [0, 1],
        ).createShader(Offset.zero & size),
    );
    canvas.drawCircle(
      center,
      size.width * 0.42,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFA14C), Color(0xFF6C2815), Color(0xFF1A0905)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DormantCraterPainter extends CustomPainter {
  const _DormantCraterPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      center + const Offset(0, 7),
      size.width * 0.42,
      Paint()
        ..color = const Color(0xAA030201)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      center,
      size.width * 0.4,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF2E1710), Color(0xFF100907)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawCircle(
      center,
      size.width * 0.4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF754126),
    );
    final crater = Path()
      ..moveTo(size.width * 0.18, size.height * 0.72)
      ..lineTo(size.width * 0.4, size.height * 0.43)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.5,
        size.width * 0.6,
        size.height * 0.43,
      )
      ..lineTo(size.width * 0.82, size.height * 0.72)
      ..close();
    canvas.drawPath(
      crater,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6A3B28), Color(0xFF25130E)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.45),
        width: size.width * 0.23,
        height: size.height * 0.08,
      ),
      Paint()..color = const Color(0xFF090403),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
