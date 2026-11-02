import 'package:flutter/foundation.dart';

import '../../../data/maintenance_repository.dart';
import '../../../models/maintenance_item.dart';
import '../domain/enums.dart';
import '../domain/fleet_vehicle.dart';

/// Ce que le client voit sur un véhicule du catalogue.
enum ClientAvailability {
  libre('Disponible'),
  reserve('Réservé'),
  maintenance('En maintenance');

  const ClientAvailability(this.label);
  final String label;
}

/// Question posée à un autre module au sujet d'un véhicule.
typedef VehicleCheck = Future<bool> Function(String vehicleId);

/// Points de branchement avec les modules des autres membres de l'équipe,
/// utilisés par le catalogue client :
/// - Réservations (Chirine) : le véhicule est-il réservé ?
/// - Maintenance (Ghofrane) : le véhicule est-il en maintenance ?
///
/// Ces modules sont seulement lus : rien n'est modifié chez eux.
class VehicleLinks {
  VehicleLinks._();

  static VehicleCheck? _reservations;
  static VehicleCheck _maintenance = _ghofraneMaintenance;

  /// Branche l'API du module Réservations, à appeler une fois au
  /// démarrage quand elle existe, par exemple :
  /// ```dart
  /// VehicleLinks.connectReservations(
  ///   (vehicleId) => ReservationApi.isReservedNow(vehicleId),
  /// );
  /// ```
  /// En attendant, « Réservé » vient du statut que le module Réservations
  /// pose via VehicleApi.markReserved / markPickedUp.
  static void connectReservations(VehicleCheck check) => _reservations = check;

  /// Remplace la lecture du module Maintenance. Par défaut : le
  /// MaintenanceRepository de Ghofrane (entretien « En réparation »).
  static void connectMaintenance(VehicleCheck check) => _maintenance = check;

  @visibleForTesting
  static void reset() {
    _reservations = null;
    _maintenance = _ghofraneMaintenance;
  }

  /// Mention à afficher au client pour ce véhicule.
  static Future<ClientAvailability> availabilityOf(FleetVehicle vehicle) async {
    if (vehicle.status == VehicleStatus.maintenance ||
        await _ask(_maintenance, vehicle.id)) {
      return ClientAvailability.maintenance;
    }
    if (vehicle.status.isOccupied || await _ask(_reservations, vehicle.id)) {
      return ClientAvailability.reserve;
    }
    return ClientAvailability.libre;
  }

  /// [availabilityOf] pour toute une liste : id du véhicule -> mention.
  static Future<Map<String, ClientAvailability>> availabilities(
      Iterable<FleetVehicle> vehicles) async {
    final result = <String, ClientAvailability>{};
    for (final vehicle in vehicles) {
      result[vehicle.id] = await availabilityOf(vehicle);
    }
    return result;
  }

  /// Une erreur d'un autre module ne doit pas bloquer le catalogue.
  static Future<bool> _ask(VehicleCheck? check, String vehicleId) async {
    if (check == null) return false;
    try {
      return await check(vehicleId);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _ghofraneMaintenance(String vehicleId) async =>
      MaintenanceRepository().maintenances.any((m) =>
          m.vehicleId == vehicleId &&
          m.status == MaintenanceStatus.inProgress);
}
