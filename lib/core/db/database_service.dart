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

    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE players (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT
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
        player_id TEXT NOT NULL,
        sport_id INTEGER NOT NULL,
        position_id INTEGER,
        FOREIGN KEY(player_id) REFERENCES players(id),
        FOREIGN KEY(sport_id) REFERENCES sports(id),
        FOREIGN KEY(position_id) REFERENCES positions(id)
      );
    ''');

    // Nueva tabla de canchas
    await db.execute('''
      CREATE TABLE courts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        location TEXT,
        hourly_rate REAL
      );
    ''');

    // Seed de deportes iniciales
    int voleyId = await db.insert('sports', {'name': 'Vóley'});
    int futbolId = await db.insert('sports', {'name': 'Fútbol'});
    int basketId = await db.insert('sports', {'name': 'Básquet'});

    // Positions: Vóley
    await db.insert('positions', {'sport_id': voleyId, 'name': 'Armador', 'short_name': 'ARM'});
    await db.insert('positions', {'sport_id': voleyId, 'name': 'Opuesto', 'short_name': 'OP'});
    await db.insert('positions', {'sport_id': voleyId, 'name': 'Punta', 'short_name': 'PTA'});
    await db.insert('positions', {'sport_id': voleyId, 'name': 'Central', 'short_name': 'CTR'});
    await db.insert('positions', {'sport_id': voleyId, 'name': 'Libero', 'short_name': 'LIB'});

    // Positions: Fútbol
    await db.insert('positions', {'sport_id': futbolId, 'name': 'Arquero', 'short_name': 'GK'});
    await db.insert('positions', {'sport_id': futbolId, 'name': 'Defensa', 'short_name': 'DEF'});
    await db.insert('positions', {'sport_id': futbolId, 'name': 'Mediocampista', 'short_name': 'MID'});
    await db.insert('positions', {'sport_id': futbolId, 'name': 'Delantero', 'short_name': 'DEL'});

    // Positions: Básquet
    await db.insert('positions', {'sport_id': basketId, 'name': 'Base', 'short_name': 'PG'});
    await db.insert('positions', {'sport_id': basketId, 'name': 'Escolta', 'short_name': 'SG'});
    await db.insert('positions', {'sport_id': basketId, 'name': 'Alero', 'short_name': 'SF'});
    await db.insert('positions', {'sport_id': basketId, 'name': 'Ala-Pívot', 'short_name': 'PF'});
    await db.insert('positions', {'sport_id': basketId, 'name': 'Pívot', 'short_name': 'C'});
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Migración para agregar canchas
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE courts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT,
          location TEXT,
          hourly_rate REAL
        );
      ''');
    }
  }
}
