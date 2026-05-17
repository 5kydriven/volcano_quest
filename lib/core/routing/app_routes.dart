class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const players = '/players';
  static const menu = '/menu';

  static String level(int levelId) => '/level/$levelId';
}
