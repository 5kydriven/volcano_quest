import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volcano_quest/core/constants/app_constants.dart';
import 'package:volcano_quest/data/local/app_database.dart';
import 'package:volcano_quest/data/models/player_model.dart';
import 'package:volcano_quest/data/repositories/leaderboard_repository.dart';
import 'package:volcano_quest/data/repositories/player_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late PlayerRepository playerRepository;
  late AppDatabase database;
  late _FakeRemoteDataSource remoteDataSource;
  late _FakeConnectionChecker connectionChecker;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      AppConstants.prefLeaderboardInstallId: 'install-1',
    });
    prefs = await SharedPreferences.getInstance();
    playerRepository = PlayerRepository(prefs);
    database = AppDatabase.forTesting(NativeDatabase.memory());
    remoteDataSource = _FakeRemoteDataSource();
    connectionChecker = _FakeConnectionChecker(isOnline: true);
  });

  tearDown(() async {
    await database.close();
    await connectionChecker.close();
  });

  LeaderboardRepository createRepository() {
    return LeaderboardRepository(
      playerRepository: playerRepository,
      database: database,
      prefs: prefs,
      remoteDataSource: remoteDataSource,
      connectionChecker: connectionChecker,
    );
  }

  test(
    'merges local profiles with cached remote entries and dedupes local rows',
    () async {
      await playerRepository.savePlayer(
        const PlayerModel(
          id: 'local-a',
          name: 'Ava',
          avatarIndex: 1,
          currentLevel: 5,
          totalXP: 100,
          earnedBadges: ['badge-a'],
        ),
      );
      await playerRepository.savePlayer(
        const PlayerModel(
          id: 'local-b',
          name: 'Ben',
          avatarIndex: 2,
          currentLevel: 4,
          totalXP: 80,
        ),
      );
      await playerRepository.setActivePlayer('local-a');
      await database.upsertCachedLeaderboardEntries([
        CachedLeaderboardEntriesCompanion.insert(
          documentId: 'install-1_local-a',
          playerId: 'local-a',
          installId: 'install-1',
          name: 'Stale Ava',
          avatarIndex: 0,
          totalXP: 1,
          currentLevel: 1,
          badgeCount: 0,
          updatedAt: const Value(null),
          appVersion: AppConstants.appVersion,
          schemaVersion: 1,
          cachedAt: DateTime.now(),
        ),
        CachedLeaderboardEntriesCompanion.insert(
          documentId: 'remote-1_remote-a',
          playerId: 'remote-a',
          installId: 'remote-1',
          name: 'Riley',
          avatarIndex: 3,
          totalXP: 150,
          currentLevel: 6,
          badgeCount: 2,
          updatedAt: const Value(null),
          appVersion: AppConstants.appVersion,
          schemaVersion: 1,
          cachedAt: DateTime.now(),
        ),
      ]);

      final entries = await createRepository().loadEntries();

      expect(entries.map((entry) => entry.name), ['Riley', 'Ava', 'Ben']);
      expect(entries.map((entry) => entry.rank), [1, 2, 3]);
      expect(entries.first.source, LeaderboardEntrySource.remote);
      expect(entries[1].isCurrentPlayer, isTrue);
      expect(entries[1].source, LeaderboardEntrySource.local);
    },
  );

  test(
    'sync uploads local profiles and stores fetched remote entries in Drift',
    () async {
      await playerRepository.savePlayer(
        const PlayerModel(
          id: 'local-a',
          name: 'Ava',
          avatarIndex: 1,
          currentLevel: 3,
          totalXP: 90,
        ),
      );
      remoteDataSource.entriesToFetch = [
        const RemoteLeaderboardEntry(
          documentId: 'remote-1_remote-a',
          playerId: 'remote-a',
          installId: 'remote-1',
          name: 'Riley',
          avatarIndex: 3,
          totalXP: 140,
          currentLevel: 4,
          badgeCount: 2,
          updatedAt: null,
          appVersion: AppConstants.appVersion,
          schemaVersion: 1,
        ),
      ];

      final result = await createRepository().syncIfOnline();

      expect(result.state, LeaderboardSyncStatus.synced);
      expect(
        remoteDataSource.uploadedEntries.single.documentId,
        'install-1_local-a',
      );
      expect(remoteDataSource.fetchCount, 1);

      final cachedEntries = await database.loadCachedLeaderboardEntries();
      expect(cachedEntries.single.name, 'Riley');

      final leaderboard = await createRepository().loadEntries();
      expect(leaderboard.map((entry) => entry.name), ['Riley', 'Ava']);
    },
  );

  test(
    'offline sync keeps showing cached entries without contacting remote',
    () async {
      connectionChecker.isOnline = false;
      await database.upsertCachedLeaderboardEntries([
        CachedLeaderboardEntriesCompanion.insert(
          documentId: 'remote-1_remote-a',
          playerId: 'remote-a',
          installId: 'remote-1',
          name: 'Riley',
          avatarIndex: 3,
          totalXP: 140,
          currentLevel: 4,
          badgeCount: 2,
          updatedAt: const Value(null),
          appVersion: AppConstants.appVersion,
          schemaVersion: 1,
          cachedAt: DateTime.now(),
        ),
      ]);

      final result = await createRepository().syncIfOnline();
      final leaderboard = await createRepository().loadEntries();

      expect(result.state, LeaderboardSyncStatus.offline);
      expect(remoteDataSource.uploadedEntries, isEmpty);
      expect(remoteDataSource.fetchCount, 0);
      expect(leaderboard.single.name, 'Riley');
    },
  );
}

class _FakeRemoteDataSource implements LeaderboardRemoteDataSource {
  final uploadedEntries = <RemoteLeaderboardUpload>[];
  var entriesToFetch = <RemoteLeaderboardEntry>[];
  var fetchCount = 0;

  @override
  Future<List<RemoteLeaderboardEntry>> fetchTopEntries() async {
    fetchCount++;
    return entriesToFetch;
  }

  @override
  Future<void> upsertEntry(RemoteLeaderboardUpload entry) async {
    uploadedEntries.add(entry);
  }
}

class _FakeConnectionChecker implements LeaderboardConnectionChecker {
  final _controller = StreamController<bool>.broadcast();
  bool isOnline;

  _FakeConnectionChecker({required this.isOnline});

  @override
  Stream<bool> get onConnectionChanged => _controller.stream;

  @override
  Future<bool> hasConnection() async => isOnline;

  Future<void> close() {
    return _controller.close();
  }
}
