import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../application/badges_controller.dart';

class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badges = ref.watch(badgesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                            childAspectRatio: 1.04,
                          ),
                      itemBuilder: (context, index) {
                        return _BadgeTile(badge: badges[index]);
                      },
                    ),
            ),
          ],
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
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
                return;
              }
              context.go(AppRoutes.menu);
            },
          ),
          const Spacer(),
          const Text(
            'Badges',
            style: TextStyle(
              color: AppColors.teal,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: () {},
          ),
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
                fontSize: 20,
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
                fontSize: 11,
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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.teal, width: 0.8),
            ),
            child: _BadgeAvatar(avatar: badge.avatar),
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              badge.name.toUpperCase(),
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${badge.exp} XP',
            style: const TextStyle(
              color: AppColors.teal,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeAvatar extends StatelessWidget {
  final String avatar;

  const _BadgeAvatar({required this.avatar});

  @override
  Widget build(BuildContext context) {
    final icon = switch (avatar) {
      'volcano' => Icons.terrain_outlined,
      'magma' => Icons.local_fire_department_outlined,
      'vocabulary' => Icons.abc_outlined,
      'map' => Icons.public_outlined,
      'champion' => Icons.workspace_premium_outlined,
      'seismic' => Icons.keyboard_voice_outlined,
      'crystal' => Icons.diamond_outlined,
      _ => Icons.military_tech_outlined,
    };

    return Icon(icon, color: AppColors.teal, size: 22);
  }
}
