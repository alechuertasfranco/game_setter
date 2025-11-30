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

  /// Asigna un deporte (y opcionalmente posición) a un jugador EXISTENTE
  Future<void> assignSportToPlayer(String playerId, int sportId, int? positionId) async {
    final db = await DatabaseService.instance.database;

    // Insertar deporte asignado
    await db.insert("player_sports", {'player_id': playerId, 'sport_id': sportId, 'position_id': positionId});
  }

  /// Obtiene todos los jugadores
  Future<List<Player>> getAllPlayers() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('players');
    return result.map((e) => Player.fromMap(e)).toList();
  }

  /// Devuelve deporte/posición asignados (si existen)
  Future<Map<String, dynamic>?> getPlayerSport(String playerId) async {
    final db = await DatabaseService.instance.database;

    final result = await db.query("player_sports", where: "player_id = ?", whereArgs: [playerId], limit: 1);

    if (result.isEmpty) return null;

    return result.first;
  }

  /// Actualizar jugador y su deporte (opcional)
  Future<void> updatePlayer(Player p, int? sportId, int? positionId) async {
    final db = await DatabaseService.instance.database;

    // Actualizar datos básicos
    await db.update("players", p.toMap(), where: "id = ?", whereArgs: [p.id]);

    final existing = await getPlayerSport(p.id);

    if (sportId == null) {
      // Si ya tenía un deporte se elimina
      if (existing != null) {
        await db.delete("player_sports", where: "player_id = ?", whereArgs: [p.id]);
      }
      return; // No hay deporte que asignar
    }

    // Si quiere deporte y ya tenía uno → actualizar
    if (existing != null) {
      await db.update("player_sports", {'sport_id': sportId, 'position_id': positionId}, where: "player_id = ?", whereArgs: [p.id]);
    } else {
      // Si quiere deporte y no tenía uno → insertar
      await db.insert("player_sports", {'player_id': p.id, 'sport_id': sportId, 'position_id': positionId});
    }
  }

  /// Lista deportes
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
}
