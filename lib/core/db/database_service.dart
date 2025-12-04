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
      version: 6, // NUEVA VERSIÓN
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
        FOREIGN KEY(sport_id) REFERENCES sports(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE player_sports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER NOT NULL,
        sport_id INTEGER NOT NULL,
        position_id INTEGER,
        FOREIGN KEY(player_id) REFERENCES players(id),
        FOREIGN KEY(sport_id) REFERENCES sports(id),
        FOREIGN KEY(position_id) REFERENCES positions(id)
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
        FOREIGN KEY(sport_id) REFERENCES sports(id),
        FOREIGN KEY(court_id) REFERENCES courts(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE match_players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        match_id INTEGER NOT NULL,
        player_id INTEGER NOT NULL,
        attended INTEGER DEFAULT 0,
        paid INTEGER DEFAULT 0,
        FOREIGN KEY(match_id) REFERENCES matches(id),
        FOREIGN KEY(player_id) REFERENCES players(id)
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
        FOREIGN KEY(match_id) REFERENCES matches(id),
        FOREIGN KEY(player_id) REFERENCES players(id),
        FOREIGN KEY(court_id) REFERENCES courts(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE match_teams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        match_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        FOREIGN KEY(match_id) REFERENCES matches(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE match_team_players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        team_id INTEGER NOT NULL,
        player_id INTEGER NOT NULL,
        position_id INTEGER,
        FOREIGN KEY(team_id) REFERENCES match_teams(id),
        FOREIGN KEY(player_id) REFERENCES players(id),
        FOREIGN KEY(position_id) REFERENCES positions(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE match_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        match_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        team1_score INTEGER DEFAULT 0,
        team2_score INTEGER DEFAULT 0,
        finished INTEGER DEFAULT 0,
        FOREIGN KEY(match_id) REFERENCES matches(id)
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

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Aquí se podrían agregar migraciones futuras si la versión cambia
  }
}
