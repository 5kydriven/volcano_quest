import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/assets.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/mission_screen_background.dart';
import '../application/leaderboard_controller.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(leaderboardProvider);
    final syncStatus = ref.watch(leaderboardSyncStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: MissionScreenBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final sidePadding = constraints.maxWidth < 380 ? 12.0 : 18.0;

              return Padding(
                padding: EdgeInsets.fromLTRB(sidePadding, 10, sidePadding, 8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      children: [
                        const _LeaderboardTopBar(),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(0, 4, 0, 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _LeaderboardHeader(),
                                const SizedBox(height: 14),
                                _SyncStatusBadge(syncStatus: syncStatus),
                                const SizedBox(height: 10),
                                leaderboard.when(
                                  data: (entries) =>
                                      _LeaderboardContent(entries: entries),
                                  loading: () => const _LeaderboardStatus(
                                    icon: Icons.sync,
                                    title: 'SYNCING LAB DATA',
                                    message: 'Preparing scientist rankings...',
                                  ),
                                  error: (_, _) => const _LeaderboardStatus(
                                    icon: Icons.warning_amber_outlined,
                                    title: 'RANKINGS UNAVAILABLE',
                                    message:
                                        'Leaderboard data could not be loaded.',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          MissionBackButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
                return;
              }
              context.go(AppRoutes.menu);
            },
          ),
          const Spacer(),
          const Expanded(
            flex: 8,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _LavaHeading('LEADERBOARDS', size: 20),
            ),
          ),
          const Spacer(),
          _SettingsButton(onPressed: () => context.push(AppRoutes.settings)),
        ],
      ),
    );
  }
}

class _LeaderboardHeader extends StatelessWidget {
  const _LeaderboardHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Manual crop/size: tune width to resize the exported LAB RANKINGS art.
        const _LeaderboardCroppedAsset(
          assetPath: Assets.header,
          crop: _headerCrop,
          width: 250,
        ),
        const SizedBox(height: 12),
        _lavaDivider(),
      ],
    );
  }
}

class _SyncStatusBadge extends StatelessWidget {
  final LeaderboardSyncSnapshot syncStatus;

  const _SyncStatusBadge({required this.syncStatus});

  @override
  Widget build(BuildContext context) {
    final content = switch (syncStatus.state) {
      LeaderboardSyncStatus.syncing => 'SYNCING ONLINE DATA',
      LeaderboardSyncStatus.synced => 'ONLINE DATA SYNCED',
      LeaderboardSyncStatus.offline => 'OFFLINE CACHE ACTIVE',
      LeaderboardSyncStatus.error => 'SYNC FAILED - SHOWING CACHE',
      LeaderboardSyncStatus.unavailable => 'LOCAL CACHE ACTIVE',
      LeaderboardSyncStatus.unknown => 'LOCAL CACHE ACTIVE',
    };

    return Center(
      child: _FramedBadge(
        assetPath: Assets.stats,
        crop: _statsCrop,
        icon: Icons.cloud_done_outlined,
        label: content,
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: _ScientistCount(totalScientists: entries.length)),
        const SizedBox(height: 18),
        _Podium(leaders: entries.take(3).toList()),
        const SizedBox(height: 20),
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

    return _FramedBadge(
      assetPath: Assets.trackContainer,
      crop: _trackCrop,
      icon: Icons.groups_2_outlined,
      label: '$totalScientists $label TRACKED',
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> leaders;

  const _Podium({required this.leaders});

  @override
  Widget build(BuildContext context) {
    final second = leaders.length > 1 ? leaders[1] : null;
    final first = leaders.first;
    final third = leaders.length > 2 ? leaders[2] : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final sideWidth = constraints.maxWidth * 0.27;
        final championWidth = constraints.maxWidth * 0.36;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: second == null
                    ? const SizedBox.shrink()
                    : _PodiumCard(width: sideWidth, scientist: second),
              ),
            ),
            _PodiumCard(
              width: championWidth,
              scientist: first,
              isChampion: true,
            ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomRight,
                child: third == null
                    ? const SizedBox.shrink()
                    : _PodiumCard(width: sideWidth, scientist: third),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final double width;
  final LeaderboardEntry scientist;
  final bool isChampion;

  const _PodiumCard({
    required this.width,
    required this.scientist,
    this.isChampion = false,
  });

  @override
  Widget build(BuildContext context) {
    final crop = isChampion ? _championCrop : _podiumCrop;
    final height = width * crop.height / crop.width;
    final avatarSize = width * (isChampion ? 0.5 : 0.46);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _LeaderboardCroppedAsset(
            assetPath: isChampion
                ? Assets.no1Container
                : Assets.rankingContainer,
            crop: crop,
            width: width,
          ),
          if (!isChampion)
            Positioned(
              top: height * 0.03,
              child: Text(
                '${scientist.rank}',
                style: TextStyle(
                  color: scientist.rank == 2
                      ? AppColors.textSecondary
                      : AppColors.teal,
                  fontSize: width * 0.18,
                  fontWeight: FontWeight.w900,
                  shadows: const [
                    Shadow(color: Colors.black, offset: Offset(2, 2)),
                  ],
                ),
              ),
            ),
          Positioned(
            top: height * (isChampion ? 0.20 : 0.24),
            child: _AvatarImage(
              avatarIndex: scientist.avatarIndex,
              size: avatarSize + 12,
              borderRadius: width * 0.08,
            ),
          ),
          Positioned(
            left: width * 0.12,
            right: width * 0.12,
            bottom: height * (isChampion ? 0.10 : 0.11),
            child: Column(
              children: [
                _FittedLabel(
                  scientist.name,
                  color: AppColors.textPrimary,
                  fontSize: isChampion ? 17 : 13,
                ),
                SizedBox(height: height * 0.015),
                _FittedLabel(
                  '${_formatNumber(scientist.totalXP)} XP',
                  color: AppColors.teal,
                  fontSize: isChampion ? 11 : 9,
                  letterSpacing: 0.6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingTable extends StatelessWidget {
  final List<LeaderboardEntry> rankings;

  const _RankingTable({required this.rankings});

  @override
  Widget build(BuildContext context) {
    return _LabPanel(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(child: _PanelHeaderLabel('SCIENTIST')),
                _PanelHeaderLabel('TOTAL XP'),
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
      height: 56,
      decoration: BoxDecoration(
        color: ranking.isCurrentPlayer
            ? const Color(0xFF7A2A12).withValues(alpha: 0.72)
            : Colors.transparent,
        border: ranking.isCurrentPlayer
            ? Border.all(color: AppColors.tealDim, width: 0.7)
            : const Border(
                top: BorderSide(color: Color(0x443B3028), width: 0.7),
              ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '${ranking.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ranking.isCurrentPlayer
                    ? AppColors.teal
                    : AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                shadows: const [
                  Shadow(color: Colors.black, offset: Offset(1, 1)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _AvatarImage(
            avatarIndex: ranking.avatarIndex,
            size: 38,
            borderRadius: 6,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ranking.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ranking.isCurrentPlayer
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                shadows: const [
                  Shadow(color: Colors.black, offset: Offset(1, 1)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 76),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _formatNumber(ranking.totalXP),
                style: const TextStyle(
                  color: AppColors.teal,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black, offset: Offset(2, 2))],
                ),
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
    return _LabPanel(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          children: [
            Icon(icon, color: AppColors.teal, size: 30),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                shadows: [Shadow(color: Colors.black, offset: Offset(1, 1))],
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FramedBadge extends StatelessWidget {
  final String assetPath;
  final Rect crop;
  final IconData icon;
  final String label;

  const _FramedBadge({
    required this.assetPath,
    required this.crop,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Manual crop/size: edit this widget width or crop below to align art.
          _LeaderboardCroppedAsset(
            assetPath: assetPath,
            crop: crop,
            width: 220,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30, right: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.teal, size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: _FittedLabel(
                    label,
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabPanel extends StatelessWidget {
  final Widget child;

  const _LabPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 24, 24, 24).withValues(alpha: 0.9),
        border: Border.all(color: const Color(0xFF8E4526), width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 10),
          BoxShadow(color: Color(0x33FF5C00), blurRadius: 5),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SettingsButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Settings',
      child: Semantics(
        button: true,
        label: 'Settings',
        child: InkResponse(
          onTap: onPressed,
          radius: 28,
          splashColor: AppColors.teal.withValues(alpha: 0.08),
          highlightColor: AppColors.teal.withValues(alpha: 0.04),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.borderAlt, width: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: AppColors.teal,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _LavaHeading extends StatelessWidget {
  final String text;
  final double size;

  const _LavaHeading(this.text, {required this.size});

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
          ).createShader(Rect.fromLTWH(0, 0, 420, 90)),
        shadows: const [
          Shadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
          Shadow(color: Color(0xFF6C2500), offset: Offset(2, 2)),
        ],
      ),
    );
  }
}

class _PanelHeaderLabel extends StatelessWidget {
  final String text;

  const _PanelHeaderLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.teal,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        shadows: [Shadow(color: Colors.black, offset: Offset(1, 1))],
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  final int avatarIndex;
  final double size;
  final double borderRadius;

  const _AvatarImage({
    required this.avatarIndex,
    required this.size,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: const Color(0xFF180D08),
        border: Border.all(color: AppColors.textSecondary, width: 1),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 5)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular((borderRadius - 2).clamp(0, 999)),
        child: Image.asset(_avatarAssetPath(avatarIndex), fit: BoxFit.cover),
      ),
    );
  }
}

class _FittedLabel extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final double letterSpacing;

  const _FittedLabel(
    this.text, {
    required this.color,
    required this.fontSize,
    this.letterSpacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: letterSpacing,
          shadows: const [Shadow(color: Colors.black, offset: Offset(1, 1))],
        ),
      ),
    );
  }
}

class _LeaderboardCroppedAsset extends StatelessWidget {
  final String assetPath;
  final Rect crop;
  final double width;

  const _LeaderboardCroppedAsset({
    required this.assetPath,
    required this.crop,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final scale = width / crop.width;
    final height = crop.height * scale;

    return ClipRect(
      child: SizedBox(
        width: width,
        height: height,
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: _leaderboardAssetSize.width * scale,
          maxWidth: _leaderboardAssetSize.width * scale,
          minHeight: _leaderboardAssetSize.height * scale,
          maxHeight: _leaderboardAssetSize.height * scale,
          child: Transform.translate(
            offset: Offset(-crop.left * scale, -crop.top * scale),
            child: Image.asset(
              assetPath,
              width: _leaderboardAssetSize.width * scale,
              height: _leaderboardAssetSize.height * scale,
              fit: BoxFit.fill,
            ),
          ),
        ),
      ),
    );
  }
}

Widget _lavaDivider() {
  return Container(
    height: 2,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.transparent,
          Color(0xFF4D2A1B),
          Color(0xFFFF7A14),
          Color(0xFF4D2A1B),
          Colors.transparent,
        ],
      ),
    ),
  );
}

const _leaderboardAssetSize = Size(322, 502);

// Manual crop knobs for leaderboard atlas-style PNGs.
const _headerCrop = Rect.fromLTWH(74, 228, 177, 46);
const _statsCrop = Rect.fromLTWH(80, 233, 165, 36);
const _trackCrop = Rect.fromLTWH(77, 233, 168, 36);
const _championCrop = Rect.fromLTWH(0, 7, 320, 470);
const _podiumCrop = Rect.fromLTWH(90, 135, 139, 234);

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
