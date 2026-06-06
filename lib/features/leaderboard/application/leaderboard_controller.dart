import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/providers/app_database_provider.dart';
import '../../../core/providers/firebase_firestore_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../../data/repositories/leaderboard_repository.dart';
import '../../player/application/player_controller.dart';

export '../../../data/repositories/leaderboard_repository.dart'
    show LeaderboardEntry, LeaderboardEntrySource, LeaderboardSyncStatus;

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final leaderboardConnectionCheckerProvider =
    Provider<LeaderboardConnectionChecker>((ref) {
      final connectivity = ref.watch(connectivityProvider);
      return ConnectivityLeaderboardConnectionChecker(connectivity);
    });

final leaderboardRemoteDataSourceProvider =
    Provider<LeaderboardRemoteDataSource?>((ref) {
      final firestore = ref.watch(firebaseFirestoreProvider);
      if (firestore == null) {
        return null;
      }
      return FirestoreLeaderboardRemoteDataSource(firestore);
    });

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  final playerRepository = ref.watch(playerRepositoryProvider);
  final database = ref.watch(appDatabaseProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  final remoteDataSource = ref.watch(leaderboardRemoteDataSourceProvider);
  final connectionChecker = ref.watch(leaderboardConnectionCheckerProvider);
  return LeaderboardRepository(
    playerRepository: playerRepository,
    database: database,
    prefs: prefs,
    remoteDataSource: remoteDataSource,
    connectionChecker: connectionChecker,
  );
});

final leaderboardSyncStatusProvider = StateProvider<LeaderboardSyncSnapshot>((
  ref,
) {
  return const LeaderboardSyncSnapshot(LeaderboardSyncStatus.unknown);
});

final leaderboardAutoSyncProvider = Provider<void>((ref) {
  final remoteDataSource = ref.watch(leaderboardRemoteDataSourceProvider);
  if (remoteDataSource == null) {
    return;
  }

  ref.watch(playerProvider);
  final repository = ref.watch(leaderboardRepositoryProvider);
  final connectionChecker = ref.watch(leaderboardConnectionCheckerProvider);
  var disposed = false;

  Future<void> syncNow() async {
    if (disposed) {
      return;
    }

    ref.read(leaderboardSyncStatusProvider.notifier).state =
        const LeaderboardSyncSnapshot(LeaderboardSyncStatus.syncing);
    final result = await repository.syncIfOnline();
    if (disposed) {
      return;
    }

    ref
        .read(leaderboardSyncStatusProvider.notifier)
        .state = LeaderboardSyncSnapshot(
      result.state,
      syncedAt: result.syncedAt,
      error: result.error,
    );
    ref.invalidate(leaderboardProvider);
  }

  unawaited(syncNow());
  final subscription = connectionChecker.onConnectionChanged.listen((isOnline) {
    if (isOnline) {
      unawaited(syncNow());
      return;
    }

    ref.read(leaderboardSyncStatusProvider.notifier).state =
        const LeaderboardSyncSnapshot(LeaderboardSyncStatus.offline);
  });

  ref.onDispose(() {
    disposed = true;
    unawaited(subscription.cancel());
  });
});

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  ref.watch(playerProvider);
  final repository = ref.watch(leaderboardRepositoryProvider);
  return repository.loadEntries();
});

class LeaderboardSyncSnapshot {
  final LeaderboardSyncStatus state;
  final DateTime? syncedAt;
  final String? error;

  const LeaderboardSyncSnapshot(this.state, {this.syncedAt, this.error});
}
