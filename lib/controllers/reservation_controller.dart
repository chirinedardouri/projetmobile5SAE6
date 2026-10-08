import 'package:flutter/foundation.dart';
import '../models/reservation.dart';
import '../models/reservation_dao.dart';

class ReservationController extends ChangeNotifier {
  static const statuses = [
    'EN_ATTENTE', 'CONFIRMEE', 'EN_COURS', 'TERMINEE', 'ANNULEE'
  ];

  final ReservationDao _dao = ReservationDao();
  List<Reservation> reservations = [];
  bool isLoading = false;

  // ---------- Filtres / statistiques ----------
  List<Reservation> withStatus(String? status) => status == null
      ? reservations
      : reservations.where((r) => r.status == status).toList();

  /// Historique = réservations terminées ou annulées
  List<Reservation> get history => reservations
      .where((r) => r.status == 'TERMINEE' || r.status == 'ANNULEE')
      .toList();

  int countOf(String status) =>
      reservations.where((r) => r.status == status).length;

  int get activeCount => reservations
      .where((r) => ['EN_ATTENTE', 'CONFIRMEE', 'EN_COURS'].contains(r.status))
      .length;

  double get totalSpent => reservations
      .where((r) => r.status != 'ANNULEE')
      .fold(0.0, (sum, r) => sum + r.totalCost);

  /// Seules les réservations en attente / confirmées sont modifiables.
  bool canModify(Reservation r) =>
      r.status == 'EN_ATTENTE' || r.status == 'CONFIRMEE';

  // ---------- CRUD ----------
  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    reservations = await _dao.getAll();
    isLoading = false;
    notifyListeners();
  }

  Reservation? findById(int id) {
    for (final r in reservations) {
      if (r.id == id) return r;
    }
    return null;
  }

  int daysBetween(DateTime start, DateTime end) {
    final d = end.difference(start).inDays;
    return d < 1 ? 1 : d;
  }

  double calculateCost(DateTime start, DateTime end, double pricePerDay) =>
      daysBetween(start, end) * pricePerDay;

  /// Retourne un message d'erreur, ou null si succès.
  Future<String?> save({
    Reservation? existing,
    required int userId,
    required int vehicleId,
    required DateTime start,
    required DateTime end,
    required double pricePerDay,
  }) async {
    if (!end.isAfter(start)) {
      return 'La date de fin doit être après la date de début';
    }
    final ok = await _dao.isVehicleAvailable(vehicleId, start, end,
        excludeId: existing?.id);
    if (!ok) return "Ce véhicule n'est pas disponible pour ces dates";

    final r = Reservation(
      id: existing?.id,
      userId: userId,
      vehicleId: vehicleId,
      startDate: start,
      endDate: end,
      totalCost: calculateCost(start, end, pricePerDay),
      status: existing?.status ?? 'EN_ATTENTE',
      createdAt: existing?.createdAt,
    );
    existing == null ? await _dao.insert(r) : await _dao.update(r);
    await load();
    return null;
  }

  Future<void> cancel(int id) async {
    await _dao.updateStatus(id, 'ANNULEE');
    await load();
  }

  Future<void> changeStatus(int id, String status) async {
    await _dao.updateStatus(id, status);
    await load();
  }

  Future<void> delete(int id) async {
    await _dao.delete(id);
    await load();
  }
}