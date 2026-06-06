import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('locomotors_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE api_cache (
          endpoint TEXT PRIMARY KEY,
          response TEXT,
          timestamp TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE print_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          printerIp TEXT,
          bytes TEXT,
          timestamp TEXT
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT,
        price REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE vehicles (
        id TEXT PRIMARY KEY,
        plateNumber TEXT,
        categoryId TEXT,
        isBlacklisted INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        vehicleId TEXT,
        status TEXT,
        checkIn TEXT,
        checkOut TEXT,
        amountDue REAL,
        driverName TEXT,
        driverPhone TEXT,
        driverCompany TEXT,
        isSynced INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        endpoint TEXT,
        method TEXT,
        payload TEXT,
        timestamp TEXT,
        retryCount INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE api_cache (
        endpoint TEXT PRIMARY KEY,
        response TEXT,
        timestamp TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE print_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        printerIp TEXT,
        bytes TEXT,
        timestamp TEXT
      )
    ''');
  }

  Future<void> clearAll() async {
    final db = await instance.database;
    await db.delete('categories');
    await db.delete('vehicles');
    await db.delete('sessions');
    await db.delete('sync_queue');
    await db.delete('api_cache');
    await db.delete('print_queue');
  }
}
