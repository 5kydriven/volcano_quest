import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio_catalog.dart';
import '../../core/audio/audio_controller.dart';
import '../../core/constants/assets.dart';
import '../../core/theme/app_theme.dart';

class MissionScreenBackground extends StatelessWidget {
  final Widget child;

  const MissionScreenBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          Assets.missionScreenBackground,
          fit: BoxFit.fill,
          alignment: Alignment.center,
        ),
        ColoredBox(color: AppColors.background.withValues(alpha: 0.14)),
        child,
      ],
    );
  }
}

class MissionBackButton extends ConsumerWidget {
  final VoidCallback? onPressed;

  const MissionBackButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed == null
          ? null
          : () {
              unawaited(
                ref.read(audioControllerProvider).playSfx(SfxCue.button),
              );
              onPressed!();
            },
      child: Image.asset(Assets.backButton, height: 36, fit: BoxFit.contain),
    );
  }
}

void showMissionSnackBar(
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
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
      backgroundColor: isError ? const Color(0xFF4A1F24) : AppColors.surface,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 1800),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isError ? const Color(0xFFFF7A7A) : AppColors.teal,
          width: 0.8,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
    ),
  );
}

class MissionVolcanoProgressBar extends StatelessWidget {
  final double value;
  final double height;

  const MissionVolcanoProgressBar({
    super.key,
    required this.value,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height + 10,
      width: double.infinity,
      child: CustomPaint(
        painter: _MissionVolcanoProgressPainter(
          value: value.clamp(0, 1),
          barHeight: height,
        ),
      ),
    );
  }
}

class _MissionVolcanoProgressPainter extends CustomPainter {
  final double value;
  final double barHeight;

  const _MissionVolcanoProgressPainter({
    required this.value,
    required this.barHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final outerRect = Offset.zero & size;
    final outerRadius = Radius.circular(size.height * 0.42);
    final outer = RRect.fromRectAndRadius(outerRect, outerRadius);

    final shadowPaint = Paint()
      ..color = const Color(0xAA000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(outer.shift(const Offset(0, 3)), shadowPaint);

    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF5A2C18), Color(0xFF241109), Color(0xFF0C0604)],
        stops: [0, 0.5, 1],
      ).createShader(outerRect);
    canvas.drawRRect(outer, basePaint);

    final topBevelPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFC46F), Color(0xFF7A3418), Color(0xFF140805)],
      ).createShader(outerRect);
    canvas.drawRRect(outer.deflate(0.8), topBevelPaint);

    final innerShadowPaint = Paint()
      ..color = const Color(0x88000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(outer.deflate(4), innerShadowPaint);

    final channelHeight = barHeight.clamp(6.0, size.height - 8);
    final channelRect = Rect.fromLTWH(
      5,
      (size.height - channelHeight) / 2 - 0.5,
      size.width - 10,
      channelHeight,
    );
    final radius = Radius.circular(channelHeight / 2);
    final track = RRect.fromRectAndRadius(channelRect, radius);

    final trackPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3A2115), Color(0xFF120A07), Color(0xFF090504)],
      ).createShader(channelRect);
    canvas.drawRRect(track, trackPaint);

    final fillWidth = (channelRect.width * value).clamp(0.0, channelRect.width);
    if (fillWidth > 0) {
      final fillRect = Rect.fromLTWH(
        channelRect.left,
        channelRect.top,
        fillWidth,
        channelRect.height,
      );
      final fillTrack = RRect.fromRectAndRadius(fillRect, radius);
      final glowPaint = Paint()
        ..color = const Color(0x66FF6D1A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawRRect(fillTrack.inflate(1), glowPaint);

      final fillPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFC46F), Color(0xFFFF7A1A), Color(0xFFC74214)],
          stops: [0, 0.48, 1],
        ).createShader(fillRect);
      canvas.drawRRect(fillTrack, fillPaint);

      final moltenPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (size.height * 0.16).clamp(1.0, 2.0)
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xCCFFE2A8);
      final y = channelRect.top + channelRect.height * 0.35;
      canvas.drawLine(
        Offset(channelRect.left + channelRect.height * 0.55, y),
        Offset(
          (channelRect.left + fillWidth - channelRect.height * 0.6).clamp(
            channelRect.left,
            channelRect.left + fillWidth,
          ),
          y,
        ),
        moltenPaint,
      );

      final capPaint = Paint()
        ..shader =
            const RadialGradient(
              colors: [Color(0xFFFFF1C2), Color(0xFFFF6D1A), Color(0x00FF6D1A)],
            ).createShader(
              Rect.fromCircle(
                center: Offset(channelRect.left + fillWidth, size.height / 2),
                radius: channelRect.height * 1.45,
              ),
            );
      canvas.drawCircle(
        Offset(channelRect.left + fillWidth, size.height / 2),
        channelRect.height,
        capPaint,
      );
    }

    final crackPaint = Paint()
      ..color = const Color(0x774A1A0D)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < 7; i++) {
      final x = size.width * (i / 7);
      canvas.drawLine(
        Offset(x, size.height * 0.18),
        Offset(x + (i.isEven ? 5 : -4), size.height * 0.82),
        crackPaint,
      );
    }

    final channelBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFBE73), Color(0xFF7A3418), Color(0xFF1A0D08)],
      ).createShader(channelRect);
    canvas.drawRRect(track.deflate(0.5), channelBorderPaint);

    final lowerLipPaint = Paint()
      ..color = const Color(0xAA090403)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
      Rect.fromLTWH(4, size.height * 0.28, size.width - 8, size.height * 0.62),
      0,
      3.14159,
      false,
      lowerLipPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MissionVolcanoProgressPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.barHeight != barHeight;
  }
}

class MissionResearchTopBar extends StatelessWidget {
  final String title;
  final int xp;
  final int? avatarIndex;
  final VoidCallback onBack;

  const MissionResearchTopBar({
    super.key,
    required this.title,
    required this.xp,
    required this.onBack,
    this.avatarIndex,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        final tight = constraints.maxWidth < 360;

        return Row(
          children: [
            MissionBackButton(onPressed: onBack),
            SizedBox(width: tight ? 6 : 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: tight
                      ? 17
                      : compact
                      ? 20
                      : 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: tight ? 1 : 2,
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
            SizedBox(width: tight ? 6 : 12),
            _MissionStatusBadge(
              xp: xp,
              avatarIndex: avatarIndex,
              compact: compact,
            ),
          ],
        );
      },
    );
  }
}

class _MissionStatusBadge extends StatelessWidget {
  final int xp;
  final int? avatarIndex;
  final bool compact;

  const _MissionStatusBadge({
    required this.xp,
    required this.avatarIndex,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 44 : 48,
      child: CustomPaint(
        painter: const _VolcanoStatusPainter(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(compact ? 9 : 12, 5, compact ? 6 : 7, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$xp XP',
                style: TextStyle(
                  color: const Color(0xFFFF7A1A),
                  fontSize: compact ? 13 : 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: compact ? 0.2 : 0.4,
                  height: 1,
                  shadows: const [
                    Shadow(
                      color: Color(0xFF4A1200),
                      offset: Offset(1.5, 1.5),
                      blurRadius: 0,
                    ),
                    Shadow(color: Color(0xAA000000), blurRadius: 5),
                  ],
                ),
              ),
              if (avatarIndex != null) ...[
                SizedBox(width: compact ? 7 : 10),
                _MissionAvatarFrame(
                  avatarIndex: avatarIndex!,
                  size: compact ? 30 : 34,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionAvatarFrame extends StatelessWidget {
  final int avatarIndex;
  final double size;

  const _MissionAvatarFrame({required this.avatarIndex, required this.size});

  @override
  Widget build(BuildContext context) {
    final avatar = Assets
        .avatars[avatarIndex.clamp(0, Assets.avatars.length - 1)]
        .imagePath;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFB45F), Color(0xFF6E2A10), Color(0xFF120C09)],
          stops: [0, 0.5, 1],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            offset: Offset(0, 3),
            blurRadius: 4,
          ),
          BoxShadow(color: Color(0x66FF7A1A), blurRadius: 8),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: const Color(0xFF170D08),
          boxShadow: const [
            BoxShadow(
              color: Color(0xAA000000),
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset(avatar, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _VolcanoStatusPainter extends CustomPainter {
  const _VolcanoStatusPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outer = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    final outerPath = Path()..addRRect(outer);

    canvas.drawShadow(
      outerPath.shift(const Offset(0, 2)),
      Colors.black,
      5,
      true,
    );

    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3A2115), Color(0xFF1A0D08), Color(0xFF0D0705)],
        stops: [0, 0.54, 1],
      ).createShader(rect);
    canvas.drawRRect(outer, basePaint);

    final bevelPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFBE73), Color(0xFFB34A16), Color(0xFF2A1008)],
      ).createShader(rect);
    canvas.drawRRect(outer.deflate(0.7), bevelPaint);

    final innerGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x55FF7A1A);
    canvas.drawRRect(outer.deflate(3), innerGlow);

    final lavaPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5
      ..color = const Color(0x99FF6D1A);
    final lavaPath = Path()
      ..moveTo(size.width * 0.08, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.33,
        size.height * 0.66,
        size.width * 0.52,
        size.height * 0.82,
      )
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.96,
        size.width * 0.93,
        size.height * 0.7,
      );
    canvas.drawPath(lavaPath, lavaPaint);

    final highlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x44FFF1E3);
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.13),
      Offset(size.width * 0.82, size.height * 0.13),
      highlight,
    );
  }

  @override
  bool shouldRepaint(covariant _VolcanoStatusPainter oldDelegate) => false;
}
