import 'package:game_setter/core/db/database_service.dart';
import '../domain/entities/sport.dart';

class SportRepository {
  final db = DatabaseService.instance;

  Future<List<Sport>> getSports() async {
    final database = await db.database;
    final result = await database.query('sports');
    return result.map((e) => Sport.fromMap(e)).toList();
  }
}
