import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_model.dart';
import '../../core/constants/app_constants.dart';

class PlayerRepository {
  final SharedPreferences _prefs;

  PlayerRepository(this._prefs);

  Future<PlayerModel> loadPlayer() async {
    await migrateLegacyPlayer();
    final players = loadPlayers();
    final activePlayerId = _prefs.getString(AppConstants.prefActivePlayerId);

    if (players.isEmpty) {
      return PlayerModel.empty;
    }

    return players.firstWhere(
      (player) => player.id == activePlayerId,
      orElse: () => players.first,
    );
  }

  List<PlayerModel> loadPlayers() {
    final encodedPlayers = _prefs.getStringList(AppConstants.prefPlayers) ?? [];

    return encodedPlayers
        .map(_decodePlayer)
        .where((player) => player.id.isNotEmpty && player.name.isNotEmpty)
        .toList();
  }

  Future<void> migrateLegacyPlayer() async {
    if (loadPlayers().isNotEmpty) {
      return;
    }

    final name = _prefs.getString(AppConstants.prefPlayerName) ?? '';
    if (name.isEmpty) {
      return;
    }

    final avatarIndex = _prefs.getInt(AppConstants.prefAvatarIndex) ?? 0;
    final currentLevel = _prefs.getInt(AppConstants.prefCurrentLevel) ?? 1;
    final totalXP = _prefs.getInt(AppConstants.prefTotalXP) ?? 0;
    final badges = _prefs.getStringList(AppConstants.prefEarnedBadges) ?? [];

    final player = PlayerModel(
      id: _newPlayerId(),
      name: name,
      avatarIndex: avatarIndex,
      currentLevel: currentLevel,
      totalXP: totalXP,
      earnedBadges: badges,
    );

    await savePlayer(player);
  }

  Future<PlayerModel> savePlayer(PlayerModel player) async {
    final savedPlayer = player.id.isEmpty
        ? player.copyWith(id: _newPlayerId())
        : player;
    final players = loadPlayers();
    final playerIndex = players.indexWhere(
      (existingPlayer) => existingPlayer.id == savedPlayer.id,
    );

    if (playerIndex == -1) {
      players.add(savedPlayer);
    } else {
      players[playerIndex] = savedPlayer;
    }

    await _savePlayers(players);
    await setActivePlayer(savedPlayer.id);
    return savedPlayer;
  }

  Future<void> setActivePlayer(String playerId) async {
    await _prefs.setString(AppConstants.prefActivePlayerId, playerId);
  }

  Future<void> _savePlayers(List<PlayerModel> players) async {
    await _prefs.setStringList(
      AppConstants.prefPlayers,
      players.map((player) => jsonEncode(player.toJson())).toList(),
    );

    if (players.isNotEmpty) {
      await _prefs.setBool(AppConstants.prefOnboardingDone, true);
    }
  }

  PlayerModel _decodePlayer(String encodedPlayer) {
    try {
      final decoded = jsonDecode(encodedPlayer);
      if (decoded is Map<String, Object?>) {
        return PlayerModel.fromJson(decoded);
      }
    } on FormatException {
      return PlayerModel.empty;
    }
    return PlayerModel.empty;
  }

  String _newPlayerId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> clearAll() async => _prefs.clear();
}
