import 'package:game_setter/core/db/database_service.dart';
import 'package:game_setter/features/players/domain/entities/player.dart';
import 'package:game_setter/features/sports/domain/entities/sport.dart';
import 'package:game_setter/features/sports/domain/entities/position.dart';

class PlayerRepository {
  /// Inserta SOLO el jugador, sin deporte
  Future<void> insertPlayerOnly(Player p) async {
    final db = await DatabaseService.instance.database;
    await db.insert("players", p.toMap());
  }

  /// Actualiza SOLO los datos básicos del jugador
  Future<void> updatePlayerOnly(Player p) async {
    final db = await DatabaseService.instance.database;
    await db.update("players", p.toMap(), where: "id = ?", whereArgs: [p.id]);
  }

  Future<void> updatePlayerPosition(int playerId, int position) async {
    final db = await DatabaseService.instance.database;
    await db.update('players', {'position': position}, where: 'id = ?', whereArgs: [playerId]);
  }

  /// Inserta deporte/posición para un jugador (puede tener varios)
  Future<void> assignSportToPlayer(int playerId, int sportId, int? positionId) async {
    final db = await DatabaseService.instance.database;
    await db.insert("player_sports", {'player_id': playerId, 'sport_id': sportId, 'position_id': positionId});
  }

  /// Elimina TODAS las asignaciones deporte/posición del jugador
  Future<void> clearPlayerSports(int playerId) async {
    final db = await DatabaseService.instance.database;
    await db.delete("player_sports", where: "player_id = ?", whereArgs: [playerId]);
  }

  /// Obtiene TODOS los deportes/posiciones de un jugador
  Future<List<Map<String, dynamic>>> getPlayerSports(int playerId) async {
    final db = await DatabaseService.instance.database;

    final result = await db.rawQuery(
      '''
        SELECT ps.player_id,
               ps.sport_id,
               ps.position_id,
               s.name AS sport_name,
               p.name AS position_name
        FROM player_sports ps
        LEFT JOIN sports s ON ps.sport_id = s.id
        LEFT JOIN positions p ON ps.position_id = p.id
        WHERE ps.player_id = ?
      ''',
      [playerId],
    );

    return result;
  }

  Future<List<Player>> getAllPlayers() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('players', orderBy: 'position ASC, name ASC');
    return result.map((e) => Player.fromMap(e)).toList();
  }

  /// Lista deportes disponibles
  Future<List<Sport>> getSports() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query("sports");
    return result.map((e) => Sport.fromMap(e)).toList();
  }

  /// Lista posiciones según deporte
  Future<List<Position>> getPositionsBySport(int sportId) async {
    final db = await DatabaseService.instance.database;
    final result = await db.query("positions", where: "sport_id = ?", whereArgs: [sportId]);
    return result.map((e) => Position.fromMap(e)).toList();
  }

  Future<void> deletePlayer(int playerId) async {
    final db = await DatabaseService.instance.database;
    await db.delete("player_sports", where: "player_id = ?", whereArgs: [playerId]);
    await db.delete("players", where: "id = ?", whereArgs: [playerId]);
  }

  /// Obtiene todos los jugadores que practican un deporte
  Future<List<Player>> getPlayersBySport(int sportId) async {
    final db = await DatabaseService.instance.database;

    final result = await db.rawQuery(
      '''
        SELECT pl.*
        FROM players pl
        INNER JOIN player_sports ps ON pl.id = ps.player_id
        WHERE ps.sport_id = ?
        GROUP BY pl.id
        ORDER BY pl.position ASC, pl.name ASC
      ''',
      [sportId],
    );

    return result.map((e) => Player.fromMap(e)).toList();
  }
}
