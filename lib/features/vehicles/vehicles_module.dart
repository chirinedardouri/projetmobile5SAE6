/// Module « Gestion des véhicules » d'Ekrili Karhba.
///
/// - Écran à afficher dans l'onglet Véhicules : [VehiclesEntryScreen].
/// - API pour les autres modules de l'équipe : [VehicleApi].
/// - Points de branchement Réservations / Maintenance : [VehicleLinks].
library;

export 'api/vehicle_api.dart';
export 'domain/agency.dart';
export 'domain/enums.dart';
export 'domain/fleet_exceptions.dart';
export 'domain/fleet_vehicle.dart';
export 'domain/vehicle_category.dart';
export 'integrations/vehicle_links.dart';
export 'ui/vehicles_entry_screen.dart';
