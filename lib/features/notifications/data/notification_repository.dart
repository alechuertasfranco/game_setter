import 'package:game_setter/core/db/database_service.dart';

class NotificationRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  /// Inserta una nueva notificación
  Future<int> insertNotification({int? matchId, int? playerId, int? courtId, required String type, required String message, String? timestamp}) async {
    final db = await _dbService.database;

    final now = timestamp ?? DateTime.now().toIso8601String();

    final id = await db.insert('notifications', {'match_id': matchId, 'player_id': playerId, 'court_id': courtId, 'type': type, 'message': message, 'timestamp': now});

    return id;
  }

  /// Obtiene todas las notificaciones
  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    final db = await _dbService.database;
    return db.query('notifications', orderBy: 'timestamp DESC');
  }

  /// Obtiene notificaciones por partido
  Future<List<Map<String, dynamic>>> getNotificationsByMatch(int matchId) async {
    final db = await _dbService.database;
    return db.query('notifications', where: 'match_id = ?', whereArgs: [matchId], orderBy: 'timestamp DESC');
  }

  /// Obtiene notificaciones por jugador
  Future<List<Map<String, dynamic>>> getNotificationsByPlayer(int playerId) async {
    final db = await _dbService.database;
    return db.query('notifications', where: 'player_id = ?', whereArgs: [playerId], orderBy: 'timestamp DESC');
  }

  /// Obtiene notificaciones por cancha
  Future<List<Map<String, dynamic>>> getNotificationsByCourt(int courtId) async {
    final db = await _dbService.database;
    return db.query('notifications', where: 'court_id = ?', whereArgs: [courtId], orderBy: 'timestamp DESC');
  }

  /// Borra notificación
  Future<int> deleteNotification(int id) async {
    final db = await _dbService.database;
    return db.delete('notifications', where: 'id = ?', whereArgs: [id]);
  }

  /// Borra todas las notificaciones
  Future<int> clearNotifications() async {
    final db = await _dbService.database;
    return db.delete('notifications');
  }
}
