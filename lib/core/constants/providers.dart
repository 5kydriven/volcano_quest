import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/player_model.dart';
import '../../data/repositories/player_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main.dart with override');
});

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

  PlayerNotifier(this._repo) : super(PlayerModel.empty) {
    _load();
  }

  Future<void> _load() async {
    state = await _repo.loadPlayer();
  }

  Future<void> setProfile({
    required String name,
    required int avatarIndex,
  }) async {
    state = state.copyWith(name: name, avatarIndex: avatarIndex);
    await _repo.savePlayer(state);
    await _repo.setOnboardingDone();
  }

  Future<void> addXP(int xp) async {
    state = state.copyWith(totalXP: state.totalXP + xp);
    await _repo.savePlayer(state);
  }

  Future<void> advanceLevel() async {
    final next = (state.currentLevel + 1).clamp(1, 8);
    state = state.copyWith(currentLevel: next);
    await _repo.savePlayer(state);
  }

  Future<void> earnBadge(String badge) async {
    if (!state.earnedBadges.contains(badge)) {
      final updated = [...state.earnedBadges, badge];
      state = state.copyWith(earnedBadges: updated);
      await _repo.savePlayer(state);
    }
  }

  bool get isOnboardingDone => _repo.isOnboardingDone;
}

final onboardingDoneProvider = Provider<bool>((ref) {
  final repo = ref.watch(playerRepositoryProvider);
  return repo.isOnboardingDone;
});
