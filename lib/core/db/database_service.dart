import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('game_setter.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7, // v7: match_teams.formation
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // --- TABLAS EXISTENTES ---
    await db.execute('''
    CREATE TABLE sports (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL
    );
  ''');

    await db.execute('''
    CREATE TABLE players (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT,
      position INTEGER DEFAULT 0
    );
  ''');

    await db.execute('''
    CREATE TABLE positions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sport_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      short_name TEXT NOT NULL,
      FOREIGN KEY(sport_id) REFERENCES sports(id) ON DELETE CASCADE
    );
  ''');

    await db.execute('''
    CREATE TABLE player_sports (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      player_id INTEGER NOT NULL,
      sport_id INTEGER NOT NULL,
      position_id INTEGER,
      FOREIGN KEY(player_id) REFERENCES players(id) ON DELETE CASCADE,
      FOREIGN KEY(sport_id) REFERENCES sports(id) ON DELETE CASCADE,
      FOREIGN KEY(position_id) REFERENCES positions(id) ON DELETE SET NULL
    );
  ''');

    await db.execute('''
    CREATE TABLE courts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT,
      location TEXT,
      hourly_rate REAL,
      position INTEGER DEFAULT 0
    );
  ''');

    await db.execute('''
    CREATE TABLE matches (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sport_id INTEGER NOT NULL,
      court_id INTEGER,
      date TEXT,
      time TEXT,
      FOREIGN KEY(sport_id) REFERENCES sports(id) ON DELETE CASCADE,
      FOREIGN KEY(court_id) REFERENCES courts(id) ON DELETE SET NULL
    );
  ''');

    await db.execute('''
    CREATE TABLE match_players (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      match_id INTEGER NOT NULL,
      player_id INTEGER NOT NULL,
      attended INTEGER DEFAULT 0,
      paid INTEGER DEFAULT 0,
      FOREIGN KEY(match_id) REFERENCES matches(id) ON DELETE CASCADE,
      FOREIGN KEY(player_id) REFERENCES players(id) ON DELETE CASCADE
    );
  ''');

    await db.execute('''
    CREATE TABLE notifications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      match_id INTEGER,
      player_id INTEGER,
      court_id INTEGER,
      type TEXT NOT NULL,
      message TEXT NOT NULL,
      timestamp TEXT NOT NULL,
      FOREIGN KEY(match_id) REFERENCES matches(id) ON DELETE CASCADE,
      FOREIGN KEY(player_id) REFERENCES players(id) ON DELETE CASCADE,
      FOREIGN KEY(court_id) REFERENCES courts(id) ON DELETE SET NULL
    );
  ''');

    await db.execute('''
    CREATE TABLE match_teams (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      match_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      formation TEXT,
      FOREIGN KEY(match_id) REFERENCES matches(id) ON DELETE CASCADE
    );
  ''');

    await db.execute('''
    CREATE TABLE match_team_players (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      team_id INTEGER NOT NULL,
      player_id INTEGER NOT NULL,
      position_id INTEGER,
      slot INTEGER DEFAULT 1,
      FOREIGN KEY(team_id) REFERENCES match_teams(id) ON DELETE CASCADE,
      FOREIGN KEY(player_id) REFERENCES players(id) ON DELETE CASCADE,
      FOREIGN KEY(position_id) REFERENCES positions(id) ON DELETE SET NULL
    );
  ''');

    await db.execute('''
    CREATE TABLE match_sets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      match_id INTEGER NOT NULL,
      set_number INTEGER NOT NULL,
      team1_id INTEGER NOT NULL,
      team2_id INTEGER NOT NULL,
      team1_score INTEGER DEFAULT 0,
      team2_score INTEGER DEFAULT 0,
      winner_team_id INTEGER,          
      decisive_player_id INTEGER,      
      finished INTEGER DEFAULT 0,
      FOREIGN KEY(match_id) REFERENCES matches(id) ON DELETE CASCADE,
      FOREIGN KEY(team1_id) REFERENCES match_teams(id) ON DELETE CASCADE,
      FOREIGN KEY(team2_id) REFERENCES match_teams(id) ON DELETE CASCADE,
      FOREIGN KEY(winner_team_id) REFERENCES match_teams(id) ON DELETE SET NULL,
      FOREIGN KEY(decisive_player_id) REFERENCES players(id) ON DELETE SET NULL
    );
  ''');

    // --- SEED INICIAL DE DEPORTES ---
    int voleyId = await db.insert('sports', {'name': 'Vóley'});
    int futbolId = await db.insert('sports', {'name': 'Fútbol'});
    int basketId = await db.insert('sports', {'name': 'Básquet'});

    // POSITIONS SEED
    await db.insert('positions', {'sport_id': voleyId, 'name': 'Armador', 'short_name': 'ARM'});
    await db.insert('positions', {'sport_id': voleyId, 'name': 'Opuesto', 'short_name': 'OP'});
    await db.insert('positions', {'sport_id': voleyId, 'name': 'Punta', 'short_name': 'PTA'});
    await db.insert('positions', {'sport_id': voleyId, 'name': 'Central', 'short_name': 'CTR'});
    await db.insert('positions', {'sport_id': voleyId, 'name': 'Libero', 'short_name': 'LIB'});

    await db.insert('positions', {'sport_id': futbolId, 'name': 'Arquero', 'short_name': 'GK'});
    await db.insert('positions', {'sport_id': futbolId, 'name': 'Defensa', 'short_name': 'DEF'});
    await db.insert('positions', {'sport_id': futbolId, 'name': 'Mediocampista', 'short_name': 'MID'});
    await db.insert('positions', {'sport_id': futbolId, 'name': 'Delantero', 'short_name': 'DEL'});

    await db.insert('positions', {'sport_id': basketId, 'name': 'Base', 'short_name': 'PG'});
    await db.insert('positions', {'sport_id': basketId, 'name': 'Escolta', 'short_name': 'SG'});
    await db.insert('positions', {'sport_id': basketId, 'name': 'Alero', 'short_name': 'SF'});
    await db.insert('positions', {'sport_id': basketId, 'name': 'Ala-Pívot', 'short_name': 'PF'});
    await db.insert('positions', {'sport_id': basketId, 'name': 'Pívot', 'short_name': 'C'});
  }

  /// Se ejecuta automáticamente la primera vez que se abre una versión nueva
  /// de la app con un número de versión de BD mayor. Nunca borra datos.
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 7) {
      await _addColumnIfMissing(db, 'match_teams', 'formation', 'TEXT');
      await _backfillTeamFormations(db);
    }
  }

  Future<void> _addColumnIfMissing(Database db, String table, String column, String type) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((c) => c['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  /// Completa la formación de los equipos creados antes de la v7.
  /// Vóley: 5-1 si tiene un Opuesto, si no 4-2. Fútbol: se deduce por el slot.
  Future<void> _backfillTeamFormations(Database db) async {
    final teams = await db.rawQuery('''
      SELECT mt.id, m.sport_id,
             MIN(mtp.slot) AS min_slot,
             SUM(CASE WHEN pos.short_name = 'OP' THEN 1 ELSE 0 END) AS op_count
      FROM match_teams mt
      INNER JOIN matches m ON m.id = mt.match_id
      LEFT JOIN match_team_players mtp ON mtp.team_id = mt.id
      LEFT JOIN positions pos ON pos.id = mtp.position_id
      WHERE mt.formation IS NULL
      GROUP BY mt.id, m.sport_id
    ''');

    for (final t in teams) {
      final sportId = t['sport_id'] as int?;
      String? formation;

      if (sportId == 1) {
        formation = ((t['op_count'] as int?) ?? 0) > 0 ? '5-1' : '4-2';
      } else if (sportId == 2) {
        final minSlot = t['min_slot'] as int?;
        if (minSlot != null && minSlot >= 100) {
          formation = _soccerFormationBySlot[(minSlot ~/ 100) * 100];
        }
      }

      if (formation != null) {
        await db.update('match_teams', {'formation': formation}, where: 'id = ?', whereArgs: [t['id']]);
      }
    }
  }

  static const _soccerFormationBySlot = {
    100: '3-1-2',
    200: '3-2-1',
    300: '4-3-3',
    400: '4-2-3-1',
    500: '3-2-3-2',
    600: '3-3-1',
    700: '3-2-2',
    800: '3-2',
    900: '2-3',
    1000: '2-2',
    1100: '3-1',
  };
}
