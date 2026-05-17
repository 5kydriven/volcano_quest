import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_model.dart';
import '../../core/constants/app_constants.dart';

class PlayerRepository {
  final SharedPreferences _prefs;

  PlayerRepository(this._prefs);

  Future<PlayerModel> loadPlayer() async {
    final name = _prefs.getString(AppConstants.prefPlayerName) ?? '';
    final avatarIndex = _prefs.getInt(AppConstants.prefAvatarIndex) ?? 0;
    final currentLevel = _prefs.getInt(AppConstants.prefCurrentLevel) ?? 1;
    final totalXP = _prefs.getInt(AppConstants.prefTotalXP) ?? 0;
    final badges = _prefs.getStringList(AppConstants.prefEarnedBadges) ?? [];

    return PlayerModel(
      name: name,
      avatarIndex: avatarIndex,
      currentLevel: currentLevel,
      totalXP: totalXP,
      earnedBadges: badges,
    );
  }

  Future<void> savePlayer(PlayerModel player) async {
    await _prefs.setString(AppConstants.prefPlayerName, player.name);
    await _prefs.setInt(AppConstants.prefAvatarIndex, player.avatarIndex);
    await _prefs.setInt(AppConstants.prefCurrentLevel, player.currentLevel);
    await _prefs.setInt(AppConstants.prefTotalXP, player.totalXP);
    await _prefs.setStringList(AppConstants.prefEarnedBadges, player.earnedBadges);
  }

  bool get isOnboardingDone =>
      _prefs.getBool(AppConstants.prefOnboardingDone) ?? false;

  Future<void> setOnboardingDone() async =>
      _prefs.setBool(AppConstants.prefOnboardingDone, true);

  Future<void> clearAll() async => _prefs.clear();
}
