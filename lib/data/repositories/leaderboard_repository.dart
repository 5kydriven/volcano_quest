import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../local/app_database.dart';
import '../models/player_model.dart';
import 'player_repository.dart';

class LeaderboardRepository {
  final PlayerRepository _playerRepository;
  final AppDatabase _database;
  final SharedPreferences _prefs;
  final LeaderboardRemoteDataSource? _remoteDataSource;
  final LeaderboardConnectionChecker _connectionChecker;

  const LeaderboardRepository({
    required PlayerRepository playerRepository,
    required AppDatabase database,
    required SharedPreferences prefs,
    required LeaderboardRemoteDataSource? remoteDataSource,
    required LeaderboardConnectionChecker connectionChecker,
  }) : _playerRepository = playerRepository,
       _database = database,
       _prefs = prefs,
       _remoteDataSource = remoteDataSource,
       _connectionChecker = connectionChecker;

  bool get canUseRemoteSync => _remoteDataSource != null;

  Future<List<LeaderboardEntry>> loadEntries() async {
    final installId = await _loadOrCreateInstallId();
    final activePlayerId = _playerRepository.loadActivePlayerId();
    final localPlayers = _playerRepository.loadPlayers();
    final localDocumentIds = <String>{};
    final entries = <LeaderboardEntry>[
      for (final player in localPlayers)
        LeaderboardEntry.fromPlayer(
          player,
          isCurrentPlayer: player.id == activePlayerId,
        ),
    ];

    for (final player in localPlayers) {
      localDocumentIds.add(
        _documentId(installId: installId, playerId: player.id),
      );
    }

    final cachedRows = await _database.loadCachedLeaderboardEntries();
    for (final row in cachedRows) {
      if (localDocumentIds.contains(row.documentId)) {
        continue;
      }
      entries.add(
        LeaderboardEntry(
          rank: 0,
          playerId: row.playerId,
          name: row.name,
          avatarIndex: row.avatarIndex,
          totalXP: row.totalXP,
          currentLevel: row.currentLevel,
          badgeCount: row.badgeCount,
          isCurrentPlayer: false,
          source: LeaderboardEntrySource.remote,
        ),
      );
    }

    entries.sort(compareLeaderboardEntries);

    return [
      for (var i = 0; i < entries.length; i++) entries[i].copyWith(rank: i + 1),
    ];
  }

  Future<LeaderboardSyncResult> syncIfOnline() async {
    final remoteDataSource = _remoteDataSource;
    if (remoteDataSource == null) {
      return const LeaderboardSyncResult(LeaderboardSyncStatus.unavailable);
    }

    final isOnline = await _connectionChecker.hasConnection();
    if (!isOnline) {
      return const LeaderboardSyncResult(LeaderboardSyncStatus.offline);
    }

    final installId = await _loadOrCreateInstallId();
    try {
      await _uploadLocalPlayers(
        installId: installId,
        remoteDataSource: remoteDataSource,
      );
      final remoteEntries = await remoteDataSource.fetchTopEntries();
      await _cacheRemoteEntries(remoteEntries);
      return LeaderboardSyncResult(
        LeaderboardSyncStatus.synced,
        syncedAt: DateTime.now(),
      );
    } on Object catch (error) {
      return LeaderboardSyncResult(
        LeaderboardSyncStatus.error,
        error: error.toString(),
      );
    }
  }

  Future<void> _uploadLocalPlayers({
    required String installId,
    required LeaderboardRemoteDataSource remoteDataSource,
  }) async {
    for (final player in _playerRepository.loadPlayers()) {
      final upload = RemoteLeaderboardUpload.fromPlayer(
        player,
        installId: installId,
      );
      final uploadHash = upload.stableHash;
      final lastHash = await _database.loadLastUploadedHash(upload.documentId);
      if (lastHash == uploadHash) {
        continue;
      }

      try {
        await remoteDataSource.upsertEntry(upload);
        await _database.markLeaderboardUploaded(
          playerKey: upload.documentId,
          uploadedHash: uploadHash,
        );
      } on Object catch (error) {
        await _database.markLeaderboardSyncError(
          playerKey: upload.documentId,
          error: error.toString(),
        );
        rethrow;
      }
    }
  }

  Future<void> _cacheRemoteEntries(List<RemoteLeaderboardEntry> entries) {
    final cachedAt = DateTime.now();
    return _database.upsertCachedLeaderboardEntries([
      for (final entry in entries)
        CachedLeaderboardEntriesCompanion.insert(
          documentId: entry.documentId,
          playerId: entry.playerId,
          installId: entry.installId,
          name: entry.name,
          avatarIndex: entry.avatarIndex,
          totalXP: entry.totalXP,
          currentLevel: entry.currentLevel,
          badgeCount: entry.badgeCount,
          updatedAt: Value(entry.updatedAt),
          appVersion: entry.appVersion,
          schemaVersion: entry.schemaVersion,
          cachedAt: cachedAt,
        ),
    ]);
  }

  Future<String> _loadOrCreateInstallId() async {
    final existing = _prefs.getString(AppConstants.prefLeaderboardInstallId);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final installId = DateTime.now().microsecondsSinceEpoch.toString();
    await _prefs.setString(AppConstants.prefLeaderboardInstallId, installId);
    return installId;
  }
}

abstract class LeaderboardRemoteDataSource {
  Future<void> upsertEntry(RemoteLeaderboardUpload entry);
  Future<List<RemoteLeaderboardEntry>> fetchTopEntries();
}

class FirestoreLeaderboardRemoteDataSource
    implements LeaderboardRemoteDataSource {
  final FirebaseFirestore _firestore;

  const FirestoreLeaderboardRemoteDataSource(this._firestore);

  static const collectionPath = 'leaderboard_entries';
  static const topEntryLimit = 10;

  @override
  Future<void> upsertEntry(RemoteLeaderboardUpload entry) {
    return _firestore.collection(collectionPath).doc(entry.documentId).set({
      'playerId': entry.playerId,
      'installId': entry.installId,
      'name': entry.name,
      'avatarIndex': entry.avatarIndex,
      'totalXP': entry.totalXP,
      'currentLevel': entry.currentLevel,
      'badgeCount': entry.badgeCount,
      'updatedAt': FieldValue.serverTimestamp(),
      'appVersion': entry.appVersion,
      'schemaVersion': entry.schemaVersion,
    }, SetOptions(merge: true));
  }

  @override
  Future<List<RemoteLeaderboardEntry>> fetchTopEntries() async {
    final snapshot = await _firestore
        .collection(collectionPath)
        .orderBy('totalXP', descending: true)
        .limit(topEntryLimit)
        .get();

    return snapshot.docs
        .map(RemoteLeaderboardEntry.fromFirestoreDocument)
        .whereType<RemoteLeaderboardEntry>()
        .toList();
  }
}

abstract class LeaderboardConnectionChecker {
  Stream<bool> get onConnectionChanged;
  Future<bool> hasConnection();
}

class ConnectivityLeaderboardConnectionChecker
    implements LeaderboardConnectionChecker {
  final Connectivity _connectivity;

  const ConnectivityLeaderboardConnectionChecker(this._connectivity);

  @override
  Stream<bool> get onConnectionChanged {
    return _connectivity.onConnectivityChanged.map(_hasNetworkConnection);
  }

  @override
  Future<bool> hasConnection() async {
    final results = await _connectivity.checkConnectivity();
    return _hasNetworkConnection(results);
  }

  bool _hasNetworkConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}

class RemoteLeaderboardUpload {
  final String documentId;
  final String playerId;
  final String installId;
  final String name;
  final int avatarIndex;
  final int totalXP;
  final int currentLevel;
  final int badgeCount;
  final String appVersion;
  final int schemaVersion;

  const RemoteLeaderboardUpload({
    required this.documentId,
    required this.playerId,
    required this.installId,
    required this.name,
    required this.avatarIndex,
    required this.totalXP,
    required this.currentLevel,
    required this.badgeCount,
    required this.appVersion,
    required this.schemaVersion,
  });

  factory RemoteLeaderboardUpload.fromPlayer(
    PlayerModel player, {
    required String installId,
  }) {
    return RemoteLeaderboardUpload(
      documentId: _documentId(installId: installId, playerId: player.id),
      playerId: player.id,
      installId: installId,
      name: player.name,
      avatarIndex: player.avatarIndex,
      totalXP: player.totalXP,
      currentLevel: player.currentLevel,
      badgeCount: player.earnedBadges.length,
      appVersion: AppConstants.appVersion,
      schemaVersion: 1,
    );
  }

  String get stableHash {
    return jsonEncode({
      'playerId': playerId,
      'installId': installId,
      'name': name,
      'avatarIndex': avatarIndex,
      'totalXP': totalXP,
      'currentLevel': currentLevel,
      'badgeCount': badgeCount,
      'appVersion': appVersion,
      'schemaVersion': schemaVersion,
    });
  }
}

class RemoteLeaderboardEntry {
  final String documentId;
  final String playerId;
  final String installId;
  final String name;
  final int avatarIndex;
  final int totalXP;
  final int currentLevel;
  final int badgeCount;
  final DateTime? updatedAt;
  final String appVersion;
  final int schemaVersion;

  const RemoteLeaderboardEntry({
    required this.documentId,
    required this.playerId,
    required this.installId,
    required this.name,
    required this.avatarIndex,
    required this.totalXP,
    required this.currentLevel,
    required this.badgeCount,
    required this.updatedAt,
    required this.appVersion,
    required this.schemaVersion,
  });

  static RemoteLeaderboardEntry? fromFirestoreDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final playerId = data['playerId'];
    final installId = data['installId'];
    final name = data['name'];
    if (playerId is! String ||
        playerId.isEmpty ||
        installId is! String ||
        installId.isEmpty ||
        name is! String ||
        name.isEmpty) {
      return null;
    }

    final updatedAt = data['updatedAt'];
    return RemoteLeaderboardEntry(
      documentId: document.id,
      playerId: playerId,
      installId: installId,
      name: name,
      avatarIndex: _readInt(data['avatarIndex']),
      totalXP: _readInt(data['totalXP']),
      currentLevel: _readInt(data['currentLevel'], fallback: 1),
      badgeCount: _readInt(data['badgeCount']),
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
      appVersion: data['appVersion'] as String? ?? AppConstants.appVersion,
      schemaVersion: _readInt(data['schemaVersion'], fallback: 1),
    );
  }
}

class LeaderboardSyncResult {
  final LeaderboardSyncStatus state;
  final DateTime? syncedAt;
  final String? error;

  const LeaderboardSyncResult(this.state, {this.syncedAt, this.error});
}

enum LeaderboardSyncStatus {
  unknown,
  syncing,
  synced,
  offline,
  error,
  unavailable,
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

int compareLeaderboardEntries(LeaderboardEntry a, LeaderboardEntry b) {
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

String _documentId({required String installId, required String playerId}) {
  return '${installId}_$playerId';
}

int _readInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return fallback;
}
