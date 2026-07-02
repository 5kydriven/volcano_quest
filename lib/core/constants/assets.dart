class AvatarAsset {
  final String imagePath;
  final String animatedPath;
  final String label;

  const AvatarAsset({
    required this.imagePath,
    required this.animatedPath,
    required this.label,
  });
}

class Assets {
  static const String splashBg = 'assets/splash_bg.png';
  static const String playerDatabaseBg = splashBg;
  static const String initializeButton = 'assets/images/initialize_button.png';
  static const String backButton = 'assets/icons/back_button.png';
  static const String closeButton = 'assets/images/close_button.png';
  static const String profileContainer = 'assets/images/profile_container.png';
  static const String checkImage = 'assets/images/check_image.png';
  static const String createNewScientistButton =
      'assets/images/create_new_scientist_button.png';
  static const String analystBoy = 'assets/avatars/Analyst_boy.png';
  static const String chemistGirl = 'assets/avatars/Chemist_girl.jpeg';
  static const String explorerGirl = 'assets/avatars/Explorer_girl.png';
  static const String geologistBoy = 'assets/avatars/Geologist_boy.jpeg';
  static const String observerBoy = 'assets/avatars/Observer_boy.jpeg';
  static const String researcherGirl = 'assets/avatars/Researcher_girl.png';
  static const String scientistBoy = 'assets/avatars/Scientist_boy.jpeg';
  static const String strategistGirl = 'assets/avatars/Strategist_girl.jpeg';
  static const String analystBoyAnimated =
      'assets/animated_avatars/analyst_boy.mp4';
  static const String chemistGirlAnimated =
      'assets/animated_avatars/chemist_girl.mp4';
  static const String explorerGirlAnimated =
      'assets/animated_avatars/explorer_girl.mp4';
  static const String geologistBoyAnimated =
      'assets/animated_avatars/geologist_boy.mp4';
  static const String observerBoyAnimated =
      'assets/animated_avatars/observer_boy.mp4';
  static const String researcherGirlAnimated =
      'assets/animated_avatars/research_girl.mp4';
  static const String scientistBoyAnimated =
      'assets/animated_avatars/scientis_boy.mp4';
  static const String strategistGirlAnimated =
      'assets/animated_avatars/strategist_girl.mp4';
  static const avatars = [
    AvatarAsset(
      imagePath: scientistBoy,
      animatedPath: scientistBoyAnimated,
      label: 'Scientist',
    ),
    AvatarAsset(
      imagePath: researcherGirl,
      animatedPath: researcherGirlAnimated,
      label: 'Researcher',
    ),
    AvatarAsset(
      imagePath: explorerGirl,
      animatedPath: explorerGirlAnimated,
      label: 'Explorer',
    ),
    AvatarAsset(
      imagePath: analystBoy,
      animatedPath: analystBoyAnimated,
      label: 'Analyst',
    ),
    AvatarAsset(
      imagePath: chemistGirl,
      animatedPath: chemistGirlAnimated,
      label: 'Chemist',
    ),
    AvatarAsset(
      imagePath: geologistBoy,
      animatedPath: geologistBoyAnimated,
      label: 'Geologist',
    ),
    AvatarAsset(
      imagePath: observerBoy,
      animatedPath: observerBoyAnimated,
      label: 'Observer',
    ),
    AvatarAsset(
      imagePath: strategistGirl,
      animatedPath: strategistGirlAnimated,
      label: 'Strategist',
    ),
  ];
  static const String volcanoBg = 'assets/videos/volcano.mp4';
  static const String missionScreenBackground =
      'assets/missions/backgrounds/mission_screen_background.jpeg';
  static const String missionOneLabBackground =
      'assets/missions/mission_one/lab_background.png';
  static const String missionOneGlowingBall =
      'assets/missions/mission_one/glowing_ball.png';
  static const String missionOneVolcanoTypeContainer =
      'assets/missions/mission_one/volcano_type_container.png';
  static const String missionOneButtonContainer =
      'assets/missions/buttons/button_container.png';
  static const String missionFourPhilippinesMap =
      'assets/missions/mission-four/philippines_volcano_map.png';
  static const String onboardingScientistIdentity =
      'assets/onboarding_screen/20260617_231800_0000.png';
  static const String onboardingScientistProfileLabel =
      'assets/onboarding_screen/scientist_profile_label.png';
  static const String onboardingSelectAvatarLabel =
      'assets/onboarding_screen/select_avatar_label.png';
  static const String onboardingDeployLabButton =
      'assets/onboarding_screen/deploy_lab_button.png';
  static const String onboardingInputField =
      'assets/onboarding_screen/input_field.png';
  static const String missionThreeHintContainer =
      'assets/missions/misson-three/hint_container.png';
  static const String missionThreeLetterSlot =
      'assets/missions/misson-three/letter_slot.png';
  static const String missionFiveSelectedContainer =
      'assets/missions/mission-five/selected_container.png';
  static const String missionSevenStatsContainer =
      'assets/images/mission_seven_stats_container.png';
  static const String missionSevenMayon =
      'assets/missions/mission-seven/mayon_volcano.jpg';
  static const String missionSevenTaal =
      'assets/missions/mission-seven/taal_volcano.jpg';
  static const String missionSevenArayat =
      'assets/missions/mission-seven/mount_arayat.png';
  static const String missionSevenMakiling =
      'assets/missions/mission-seven/mount_makiling.png';
  static const String missionEightMagmaClassification =
      'assets/missions/mission_eight/magma_classification.png';
  static const String missionEightWhyLiveNearVolcanoes =
      'assets/missions/mission_eight/why_live_near_volcanoes.png';
  static const missionTwoAnswerContainers = [
    'assets/missions/ABCD_container/A_container.png',
    'assets/missions/ABCD_container/B_container.png',
    'assets/missions/ABCD_container/C_container.png',
    'assets/missions/ABCD_container/D_container.png',
  ];
  static const String missionSubmitAnswerButton =
      'assets/missions/buttons/submit_answer_button.png';
  static const String missionNextQuestionButton =
      'assets/missions/buttons/next_question_button.png';
  static const String missionViewResultsButton =
      'assets/missions/buttons/view_results_button.png';
  static const String missionActiveButton =
      'assets/missions/buttons/active_button.png';
  static const String missionInactiveButton =
      'assets/missions/buttons/inactive_button.png';
  static const String missionAnalyzeVolcanoButton =
      'assets/missions/buttons/analyze_volcano_button.png';
  static const String squareContainer =
      'assets/containers/square_container.png';
  static const String rectangleContainer =
      'assets/containers/rectangle_container.png';
  static const String volcanoCutaway =
      'assets/Meshy_AI_2fa1536bd2215c18f695398ed54154e2bd2d4a85.png';
  static const String volcano3dSection = 'assets/models/volcano-3d-section.glb';
  static const String explore = 'assets/splash_screen/explore.png';
  static const String predict = 'assets/splash_screen/predict.png';
  static const String survive = 'assets/splash_screen/survive.png';
  static const String splashBtn = 'assets/splash_screen/splash_btn.png';
  static const String splashLogo = 'assets/splash_screen/splash_logo.png';
  static const String splashScreenBg = 'assets/splash_screen/splash_bg.jpg';
  static const String settingUnmute = 'assets/setting_screen/unmute.png';
  static const String settingBgm = 'assets/setting_screen/bgm.png';
  static const String settingMute = 'assets/setting_screen/mute.png';
  static const String settingSfx = 'assets/setting_screen/sfx.png';
  static const String settingToggleOff = 'assets/setting_screen/toggle_of.png';
  static const String settingToggleOn = 'assets/setting_screen/toggle_on.png';
  static const String menuBg = 'assets/menu_screen/menu_bg.jpeg';
  static const String appLogo = 'assets/app_logo.png';
  static const String containerList = 'assets/leaderboard/container_list.png';
  static const String header = 'assets/leaderboard/header.png';
  static const String leaderboardBg = 'assets/leaderboard/leaderboard_bg.png';
  static const String no1Container = 'assets/leaderboard/no_1_container.png';
  static const String rankingContainer =
      'assets/leaderboard/ranking_container.png';
  static const String stats = 'assets/leaderboard/stats.png';
  static const String trackContainer = 'assets/leaderboard/track_container.png';
}
