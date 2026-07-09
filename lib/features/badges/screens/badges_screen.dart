import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/badge_award_image.dart';
import '../../../shared/widgets/mission_screen_background.dart';
import '../application/badges_controller.dart';

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
            slivers: [
              const SliverToBoxAdapter(child: _BadgesTopBar()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 34, 24, 32),
                sliver: badges.isEmpty
                    ? const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyBadgesState(),
                      )
                    : SliverGrid.builder(
                        itemCount: badges.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.98,
                            ),
                        itemBuilder: (context, index) {
                          return _BadgeTile(badge: badges[index]);
                        },
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
  const _BadgesTopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          SizedBox(
            width: 38,
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
          const Spacer(),
          const Expanded(
            flex: 8,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _BadgesHeading('BADGES', size: 24),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 38),
        ],
      ),
    );
  }
}

class _BadgesHeading extends StatelessWidget {
  final String text;
  final double size;

  const _BadgesHeading(this.text, {required this.size});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        foreground: Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFB13A), Color(0xFFFF6416), Color(0xFFC43110)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, 260, 70)),
        shadows: const [
          Shadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
          Shadow(color: Color(0xFF6C2500), offset: Offset(2, 2)),
        ],
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
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.borderAlt, width: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.military_tech_outlined,
                color: AppColors.teal,
                size: 38,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'NO BADGES EARNED',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'GO COMPLETE A MISSION',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.teal,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderAlt, width: 0.5),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 78,
            height: 78,
            child: BadgeAwardImage(imagePath: badge.imagePath, size: 78),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: Text(
              badge.name.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
