import 'package:game_setter/features/match_teams/domain/entities/match_team.dart';
import 'package:game_setter/features/players/domain/entities/player.dart';

class MatchSet {
  final int id;
  final int matchId;
  final int setNumber;
  final int team1Id;
  final int team2Id;
  final int team1Score;
  final int team2Score;
  final int? winnerTeamId;
  final int? decisivePlayerId;
  final bool finished;

  // Nuevos campos opcionales
  final MatchTeam? team1;
  final MatchTeam? team2;
  final Player? decisivePlayer;
  final MatchTeam? winnerTeam;

  MatchSet({
    required this.id,
    required this.matchId,
    required this.setNumber,
    required this.team1Id,
    required this.team2Id,
    required this.team1Score,
    required this.team2Score,
    this.winnerTeamId,
    this.decisivePlayerId,
    required this.finished,
    this.team1,
    this.team2,
    this.decisivePlayer,
    this.winnerTeam,
  });

  // Convertir de Map (SQLite) a MatchSet
  factory MatchSet.fromMap(Map<String, dynamic> map) {
    return MatchSet(
      id: map['id'] as int,
      matchId: map['match_id'] as int,
      setNumber: map['set_number'] as int,
      team1Id: map['team1_id'] as int,
      team2Id: map['team2_id'] as int,
      team1Score: map['team1_score'] as int,
      team2Score: map['team2_score'] as int,
      winnerTeamId: map['winner_team_id'] as int?,
      decisivePlayerId: map['decisive_player_id'] as int?,
      finished: (map['finished'] as int) == 1,
    );
  }

  // Convertir de MatchSet a Map (para guardar en SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'match_id': matchId,
      'set_number': setNumber,
      'team1_id': team1Id,
      'team2_id': team2Id,
      'team1_score': team1Score,
      'team2_score': team2Score,
      'winner_team_id': winnerTeamId,
      'decisive_player_id': decisivePlayerId,
      'finished': finished ? 1 : 0,
    };
  }

  MatchSet copyWith({
    int? id,
    int? matchId,
    int? setNumber,
    int? team1Id,
    int? team2Id,
    int? team1Score,
    int? team2Score,
    int? winnerTeamId,
    int? decisivePlayerId,
    bool? finished,
    MatchTeam? team1,
    MatchTeam? team2,
    Player? decisivePlayer,
    MatchTeam? winnerTeam,
  }) {
    return MatchSet(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      setNumber: setNumber ?? this.setNumber,
      team1Id: team1Id ?? this.team1Id,
      team2Id: team2Id ?? this.team2Id,
      team1Score: team1Score ?? this.team1Score,
      team2Score: team2Score ?? this.team2Score,
      winnerTeamId: winnerTeamId ?? this.winnerTeamId,
      decisivePlayerId: decisivePlayerId ?? this.decisivePlayerId,
      finished: finished ?? this.finished,
      team1: team1 ?? this.team1,
      team2: team2 ?? this.team2,
      decisivePlayer: decisivePlayer ?? this.decisivePlayer,
      winnerTeam: winnerTeam ?? this.winnerTeam,
    );
  }
}
