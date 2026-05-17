class PlayerModel {
  final String id;
  final String name;
  final int avatarIndex;
  final int currentLevel;
  final int totalXP;
  final List<String> earnedBadges;

  const PlayerModel({
    required this.id,
    required this.name,
    required this.avatarIndex,
    this.currentLevel = 1,
    this.totalXP = 0,
    this.earnedBadges = const [],
  });

  PlayerModel copyWith({
    String? id,
    String? name,
    int? avatarIndex,
    int? currentLevel,
    int? totalXP,
    List<String>? earnedBadges,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      currentLevel: currentLevel ?? this.currentLevel,
      totalXP: totalXP ?? this.totalXP,
      earnedBadges: earnedBadges ?? this.earnedBadges,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarIndex': avatarIndex,
      'currentLevel': currentLevel,
      'totalXP': totalXP,
      'earnedBadges': earnedBadges,
    };
  }

  factory PlayerModel.fromJson(Map<String, Object?> json) {
    final badges = json['earnedBadges'];

    return PlayerModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarIndex: json['avatarIndex'] as int? ?? 0,
      currentLevel: json['currentLevel'] as int? ?? 1,
      totalXP: json['totalXP'] as int? ?? 0,
      earnedBadges: badges is List
          ? badges.whereType<String>().toList()
          : const [],
    );
  }

  static const empty = PlayerModel(id: '', name: '', avatarIndex: 0);
}
