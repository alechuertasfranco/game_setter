import 'package:game_setter/core/db/database_service.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team.dart';
import 'package:game_setter/features/match_teams/domain/entities/match_team_player.dart';
import 'package:game_setter/features/players/domain/entities/player.dart';
import 'package:game_setter/features/sports/domain/entities/position.dart';

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

  /// Obtener todos los jugadores de un equipo
  Future<List<MatchTeamPlayer>> getPlayersByTeam(int teamId) async {
    final database = await db.database;

    final playerMaps = await database.rawQuery(
      '''
        SELECT mtp.id AS mtp_id, mtp.team_id, mtp.player_id, mtp.position_id, mtp.slot,
              p.name AS player_name, p.phone AS player_phone,
              pos.name AS position_name, pos.short_name AS position_short_name, pos.sport_id AS position_sport_id
        FROM match_team_players mtp
        INNER JOIN players p ON p.id = mtp.player_id
        LEFT JOIN positions pos ON pos.id = mtp.position_id
        WHERE mtp.team_id = ?
        ORDER BY mtp.slot
      ''',
      [teamId],
    );

    return playerMaps.map((m) => _buildMatchTeamPlayer(m)).toList();
  }

  /// MÉTODO UNIFICADO: Obtener equipos con sus jugadores y sets en UNA sola operación
  Future<MatchTeamsWithPlayers> getTeamsWithPlayersByMatch(int matchId) async {
    final database = await db.database;
    await Future.delayed(const Duration(milliseconds: 350));

    // 1. Obtener equipos
    final teamMaps = await database.query('match_teams', where: 'match_id = ?', whereArgs: [matchId]);

    // 2. Obtener todos los jugadores de todos los equipos
    final playerMaps = await database.rawQuery(
      '''
      SELECT mtp.id AS mtp_id, mtp.team_id, mtp.player_id, mtp.position_id, mtp.slot,
             p.name AS player_name, p.phone AS player_phone,
             pos.name AS position_name, pos.short_name AS position_short_name, pos.sport_id AS position_sport_id
      FROM match_team_players mtp
      INNER JOIN match_teams mt ON mt.id = mtp.team_id
      INNER JOIN players p ON p.id = mtp.player_id
      LEFT JOIN positions pos ON pos.id = mtp.position_id
      WHERE mt.match_id = ?
      ORDER BY mtp.team_id, mtp.slot
    ''',
      [matchId],
    );

    final Map<int, List<MatchTeamPlayer>> playersGrouped = {};
    for (final m in playerMaps) {
      final teamId = m['team_id'] as int;
      final player = _buildMatchTeamPlayer(m);
      playersGrouped.putIfAbsent(teamId, () => []).add(player);
    }

    // 4. Crear equipos con sus jugadores
    final teams = teamMaps.map((t) {
      final teamId = t['id'] as int;
      final players = playersGrouped[teamId] ?? [];
      return MatchTeam.fromMap(t, players: players);
    }).toList();

    return MatchTeamsWithPlayers(teams: teams, playersGrouped: playersGrouped);
  }

  /// Construir jugadores de equipo
  MatchTeamPlayer _buildMatchTeamPlayer(Map<String, dynamic> m) {
    final playerId = m['player_id'] as int?;
    final playerName = m['player_name'] as String?;
    final positionId = m['position_id'] as int?;

    return MatchTeamPlayer(
      id: m['mtp_id'] as int?,
      teamId: m['team_id'] as int,
      playerId: playerId ?? 0,
      player: playerName != null ? Player(id: playerId, name: playerName, phone: m['player_phone'] as String?) : null,
      positionId: positionId,
      slot: (m['slot'] as int?) ?? 1,
      position: positionId != null
          ? Position(id: positionId, sportId: m['position_sport_id'] as int, name: (m['position_name'] as String?) ?? '', shortName: (m['position_short_name'] as String?) ?? '')
          : null,
    );
  }
}

/// Clase para retornar equipos, jugadores y sets (general)
class MatchTeamsWithPlayers {
  final List<MatchTeam> teams;
  final Map<int, List<MatchTeamPlayer>> playersGrouped;

  MatchTeamsWithPlayers({required this.teams, required this.playersGrouped});
}
