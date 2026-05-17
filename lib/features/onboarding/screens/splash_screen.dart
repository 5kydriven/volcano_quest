import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_routes.dart';
import '../../../shared/widgets/lab_widgets.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _iconScale = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
  }

  @override
  void dispose() {
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
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const StatusDot(label: 'SYSTEM ONLINE'),
                const Spacer(),
                ScaleTransition(
                  scale: _iconScale,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.teal, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.terrain_outlined,
                      color: AppColors.teal,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const LabBadge(text: 'VOLCANO QUEST'),
                const SizedBox(height: 16),
                const Text(
                  'Explore.\nPredict.\nSurvive.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    height: 1.25,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const ScanLine(),
                const SizedBox(height: 8),
                const Text(
                  'SCIENCE 9 · VOLCANO MODULE',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                LabButton(label: 'INITIALIZE MISSION', onTap: _onStart),
                const SizedBox(height: 16),
                Text(
                  '${AppConstants.appVersion} · PHIVOLCS LEARNING LAB',
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
