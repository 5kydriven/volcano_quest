import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/assets.dart';
import '../../../core/theme/app_theme.dart';
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
      animationBehavior: AnimationBehavior.preserve,
    );
    _logoPulse = Tween<double>(begin: 0.98, end: 1.04).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOutCubic),
    );
    _logoFloat = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOutCubic),
    );
    _logoController.value = 0.5;
  }

  @override
  void dispose() {
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
          var maxLogoWidth = 760.0;

          if (constraints.maxWidth < 420) {
            horizontalPadding = 12.0;
          }

          if (constraints.maxHeight < 720) {
            topSpacing = 0;
            contentSpacing = 4.0;
            maxLogoWidth = 560.0;
          }

          final logoWidth =
              (constraints.maxWidth - horizontalPadding).clamp(
                340.0,
                maxLogoWidth,
              ) *
              1.3;
          final buttonWidth = constraints.maxWidth - horizontalPadding * 2;
          final contentWidth = buttonWidth.clamp(300.0, 520.0);
          final featureWidth = contentWidth * 0.9;

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                Assets.splashScreenBg,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
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
                                flex: 3,
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
                                            semanticLabel: 'Lahar Lab',
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: contentSpacing),
                              Expanded(
                                flex: 4,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.topCenter,
                                  child: SizedBox(
                                    width: contentWidth,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _FeaturePanel(
                                          assetPath: Assets.explore,
                                          width: featureWidth,
                                          heightFactor: 0.3,
                                          semanticLabel:
                                              'Explore. Discover the unknown.',
                                        ),
                                        _FeaturePanel(
                                          assetPath: Assets.predict,
                                          width: featureWidth,
                                          heightFactor: 0.3,
                                          semanticLabel:
                                              'Predict. Foresee the future.',
                                        ),
                                        _FeaturePanel(
                                          assetPath: Assets.survive,
                                          width: featureWidth,
                                          heightFactor: 0.28,
                                          semanticLabel:
                                              'Survive. Prepare, protect, endure.',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: _InitializeMissionButton(
                                  onTap: _onStart,
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

class _FeaturePanel extends StatelessWidget {
  final String assetPath;
  final double width;
  final double heightFactor;
  final String semanticLabel;

  const _FeaturePanel({
    required this.assetPath,
    required this.width,
    required this.heightFactor,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return _CroppedSplashImage(
      assetPath: assetPath,
      width: width,
      heightFactor: heightFactor,
      semanticLabel: semanticLabel,
    );
  }
}

class _CroppedSplashImage extends StatelessWidget {
  final String assetPath;
  final double width;
  final double heightFactor;
  final String? semanticLabel;

  const _CroppedSplashImage({
    required this.assetPath,
    required this.width,
    required this.heightFactor,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Align(
        heightFactor: heightFactor,
        child: Image.asset(
          assetPath,
          width: width,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          semanticLabel: semanticLabel,
          excludeFromSemantics: semanticLabel == null,
        ),
      ),
    );
  }
}

class _InitializeMissionButton extends StatefulWidget {
  final VoidCallback onTap;

  const _InitializeMissionButton({required this.onTap});

  @override
  State<_InitializeMissionButton> createState() =>
      _InitializeMissionButtonState();
}

class _InitializeMissionButtonState extends State<_InitializeMissionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Initialize mission',
      child: SizedBox(
        width: double.infinity,
        key: const ValueKey('splashInitializeMissionButton'),
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.click,
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onTap();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _setPressed(true),
            onTapCancel: () => _setPressed(false),
            onTapUp: (_) => _setPressed(false),
            onTap: widget.onTap,
            child: AnimatedSlide(
              offset: _pressed ? const Offset(0, 0.05) : Offset.zero,
              duration: const Duration(milliseconds: 90),
              curve: Curves.easeOutCubic,
              child: AnimatedScale(
                scale: _pressed ? 0.96 : 1,
                duration: const Duration(milliseconds: 90),
                curve: Curves.easeOutCubic,
                child: Image.asset(Assets.splashBtn, fit: BoxFit.cover),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setPressed(bool pressed) {
    if (_pressed == pressed) {
      return;
    }

    setState(() {
      _pressed = pressed;
    });
  }
}
