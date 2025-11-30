class PlayerSport {
  final int id;
  final String playerId;
  final int sportId;
  final int? positionId;

  PlayerSport({required this.id, required this.playerId, required this.sportId, this.positionId});

  factory PlayerSport.fromMap(Map<String, dynamic> map) {
    return PlayerSport(id: map['id'] as int, playerId: map['player_id'] as String, sportId: map['sport_id'] as int, positionId: map['position_id'] as int?);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'player_id': playerId, 'sport_id': sportId, 'position_id': positionId};
  }
}
