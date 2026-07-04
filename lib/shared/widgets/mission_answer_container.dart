import 'package:flutter/material.dart';

enum MissionAnswerFeedback { none, correct, wrong }

class MissionAnswerContainer extends StatelessWidget {
  final String letter;
  final bool isSelected;
  final MissionAnswerFeedback feedback;

  const MissionAnswerContainer({
    super.key,
    required this.letter,
    required this.isSelected,
    this.feedback = MissionAnswerFeedback.none,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MissionAnswerContainerPainter(
        isSelected: isSelected,
        feedback: feedback,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: 0.2,
          heightFactor: 0.82,
          child: Center(
            child: Text(
              letter,
              style: const TextStyle(
                color: Color(0xFF292828),
                fontSize: 20,
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
            ),
          ),
        ),
      ),
    );
  }
}

class _MissionAnswerContainerPainter extends CustomPainter {
  final bool isSelected;
  final MissionAnswerFeedback feedback;

  const _MissionAnswerContainerPainter({
    required this.isSelected,
    required this.feedback,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.height * 0.12;
    final notch = size.height * 0.22;
    final leftBand = size.width * 0.22;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bodyPath = Path()
      ..moveTo(radius, 0)
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, radius)
      ..lineTo(size.width, size.height - radius)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width - radius,
        size.height,
      )
      ..lineTo(radius, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - radius)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..close();

    if (isSelected) {
      canvas.drawShadow(bodyPath, const Color(0xFFFF5A00), 12, false);
      final glowPaint = Paint()
        ..color = const Color(0xFFFF5A00).withValues(alpha: 0.34)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(2), Radius.circular(radius)),
        glowPaint,
      );
    }

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: _bodyColors,
        stops: const [0, 0.45, 1],
      ).createShader(rect);
    canvas.drawPath(bodyPath, bodyPaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.045
      ..color = _borderColor;
    canvas.drawPath(bodyPath, borderPaint);

    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.028
      ..color = const Color(0xFFF8E2CF).withValues(alpha: 0.72);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(size.height * 0.08),
        Radius.circular(radius * 0.72),
      ),
      highlightPaint,
    );

    final bandPath = Path()
      ..moveTo(0, 0)
      ..lineTo(leftBand + notch, 0)
      ..quadraticBezierTo(
        leftBand,
        size.height * 0.5,
        leftBand + notch,
        size.height,
      )
      ..lineTo(0, size.height)
      ..close();
    final bandPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: _bandColors,
      ).createShader(Rect.fromLTWH(0, 0, leftBand + notch, size.height));
    canvas.drawPath(bandPath, bandPaint);

    final dividerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.035
      ..color = const Color(0xFF292828).withValues(alpha: 0.76);
    canvas.drawPath(
      Path()
        ..moveTo(leftBand + notch * 0.75, size.height * 0.08)
        ..quadraticBezierTo(
          leftBand,
          size.height * 0.5,
          leftBand + notch * 0.75,
          size.height * 0.92,
        ),
      dividerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MissionAnswerContainerPainter oldDelegate) {
    return oldDelegate.isSelected != isSelected ||
        oldDelegate.feedback != feedback;
  }

  List<Color> get _bodyColors {
    return switch (feedback) {
      MissionAnswerFeedback.correct => const [
        Color(0xFFEAF0D3),
        Color(0xFFD5C9A0),
        Color(0xFFB59E76),
      ],
      MissionAnswerFeedback.wrong => const [
        Color(0xFFF4D3C8),
        Color(0xFFE0B39E),
        Color(0xFFC48A72),
      ],
      MissionAnswerFeedback.none => const [
        Color(0xFFF3DCC8),
        Color(0xFFE2BEA4),
        Color(0xFFC99573),
      ],
    };
  }

  List<Color> get _bandColors {
    return switch (feedback) {
      MissionAnswerFeedback.correct => const [
        Color(0xFFC8C94B),
        Color(0xFFAEB13B),
        Color(0xFF8F842A),
      ],
      MissionAnswerFeedback.wrong => const [
        Color(0xFFE89444),
        Color(0xFFD77832),
        Color(0xFFB14F22),
      ],
      MissionAnswerFeedback.none => const [
        Color(0xFFFFC248),
        Color(0xFFFFA700),
        Color(0xFFD96F00),
      ],
    };
  }

  Color get _borderColor {
    return switch (feedback) {
      MissionAnswerFeedback.correct => const Color(0xFF27342D),
      MissionAnswerFeedback.wrong => const Color(0xFF3F2522),
      MissionAnswerFeedback.none => const Color(0xFF232221),
    };
  }
}
