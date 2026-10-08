import '../database/database_helper.dart';
import 'reservation.dart';

class ReservationDao {
  Future<int> insert(Reservation r) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('reservations', r.toMap()..remove('id'));
  }

  Future<List<Reservation>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('reservations', orderBy: 'created_at DESC');
    return rows.map(Reservation.fromMap).toList();
  }

  Future<Reservation?> getById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('reservations', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Reservation.fromMap(rows.first);
  }

  Future<int> update(Reservation r) async {
    final db = await DatabaseHelper.instance.database;
    return db.update('reservations', r.toMap(), where: 'id = ?', whereArgs: [r.id]);
  }

  Future<int> updateStatus(int id, String status) async {
    final db = await DatabaseHelper.instance.database;
    return db.update('reservations', {'status': status},
        where: 'id = ?', whereArgs: [id]);
  }

  /// Permanently removes a reservation.
  Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    return db.delete('reservations', where: 'id = ?', whereArgs: [id]);
  }

  /// True if no non-cancelled reservation overlaps [start, end] for this vehicle.
  Future<bool> isVehicleAvailable(int vehicleId, DateTime start, DateTime end,
      {int? excludeId}) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'reservations',
      where: "vehicle_id = ? AND status != 'ANNULEE' "
          "AND start_date < ? AND end_date > ? AND id != ?",
      whereArgs: [
        vehicleId,
        end.toIso8601String(),
        start.toIso8601String(),
        excludeId ?? -1
      ],
    );
    return rows.isEmpty;
  }
}