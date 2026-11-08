import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;

  Future<Database> get database async => _db ??= await _init();

  /// Version 2 : `vehicle_id` devient TEXT (les ids du module Véhicules
  /// sont des chaînes, ex. « veh_bmw_3 »).
  static const int _version = 2;

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'ekrili_karhba.db');
    return openDatabase(
      path,
      version: _version,
      onCreate: (db, version) => _createReservations(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // SQLite ne sait pas changer le type d'une colonne : on recrée la table.
          await db.execute('ALTER TABLE reservations RENAME TO reservations_old');
          await _createReservations(db);
          await db.execute('''
            INSERT INTO reservations
              (id, user_id, vehicle_id, start_date, end_date, total_cost, status, created_at)
            SELECT id, user_id, CAST(vehicle_id AS TEXT), start_date, end_date,
                   total_cost, status, created_at
            FROM reservations_old
          ''');
          await db.execute('DROP TABLE reservations_old');
        }
      },
    );
  }

  // --- Module 3: Reservations ---
  static Future<void> _createReservations(Database db) => db.execute('''
        CREATE TABLE reservations(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          vehicle_id TEXT NOT NULL,
          start_date TEXT NOT NULL,
          end_date TEXT NOT NULL,
          total_cost REAL NOT NULL,
          status TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
}