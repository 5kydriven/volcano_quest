import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_routes.dart';

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
    _videoController = VideoPlayerController.asset(Assets.volcanoBg)
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _videoController.play();
      });
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
          final isCompact = constraints.maxHeight < 720;
          final horizontalPadding = constraints.maxWidth < 420 ? 12.0 : 20.0;
          final logoWidth =
              (constraints.maxWidth - horizontalPadding).clamp(
                340.0,
                isCompact ? 560.0 : 760.0,
              ) *
              1.3;
          final buttonWidth = (constraints.maxWidth - horizontalPadding * 2)
              .clamp(260.0, isCompact ? 330.0 : 390.0);
          final logoSlotHeight =
              constraints.maxHeight * (isCompact ? 0.72 : 0.76);

          return Stack(
            fit: StackFit.expand,
            children: [
              _VideoBackground(controller: _videoController),
              if (!_videoController.value.isInitialized)
                Image.asset(
                  Assets.splashBg,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              if (_videoController.value.isInitialized)
                ColoredBox(
                  color: AppColors.background.withValues(alpha: 0.08),
                ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x330A0F1A),
                      Color(0x8C0A0F1A),
                      Color(0xF20A0F1A),
                    ],
                    stops: [0, 0.48, 1],
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.18),
                    radius: 0.76,
                    colors: [Color(0x00FF6A1A), Color(0x990A0F1A)],
                    stops: [0.2, 1],
                  ),
                ),
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
                      child: Column(
                        children: [
                          SizedBox(height: isCompact ? 0 : 8),
                          SizedBox(
                            height: logoSlotHeight,
                            child: Center(
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
                                child: Image.asset(
                                  Assets.splashLogo,
                                  width: logoWidth,
                                  height: logoSlotHeight,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          _InitializeMissionButton(
                            width: buttonWidth,
                            isCompact: isCompact,
                            onTap: _onStart,
                          ),
                          SizedBox(height: isCompact ? 8 : 14),
                          Text(
                            '${AppConstants.appVersion} / PHIVOLCS LEARNING LAB',
                            style: const TextStyle(
                              color: AppColors.textDim,
                              fontSize: 9,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: isCompact ? 14 : 24),
                        ],
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

class _InitializeMissionButton extends StatefulWidget {
  final double width;
  final bool isCompact;
  final VoidCallback onTap;

  const _InitializeMissionButton({
    required this.width,
    required this.isCompact,
    required this.onTap,
  });

  @override
  State<_InitializeMissionButton> createState() =>
      _InitializeMissionButtonState();
}

class _InitializeMissionButtonState extends State<_InitializeMissionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Initialize mission',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isHovered ? 1.04 : 1,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: _isHovered ? 0.92 : 1,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: _CroppedSplashAsset(
                assetPath: Assets.initializeButton,
                width: widget.width,
                heightFactor: widget.isCompact ? 0.18 : 0.22,
                alignment: const Alignment(0, -0.24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CroppedSplashAsset extends StatelessWidget {
  final String assetPath;
  final double width;
  final double heightFactor;
  final Alignment alignment;

  const _CroppedSplashAsset({
    required this.assetPath,
    required this.width,
    required this.heightFactor,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Align(
        alignment: alignment,
        heightFactor: heightFactor,
        child: Image.asset(
          assetPath,
          width: width,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
