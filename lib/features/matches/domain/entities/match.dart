import 'match_player.dart';

class Match {
  final int id;
  final int sportId;
  final int? courtId;
  final String? date;
  final String? time;
  final String? sportName;
  final String? courtName;
  final List<MatchPlayer> players;

  Match({required this.id, required this.sportId, this.courtId, this.date, this.time, this.sportName, this.courtName, this.players = const []});

  factory Match.fromMap(Map<String, dynamic> map, {List<MatchPlayer> players = const []}) {
    return Match(
      id: map['id'] as int,
      sportId: map['sport_id'] as int,
      courtId: map['court_id'] as int?,
      date: map['date'] as String?,
      time: map['time'] as String?,
      sportName: map['sport_name'] as String?,
      courtName: map['court_name'] as String?,
      players: players,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'sport_id': sportId, 'court_id': courtId, 'date': date, 'time': time};
  }

  Match copyWith({int? id, int? sportId, int? courtId, String? date, String? time, String? sportName, String? courtName, List<MatchPlayer>? players}) {
    return Match(
      id: id ?? this.id,
      sportId: sportId ?? this.sportId,
      courtId: courtId ?? this.courtId,
      date: date ?? this.date,
      time: time ?? this.time,
      sportName: sportName ?? this.sportName,
      courtName: courtName ?? this.courtName,
      players: players ?? this.players,
    );
  }
}
