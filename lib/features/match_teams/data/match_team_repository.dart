import 'package:game_setter/core/db/database_service.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team_player.dart';

class MatchTeamRepository {
  final db = DatabaseService.instance;

  /// Crear equipo, devuelve teamId
  Future<int> addTeam(MatchTeam team) async {
    final database = await db.database;
    return await database.insert('match_teams', team.toMap());
  }

  /// Actualizar equipo
  Future<void> updateTeam(MatchTeam team) async {
    final database = await db.database;
    await database.update("match_teams", team.toMap(), where: "id = ?", whereArgs: [team.id]);
  }

  /// Eliminar equipo
  Future<void> deleteTeam(int teamId) async {
    final database = await db.database;
    await database.delete("match_team_players", where: "team_id = ?", whereArgs: [teamId]);
    await database.delete("match_teams", where: "id = ?", whereArgs: [teamId]);
  }

  /// Obtiene los equipos de un match
  Future<List<MatchTeam>> getTeamsByMatch(int matchId) async {
    final database = await db.database;

    final teamMaps = await database.query('match_teams', where: 'match_id = ?', whereArgs: [matchId]);
    final List<MatchTeam> teams = [];

    for (final t in teamMaps) {
      final players = await getPlayersByTeam(t['id'] as int);
      teams.add(MatchTeam.fromMap(t, players: players));
    }

    return teams;
  }

  /// Limpia la tabla match_team_players para ese equipo
  Future<void> clearTeamPlayers(int teamId) async {
    final database = await db.database;
    await database.delete('match_team_players', where: 'team_id = ?', whereArgs: [teamId]);
  }

  /// Agregar jugador a un equipo
  Future<void> addPlayerToTeam(int teamId, MatchTeamPlayer player) async {
    final database = await db.database;
    await database.insert('match_team_players', player.copyWith(teamId: teamId).toMap());
  }

  /// Obtener jugadores de un equipo
  Future<List<MatchTeamPlayer>> getPlayersByTeam(int teamId) async {
    final database = await db.database;
    final maps = await database.query('match_team_players', where: 'team_id = ?', whereArgs: [teamId]);
    return maps.map((m) => MatchTeamPlayer.fromMap(m)).toList();
  }
}
