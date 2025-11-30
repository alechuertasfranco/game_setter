import 'package:game_setter/core/db/database_service.dart';
import '../domain/entities/position.dart';

class PositionRepository {
  final db = DatabaseService.instance;

  Future<List<Position>> getBySport(int sportId) async {
    final database = await db.database;

    final result = await database.query('positions', where: 'sport_id = ?', whereArgs: [sportId]);

    return result.map((e) => Position.fromMap(e)).toList();
  }
}
