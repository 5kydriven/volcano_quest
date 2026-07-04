import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/assets.dart';
import '../../player/application/player_controller.dart';

class BadgeCollectionItem {
  final String name;
  final String imagePath;
  final int exp;

  const BadgeCollectionItem({
    required this.name,
    required this.imagePath,
    required this.exp,
  });
}

final badgesProvider = Provider<List<BadgeCollectionItem>>((ref) {
  final player = ref.watch(playerProvider);

  return [
    for (final badge in player.earnedBadges) ...[
      if (badge == PlayerNotifier.volcanoExplorerBadge)
        const BadgeCollectionItem(
          name: 'Volcano Explorer',
          imagePath: Assets.badgeVolcanoExplorer,
          exp: 30,
        ),
      if (badge == PlayerNotifier.lavaInvestigatorBadge)
        const BadgeCollectionItem(
          name: 'Lava Investigator',
          imagePath: Assets.badgeLavaInvestigator,
          exp: 75,
        ),
      if (badge == PlayerNotifier.volcanoVocabularyBadge)
        const BadgeCollectionItem(
          name: 'Volcano Vocabulary',
          imagePath: Assets.badgeVolcanoVocabulary,
          exp: 80,
        ),
      if (badge == PlayerNotifier.philippineVolcanoExplorerBadge)
        const BadgeCollectionItem(
          name: 'Philippine Volcano Explorer',
          imagePath: Assets.badgePhilippineVolcanoExplorer,
          exp: 150,
        ),
      if (badge == PlayerNotifier.volcanoExplorerChampionBadge)
        const BadgeCollectionItem(
          name: 'Volcano Explorer Champion',
          imagePath: Assets.badgeVolcanoExplorerChampion,
          exp: 150,
        ),
      if (badge == PlayerNotifier.magmaAnalystBadge)
        const BadgeCollectionItem(
          name: 'Magma Analyst',
          imagePath: Assets.badgeMagmaAnalyst,
          exp: 40,
        ),
      if (badge == PlayerNotifier.volcanoArchitectBadge)
        const BadgeCollectionItem(
          name: 'Volcano Architect',
          imagePath: Assets.badgeVolcanoArchitect,
          exp: 250,
        ),
      if (badge == PlayerNotifier.lavaBridgeChampionBadge)
        const BadgeCollectionItem(
          name: 'Lava Bridge Champion',
          imagePath: Assets.badgeLavaBridgeChampion,
          exp: 60,
        ),
      if (badge == PlayerNotifier.eruptionWarningSpecialistBadge)
        const BadgeCollectionItem(
          name: 'Eruption Warning Specialist',
          imagePath: Assets.badgeEruptionWarningSpecialist,
          exp: 70,
        ),
      if (badge == PlayerNotifier.volcanoMasterBadge)
        const BadgeCollectionItem(
          name: 'Volcano Master',
          imagePath: Assets.badgeVolcanoMaster,
          exp: 100,
        ),
    ],
  ];
});
