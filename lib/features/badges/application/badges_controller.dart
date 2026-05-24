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
    ],
  ];
});
