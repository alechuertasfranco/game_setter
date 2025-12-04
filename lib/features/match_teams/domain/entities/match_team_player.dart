import 'package:game_setter/features/players/domain/entities/player.dart';
import 'package:game_setter/features/sports/domain/entities/position.dart';

class MatchTeamPlayer {
  final int? id;
  final int teamId;
  final int playerId;
  final Player? player;
  final int? positionId;
  final Position? position;
  final int slot;

  MatchTeamPlayer({this.id, required this.teamId, required this.playerId, this.player, this.positionId, this.position, this.slot = 1});

  Map<String, dynamic> toMap() {
    return {'id': id, 'team_id': teamId, 'player_id': playerId, 'position_id': positionId, 'slot': slot};
  }

  factory MatchTeamPlayer.fromMap(Map<String, dynamic> map) {
    return MatchTeamPlayer(
      id: map['id'] as int?,
      teamId: map['team_id'] as int,
      playerId: map['player_id'] as int,
      player: map['player'] as Player?,
      positionId: map['position_id'] as int?,
      position: map['position'] as Position?,
      slot: map['slot'] as int? ?? 1,
    );
  }

  MatchTeamPlayer copyWith({int? id, int? teamId, int? playerId, Player? player, int? positionId, Position? position, int? slot}) {
    return MatchTeamPlayer(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      playerId: playerId ?? this.playerId,
      player: player ?? this.player,
      positionId: positionId ?? this.positionId,
      position: position ?? this.position,
      slot: slot ?? this.slot,
    );
  }
}
