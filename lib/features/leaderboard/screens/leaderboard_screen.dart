import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  static const _leaders = [
    _TopScientist(
      rank: 2,
      name: 'Dr. Stone',
      xp: '12,450 XP',
      icon: Icons.biotech_outlined,
    ),
    _TopScientist(
      rank: 1,
      name: 'MagmaMax',
      xp: '15,890 XP',
      icon: Icons.rocket_launch,
      isChampion: true,
    ),
    _TopScientist(
      rank: 3,
      name: 'PyroLog',
      xp: '11,200 XP',
      icon: Icons.science,
    ),
  ];

  static const _rankings = [
    _ScientistRanking(
      rank: 4,
      name: 'TerraNova',
      xp: '10,850',
      icon: Icons.link,
    ),
    _ScientistRanking(
      rank: 5,
      name: 'You (AlphaSci)',
      xp: '9,420',
      icon: Icons.person_search_outlined,
      isCurrentPlayer: true,
    ),
    _ScientistRanking(
      rank: 6,
      name: 'GeoMind',
      xp: '8,900',
      icon: Icons.psychology_outlined,
    ),
    _ScientistRanking(
      rank: 7,
      name: 'AshWalker',
      xp: '8,150',
      icon: Icons.travel_explore_outlined,
    ),
    _ScientistRanking(
      rank: 8,
      name: 'CoreDiver',
      xp: '7,600',
      icon: Icons.public_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                'GLOBAL EXPEDITION STANDINGS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.teal,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 34),
              const _Podium(leaders: _leaders),
              const SizedBox(height: 44),
              const _RankingTable(rankings: _rankings),
            ],
          ),
        ),
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
          onPressed: () {},
        ),
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  final List<_TopScientist> leaders;

  const _Podium({required this.leaders});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _PodiumScientist(scientist: leaders[0])),
        const SizedBox(width: 10),
        Expanded(child: _PodiumScientist(scientist: leaders[1])),
        const SizedBox(width: 10),
        Expanded(child: _PodiumScientist(scientist: leaders[2])),
      ],
    );
  }
}

class _PodiumScientist extends StatelessWidget {
  final _TopScientist scientist;

  const _PodiumScientist({required this.scientist});

  @override
  Widget build(BuildContext context) {
    final badgeSize = scientist.isChampion ? 74.0 : 56.0;

    return Column(
      children: [
        SizedBox(
          height: scientist.isChampion ? 16 : 0,
          child: scientist.isChampion
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
            color: scientist.isChampion
                ? AppColors.teal.withValues(alpha: 0.14)
                : AppColors.surface,
            border: Border.all(
              color: scientist.isChampion
                  ? AppColors.teal
                  : AppColors.borderAlt,
              width: scientist.isChampion ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(7),
            boxShadow: scientist.isChampion
                ? [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.32),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            scientist.icon,
            color: AppColors.teal,
            size: scientist.isChampion ? 34 : 26,
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -10),
          child: Container(
            width: scientist.isChampion ? 30 : 22,
            height: scientist.isChampion ? 30 : 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scientist.isChampion
                  ? AppColors.teal
                  : AppColors.borderAlt,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${scientist.rank}',
              style: TextStyle(
                color: scientist.isChampion
                    ? AppColors.background
                    : AppColors.textPrimary,
                fontSize: scientist.isChampion ? 12 : 10,
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
                  scientist.xp,
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
  final List<_ScientistRanking> rankings;

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
  final _ScientistRanking ranking;

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
            child: Icon(ranking.icon, color: AppColors.textSecondary, size: 18),
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
              ranking.xp,
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

class _TopScientist {
  final int rank;
  final String name;
  final String xp;
  final IconData icon;
  final bool isChampion;

  const _TopScientist({
    required this.rank,
    required this.name,
    required this.xp,
    required this.icon,
    this.isChampion = false,
  });
}

class _ScientistRanking {
  final int rank;
  final String name;
  final String xp;
  final IconData icon;
  final bool isCurrentPlayer;

  const _ScientistRanking({
    required this.rank,
    required this.name,
    required this.xp,
    required this.icon,
    this.isCurrentPlayer = false,
  });
}
