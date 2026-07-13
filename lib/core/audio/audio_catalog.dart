import '../constants/audios.dart';

enum BgmTrack {
  menu,
  gameMenu,
  missionOne,
  missionTwo,
  missionThree,
  missionFour,
  missionFive,
  missionSix,
  missionSeven,
  missionEight,
  missionNine,
  sideQuest,
  fieldLesson,
}

enum SfxCue { button, correct, wrong, achievement, erupt, falling, gameAction }

class AudioCatalog {
  const AudioCatalog._();

  static String bgmAsset(BgmTrack track) {
    return switch (track) {
      BgmTrack.menu => Audios.bgMenu2,
      BgmTrack.gameMenu => Audios.bgGameMenu1,
      BgmTrack.missionOne => Audios.bgGame1,
      BgmTrack.missionTwo => Audios.bgGame2,
      BgmTrack.missionThree => Audios.bgGame2,
      BgmTrack.missionFour => Audios.bgGame2,
      BgmTrack.missionFive => Audios.bgGame1,
      BgmTrack.missionSix => Audios.bgGame1,
      BgmTrack.missionSeven => Audios.bgGame2,
      BgmTrack.missionEight => Audios.bgGame2,
      BgmTrack.missionNine => Audios.bgGame2,
      BgmTrack.sideQuest => Audios.bgGame1,
      BgmTrack.fieldLesson => Audios.bgGameMenu2,
    };
  }

  static List<String> sfxAssets(SfxCue cue) {
    return switch (cue) {
      SfxCue.button => const [
        Audios.sfxBtn1,
      ],
      SfxCue.correct => const [
        Audios.sfxCorrect1,
      ],
      SfxCue.wrong => const [Audios.sfxWrong1],
      SfxCue.achievement => const [
        Audios.sfxAchievement1,
        Audios.sfxAchievement2,
      ],
      SfxCue.erupt => const [
        Audios.sfxErupt1,
        Audios.sfxErupt2,
        Audios.sfxErupt3,
      ],
      SfxCue.falling => const [
        Audios.sfxFalling1,
        Audios.sfxFalling2,
        Audios.sfxFalling3,
      ],
      SfxCue.gameAction => const [Audios.sfxGame1],
    };
  }
}
