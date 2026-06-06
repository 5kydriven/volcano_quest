import 'package:flutter/material.dart';

class HoverElevatingImage extends StatefulWidget {
  final ImageProvider image;
  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final BorderRadiusGeometry borderRadius;
  final EdgeInsetsGeometry padding;
  final double? heightFactor;
  final Color? backgroundColor;
  final Color shadowColor;
  final double hoverOffset;
  final double shadowBlurRadius;
  final double shadowSpreadRadius;
  final Duration duration;
  final Curve curve;
  final FilterQuality filterQuality;
  final String? semanticLabel;
  final bool excludeFromSemantics;

  const HoverElevatingImage({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.borderRadius = BorderRadius.zero,
    this.padding = EdgeInsets.zero,
    this.heightFactor,
    this.backgroundColor,
    this.shadowColor = Colors.black38,
    this.hoverOffset = 8,
    this.shadowBlurRadius = 18,
    this.shadowSpreadRadius = 1,
    this.duration = const Duration(milliseconds: 180),
    this.curve = Curves.easeOutCubic,
    this.filterQuality = FilterQuality.high,
    this.semanticLabel,
    this.excludeFromSemantics = false,
  });

  @override
  State<HoverElevatingImage> createState() => _HoverElevatingImageState();
}

class _HoverElevatingImageState extends State<HoverElevatingImage> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: widget.curve,
        transform: Matrix4.translationValues(
          0,
          _isHovered ? -widget.hoverOffset : 0,
          0,
        ),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: widget.borderRadius,
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: widget.shadowColor,
                    blurRadius: widget.shadowBlurRadius,
                    spreadRadius: widget.shadowSpreadRadius,
                    offset: Offset(0, widget.hoverOffset),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: ClipRect(
            child: Align(
              alignment: widget.alignment,
              heightFactor: widget.heightFactor,
              child: Padding(
                padding: widget.padding,
                child: Image(
                  image: widget.image,
                  width: widget.width,
                  height: widget.height,
                  fit: widget.fit,
                  alignment: widget.alignment,
                  filterQuality: widget.filterQuality,
                  semanticLabel: widget.semanticLabel,
                  excludeFromSemantics: widget.excludeFromSemantics,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setHovered(bool isHovered) {
    if (_isHovered == isHovered) {
      return;
    }

    setState(() {
      _isHovered = isHovered;
    });
  }
}
