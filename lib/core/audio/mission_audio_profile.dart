import '../constants/app_constants.dart';
import '../routing/app_routes.dart';
import 'audio_catalog.dart';

class MissionAudioProfile {
  const MissionAudioProfile._();

  static BgmTrack bgmForLocation(String location) {
    final uri = Uri.tryParse(location);
    final path = uri?.path ?? location;

    if (_menuPaths.contains(path)) {
      return BgmTrack.menu;
    }

    if (_gameMenuPaths.contains(path)) {
      return BgmTrack.gameMenu;
    }

    if (path == AppRoutes.sideQuestVolcanoStructure) {
      return BgmTrack.sideQuest;
    }

    if (path == AppRoutes.levelEightLesson) {
      return BgmTrack.fieldLesson;
    }

    final levelId = _levelIdFromPath(path);
    if (levelId != null) {
      return _bgmForLevel(levelId);
    }

    return BgmTrack.menu;
  }

  static const _menuPaths = {
    AppRoutes.splash,
    AppRoutes.onboarding,
    AppRoutes.players,
  };

  static const _gameMenuPaths = {
    AppRoutes.menu,
    AppRoutes.settings,
    AppRoutes.badges,
    AppRoutes.leaderboard,
    AppRoutes.credits,
  };

  static int? _levelIdFromPath(String path) {
    final segments = Uri(path: path).pathSegments;
    if (segments.length != 2 || segments.first != 'level') {
      return null;
    }
    return int.tryParse(segments[1]);
  }

  static BgmTrack _bgmForLevel(int levelId) {
    return switch (levelId.clamp(1, AppConstants.totalLevels)) {
      1 => BgmTrack.missionOne,
      2 => BgmTrack.missionTwo,
      3 => BgmTrack.missionThree,
      4 => BgmTrack.missionFour,
      5 => BgmTrack.missionFive,
      6 => BgmTrack.missionSix,
      7 => BgmTrack.missionSeven,
      8 => BgmTrack.missionEight,
      9 => BgmTrack.missionNine,
      _ => BgmTrack.missionOne,
    };
  }
}
