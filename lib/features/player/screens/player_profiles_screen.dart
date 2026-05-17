import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/player_model.dart';
import '../../../shared/widgets/lab_widgets.dart';
import '../application/player_controller.dart';

class PlayerProfilesScreen extends ConsumerWidget {
  const PlayerProfilesScreen({super.key});

  static const _avatarIcons = [
    Icons.person_outline,
    Icons.biotech_outlined,
    Icons.rocket_launch_outlined,
    Icons.hub_outlined,
    Icons.science_outlined,
    Icons.public_outlined,
    Icons.travel_explore_outlined,
    Icons.psychology_outlined,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(playerProfilesProvider);
    final activePlayer = ref.watch(playerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusDot(label: 'LOCAL PLAYER DATABASE'),
              const SizedBox(height: 18),
              const Text(
                'Scientist profiles',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const ScanLine(),
              const SizedBox(height: 16),
              if (players.isEmpty)
                const _EmptyProfiles()
              else
                for (final player in players) ...[
                  _PlayerProfileTile(
                    player: player,
                    icon:
                        _avatarIcons[player.avatarIndex.clamp(
                          0,
                          _avatarIcons.length - 1,
                        )],
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
                  const SizedBox(height: 10),
                ],
              const SizedBox(height: 18),
              LabButton(
                label: 'CREATE NEW SCIENTIST',
                onTap: () => context.go(AppRoutes.onboarding),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerProfileTile extends StatelessWidget {
  final PlayerModel player;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _PlayerProfileTile({
    required this.player,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surfaceAlt : AppColors.surface,
          border: Border.all(
            color: isActive ? AppColors.teal : AppColors.borderAlt,
            width: isActive ? 1 : 0.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.tealDark,
                border: Border.all(color: AppColors.teal, width: 0.5),
              ),
              child: Icon(icon, color: AppColors.teal, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'LEVEL ${player.currentLevel} - ${player.totalXP} XP',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              const Icon(Icons.check_circle_outline, color: AppColors.teal)
            else
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _EmptyProfiles extends StatelessWidget {
  const _EmptyProfiles();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderAlt, width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'NO SCIENTIST PROFILES FOUND',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
