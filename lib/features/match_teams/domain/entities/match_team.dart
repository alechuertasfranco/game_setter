import 'match_team_player.dart';

class MatchTeam {
  final int? id;
  final int matchId;
  final String name;
  final List<MatchTeamPlayer> players;

  MatchTeam({this.id, required this.matchId, required this.name, this.players = const []});

  Map<String, dynamic> toMap() {
    return {'id': id, 'match_id': matchId, 'name': name};
  }

  factory MatchTeam.fromMap(Map<String, dynamic> map, {List<MatchTeamPlayer> players = const []}) {
    return MatchTeam(id: map['id'] as int?, matchId: map['match_id'] as int, name: map['name'] as String, players: players);
  }

  MatchTeam copyWith({int? id, int? matchId, String? name, List<MatchTeamPlayer>? players}) {
    return MatchTeam(id: id ?? this.id, matchId: matchId ?? this.matchId, name: name ?? this.name, players: players ?? this.players);
  }
}
