import 'package:game_setter/core/db/database_service.dart';
import 'package:game_setter/features/courts/domain/entities/court.dart';
import 'package:game_setter/features/matches/domain/entities/match.dart';
import 'package:game_setter/features/matches/domain/entities/match_player.dart';
import 'package:game_setter/features/players/domain/entities/player.dart';

class MatchRepository {
  /// Inserta SOLO el partido, sin jugador
  Future<int> insertMatch(Match match) async {
    final db = await DatabaseService.instance.database;
    final id = await db.insert("matches", match.toMap());
    return id; // Devuelve el ID correcto generado por SQLite
  }

  /// Actualiza SOLO los datos básicos del partido
  Future<void> updateMatch(Match match) async {
    final db = await DatabaseService.instance.database;
    await db.update("matches", match.toMap(), where: "id = ?", whereArgs: [match.id]);
  }

  /// Inserta jugador para un partido (puede tener varios)
  Future<void> assignPlayerToMatch(int matchId, MatchPlayer mp) async {
    final db = await DatabaseService.instance.database;
    await db.insert("match_players", {'match_id': matchId, 'player_id': mp.playerId, 'attended': mp.attended ? 1 : 0, 'paid': mp.paid ? 1 : 0});
  }

  /// Elimina todas las asignaciones de jugadores del partido
  Future<void> clearMatchPlayers(int matchId) async {
    final db = await DatabaseService.instance.database;
    await db.delete("match_players", where: "match_id = ?", whereArgs: [matchId]);
  }

  /// Elimina un partido (incluye participantes)
  Future<void> deleteMatch(int matchId) async {
    final db = await DatabaseService.instance.database;

    await db.delete("match_players", where: "match_id = ?", whereArgs: [matchId]);
    await db.delete("matches", where: "id = ?", whereArgs: [matchId]);
  }

  /// Obtiene todos los partidos
  Future<List<Match>> getAllMatches() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query("matches");

    return result.map((e) => Match.fromMap(e)).toList();
  }

  /// Obtiene todos los partidos con deporte, cancha y jugadores
  Future<List<Match>> getAllMatchesDetailed() async {
    final db = await DatabaseService.instance.database;

    // 1) Traer partidos con NOMBRE del deporte y NOMBRE de la cancha
    final result = await db.rawQuery('''
      SELECT m.*, s.name AS sport_name, c.name AS court_name
      FROM matches m
      INNER JOIN sports s ON m.sport_id = s.id
      LEFT JOIN courts c ON m.court_id = c.id
      ORDER BY m.date DESC, m.time DESC
    ''');

    // 2) Traer todos los players relacionados, indexados por matchId
    final mpRows = await db.rawQuery('SELECT * FROM match_players');

    final Map<int, List<MatchPlayer>> playersByMatch = {};

    for (final row in mpRows) {
      final mp = MatchPlayer.fromMap(row);
      playersByMatch.putIfAbsent(mp.matchId, () => []);
      playersByMatch[mp.matchId]!.add(mp);
    }

    // 3) Ensamblar cada match con su lista de players
    return result.map((e) {
      final matchId = e['id'] as int;
      final players = playersByMatch[matchId] ?? [];

      return Match.fromMap(e, players: players);
    }).toList();
  }

  /// Obtiene estadísticas usadas por MatchCard (confirmados, pagados)
  Future<Map<String, dynamic>> getMatchStatistics(int matchId) async {
    final db = await DatabaseService.instance.database;

    final result = await db.rawQuery(
      '''
        SELECT 
          SUM(CASE WHEN attended = 1 THEN 1 ELSE 0 END) AS attended,
          SUM(CASE WHEN paid = 1 THEN 1 ELSE 0 END) AS paid
        FROM match_players
        WHERE match_id = ?
      ''',
      [matchId],
    );

    return result.isNotEmpty ? result.first : {};
  }

  /// Lista jugadores asignados a un partido (join para detalle)
  Future<List<MatchPlayer>> getMatchPlayersDetailed(int matchId) async {
    final db = await DatabaseService.instance.database;

    final result = await db.rawQuery(
      '''
        SELECT mp.id, mp.match_id, mp.player_id, mp.attended, mp.paid, p.name, p.phone
        FROM match_players mp LEFT JOIN players p ON mp.player_id = p.id
        WHERE mp.match_id = ?
      ''',
      [matchId],
    );

    return result.map((map) {
      final player = map['name'] != null ? Player(id: map['player_id'] as int, name: map['name'] as String, phone: map['phone'] as String?) : null;

      return MatchPlayer.fromMap(map, player: player);
    }).toList();
  }

  /// Obtiene el Court asociado a un Match, puede ser null
  Future<Court?> getCourt(int? courtId) async {
    if (courtId == null) return null;
    final db = await DatabaseService.instance.database;
    final result = await db.query('courts', where: 'id = ?', whereArgs: [courtId], limit: 1);

    if (result.isEmpty) return null;
    return Court.fromMap(result.first);
  }
}
