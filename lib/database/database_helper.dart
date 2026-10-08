import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;

  Future<Database> get database async => _db ??= await _init();

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'ekrili_karhba.db');
    return openDatabase(path, version: 1, onCreate: (db, version) async {
      // --- Module 3: Reservations ---
      await db.execute('''
        CREATE TABLE reservations(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          vehicle_id INTEGER NOT NULL,
          start_date TEXT NOT NULL,
          end_date TEXT NOT NULL,
          total_cost REAL NOT NULL,
          status TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    });
  }
}