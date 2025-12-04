import 'package:game_setter/core/db/database_service.dart';
import 'package:game_setter/features/matches/domain/entities/match_player.dart';
import 'package:game_setter/features/sports/domain/entities/position.dart';

class MatchPlayerRepository {
  final db = DatabaseService.instance;

  /// Agregar jugador a partido
  Future<void> addPlayerToMatch(String matchId, String playerId, {bool attended = false, bool paid = false}) async {
    final database = await db.database;

    await database.insert("match_players", {"match_id": matchId, "player_id": playerId, "attended": attended ? 1 : 0, "paid": paid ? 1 : 0});
  }

  /// Obtener jugadores por partido
  Future<List<MatchPlayer>> getPlayersByMatch(String matchId) async {
    final database = await db.database;

    final result = await database.query("match_players", where: "match_id = ?", whereArgs: [matchId]);

    return result.map((e) => MatchPlayer.fromMap(e)).toList();
  }

  /// Obtener partidos donde participa un jugador específico
  Future<List<MatchPlayer>> getMatchesByPlayer(String playerId) async {
    final database = await db.database;

    final result = await database.query("match_players", where: "player_id = ?", whereArgs: [playerId]);

    return result.map((e) => MatchPlayer.fromMap(e)).toList();
  }

  /// Obtener posiciones de un jugador para un deporte específico
  Future<List<Position>> getPlayerPositionsForMatch({required int playerId, required int sportId}) async {
    final db = await DatabaseService.instance.database;

    final result = await db.rawQuery(
      '''
        SELECT pos.id, pos.name, pos.short_name
        FROM player_sports ps
        LEFT JOIN positions pos ON ps.position_id = pos.id
        WHERE ps.player_id = ? AND ps.sport_id = ?
      ''',
      [playerId, sportId],
    );

    return result.map((p) => Position(id: p['id'] as int, sportId: sportId, name: p['name'] as String, shortName: p['short_name'] as String)).toList();
  }

  /// Devuelve todos los player_id que pertenecen a algún equipo de un match específico
  Future<List<int>> getPlayersTaken({required int matchId}) async {
    final db = await DatabaseService.instance.database;

    final result = await db.rawQuery(
      '''
        SELECT mtp.player_id
        FROM match_team_players mtp
        INNER JOIN match_teams mt ON mtp.team_id = mt.id
        WHERE mt.match_id = ?
      ''',
      [matchId],
    );

    return result.map<int>((row) => row['player_id'] as int).toList();
  }

  /// Actualizar estado (confirmado, pagado)
  Future<void> updateParticipation(String matchId, String playerId, {bool? attended, bool? paid}) async {
    final database = await db.database;

    final data = <String, dynamic>{};
    if (attended != null) data["attended"] = attended ? 1 : 0;
    if (paid != null) data["paid"] = paid ? 1 : 0;

    await database.update("match_players", data, where: "match_id = ? AND player_id = ?", whereArgs: [matchId, playerId]);
  }

  /// Eliminar a un jugador de un partido
  Future<void> removePlayer(String matchId, String playerId) async {
    final database = await db.database;

    await database.delete("match_players", where: "match_id = ? AND player_id = ?", whereArgs: [matchId, playerId]);
  }
}
