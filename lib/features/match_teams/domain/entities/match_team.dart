import 'match_team_player.dart';
import 'package:game_setter/features/match_sets/domain/entities/match_set.dart';

class MatchTeam {
  final int? id;
  final int matchId;
  final String name;
  final List<MatchTeamPlayer> players;
  final List<MatchSet> sets;

  MatchTeam({this.id, required this.matchId, required this.name, this.players = const [], this.sets = const []});

  Map<String, dynamic> toMap() {
    return {'id': id, 'match_id': matchId, 'name': name};
  }

  factory MatchTeam.fromMap(Map<String, dynamic> map, {List<MatchTeamPlayer> players = const [], List<MatchSet> sets = const []}) {
    return MatchTeam(id: map['id'] as int?, matchId: map['match_id'] as int, name: map['name'] as String, players: players, sets: sets);
  }

  MatchTeam copyWith({int? id, int? matchId, String? name, List<MatchTeamPlayer>? players, List<MatchSet>? sets}) {
    return MatchTeam(id: id ?? this.id, matchId: matchId ?? this.matchId, name: name ?? this.name, players: players ?? this.players, sets: sets ?? this.sets);
  }
}
