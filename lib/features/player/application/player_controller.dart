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
  static const volcanoVocabularyBadge = AppConstants.volcanoVocabularyBadge;
  static const philippineVolcanoExplorerBadge =
      AppConstants.philippineVolcanoExplorerBadge;
  static const volcanoExplorerChampionBadge =
      AppConstants.volcanoExplorerChampionBadge;
  static const magmaAnalystBadge = AppConstants.magmaAnalystBadge;
  static const volcanoArchitectBadge = AppConstants.volcanoArchitectBadge;
  static const lavaBridgeChampionBadge = AppConstants.lavaBridgeChampionBadge;
  static const eruptionWarningSpecialistBadge =
      AppConstants.eruptionWarningSpecialistBadge;
  static const volcanoMasterBadge = AppConstants.volcanoMasterBadge;

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
    final next = (state.currentLevel + 1).clamp(1, AppConstants.totalLevels);
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

  Future<void> completeMissionThreeWord(String wordId) async {
    final solvedWords =
        state.completedMissionOrbs[AppConstants.missionThreeId] ?? const [];
    if (solvedWords.contains(wordId)) {
      return;
    }

    _mutationCount++;
    final updatedMissionProgress = Map<String, List<String>>.from(
      state.completedMissionOrbs,
    );
    final updatedSolvedWords = [...solvedWords, wordId];
    updatedMissionProgress[AppConstants.missionThreeId] = updatedSolvedWords;

    final hasCompletedMissionThree = AppConstants.missionThreeWordIds.every(
      updatedSolvedWords.contains,
    );
    final updatedBadges =
        hasCompletedMissionThree &&
            !state.earnedBadges.contains(volcanoVocabularyBadge)
        ? [...state.earnedBadges, volcanoVocabularyBadge]
        : state.earnedBadges;
    state = await _repo.savePlayer(
      state.copyWith(
        totalXP: state.totalXP + AppConstants.missionThreeXpPerWord,
        earnedBadges: updatedBadges,
        completedMissionOrbs: updatedMissionProgress,
      ),
    );
  }

  Future<void> submitSideQuestVolcanoStructureAnswer({
    required String questionId,
    required bool isCorrect,
  }) async {
    final answeredQuestions =
        state.completedMissionOrbs[AppConstants.sideQuestVolcanoStructureId] ??
        const [];
    if (answeredQuestions.contains(questionId)) {
      return;
    }

    _mutationCount++;
    final questionIndex = AppConstants.sideQuestVolcanoStructureQuestionIds
        .indexOf(questionId);
    final earnedXP = isCorrect && questionIndex != -1
        ? AppConstants.sideQuestVolcanoStructureXp[questionIndex]
        : 0;
    final correctAnswers =
        state.completedMissionOrbs[AppConstants
            .sideQuestVolcanoStructureCorrectAnswersId] ??
        const [];
    final updatedMissionProgress = Map<String, List<String>>.from(
      state.completedMissionOrbs,
    );
    final updatedAnsweredQuestions = [...answeredQuestions, questionId];
    final updatedCorrectAnswers = isCorrect
        ? [...correctAnswers, questionId]
        : correctAnswers;

    updatedMissionProgress[AppConstants.sideQuestVolcanoStructureId] =
        updatedAnsweredQuestions;
    updatedMissionProgress[AppConstants
            .sideQuestVolcanoStructureCorrectAnswersId] =
        updatedCorrectAnswers;

    final hasCompletedSideQuest = AppConstants
        .sideQuestVolcanoStructureQuestionIds
        .every(updatedAnsweredQuestions.contains);
    final nextLevel = hasCompletedSideQuest && state.currentLevel < 4
        ? 4
        : state.currentLevel;

    state = await _repo.savePlayer(
      state.copyWith(
        totalXP: state.totalXP + earnedXP,
        currentLevel: nextLevel,
        completedMissionOrbs: updatedMissionProgress,
      ),
    );
  }

  Future<void> submitMissionFourAnswer({
    required String volcanoId,
    required bool isCorrect,
  }) async {
    final answeredVolcanoes =
        state.completedMissionOrbs[AppConstants.missionFourId] ?? const [];
    if (answeredVolcanoes.contains(volcanoId)) {
      return;
    }

    _mutationCount++;
    final correctVolcanoes =
        state.completedMissionOrbs[AppConstants.missionFourCorrectAnswersId] ??
        const [];
    final updatedMissionProgress = Map<String, List<String>>.from(
      state.completedMissionOrbs,
    );
    final updatedAnsweredVolcanoes = [...answeredVolcanoes, volcanoId];
    final updatedCorrectVolcanoes = isCorrect
        ? [...correctVolcanoes, volcanoId]
        : correctVolcanoes;

    updatedMissionProgress[AppConstants.missionFourId] =
        updatedAnsweredVolcanoes;
    updatedMissionProgress[AppConstants.missionFourCorrectAnswersId] =
        updatedCorrectVolcanoes;

    final hasCompletedMissionFour = AppConstants.missionFourVolcanoIds.every(
      updatedAnsweredVolcanoes.contains,
    );
    final hasPerfectScore = AppConstants.missionFourVolcanoIds.every(
      updatedCorrectVolcanoes.contains,
    );
    final updatedBadges = [...state.earnedBadges];
    if (hasCompletedMissionFour &&
        !updatedBadges.contains(philippineVolcanoExplorerBadge)) {
      updatedBadges.add(philippineVolcanoExplorerBadge);
    }
    if (hasCompletedMissionFour &&
        hasPerfectScore &&
        !updatedBadges.contains(volcanoExplorerChampionBadge)) {
      updatedBadges.add(volcanoExplorerChampionBadge);
    }
    final nextLevel = hasCompletedMissionFour && state.currentLevel < 5
        ? 5
        : state.currentLevel;
    final earnedXP = isCorrect ? AppConstants.missionFourXpPerCorrect : 0;

    state = await _repo.savePlayer(
      state.copyWith(
        totalXP: state.totalXP + earnedXP,
        currentLevel: nextLevel,
        earnedBadges: updatedBadges,
        completedMissionOrbs: updatedMissionProgress,
      ),
    );
  }

  Future<void> completeMissionFiveAnatomyLab() async {
    final completedParts =
        state.completedMissionOrbs[AppConstants.missionFiveId] ?? const [];
    final hasCompletedMissionFive = AppConstants.missionFiveAnatomyPartIds
        .every(completedParts.contains);
    if (hasCompletedMissionFive) {
      return;
    }

    _mutationCount++;
    final updatedMissionProgress = Map<String, List<String>>.from(
      state.completedMissionOrbs,
    );
    updatedMissionProgress[AppConstants.missionFiveId] = [
      ...AppConstants.missionFiveAnatomyPartIds,
    ];

    final updatedBadges = state.earnedBadges.contains(magmaAnalystBadge)
        ? state.earnedBadges
        : [...state.earnedBadges, magmaAnalystBadge];
    final nextLevel = state.currentLevel < 6 ? 6 : state.currentLevel;

    state = await _repo.savePlayer(
      state.copyWith(
        totalXP: state.totalXP + AppConstants.missionFiveXp,
        currentLevel: nextLevel,
        earnedBadges: updatedBadges,
        completedMissionOrbs: updatedMissionProgress,
      ),
    );
  }

  Future<void> completeMissionSixVolcanoBuilderPart(String partId) async {
    final completedParts =
        state.completedMissionOrbs[AppConstants.missionSixId] ?? const [];
    if (completedParts.contains(partId) ||
        !AppConstants.missionSixBuilderPartIds.contains(partId)) {
      return;
    }

    _mutationCount++;
    final updatedMissionProgress = Map<String, List<String>>.from(
      state.completedMissionOrbs,
    );
    final updatedCompletedParts = [...completedParts, partId];
    updatedMissionProgress[AppConstants.missionSixId] = updatedCompletedParts;

    final hasCompletedMissionSix = AppConstants.missionSixBuilderPartIds.every(
      updatedCompletedParts.contains,
    );
    final updatedBadges =
        hasCompletedMissionSix &&
            !state.earnedBadges.contains(volcanoArchitectBadge)
        ? [...state.earnedBadges, volcanoArchitectBadge]
        : state.earnedBadges;
    final nextLevel = hasCompletedMissionSix && state.currentLevel < 7
        ? 7
        : state.currentLevel;

    state = await _repo.savePlayer(
      state.copyWith(
        totalXP: state.totalXP + AppConstants.missionSixXp,
        currentLevel: nextLevel,
        earnedBadges: updatedBadges,
        completedMissionOrbs: updatedMissionProgress,
      ),
    );
  }

  Future<void> submitMissionSevenVolcano({
    required String volcanoId,
    required bool isCorrect,
  }) async {
    final attemptedVolcanoes =
        state.completedMissionOrbs[AppConstants.missionSevenId] ?? const [];
    if (attemptedVolcanoes.contains(volcanoId) ||
        !AppConstants.missionSevenVolcanoIds.contains(volcanoId)) {
      return;
    }

    _mutationCount++;
    final updatedMissionProgress = Map<String, List<String>>.from(
      state.completedMissionOrbs,
    );
    final updatedAttemptedVolcanoes = [...attemptedVolcanoes, volcanoId];
    final correctVolcanoes =
        state.completedMissionOrbs[AppConstants.missionSevenCorrectAnswersId] ??
        const [];
    final updatedCorrectVolcanoes = isCorrect
        ? [...correctVolcanoes, volcanoId]
        : correctVolcanoes;
    updatedMissionProgress[AppConstants.missionSevenId] =
        updatedAttemptedVolcanoes;
    updatedMissionProgress[AppConstants.missionSevenCorrectAnswersId] =
        updatedCorrectVolcanoes;

    final hasAttemptedAllVolcanoes = AppConstants.missionSevenVolcanoIds.every(
      updatedAttemptedVolcanoes.contains,
    );
    final hasPerfectScore = AppConstants.missionSevenVolcanoIds.every(
      updatedCorrectVolcanoes.contains,
    );
    final earnedXP =
        (isCorrect ? AppConstants.missionSevenXpPerCorrect : 0) +
        (hasPerfectScore ? AppConstants.missionSevenPerfectBonusXp : 0);
    final updatedBadges =
        hasPerfectScore && !state.earnedBadges.contains(lavaBridgeChampionBadge)
        ? [...state.earnedBadges, lavaBridgeChampionBadge]
        : state.earnedBadges;
    final nextLevel = hasAttemptedAllVolcanoes && state.currentLevel < 8
        ? 8
        : state.currentLevel;

    state = await _repo.savePlayer(
      state.copyWith(
        totalXP: state.totalXP + earnedXP,
        currentLevel: nextLevel,
        earnedBadges: updatedBadges,
        completedMissionOrbs: updatedMissionProgress,
      ),
    );
  }

  Future<void> submitMissionEightWarningSign({
    required String signId,
    required bool isCorrect,
  }) async {
    final attemptedSigns =
        state.completedMissionOrbs[AppConstants.missionEightId] ?? const [];
    if (attemptedSigns.contains(signId) ||
        !AppConstants.missionEightWarningSignIds.contains(signId)) {
      return;
    }

    _mutationCount++;
    final signIndex = AppConstants.missionEightWarningSignIds.indexOf(signId);
    final updatedMissionProgress = Map<String, List<String>>.from(
      state.completedMissionOrbs,
    );
    final updatedAttemptedSigns = [...attemptedSigns, signId];
    final correctSigns =
        state.completedMissionOrbs[AppConstants.missionEightCorrectAnswersId] ??
        const [];
    final updatedCorrectSigns = isCorrect
        ? [...correctSigns, signId]
        : correctSigns;

    updatedMissionProgress[AppConstants.missionEightId] = updatedAttemptedSigns;
    updatedMissionProgress[AppConstants.missionEightCorrectAnswersId] =
        updatedCorrectSigns;

    final hasAttemptedAllSigns = AppConstants.missionEightWarningSignIds.every(
      updatedAttemptedSigns.contains,
    );
    final hasPerfectScore = AppConstants.missionEightWarningSignIds.every(
      updatedCorrectSigns.contains,
    );
    final earnedXP =
        (isCorrect ? AppConstants.missionEightXpPerCorrect[signIndex] : 0) +
        (hasPerfectScore ? AppConstants.missionEightPerfectBonusXp : 0);
    final updatedBadges =
        hasPerfectScore &&
            !state.earnedBadges.contains(eruptionWarningSpecialistBadge)
        ? [...state.earnedBadges, eruptionWarningSpecialistBadge]
        : state.earnedBadges;
    final nextLevel = hasAttemptedAllSigns && state.currentLevel < 9
        ? 9
        : state.currentLevel;

    state = await _repo.savePlayer(
      state.copyWith(
        totalXP: state.totalXP + earnedXP,
        currentLevel: nextLevel,
        earnedBadges: updatedBadges,
        completedMissionOrbs: updatedMissionProgress,
      ),
    );
  }

  Future<void> completeLevelEightLesson() async {
    final completedLessons =
        state.completedMissionOrbs[AppConstants.levelEightLessonId] ?? const [];
    if (completedLessons.contains(AppConstants.levelEightLessonCompleteId)) {
      return;
    }

    _mutationCount++;
    final updatedMissionProgress = Map<String, List<String>>.from(
      state.completedMissionOrbs,
    );
    updatedMissionProgress[AppConstants.levelEightLessonId] = [
      ...completedLessons,
      AppConstants.levelEightLessonCompleteId,
    ];

    final nextLevel = state.currentLevel < 9 ? 9 : state.currentLevel;
    state = await _repo.savePlayer(
      state.copyWith(
        currentLevel: nextLevel,
        completedMissionOrbs: updatedMissionProgress,
      ),
    );
  }

  Future<void> submitMissionNineAnswer({
    required String questionId,
    required bool isCorrect,
  }) async {
    final answeredQuestions =
        state.completedMissionOrbs[AppConstants.missionNineId] ?? const [];
    if (answeredQuestions.contains(questionId) ||
        !AppConstants.missionNineQuestionIds.contains(questionId)) {
      return;
    }

    _mutationCount++;
    final updatedMissionProgress = Map<String, List<String>>.from(
      state.completedMissionOrbs,
    );
    final updatedAnsweredQuestions = [...answeredQuestions, questionId];
    final correctAnswers =
        state.completedMissionOrbs[AppConstants.missionNineCorrectAnswersId] ??
        const [];
    final updatedCorrectAnswers = isCorrect
        ? [...correctAnswers, questionId]
        : correctAnswers;

    updatedMissionProgress[AppConstants.missionNineId] =
        updatedAnsweredQuestions;
    updatedMissionProgress[AppConstants.missionNineCorrectAnswersId] =
        updatedCorrectAnswers;

    final hasCompletedMissionNine = AppConstants.missionNineQuestionIds.every(
      updatedAnsweredQuestions.contains,
    );
    final updatedBadges =
        hasCompletedMissionNine &&
            !state.earnedBadges.contains(volcanoMasterBadge)
        ? [...state.earnedBadges, volcanoMasterBadge]
        : state.earnedBadges;
    final earnedXP = hasCompletedMissionNine ? AppConstants.missionNineXp : 0;

    state = await _repo.savePlayer(
      state.copyWith(
        totalXP: state.totalXP + earnedXP,
        currentLevel: AppConstants.totalLevels,
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
