import 'package:game_setter/core/db/database_service.dart';
import 'package:game_setter/features/sports/domain/entities/position.dart';

class PositionRepository {
  final db = DatabaseService.instance;

  /// Obtiene posiciones por ID de deporte
  Future<List<Position>> getBySport(int sportId) async {
    final database = await db.database;

    final result = await database.query('positions', where: 'sport_id = ?', whereArgs: [sportId]);

    return result.map((e) => Position.fromMap(e)).toList();
  }

  /// Obtiene posiciones según el deporte del partido (CORREGIDO)
  Future<List<Position>> getByMatchId(int matchId) async {
    final database = await db.database;
    final matchResult = await database.query('matches', columns: ['sport_id'], where: 'id = ?', whereArgs: [matchId], limit: 1);
    if (matchResult.isEmpty) {
      return [];
    }

    final sportId = matchResult.first['sport_id'] as int;
    final positionsResult = await database.query('positions', where: 'sport_id = ?', whereArgs: [sportId]);

    return positionsResult.map((e) => Position.fromMap(e)).toList();
  }
}
