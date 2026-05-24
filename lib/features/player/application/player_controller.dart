import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/player_model.dart';
import '../../../data/repositories/player_repository.dart';

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PlayerRepository(prefs);
});

final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerModel>((
  ref,
) {
  final repo = ref.watch(playerRepositoryProvider);
  return PlayerNotifier(repo);
});

class PlayerNotifier extends StateNotifier<PlayerModel> {
  final PlayerRepository _repo;
  var _mutationCount = 0;

  static const missionOneId = AppConstants.missionOneId;
  static const missionTwoId = AppConstants.missionTwoId;
  static const volcanoExplorerBadge = AppConstants.volcanoExplorerBadge;
  static const lavaInvestigatorBadge = AppConstants.lavaInvestigatorBadge;

  PlayerNotifier(this._repo) : super(PlayerModel.empty) {
    _load();
  }

  Future<void> _load() async {
    final loadedPlayer = await _repo.loadPlayer();
    if (_mutationCount == 0) {
      state = loadedPlayer;
    }
  }

  Future<void> setProfile({
    required String name,
    required int avatarIndex,
  }) async {
    _mutationCount++;
    final player = PlayerModel(id: '', name: name, avatarIndex: avatarIndex);
    state = await _repo.savePlayer(player);
  }

  Future<void> addXP(int xp) async {
    _mutationCount++;
    state = await _repo.savePlayer(state.copyWith(totalXP: state.totalXP + xp));
  }

  Future<void> advanceLevel() async {
    _mutationCount++;
    final next = (state.currentLevel + 1).clamp(1, 8);
    state = await _repo.savePlayer(state.copyWith(currentLevel: next));
  }

  Future<void> earnBadge(String badge) async {
    if (!state.earnedBadges.contains(badge)) {
      _mutationCount++;
      final updated = [...state.earnedBadges, badge];
      state = await _repo.savePlayer(state.copyWith(earnedBadges: updated));
    }
  }

  Future<void> completeMissionOneOrb(String orbId) async {
    final completedOrbs =
        state.completedMissionOrbs[AppConstants.missionOneId] ?? const [];
    if (completedOrbs.contains(orbId)) {
      return;
    }

    _mutationCount++;
    final updatedMissionOrbs = Map<String, List<String>>.from(
      state.completedMissionOrbs,
    );
    final updatedCompletedOrbs = [...completedOrbs, orbId];
    updatedMissionOrbs[AppConstants.missionOneId] = updatedCompletedOrbs;

    final hasCompletedMissionOne = AppConstants.missionOneOrbIds.every(
      updatedCompletedOrbs.contains,
    );
    final updatedBadges =
        hasCompletedMissionOne &&
            !state.earnedBadges.contains(volcanoExplorerBadge)
        ? [...state.earnedBadges, volcanoExplorerBadge]
        : state.earnedBadges;
    final nextLevel = hasCompletedMissionOne && state.currentLevel < 2
        ? 2
        : state.currentLevel;

    state = await _repo.savePlayer(
      state.copyWith(
        totalXP: state.totalXP + 10,
        currentLevel: nextLevel,
        earnedBadges: updatedBadges,
        completedMissionOrbs: updatedMissionOrbs,
      ),
    );
  }

  Future<void> submitMissionTwoAnswer({
    required String questionId,
    required bool isCorrect,
  }) async {
    final answeredQuestions =
        state.completedMissionOrbs[AppConstants.missionTwoId] ?? const [];
    if (answeredQuestions.contains(questionId)) {
      return;
    }

    _mutationCount++;
    final correctAnswers =
        state.completedMissionOrbs[AppConstants.missionTwoCorrectAnswersId] ??
        const [];
    final updatedMissionProgress = Map<String, List<String>>.from(
      state.completedMissionOrbs,
    );
    final updatedAnsweredQuestions = [...answeredQuestions, questionId];
    final updatedCorrectAnswers = isCorrect
        ? [...correctAnswers, questionId]
        : correctAnswers;

    updatedMissionProgress[AppConstants.missionTwoId] =
        updatedAnsweredQuestions;
    updatedMissionProgress[AppConstants.missionTwoCorrectAnswersId] =
        updatedCorrectAnswers;

    final hasCompletedMissionTwo = AppConstants.missionTwoQuestionIds.every(
      updatedAnsweredQuestions.contains,
    );
    final updatedBadges =
        hasCompletedMissionTwo &&
            !state.earnedBadges.contains(lavaInvestigatorBadge)
        ? [...state.earnedBadges, lavaInvestigatorBadge]
        : state.earnedBadges;
    final nextLevel = hasCompletedMissionTwo && state.currentLevel < 3
        ? 3
        : state.currentLevel;
    final earnedXP = isCorrect ? AppConstants.missionTwoXpPerCorrect : 0;

    state = await _repo.savePlayer(
      state.copyWith(
        totalXP: state.totalXP + earnedXP,
        currentLevel: nextLevel,
        earnedBadges: updatedBadges,
        completedMissionOrbs: updatedMissionProgress,
      ),
    );
  }

  Future<void> switchPlayer(String playerId) async {
    final players = _repo.loadPlayers();
    PlayerModel? selectedPlayer;

    for (final player in players) {
      if (player.id == playerId) {
        selectedPlayer = player;
        break;
      }
    }

    if (selectedPlayer == null) {
      return;
    }

    _mutationCount++;
    await _repo.setActivePlayer(playerId);
    state = selectedPlayer;
  }
}

final playerProfilesProvider = Provider<List<PlayerModel>>((ref) {
  ref.watch(playerProvider);
  final repo = ref.watch(playerRepositoryProvider);
  return repo.loadPlayers();
});
