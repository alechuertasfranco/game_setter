import 'package:game_setter/core/db/database_service.dart';
import 'package:game_setter/features/courts/domain/entities/court.dart';

class CourtRepository {
  /// Inserta una nueva cancha
  Future<int> insertCourt(Court court) async {
    final db = await DatabaseService.instance.database;
    return await db.insert("courts", court.toMap());
  }

  /// Actualiza una cancha existente
  Future<void> updateCourt(Court court) async {
    final db = await DatabaseService.instance.database;
    await db.update("courts", court.toMap(), where: "id = ?", whereArgs: [court.id]);
  }

  Future<void> updateCourtPosition(int courtId, int position) async {
    final db = await DatabaseService.instance.database;
    await db.update('courts', {'position': position}, where: 'id = ?', whereArgs: [courtId]);
  }

  /// Elimina una cancha por ID
  Future<void> deleteCourt(int courtId) async {
    final db = await DatabaseService.instance.database;
    await db.delete("courts", where: "id = ?", whereArgs: [courtId]);
  }

  /// Obtiene todas las canchas
  Future<List<Court>> getAllCourts() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query("courts", orderBy: 'position ASC, name ASC');
    return result.map((e) => Court.fromMap(e)).toList();
  }

  /// Obtiene una cancha por ID
  Future<Court?> getCourtById(int id) async {
    final db = await DatabaseService.instance.database;
    final result = await db.query("courts", where: "id = ?", whereArgs: [id], limit: 1);
    if (result.isNotEmpty) return Court.fromMap(result.first);
    return null;
  }
}
