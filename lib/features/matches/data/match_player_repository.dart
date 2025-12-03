import 'package:game_setter/core/db/database_service.dart';
import 'package:game_setter/features/matches/domain/entities/match_player.dart';

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
