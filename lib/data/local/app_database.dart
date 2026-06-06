import 'package:drift/drift.dart';

import 'database_connection.dart';

part 'app_database.g.dart';

class CachedLeaderboardEntries extends Table {
  TextColumn get documentId => text()();
  TextColumn get playerId => text()();
  TextColumn get installId => text()();
  TextColumn get name => text()();
  IntColumn get avatarIndex => integer()();
  IntColumn get totalXP => integer()();
  IntColumn get currentLevel => integer()();
  IntColumn get badgeCount => integer()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get appVersion => text()();
  IntColumn get schemaVersion => integer()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {documentId};
}

class LeaderboardSyncState extends Table {
  TextColumn get playerKey => text()();
  TextColumn get lastUploadedHash => text().nullable()();
  DateTimeColumn get lastUploadedAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {playerKey};
}

@DriftDatabase(tables: [CachedLeaderboardEntries, LeaderboardSyncState])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openDatabaseConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  Future<List<CachedLeaderboardEntry>> loadCachedLeaderboardEntries() {
    return select(cachedLeaderboardEntries).get();
  }

  Future<void> upsertCachedLeaderboardEntries(
    List<CachedLeaderboardEntriesCompanion> entries,
  ) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(cachedLeaderboardEntries, entries);
    });
  }

  Future<String?> loadLastUploadedHash(String playerKey) async {
    final query = select(leaderboardSyncState)
      ..where((row) => row.playerKey.equals(playerKey));
    final state = await query.getSingleOrNull();
    return state?.lastUploadedHash;
  }

  Future<void> markLeaderboardUploaded({
    required String playerKey,
    required String uploadedHash,
  }) {
    return into(leaderboardSyncState).insertOnConflictUpdate(
      LeaderboardSyncStateCompanion.insert(
        playerKey: playerKey,
        lastUploadedHash: Value(uploadedHash),
        lastUploadedAt: Value(DateTime.now()),
        lastError: const Value(null),
      ),
    );
  }

  Future<void> markLeaderboardSyncError({
    required String playerKey,
    required String error,
  }) {
    return into(leaderboardSyncState).insertOnConflictUpdate(
      LeaderboardSyncStateCompanion.insert(
        playerKey: playerKey,
        lastError: Value(error),
      ),
    );
  }
}
