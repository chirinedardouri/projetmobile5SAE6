import 'package:ekrili_karhba/features/vehicles/domain/enums.dart';
import 'package:ekrili_karhba/features/vehicles/domain/fleet_vehicle.dart';
import 'package:ekrili_karhba/features/vehicles/integrations/vehicle_links.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mentions « Réservé » / « En maintenance » du catalogue client, d'après
/// le module Véhicules et les modules Réservations et Maintenance.
void main() {
  final now = DateTime(2026, 11, 2, 10);

  FleetVehicle vehicle(String id,
          [VehicleStatus status = VehicleStatus.disponible]) =>
      FleetVehicle(
        id: id,
        agencyId: '2',
        categoryId: 'cat_eco',
        brand: 'Kia',
        model: 'Picanto',
        year: 2023,
        registrationPlate: '230 TUN 4567',
        pricePerDay: 60,
        status: status,
        validation: ValidationStatus.valide,
        createdAt: now,
        updatedAt: now,
      );

  // Les tests ne lisent jamais le vrai module Maintenance.
  setUp(() => VehicleLinks.connectMaintenance((_) async => false));
  tearDown(VehicleLinks.reset);

  test('sans autre module : le statut du véhicule suffit', () async {
    expect(await VehicleLinks.availabilityOf(vehicle('a')),
        ClientAvailability.libre);
    expect(
        await VehicleLinks.availabilityOf(
            vehicle('b', VehicleStatus.reserve)),
        ClientAvailability.reserve);
    expect(await VehicleLinks.availabilityOf(vehicle('c', VehicleStatus.loue)),
        ClientAvailability.reserve);
    expect(
        await VehicleLinks.availabilityOf(
            vehicle('d', VehicleStatus.maintenance)),
        ClientAvailability.maintenance);
  });

  test('API du module Réservations : « Réservé »', () async {
    VehicleLinks.connectReservations((id) async => id == 'veh_bmw_3');
    final result = await VehicleLinks.availabilities(
        [vehicle('veh_bmw_3'), vehicle('veh_kia_picanto')]);
    expect(result, {
      'veh_bmw_3': ClientAvailability.reserve,
      'veh_kia_picanto': ClientAvailability.libre,
    });
  });

  test('API du module Maintenance : « En maintenance » prioritaire',
      () async {
    VehicleLinks.connectReservations((_) async => true);
    VehicleLinks.connectMaintenance((id) async => id == 'veh_bmw_3');
    expect(await VehicleLinks.availabilityOf(vehicle('veh_bmw_3')),
        ClientAvailability.maintenance);
    expect(await VehicleLinks.availabilityOf(vehicle('veh_kia_picanto')),
        ClientAvailability.reserve);
  });

  test("une erreur d'un autre module ne bloque pas le catalogue", () async {
    VehicleLinks.connectReservations((_) async => throw StateError('hors'));
    expect(await VehicleLinks.availabilityOf(vehicle('a')),
        ClientAvailability.libre);
  });
}
