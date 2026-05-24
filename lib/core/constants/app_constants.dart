class AppConstants {
  static const appVersion = 'v1.0.0';
  static const totalLevels = 8;

  static const levelNames = [
    'Volcano Research Base',
    'Volcano Knowledge Scanner',
    'Lava Word Builder',
    'Philippine Volcano Explorer',
    'Volcano Anatomy Lab',
    'Volcano Builder',
    'Volcano Investigation Center',
    'Eruption Warning Lab',
  ];

  static const levelXP = [10, 15, 20, 30, 40, 50, 60, 70];

  static const missionOneId = 'mission_1';
  static const missionTwoId = 'mission_2';
  static const missionTwoCorrectAnswersId = 'mission_2_correct_answers';
  static const missionThreeId = 'mission_3';
  static const volcanoExplorerBadge = 'volcano_explorer';
  static const lavaInvestigatorBadge = 'lava_investigator';
  static const volcanoVocabularyBadge = 'volcano_vocabulary';
  static const missionTwoXpPerCorrect = 15;
  static const missionThreeXpPerWord = 20;
  static const missionOneOrbIds = [
    'volcano_types',
    'volcano_structure',
    'eruption_types',
  ];
  static const missionTwoQuestionIds = [
    'magma_chamber',
    'shield_volcano',
    'mayon_volcano',
    'strombolian_eruption',
    'volcanic_tremors',
  ];
  static const missionThreeWordIds = ['magma', 'lava', 'ash', 'eruption'];

  static const avatarKeys = [
    'scientist',
    'researcher',
    'explorer',
    'analyst',
    'chemist',
    'astronomer',
    'observer',
    'strategist',
  ];

  static const String prefPlayerName = 'player_name';
  static const String prefAvatarIndex = 'avatar_index';
  static const String prefCurrentLevel = 'current_level';
  static const String prefTotalXP = 'total_xp';
  static const String prefOnboardingDone = 'onboarding_done';
  static const String prefEarnedBadges = 'earned_badges';
  static const String prefPlayers = 'players';
  static const String prefActivePlayerId = 'active_player_id';
}
