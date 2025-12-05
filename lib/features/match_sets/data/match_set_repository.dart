import 'package:game_setter/core/db/database_service.dart';
import 'package:game_setter/features/match_sets/domain/entities/match_set.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team.dart';
import 'package:game_setter/features/players/domain/entities/player.dart';

class MatchSetRepository {
  final db = DatabaseService.instance;

  /// Inserta un set completo en la base de datos y devuelve su id
  Future<int> insertMatchSet(MatchSet matchSet) async {
    final database = await db.database;
    return await database.insert('match_sets', matchSet.toMap()..remove('id'));
  }

  /// Inserta un set vacío (solo para inicializar)
  Future<int> initMatchSet(int matchId, int team1Id, int team2Id) async {
    final database = await db.database;

    final result = await database.rawQuery('SELECT MAX(set_number) as max_set FROM match_sets WHERE match_id = ?', [matchId]);
    final lastSetNumber = (result.isNotEmpty && result[0]['max_set'] != null) ? result[0]['max_set'] as int : 0;

    return await database.insert('match_sets', {
      'match_id': matchId,
      'set_number': lastSetNumber + 1,
      'team1_id': team1Id,
      'team2_id': team2Id,
      'team1_score': 0,
      'team2_score': 0,
      'winner_team_id': null,
      'decisive_player_id': null,
      'finished': 0,
    });
  }

  /// Actualiza un set existente
  Future<int> updateMatchSet(MatchSet matchSet) async {
    final database = await db.database;
    return await database.update('match_sets', matchSet.toMap(), where: 'id = ?', whereArgs: [matchSet.id]);
  }

  /// Buscar un set por su ID
  Future<MatchSet> findSetById(int matchSetId) async {
    final database = await db.database;
    final result = await database.query('match_sets', where: 'id = ?', whereArgs: [matchSetId]);
    if (result.isEmpty) throw Exception('Set no encontrado con id $matchSetId');

    final map = result.first;
    final set = MatchSet.fromMap(map);

    final team1Map = await database.query('match_teams', where: 'id = ?', whereArgs: [set.team1Id]);
    final team2Map = await database.query('match_teams', where: 'id = ?', whereArgs: [set.team2Id]);
    final team1 = team1Map.isNotEmpty ? MatchTeam.fromMap(team1Map.first) : null;
    final team2 = team2Map.isNotEmpty ? MatchTeam.fromMap(team2Map.first) : null;
    final winnerMap = set.winnerTeamId != null ? await database.query('match_teams', where: 'id = ?', whereArgs: [set.winnerTeamId]) : null;
    final winnerTeam = (winnerMap != null && winnerMap.isNotEmpty) ? MatchTeam.fromMap(winnerMap.first) : null;

    Player? decisivePlayer;
    if (set.decisivePlayerId != null) {
      final playerMap = await database.query('players', where: 'id = ?', whereArgs: [set.decisivePlayerId]);
      decisivePlayer = playerMap.isNotEmpty ? Player.fromMap(playerMap.first) : null;
    }

    return set.copyWith(team1: team1, team2: team2, winnerTeam: winnerTeam, decisivePlayer: decisivePlayer);
  }

  Future<List<MatchSet>> getSetsByMatchId(int matchId) async {
    final database = await db.database;
    final setMaps = await database.query('match_sets', where: 'match_id = ?', whereArgs: [matchId], orderBy: 'set_number DESC');
    List<MatchSet> sets = [];

    for (final map in setMaps) {
      final set = MatchSet.fromMap(map);

      final team1Map = await database.query('match_teams', where: 'id = ?', whereArgs: [set.team1Id]);
      final team2Map = await database.query('match_teams', where: 'id = ?', whereArgs: [set.team2Id]);
      final winnerMap = set.winnerTeamId != null ? await database.query('match_teams', where: 'id = ?', whereArgs: [set.winnerTeamId]) : null;

      final team1 = team1Map.isNotEmpty ? MatchTeam.fromMap(team1Map.first) : null;
      final team2 = team2Map.isNotEmpty ? MatchTeam.fromMap(team2Map.first) : null;
      final winnerTeam = (winnerMap != null && winnerMap.isNotEmpty) ? MatchTeam.fromMap(winnerMap.first) : null;

      Player? decisivePlayer;
      if (set.decisivePlayerId != null) {
        final playerMap = await database.query('players', where: 'id = ?', whereArgs: [set.decisivePlayerId]);
        decisivePlayer = playerMap.isNotEmpty ? Player.fromMap(playerMap.first) : null;
      }

      sets.add(set.copyWith(team1: team1, team2: team2, winnerTeam: winnerTeam, decisivePlayer: decisivePlayer));
    }

    return sets;
  }

  Future<void> assignSportToMatchSet(int matchSetId, int sportId, int? positionId) async {
    final database = await db.database;
    await database.insert('match_set_sports', {'match_set_id': matchSetId, 'sport_id': sportId, 'position_id': positionId});
  }

  Future<void> deleteMatchSet(int matchSetId) async {
    final database = await db.database;
    await database.delete('match_sets', where: 'id = ?', whereArgs: [matchSetId]);
  }
}
