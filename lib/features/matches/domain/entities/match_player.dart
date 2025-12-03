import 'package:game_setter/features/players/domain/entities/player.dart';

class MatchPlayer {
  final int id;
  final int matchId;
  final int playerId;
  final bool attended;
  final bool paid;
  final Player? player;

  MatchPlayer({required this.id, required this.matchId, required this.playerId, this.attended = false, this.paid = false, this.player});

  factory MatchPlayer.fromMap(Map<String, dynamic> map, {Player? player}) {
    return MatchPlayer(
      id: map['id'] as int,
      matchId: map['match_id'] as int,
      playerId: map['player_id'] as int,
      attended: (map['attended'] ?? 0) == 1,
      paid: (map['paid'] ?? 0) == 1,
      player: player,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'match_id': matchId, 'player_id': playerId, 'attended': attended ? 1 : 0, 'paid': paid ? 1 : 0};
  }

  MatchPlayer copyWith({int? id, int? matchId, int? playerId, bool? attended, bool? paid, Player? player}) {
    return MatchPlayer(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      playerId: playerId ?? this.playerId,
      attended: attended ?? this.attended,
      paid: paid ?? this.paid,
      player: player ?? this.player,
    );
  }
}
