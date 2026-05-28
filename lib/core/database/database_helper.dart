import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'tables.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  Database? _database;
  final bool _isTesting;

  DatabaseHelper._() : _isTesting = false;
  DatabaseHelper.forTesting() : _isTesting = true;

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (_isTesting) {
      return openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: _onCreate,
      );
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'zoomview.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(Tables.bookmarkFolders);
    await db.execute(Tables.bookmarks);
    await db.execute(Tables.downloads);
    await db.execute(Tables.history);
    await db.execute(Tables.settings);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
