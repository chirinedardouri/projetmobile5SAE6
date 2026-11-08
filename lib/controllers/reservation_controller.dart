import 'package:flutter/foundation.dart';
import '../features/vehicles/api/vehicle_api.dart';
import '../features/vehicles/domain/fleet_vehicle.dart';
import '../models/reservation.dart';
import '../models/reservation_dao.dart';

class ReservationController extends ChangeNotifier {
  static const statuses = [
    'EN_ATTENTE', 'CONFIRMEE', 'EN_COURS', 'TERMINEE', 'ANNULEE'
  ];

  final ReservationDao _dao = ReservationDao();
  List<Reservation> reservations = [];
  bool isLoading = false;

  // ---------- Véhicules (module Gestion des véhicules, via VehicleApi) ----------
  /// Véhicules louables proposés dans le formulaire.
  List<FleetVehicle> rentableVehicles = [];
  bool vehiclesLoading = false;
  final Map<String, FleetVehicle> _vehicleCache = {};

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

  /// Retourne toutes les réservations actives (non annulées) pour un véhicule donné.
  List<Reservation> getActiveReservationsForVehicle(String vehicleId, {int? excludeId}) =>
      reservations
          .where((r) =>
              r.vehicleId == vehicleId &&
              r.status != 'ANNULEE' &&
              (excludeId == null || r.id != excludeId))
          .toList();

  /// Vérifie si une date précise est déjà réservée pour un véhicule donné (style Airbnb).
  bool isDateOccupied(String vehicleId, DateTime date, {int? excludeId}) {
    final target = DateTime(date.year, date.month, date.day);
    final active = getActiveReservationsForVehicle(vehicleId, excludeId: excludeId);
    for (final r in active) {
      final start = DateTime(r.startDate.year, r.startDate.month, r.startDate.day);
      final end = DateTime(r.endDate.year, r.endDate.month, r.endDate.day);
      if (!target.isBefore(start) && !target.isAfter(end)) {
        return true;
      }
    }
    return false;
  }

  /// Vérifie si une plage de dates [start, end] chevauche une réservation existante.
  bool hasOverlap(String vehicleId, DateTime start, DateTime end, {int? excludeId}) {
    final active = getActiveReservationsForVehicle(vehicleId, excludeId: excludeId);
    for (final r in active) {
      if (start.isBefore(r.endDate) && end.isAfter(r.startDate)) {
        return true;
      }
    }
    return false;
  }

  // ---------- CRUD ----------
  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    reservations = await _dao.getAll();
    isLoading = false;
    notifyListeners();
    await _cacheVehiclesOf(reservations);
  }

  // ---------- Véhicules ----------

  /// Charge la liste des véhicules louables depuis VehicleApi.
  Future<void> loadVehicles() async {
    vehiclesLoading = true;
    notifyListeners();
    try {
      rentableVehicles = await VehicleApi.listRentableVehicles();
      for (final v in rentableVehicles) {
        _vehicleCache[v.id] = v;
      }
    } catch (_) {
      rentableVehicles = [];
    }
    vehiclesLoading = false;
    notifyListeners();
  }

  /// Véhicule déjà connu (cache), sans appel asynchrone.
  FleetVehicle? cachedVehicle(String id) => _vehicleCache[id];

  /// Véhicule par id (cache puis VehicleApi).
  Future<FleetVehicle?> vehicleById(String id) async {
    final cached = _vehicleCache[id];
    if (cached != null) return cached;
    try {
      final v = await VehicleApi.getVehicle(id);
      if (v != null) _vehicleCache[id] = v;
      return v;
    } catch (_) {
      return null;
    }
  }

  /// Nom à afficher pour un véhicule dans les listes / détails.
  String vehicleLabel(String id) =>
      _vehicleCache[id]?.fullName ?? 'Véhicule indisponible';

  /// Récupère les véhicules des réservations pour pouvoir afficher leur nom.
  Future<void> _cacheVehiclesOf(List<Reservation> list) async {
    var changed = false;
    for (final id in list.map((r) => r.vehicleId).toSet()) {
      if (_vehicleCache.containsKey(id)) continue;
      if (await vehicleById(id) != null) changed = true;
    }
    if (changed) notifyListeners();
  }

  /// Véhicules libres sur toute la période [start, end] :
  /// disponibles côté flotte (VehicleApi) ET sans réservation active ici.
  Future<List<FleetVehicle>> searchAvailableVehicles(
      DateTime start, DateTime end) async {
    final fleetFree = await VehicleApi.listRentableVehicles(from: start, to: end);
    final taken = await _dao.reservedVehicleIds(start, end);
    final result = <FleetVehicle>[];
    for (final v in fleetFree) {
      if (taken.contains(v.id)) continue;
      // Mêmes règles que lors de l'enregistrement (documents expirés, etc.)
      if (await VehicleApi.availabilityProblem(v.id, start, end) != null) {
        continue;
      }
      _vehicleCache[v.id] = v;
      result.add(v);
    }
    result.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
    return result;
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
    required String vehicleId,
    required DateTime start,
    required DateTime end,
  }) async {
    if (!end.isAfter(start)) {
      return 'La date de fin doit être après la date de début';
    }

    // Règles du module Véhicules (statut, maintenance, documents, blocages…)
    double? pricePerDay;
    try {
      final problem = await VehicleApi.availabilityProblem(vehicleId, start, end);
      if (problem != null) return problem;
      pricePerDay = await VehicleApi.getPricePerDay(vehicleId);
    } catch (_) {
      return 'Impossible de joindre le module Véhicules. Réessayez.';
    }
    if (pricePerDay == null) return 'Véhicule introuvable.';

    // Réservations déjà enregistrées pour ce véhicule
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