import 'fleet_vehicle.dart';

/// Type d'événement de la flotte qui mérite une notification push (FCM).
enum FleetEventKind {
  /// Un véhicule devient visible des clients (ajouté par l'admin ou validé)
  /// -> notification aux clients.
  nouveauVehicule,

  /// Une agence a modifié un de ses véhicules -> notification à l'admin.
  modificationAgence,

  /// Un document expire bientôt ou est expiré -> notification à l'admin.
  problemePapiers,
}

/// Événement émis par FleetService après une modification réussie.
class FleetEvent {
  const FleetEvent(this.kind, this.vehicle, this.detail);

  final FleetEventKind kind;
  final FleetVehicle vehicle;

  /// Précision lisible, ex. « Statut : Disponible → Maintenance ».
  final String detail;
}
