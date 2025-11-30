import 'package:game_setter/core/db/database_service.dart';
import 'package:game_setter/features/players/domain/entities/player_sport.dart';

class PlayerSportRepository {
  final db = DatabaseService.instance;

  Future<void> addPlayerToSport(String playerId, int sportId, {int? positionId}) async {
    final database = await db.database;

    await database.insert('player_sports', {'player_id': playerId, 'sport_id': sportId, 'position_id': positionId});
  }

  Future<List<PlayerSport>> getByPlayer(String playerId) async {
    final database = await db.database;

    final result = await database.query('player_sports', where: 'player_id = ?', whereArgs: [playerId]);

    return result.map((e) => PlayerSport.fromMap(e)).toList();
  }

  Future<List<PlayerSport>> getBySport(int sportId) async {
    final database = await db.database;

    final result = await database.query('player_sports', where: 'sport_id = ?', whereArgs: [sportId]);

    return result.map((e) => PlayerSport.fromMap(e)).toList();
  }
}
