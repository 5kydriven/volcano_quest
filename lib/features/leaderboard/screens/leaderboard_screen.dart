import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/assets.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../application/leaderboard_controller.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(leaderboardProvider);
    final syncStatus = ref.watch(leaderboardSyncStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            children: [
              const _LeaderboardTopBar(),
              const SizedBox(height: 50),
              const Text(
                'LAB RANKINGS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'LOCAL EXPEDITION STANDINGS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.teal,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              _SyncStatusBadge(syncStatus: syncStatus),
              const SizedBox(height: 34),
              leaderboard.when(
                data: (entries) => _LeaderboardContent(entries: entries),
                loading: () => const _LeaderboardStatus(
                  icon: Icons.sync,
                  title: 'SYNCING LAB DATA',
                  message: 'Preparing scientist rankings...',
                ),
                error: (_, _) => const _LeaderboardStatus(
                  icon: Icons.warning_amber_outlined,
                  title: 'RANKINGS UNAVAILABLE',
                  message: 'Leaderboard data could not be loaded.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncStatusBadge extends StatelessWidget {
  final LeaderboardSyncSnapshot syncStatus;

  const _SyncStatusBadge({required this.syncStatus});

  @override
  Widget build(BuildContext context) {
    final content = switch (syncStatus.state) {
      LeaderboardSyncStatus.syncing => (
        Icons.sync,
        'SYNCING ONLINE DATA',
        AppColors.teal,
      ),
      LeaderboardSyncStatus.synced => (
        Icons.cloud_done_outlined,
        'ONLINE DATA SYNCED',
        AppColors.teal,
      ),
      LeaderboardSyncStatus.offline => (
        Icons.cloud_off_outlined,
        'OFFLINE CACHE ACTIVE',
        AppColors.textMuted,
      ),
      LeaderboardSyncStatus.error => (
        Icons.warning_amber_outlined,
        'SYNC FAILED - SHOWING CACHE',
        AppColors.textMuted,
      ),
      LeaderboardSyncStatus.unavailable => (
        Icons.storage_outlined,
        'LOCAL CACHE ACTIVE',
        AppColors.textMuted,
      ),
      LeaderboardSyncStatus.unknown => (
        Icons.storage_outlined,
        'LOCAL CACHE ACTIVE',
        AppColors.textMuted,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderAlt, width: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(content.$1, color: content.$3, size: 14),
          const SizedBox(width: 8),
          Text(
            content.$2,
            style: TextStyle(
              color: content.$3,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardContent extends StatelessWidget {
  final List<LeaderboardEntry> entries;

  const _LeaderboardContent({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _LeaderboardStatus(
        icon: Icons.person_search_outlined,
        title: 'NO SCIENTIST DATA FOUND',
        message: 'Create a profile to enter the rankings.',
      );
    }

    return Column(
      children: [
        _ScientistCount(totalScientists: entries.length),
        const SizedBox(height: 24),
        _Podium(leaders: entries.take(3).toList()),
        const SizedBox(height: 44),
        _RankingTable(rankings: entries),
      ],
    );
  }
}

class _ScientistCount extends StatelessWidget {
  final int totalScientists;

  const _ScientistCount({required this.totalScientists});

  @override
  Widget build(BuildContext context) {
    final label = totalScientists == 1 ? 'SCIENTIST' : 'SCIENTISTS';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderAlt, width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.groups_2_outlined, color: AppColors.teal, size: 15),
          const SizedBox(width: 8),
          Text(
            '$totalScientists $label TRACKED',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardTopBar extends StatelessWidget {
  const _LeaderboardTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
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
          'Leaderboards',
          style: TextStyle(
            color: AppColors.teal,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(
            Icons.settings_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onPressed: () => context.push(AppRoutes.settings),
        ),
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> leaders;

  const _Podium({required this.leaders});

  @override
  Widget build(BuildContext context) {
    final leftScientist = leaders.length > 1 ? leaders[1] : null;
    final centerScientist = leaders.first;
    final rightScientist = leaders.length > 2 ? leaders[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _PodiumSlot(scientist: leftScientist)),
        const SizedBox(width: 10),
        Expanded(child: _PodiumSlot(scientist: centerScientist)),
        const SizedBox(width: 10),
        Expanded(child: _PodiumSlot(scientist: rightScientist)),
      ],
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final LeaderboardEntry? scientist;

  const _PodiumSlot({required this.scientist});

  @override
  Widget build(BuildContext context) {
    final scientist = this.scientist;
    if (scientist == null) {
      return const SizedBox.shrink();
    }

    return _PodiumScientist(scientist: scientist);
  }
}

class _PodiumScientist extends StatelessWidget {
  final LeaderboardEntry scientist;

  const _PodiumScientist({required this.scientist});

  @override
  Widget build(BuildContext context) {
    final isChampion = scientist.rank == 1;
    final badgeSize = isChampion ? 74.0 : 56.0;

    return Column(
      children: [
        SizedBox(
          height: isChampion ? 16 : 0,
          child: isChampion
              ? const Icon(
                  Icons.workspace_premium,
                  color: AppColors.teal,
                  size: 16,
                )
              : null,
        ),
        Container(
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(
            color: isChampion
                ? AppColors.teal.withValues(alpha: 0.14)
                : AppColors.surface,
            border: Border.all(
              color: isChampion ? AppColors.teal : AppColors.borderAlt,
              width: isChampion ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(7),
            boxShadow: isChampion
                ? [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.32),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.asset(
                _avatarAssetPath(scientist.avatarIndex),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -10),
          child: Container(
            width: isChampion ? 30 : 22,
            height: isChampion ? 30 : 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isChampion ? AppColors.teal : AppColors.borderAlt,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${scientist.rank}',
              style: TextStyle(
                color: isChampion
                    ? AppColors.background
                    : AppColors.textPrimary,
                fontSize: isChampion ? 12 : 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -6),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  scientist.name,
                  maxLines: 1,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${_formatNumber(scientist.totalXP)} XP',
                  maxLines: 1,
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RankingTable extends StatelessWidget {
  final List<LeaderboardEntry> rankings;

  const _RankingTable({required this.rankings});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderAlt, width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 15, 18, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'SCIENTIST',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Text(
                  'TOTAL XP',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          for (final ranking in rankings) _RankingRow(ranking: ranking),
        ],
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  final LeaderboardEntry ranking;

  const _RankingRow({required this.ranking});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ranking.isCurrentPlayer
          ? AppColors.teal.withValues(alpha: 0.09)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '${ranking.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ranking.isCurrentPlayer
                    ? AppColors.teal
                    : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: ranking.isCurrentPlayer
                  ? AppColors.teal.withValues(alpha: 0.25)
                  : AppColors.borderAlt,
              border: Border.all(
                color: ranking.isCurrentPlayer
                    ? AppColors.teal
                    : AppColors.borderAlt,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Padding(
              padding: const EdgeInsets.all(1),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Image.asset(
                  _avatarAssetPath(ranking.avatarIndex),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              ranking.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ranking.isCurrentPlayer
                    ? AppColors.teal
                    : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatNumber(ranking.totalXP),
              style: const TextStyle(
                color: AppColors.teal,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardStatus extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _LeaderboardStatus({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderAlt, width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.teal, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

String _avatarAssetPath(int avatarIndex) {
  return Assets
      .avatars[avatarIndex.clamp(0, Assets.avatars.length - 1)]
      .imagePath;
}

String _formatNumber(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    buffer.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }

  return buffer.toString();
}
