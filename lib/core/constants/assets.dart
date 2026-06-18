class AvatarAsset {
  final String imagePath;
  final String label;

  const AvatarAsset({required this.imagePath, required this.label});
}

class Assets {
  static const String splashBg = 'assets/images/splash_bg.png';
  static const String initializeButton = 'assets/images/initialize_button.png';
  static const String playerDatabaseBg = 'assets/images/splash_bg.png';
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
  static const avatars = [
    AvatarAsset(imagePath: scientistBoy, label: 'Scientist'),
    AvatarAsset(imagePath: researcherGirl, label: 'Researcher'),
    AvatarAsset(imagePath: explorerGirl, label: 'Explorer'),
    AvatarAsset(imagePath: analystBoy, label: 'Analyst'),
    AvatarAsset(imagePath: chemistGirl, label: 'Chemist'),
    AvatarAsset(imagePath: geologistBoy, label: 'Geologist'),
    AvatarAsset(imagePath: observerBoy, label: 'Observer'),
    AvatarAsset(imagePath: strategistGirl, label: 'Strategist'),
  ];
  static const String volcanoBg = 'assets/videos/volcano.mp4';
  static const String volcanoCutaway =
      'assets/Meshy_AI_2fa1536bd2215c18f695398ed54154e2bd2d4a85.png';
  static const String volcano3dSection = 'assets/models/volcano-3d-section.glb';
  static const String explore = 'assets/spash_screen/explore.png';
  static const String predict = 'assets/splash_screen/predict.png';
  static const String survive = 'assets/splash_screen/survive.png';
  static const String splashBtn = 'assets/splash_screen/splash_btn.png';
  static const String splashLogo = 'assets/splash_screen/splash_logo.png';
}
