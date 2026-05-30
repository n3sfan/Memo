import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase({
    DatabaseFactory? factory,
    String? databasePath,
  })  : _databaseFactory = factory,
        _databasePath = databasePath;

  final DatabaseFactory? _databaseFactory;
  final String? _databasePath;
  Database? _database;

  Future<Database> get database async {
    final Database? current = _database;
    if (current != null) {
      return current;
    }

    final Database opened = await _openDatabase();
    _database = opened;

    return opened;
  }

  Future<void> close() async {
    final Database? current = _database;
    if (current == null) {
      return;
    }

    await current.close();
    _database = null;
  }

  Future<Database> _openDatabase() async {
    final DatabaseFactory factory = _databaseFactory ?? databaseFactory;
    final String path = _databasePath ?? '${await getDatabasesPath()}/memo.db';

    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createSchema,
      ),
    );
  }

  static Future<void> _createSchema(Database db, int _) async {
    await db.execute('''
CREATE TABLE cached_pins (
  id TEXT PRIMARY KEY,
  client_id TEXT,
  map_id TEXT NOT NULL,
  title TEXT NOT NULL,
  note TEXT,
  memory_date TEXT,
  lat REAL NOT NULL,
  lng REAL NOT NULL,
  media_json TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  synced_at TEXT
)
''');

    await db.execute('''
CREATE TABLE cached_media_meta (
  id TEXT PRIMARY KEY,
  pin_id TEXT NOT NULL,
  media_type TEXT NOT NULL,
  object_key TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  size_bytes INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  url TEXT
)
''');

    await db.execute('''
CREATE TABLE pending_pin_mutations (
  id TEXT PRIMARY KEY,
  client_id TEXT NOT NULL,
  operation TEXT NOT NULL,
  payload_json TEXT NOT NULL,
  created_at TEXT NOT NULL,
  retry_count INTEGER NOT NULL DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE pending_media_uploads (
  id TEXT PRIMARY KEY,
  pin_client_id TEXT NOT NULL,
  local_path TEXT NOT NULL,
  media_type TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  size_bytes INTEGER NOT NULL,
  file_name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  retry_count INTEGER NOT NULL DEFAULT 0
)
''');
  }
}
