class PlayerModel {
  final String name;
  final int avatarIndex;
  final int currentLevel;
  final int totalXP;
  final List<String> earnedBadges;

  const PlayerModel({
    required this.name,
    required this.avatarIndex,
    this.currentLevel = 1,
    this.totalXP = 0,
    this.earnedBadges = const [],
  });

  PlayerModel copyWith({
    String? name,
    int? avatarIndex,
    int? currentLevel,
    int? totalXP,
    List<String>? earnedBadges,
  }) {
    return PlayerModel(
      name: name ?? this.name,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      currentLevel: currentLevel ?? this.currentLevel,
      totalXP: totalXP ?? this.totalXP,
      earnedBadges: earnedBadges ?? this.earnedBadges,
    );
  }

  static const empty = PlayerModel(name: '', avatarIndex: 0);
}
