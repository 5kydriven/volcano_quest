class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const players = '/players';
  static const menu = '/menu';
  static const starterKnowledge = '/starter-knowledge';
  static const leaderboard = '/leaderboard';
  static const badges = '/badges';
  static const settings = '/settings';
  static const sideQuestVolcanoStructure = '/side-quest/volcano-structure';
  static const levelEightLesson = '/level/8/field-lesson';
  static const levelPath = '/level/:levelId';

  static String get playersFromMenu {
    return Uri(path: players, queryParameters: {'from': 'menu'}).toString();
  }

  static String get requiredStarterKnowledge {
    return Uri(
      path: starterKnowledge,
      queryParameters: {'required': 'true'},
    ).toString();
  }

  static String level(int levelId) => '/level/$levelId';

  static String replayLevel(int levelId) => _withReplay(level(levelId));

  static String replay(String route) => _withReplay(route);

  static String _withReplay(String route) {
    return Uri(path: route, queryParameters: {'replay': 'true'}).toString();
  }
}
