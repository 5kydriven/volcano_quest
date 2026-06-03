import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/player_model.dart';
import '../../../data/repositories/player_repository.dart';
import '../../player/application/player_controller.dart';

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  final playerRepository = ref.watch(playerRepositoryProvider);
  return LocalLeaderboardRepository(playerRepository);
});

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  ref.watch(playerProvider);
  final repository = ref.watch(leaderboardRepositoryProvider);
  return repository.loadEntries();
});

abstract class LeaderboardRepository {
  Future<List<LeaderboardEntry>> loadEntries();
}

class LocalLeaderboardRepository implements LeaderboardRepository {
  final PlayerRepository _playerRepository;

  const LocalLeaderboardRepository(this._playerRepository);

  @override
  Future<List<LeaderboardEntry>> loadEntries() async {
    final activePlayerId = _playerRepository.loadActivePlayerId();
    final entries = _playerRepository
        .loadPlayers()
        .map(
          (player) => LeaderboardEntry.fromPlayer(
            player,
            isCurrentPlayer: player.id == activePlayerId,
          ),
        )
        .toList();

    entries.sort(_compareEntries);

    return [
      for (var i = 0; i < entries.length; i++) entries[i].copyWith(rank: i + 1),
    ];
  }

  int _compareEntries(LeaderboardEntry a, LeaderboardEntry b) {
    final xpComparison = b.totalXP.compareTo(a.totalXP);
    if (xpComparison != 0) {
      return xpComparison;
    }

    final levelComparison = b.currentLevel.compareTo(a.currentLevel);
    if (levelComparison != 0) {
      return levelComparison;
    }

    final badgeComparison = b.badgeCount.compareTo(a.badgeCount);
    if (badgeComparison != 0) {
      return badgeComparison;
    }

    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }
}

class LeaderboardEntry {
  final int rank;
  final String playerId;
  final String name;
  final int avatarIndex;
  final int totalXP;
  final int currentLevel;
  final int badgeCount;
  final bool isCurrentPlayer;
  final LeaderboardEntrySource source;

  const LeaderboardEntry({
    required this.rank,
    required this.playerId,
    required this.name,
    required this.avatarIndex,
    required this.totalXP,
    required this.currentLevel,
    required this.badgeCount,
    required this.isCurrentPlayer,
    required this.source,
  });

  factory LeaderboardEntry.fromPlayer(
    PlayerModel player, {
    required bool isCurrentPlayer,
  }) {
    return LeaderboardEntry(
      rank: 0,
      playerId: player.id,
      name: player.name,
      avatarIndex: player.avatarIndex,
      totalXP: player.totalXP,
      currentLevel: player.currentLevel,
      badgeCount: player.earnedBadges.length,
      isCurrentPlayer: isCurrentPlayer,
      source: LeaderboardEntrySource.local,
    );
  }

  LeaderboardEntry copyWith({
    int? rank,
    bool? isCurrentPlayer,
    LeaderboardEntrySource? source,
  }) {
    return LeaderboardEntry(
      rank: rank ?? this.rank,
      playerId: playerId,
      name: name,
      avatarIndex: avatarIndex,
      totalXP: totalXP,
      currentLevel: currentLevel,
      badgeCount: badgeCount,
      isCurrentPlayer: isCurrentPlayer ?? this.isCurrentPlayer,
      source: source ?? this.source,
    );
  }
}

enum LeaderboardEntrySource { local, remote }
