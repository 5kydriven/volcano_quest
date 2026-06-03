import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../player/application/player_controller.dart';

class BadgeCollectionItem {
  final String name;
  final String avatar;
  final int exp;

  const BadgeCollectionItem({
    required this.name,
    required this.avatar,
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
          avatar: 'volcano',
          exp: 30,
        ),
      if (badge == PlayerNotifier.lavaInvestigatorBadge)
        const BadgeCollectionItem(
          name: 'Lava Investigator',
          avatar: 'magma',
          exp: 75,
        ),
      if (badge == PlayerNotifier.volcanoVocabularyBadge)
        const BadgeCollectionItem(
          name: 'Volcano Vocabulary',
          avatar: 'vocabulary',
          exp: 80,
        ),
      if (badge == PlayerNotifier.philippineVolcanoExplorerBadge)
        const BadgeCollectionItem(
          name: 'Philippine Volcano Explorer',
          avatar: 'map',
          exp: 150,
        ),
      if (badge == PlayerNotifier.volcanoExplorerChampionBadge)
        const BadgeCollectionItem(
          name: 'Volcano Explorer Champion',
          avatar: 'champion',
          exp: 150,
        ),
      if (badge == PlayerNotifier.magmaAnalystBadge)
        const BadgeCollectionItem(
          name: 'Magma Analyst',
          avatar: 'magma_analyst',
          exp: 40,
        ),
      if (badge == PlayerNotifier.volcanoArchitectBadge)
        const BadgeCollectionItem(
          name: 'Volcano Architect',
          avatar: 'volcano_architect',
          exp: 250,
        ),
      if (badge == PlayerNotifier.lavaBridgeChampionBadge)
        const BadgeCollectionItem(
          name: 'Lava Bridge Champion',
          avatar: 'lava_bridge',
          exp: 60,
        ),
    ],
  ];
});
