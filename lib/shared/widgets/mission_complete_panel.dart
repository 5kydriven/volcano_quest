import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio_catalog.dart';
import '../../core/audio/audio_controller.dart';
import '../../core/constants/assets.dart';
import '../../core/theme/app_theme.dart';
import 'badge_award_image.dart';

const _lava = Color(0xFFFF7A1A);
const _lavaDeep = Color(0xFFC74214);
const _ember = Color(0xFFFFB45F);

class MissionCompletePanel extends ConsumerStatefulWidget {
  final String title;
  final String badgeName;
  final String? badgeImagePath;
  final String? secondaryBadgeImagePath;
  final IconData fallbackIcon;
  final String message;
  final List<MissionCompleteMetric> metrics;
  final VoidCallback onProceed;
  final String buttonLabel;

  const MissionCompletePanel({
    super.key,
    required this.title,
    required this.badgeName,
    required this.metrics,
    required this.onProceed,
    this.badgeImagePath,
    this.secondaryBadgeImagePath,
    this.fallbackIcon = Icons.workspace_premium_outlined,
    this.message = 'Congratulations, scientist. You earned this badge.',
    this.buttonLabel = 'RETURN TO MENU',
  });

  @override
  ConsumerState<MissionCompletePanel> createState() =>
      _MissionCompletePanelState();
}

class _MissionCompletePanelState extends ConsumerState<MissionCompletePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (_isAutomatedTestBinding()) {
      _shineController.value = 0;
    } else {
      _shineController.repeat();
    }
    unawaited(ref.read(audioControllerProvider).playSfx(SfxCue.achievement));
  }

  bool _isAutomatedTestBinding() {
    final bindingType = WidgetsBinding.instance.runtimeType.toString();
    return bindingType.contains('TestWidgetsFlutterBinding') ||
        bindingType.contains('AutomatedTestWidgetsFlutterBinding');
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _MissionCompletePanelPainter(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 136,
              height: 136,
              child: AnimatedBuilder(
                animation: _shineController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _BadgeShinePainter(
                      progress: _shineController.value,
                    ),
                    child: child,
                  );
                },
                child: Center(child: _BadgeDisplay(widget: widget)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _displayTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.badgeName.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ember,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.3,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                for (var index = 0; index < widget.metrics.length; index++) ...[
                  if (index > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _MissionCompleteMetricTile(widget.metrics[index]),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            _MissionCompleteImageButton(
              onPressed: widget.onProceed,
              child: Text(widget.buttonLabel),
            ),
          ],
        ),
      ),
    );
  }

  String get _displayTitle {
    return widget.title.endsWith('!')
        ? widget.title.substring(0, widget.title.length - 1)
        : widget.title;
  }
}

class _BadgeDisplay extends StatelessWidget {
  final MissionCompletePanel widget;

  const _BadgeDisplay({required this.widget});

  @override
  Widget build(BuildContext context) {
    final badgeImagePath = widget.badgeImagePath;
    final secondaryBadgeImagePath = widget.secondaryBadgeImagePath;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _ember.withValues(alpha: 0.34),
            blurRadius: 32,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: _lava.withValues(alpha: 0.22),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: secondaryBadgeImagePath == null
          ? badgeImagePath == null
                ? Icon(widget.fallbackIcon, color: _ember, size: 72)
                : BadgeAwardImage(
                    imagePath: badgeImagePath,
                    fallbackIcon: widget.fallbackIcon,
                    fallbackColor: _ember,
                    size: 104,
                  )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BadgeAwardImage(
                  imagePath: badgeImagePath ?? secondaryBadgeImagePath,
                  fallbackIcon: widget.fallbackIcon,
                  fallbackColor: _ember,
                  size: 70,
                ),
                const SizedBox(width: 6),
                BadgeAwardImage(
                  imagePath: secondaryBadgeImagePath,
                  fallbackIcon: Icons.workspace_premium_outlined,
                  fallbackColor: _ember,
                  size: 70,
                ),
              ],
            ),
    );
  }
}

class MissionCompleteMetric {
  final String label;
  final String value;

  const MissionCompleteMetric({required this.label, required this.value});
}

class _MissionCompleteMetricTile extends StatelessWidget {
  final MissionCompleteMetric metric;

  const _MissionCompleteMetricTile(this.metric);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B0E08).withValues(alpha: 0.82),
        border: Border.all(color: _lavaDeep.withValues(alpha: 0.54), width: 1),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: _lavaDeep.withValues(alpha: 0.12),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            metric.value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.label,
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

class _MissionCompletePanelPainter extends CustomPainter {
  const _MissionCompletePanelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final panel = RRect.fromRectAndRadius(rect, const Radius.circular(10));

    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xF20F0E0D), Color(0xF22A1208)],
      ).createShader(rect);
    canvas.drawRRect(panel, basePaint);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.52),
        radius: 0.82,
        colors: [
          _lava.withValues(alpha: 0.24),
          _lavaDeep.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0, 0.48, 1],
      ).createShader(rect);
    canvas.drawRRect(panel, glowPaint);

    final ridgePath = Path()
      ..moveTo(0, size.height * 0.72)
      ..lineTo(size.width * 0.18, size.height * 0.62)
      ..lineTo(size.width * 0.32, size.height * 0.69)
      ..lineTo(size.width * 0.48, size.height * 0.54)
      ..lineTo(size.width * 0.64, size.height * 0.68)
      ..lineTo(size.width * 0.8, size.height * 0.6)
      ..lineTo(size.width, size.height * 0.72)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      ridgePath,
      Paint()..color = const Color(0xFF160A05).withValues(alpha: 0.64),
    );

    final lavaPath = Path()
      ..moveTo(size.width * 0.44, size.height * 0.55)
      ..lineTo(size.width * 0.49, size.height * 0.62)
      ..lineTo(size.width * 0.47, size.height * 0.77)
      ..lineTo(size.width * 0.53, size.height * 0.92)
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(size.width * 0.57, size.height)
      ..lineTo(size.width * 0.6, size.height * 0.9)
      ..lineTo(size.width * 0.54, size.height * 0.75)
      ..lineTo(size.width * 0.56, size.height * 0.62)
      ..lineTo(size.width * 0.51, size.height * 0.55)
      ..close();
    canvas.drawPath(
      lavaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_ember.withValues(alpha: 0.36), _lava.withValues(alpha: 0)],
        ).createShader(rect),
    );

    final scanPaint = Paint()
      ..color = _ember.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    for (var y = 12.0; y < size.height; y += 14) {
      canvas.drawLine(Offset(12, y), Offset(size.width - 12, y), scanPaint);
    }

    final cornerPaint = Paint()
      ..color = _ember.withValues(alpha: 0.42)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square;
    const inset = 12.0;
    const corner = 26.0;
    canvas
      ..drawLine(
        const Offset(inset, inset),
        const Offset(inset + corner, inset),
        cornerPaint,
      )
      ..drawLine(
        const Offset(inset, inset),
        const Offset(inset, inset + corner),
        cornerPaint,
      )
      ..drawLine(
        Offset(size.width - inset - corner, inset),
        Offset(size.width - inset, inset),
        cornerPaint,
      )
      ..drawLine(
        Offset(size.width - inset, inset),
        Offset(size.width - inset, inset + corner),
        cornerPaint,
      )
      ..drawLine(
        Offset(inset, size.height - inset - corner),
        Offset(inset, size.height - inset),
        cornerPaint,
      )
      ..drawLine(
        Offset(inset, size.height - inset),
        Offset(inset + corner, size.height - inset),
        cornerPaint,
      )
      ..drawLine(
        Offset(size.width - inset - corner, size.height - inset),
        Offset(size.width - inset, size.height - inset),
        cornerPaint,
      )
      ..drawLine(
        Offset(size.width - inset, size.height - inset - corner),
        Offset(size.width - inset, size.height - inset),
        cornerPaint,
      );
  }

  @override
  bool shouldRepaint(covariant _MissionCompletePanelPainter oldDelegate) {
    return false;
  }
}

class _BadgeShinePainter extends CustomPainter {
  final double progress;

  const _BadgeShinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    final rayPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;

    for (var index = 0; index < 12; index++) {
      final angle = (math.pi * 2 * (index / 12)) + (progress * math.pi * 2);
      final pulse = 0.45 + 0.55 * math.sin((progress * math.pi * 2) + index);
      rayPaint.color = _ember.withValues(alpha: 0.14 + (pulse * 0.2));
      final inner = Offset(
        center.dx + math.cos(angle) * radius * 0.58,
        center.dy + math.sin(angle) * radius * 0.58,
      );
      final outer = Offset(
        center.dx + math.cos(angle) * radius * (0.82 + pulse * 0.1),
        center.dy + math.sin(angle) * radius * (0.82 + pulse * 0.1),
      );
      canvas.drawLine(inner, outer, rayPaint);
    }

    final glintAngle = progress * math.pi * 2;
    final glintPaint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.2)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    final glintCenter = Offset(
      center.dx + math.cos(glintAngle) * radius * 0.42,
      center.dy + math.sin(glintAngle) * radius * 0.42,
    );
    canvas
      ..drawLine(
        glintCenter.translate(-8, 0),
        glintCenter.translate(8, 0),
        glintPaint,
      )
      ..drawLine(
        glintCenter.translate(0, -8),
        glintCenter.translate(0, 8),
        glintPaint,
      );
  }

  @override
  bool shouldRepaint(covariant _BadgeShinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _MissionCompleteImageButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const _MissionCompleteImageButton({
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled = onPressed != null;

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
                onTap: onPressed == null
                    ? null
                    : () {
                        unawaited(
                          ref
                              .read(audioControllerProvider)
                              .playSfx(SfxCue.button),
                        );
                        onPressed!();
                      },
                child: Center(
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                    child: child,
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
