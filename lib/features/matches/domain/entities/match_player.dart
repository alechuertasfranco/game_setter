class MatchPlayer {
  final int id;
  final int matchId;
  final String playerId;
  final bool attended;
  final bool paid;

  MatchPlayer({required this.id, required this.matchId, required this.playerId, this.attended = false, this.paid = false});

  factory MatchPlayer.fromMap(Map<String, dynamic> map) {
    return MatchPlayer(
      id: map['id'] as int,
      matchId: map['match_id'] as int,
      playerId: map['player_id'] as String,
      attended: (map['attended'] ?? 0) == 1,
      paid: (map['paid'] ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'match_id': matchId, 'player_id': playerId, 'attended': attended ? 1 : 0, 'paid': paid ? 1 : 0};
  }

  MatchPlayer copyWith({int? id, int? matchId, String? playerId, bool? attended, bool? paid}) {
    return MatchPlayer(id: id ?? this.id, matchId: matchId ?? this.matchId, playerId: playerId ?? this.playerId, attended: attended ?? this.attended, paid: paid ?? this.paid);
  }
}
