import 'package:game_setter/features/players/domain/entities/player.dart';
import 'package:game_setter/features/sports/domain/entities/position.dart';

class MatchPlayer {
  final int id;
  final int matchId;
  final Match? match;
  final int playerId;
  final Player? player;
  final bool attended;
  final bool paid;
  final List<Position> positions;

  MatchPlayer({required this.id, required this.matchId, this.match, required this.playerId, this.attended = false, this.paid = false, this.player, this.positions = const []});

  factory MatchPlayer.fromMap(Map<String, dynamic> map, {Match? match, Player? player, List<Position>? positions}) {
    return MatchPlayer(
      id: map['id'] as int,
      matchId: map['match_id'] as int,
      match: match,
      playerId: map['player_id'] as int,
      player: player,
      attended: (map['attended'] ?? 0) == 1,
      paid: (map['paid'] ?? 0) == 1,
      positions: positions ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'match_id': matchId, 'player_id': playerId, 'attended': attended ? 1 : 0, 'paid': paid ? 1 : 0};
  }

  MatchPlayer copyWith({int? id, int? matchId, Match? match, int? playerId, Player? player, bool? attended, bool? paid, List<Position>? positions}) {
    return MatchPlayer(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      match: match ?? this.match,
      playerId: playerId ?? this.playerId,
      player: player ?? this.player,
      attended: attended ?? this.attended,
      paid: paid ?? this.paid,
      positions: positions ?? this.positions,
    );
  }
}
