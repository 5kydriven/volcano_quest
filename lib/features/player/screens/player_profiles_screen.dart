import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:volcano_quest/core/audio/audio_catalog.dart';
import 'package:volcano_quest/core/audio/audio_controller.dart';

import '../../../core/constants/assets.dart';
import '../../../core/routing/app_routes.dart';
import '../../../data/models/player_model.dart';
import '../application/player_controller.dart';

class PlayerProfilesScreen extends ConsumerWidget {
  final bool showCloseButton;

  const PlayerProfilesScreen({super.key, this.showCloseButton = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(playerProfilesProvider);
    final activePlayer = ref.watch(playerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF080B12),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(Assets.playerDatabaseBg, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x99070A10),
                  Color(0x660B0604),
                  Color(0xE6070910),
                ],
                stops: [0, 0.42, 1],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.1, -0.18),
                radius: 0.88,
                colors: [Color(0x55FF7A1A), Color(0x00000000)],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const maxMobileContentWidth = 430.0;
                final edgeInset = constraints.maxWidth < 360 ? 14.0 : 18.0;
                final contentWidth = constraints.maxWidth.clamp(
                  0.0,
                  maxMobileContentWidth,
                );
                final horizontalInset =
                    ((constraints.maxWidth - contentWidth) / 2) + edgeInset;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalInset,
                    20,
                    horizontalInset,
                    32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(
                        showCloseButton: showCloseButton,
                        onClose: () => context.pop(),
                      ),
                      const SizedBox(height: 44),
                      if (players.isEmpty)
                        const _EmptyProfiles()
                      else
                        for (final player in players) ...[
                          _PlayerProfileTile(
                            player: player,
                            avatarAsset: Assets
                                .avatars[player.avatarIndex.clamp(
                                  0,
                                  Assets.avatars.length - 1,
                                )]
                                .imagePath,
                            isActive: player.id == activePlayer.id,
                            onTap: () async {
                              await ref
                                  .read(playerProvider.notifier)
                                  .switchPlayer(player.id);
                              if (context.mounted) {
                                context.go(AppRoutes.menu);
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                        ],
                      const SizedBox(height: 10),
                      _CreateScientistButton(
                        onTap: () {
                          unawaited(
                            ref
                                .read(audioControllerProvider)
                                .playSfx(SfxCue.button),
                          );
                          context.go(AppRoutes.onboarding);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool showCloseButton;
  final VoidCallback onClose;

  const _Header({required this.showCloseButton, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFE79C73),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x99FF6A1A),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: SizedBox(width: 8, height: 8),
                  ),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'LOCAL PLAYERS',
                      style: TextStyle(
                        color: Color(0xFFD59873),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.2,
                        shadows: [
                          Shadow(
                            color: Color(0xCC130704),
                            blurRadius: 7,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: _OutlinedText(
                  'Scientist Profiles',
                  fontSize: 34,
                  fill: Color(0xFFE9965B),
                  stroke: Color(0xFF2B120A),
                  strokeWidth: 4,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(color: Color(0xDDFFAB6A), blurRadius: 9),
                    Shadow(
                      color: Color(0xCC160806),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0x00D89A6B),
                      Color(0xE0B36A3E),
                      Color(0x00D89A6B),
                    ],
                  ),
                ),
                child: SizedBox(height: 1, width: double.infinity),
              ),
            ],
          ),
        ),
        if (showCloseButton) ...[
          const SizedBox(width: 16),
          _ImageButton(
            asset: Assets.closeButton,
            size: 56,
            tooltip: 'Close',
            onTap: onClose,
          ),
        ],
      ],
    );
  }
}

class _PlayerProfileTile extends StatelessWidget {
  final PlayerModel player;
  final String avatarAsset;
  final bool isActive;
  final VoidCallback onTap;

  const _PlayerProfileTile({
    required this.player,
    required this.avatarAsset,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _MoltenHover(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: FractionallySizedBox(
        widthFactor: 0.92,
        alignment: Alignment.centerLeft,
        child: AspectRatio(
          aspectRatio: 705 / 363,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      Assets.profileContainer,
                      fit: BoxFit.fill,
                    ),
                  ),
                  Positioned(
                    left: width * 0.135,
                    top: height * 0.265,
                    width: width * 0.235,
                    height: height * 0.46,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(width * 0.035),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF231A15),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xAA160A05),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.asset(avatarAsset, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  Positioned(
                    left: width * 0.42,
                    top: height * 0.34,
                    right: width * 0.15,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _GradientOutlinedText(
                            player.name.toUpperCase(),
                            fontSize: 28,
                            strokeWidth: 4,
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFFFF04A),
                                Color(0xFFFF9B0B),
                                Color(0xFFE94708),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: height * 0.025),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _OutlinedText(
                            'LEVEL ${player.currentLevel} - ${player.totalXP} XP',
                            fontSize: 14,
                            fill: const Color(0xFFF1A071),
                            stroke: const Color(0xFF261009),
                            strokeWidth: 2.5,
                            fontWeight: FontWeight.w900,
                            shadows: const [
                              Shadow(
                                color: Color(0xAA1A0804),
                                blurRadius: 3,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Positioned(
                      right: -width * 0.02,
                      top: height * 0.05,
                      width: width * 0.18,
                      child: Image.asset(
                        Assets.checkImage,
                        fit: BoxFit.contain,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CreateScientistButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateScientistButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Create new scientist',
      child: _MoltenHover(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 694 / 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Image.asset(
                  Assets.createNewScientistButton,
                  fit: BoxFit.fill,
                  excludeFromSemantics: true,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 46),
                child: FittedBox(fit: BoxFit.scaleDown),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyProfiles extends StatelessWidget {
  const _EmptyProfiles();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: _OutlinedText(
          'NO SCIENTIST PROFILES FOUND',
          fontSize: 18,
          fill: Color(0xFFE2B079),
          stroke: Color(0xFF24110A),
          strokeWidth: 3,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ImageButton extends StatefulWidget {
  final String asset;
  final double size;
  final String tooltip;
  final VoidCallback onTap;

  const _ImageButton({
    required this.asset,
    required this.size,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_ImageButton> createState() => _ImageButtonState();
}

class _ImageButtonState extends State<_ImageButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.92 : (_hovered ? 1.06 : 1),
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _hovered
                        ? const Color(0xFFFF7A18)
                        : const Color(0xAA120703),
                    blurRadius: _hovered ? 24 : 12,
                    spreadRadius: _hovered ? 3 : 0,
                  ),
                ],
              ),
              child: Image.asset(widget.asset, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoltenHover extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  const _MoltenHover({
    required this.child,
    required this.borderRadius,
    required this.onTap,
  });

  @override
  State<_MoltenHover> createState() => _MoltenHoverState();
}

class _MoltenHoverState extends State<_MoltenHover> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.985 : (_hovered ? 1.015 : 1),
          duration: const Duration(milliseconds: 130),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              boxShadow: [
                BoxShadow(
                  color: _hovered
                      ? const Color(0xDDFF7418)
                      : const Color(0x88100503),
                  blurRadius: _hovered ? 30 : 16,
                  spreadRadius: _hovered ? 4 : 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _GradientOutlinedText extends StatelessWidget {
  final String text;
  final double fontSize;
  final double strokeWidth;
  final Gradient gradient;

  const _GradientOutlinedText(
    this.text, {
    required this.fontSize,
    required this.strokeWidth,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = const Color(0xFF2A1006),
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => gradient.createShader(bounds),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              shadows: const [
                Shadow(
                  color: Color(0xCC5C1804),
                  blurRadius: 3,
                  offset: Offset(0, 3),
                ),
                Shadow(color: Color(0x99FFD15B), blurRadius: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OutlinedText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color fill;
  final Color stroke;
  final double strokeWidth;
  final FontWeight fontWeight;
  final List<Shadow>? shadows;

  const _OutlinedText(
    this.text, {
    required this.fontSize,
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
    required this.fontWeight,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            letterSpacing: 0,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = stroke,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            color: fill,
            fontSize: fontSize,
            fontWeight: fontWeight,
            letterSpacing: 0,
            shadows: shadows,
          ),
        ),
      ],
    );
  }
}
