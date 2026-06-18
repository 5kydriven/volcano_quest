import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_routes.dart';
import '../../../shared/widgets/hover_elevating_image.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _logoController;
  late Animation<double> _fadeIn;
  late Animation<double> _rise;
  late Animation<double> _logoPulse;
  late Animation<double> _logoFloat;
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _rise = Tween<double>(
      begin: 24,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _logoPulse = Tween<double>(begin: 0.98, end: 1.04).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOutCubic),
    );
    _logoFloat = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOutCubic),
    );
    _videoController = VideoPlayerController.asset(Assets.volcanoBg);
    try {
      unawaited(_videoController.setLooping(true).catchError((_) {}));
      unawaited(_videoController.setVolume(0).catchError((_) {}));
      unawaited(
        _videoController
            .initialize()
            .then((_) {
              if (!mounted) return;
              setState(() {});
              _videoController.play();
            })
            .catchError((_) {}),
      );
    } on UnimplementedError {
      // Widget tests and unsupported platforms can still use the static fallback.
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _logoController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onStart() {
    context.go(AppRoutes.players);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          var horizontalPadding = 20.0;
          var topSpacing = 8.0;
          var contentSpacing = 12.0;
          var footerSpacing = 14.0;
          var bottomSpacing = 24.0;
          var maxLogoWidth = 760.0;

          if (constraints.maxWidth < 420) {
            horizontalPadding = 12.0;
          }

          if (constraints.maxHeight < 720) {
            topSpacing = 0;
            contentSpacing = 8.0;
            footerSpacing = 8.0;
            bottomSpacing = 14.0;
            maxLogoWidth = 560.0;
          }

          final logoWidth =
              (constraints.maxWidth - horizontalPadding).clamp(
                340.0,
                maxLogoWidth,
              ) *
              1.3;
          final buttonWidth = constraints.maxWidth - horizontalPadding * 2;

          return Stack(
            fit: StackFit.expand,
            children: [
              Builder(
                builder: (context) {
                  if (!_videoController.value.isInitialized) {
                    return const ColoredBox(color: AppColors.background);
                  }

                  return _VideoBackground(controller: _videoController);
                },
              ),
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: AnimatedBuilder(
                    animation: _rise,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _rise.value),
                        child: child,
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Builder(
                        builder: (context) {
                          return Column(
                            children: [
                              SizedBox(height: topSpacing),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, logoConstraints) {
                                    return Center(
                                      child: AnimatedBuilder(
                                        animation: _logoController,
                                        builder: (context, child) {
                                          return Transform.translate(
                                            offset: Offset(0, _logoFloat.value),
                                            child: Transform.scale(
                                              scale: _logoPulse.value,
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: logoWidth,
                                            maxHeight:
                                                logoConstraints.maxHeight,
                                          ),
                                          child: Image.asset(
                                            Assets.splashLogo,
                                            fit: BoxFit.contain,
                                            filterQuality: FilterQuality.high,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: contentSpacing),
                              Flexible(
                                child: LayoutBuilder(
                                  builder: (context, buttonConstraints) {
                                    var buttonHeight =
                                        buttonConstraints.maxHeight -
                                        footerSpacing -
                                        bottomSpacing -
                                        16;
                                    if (buttonHeight < 0) {
                                      buttonHeight = 0;
                                    }

                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        SizedBox(
                                          width: double.infinity,
                                          height: buttonHeight,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.topCenter,
                                            child: SizedBox(
                                              width: buttonWidth,
                                              child: _InitializeMissionButton(
                                                width: buttonWidth,
                                                onTap: _onStart,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: footerSpacing),
                                        SizedBox(height: bottomSpacing),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VideoBackground extends StatelessWidget {
  final VideoPlayerController controller;

  const _VideoBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const SizedBox.expand();
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class _InitializeMissionButton extends StatelessWidget {
  final double width;
  final VoidCallback onTap;

  const _InitializeMissionButton({required this.width, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Initialize mission',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: HoverElevatingImage(
            image: const AssetImage(Assets.initializeButton),
            width: width,
            heightFactor: 0.11,
            alignment: const Alignment(0, -0.12),
            hoverOffset: 10,
            shadowColor: Colors.black54,
          ),
        ),
      ),
    );
  }
}
