import 'package:game_setter/features/sports/domain/entities/position.dart';

class MatchTeamPlayer {
  final int? id;
  final int teamId;
  final int playerId;
  final int? positionId;
  final Position? position;

  MatchTeamPlayer({this.id, required this.teamId, required this.playerId, this.positionId, this.position});

  Map<String, dynamic> toMap() {
    return {'id': id, 'team_id': teamId, 'player_id': playerId, 'position_id': positionId};
  }

  factory MatchTeamPlayer.fromMap(Map<String, dynamic> map) {
    return MatchTeamPlayer(
      id: map['id'] as int?,
      teamId: map['team_id'] as int,
      playerId: map['player_id'] as int,
      positionId: map['position_id'] as int?,
      position: map['position'] as Position?,
    );
  }

  MatchTeamPlayer copyWith({int? id, int? teamId, int? playerId, int? positionId, Position? position}) {
    return MatchTeamPlayer(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      playerId: playerId ?? this.playerId,
      positionId: positionId ?? this.positionId,
      position: position ?? this.position,
    );
  }
}
