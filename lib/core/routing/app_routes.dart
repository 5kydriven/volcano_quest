class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const players = '/players';
  static const menu = '/menu';
  static const leaderboard = '/leaderboard';
  static const badges = '/badges';
  static const settings = '/settings';
  static const sideQuestVolcanoStructure = '/side-quest/volcano-structure';
  static const levelEightLesson = '/level/8/field-lesson';
  static const levelPath = '/level/:levelId';

  static String level(int levelId) => '/level/$levelId';
}
