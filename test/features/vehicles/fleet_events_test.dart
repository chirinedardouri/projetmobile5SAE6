import 'dart:async';

import 'package:ekrili_karhba/features/vehicles/data/fleet_database.dart';
import 'package:ekrili_karhba/features/vehicles/data/fleet_repository.dart';
import 'package:ekrili_karhba/features/vehicles/domain/actor.dart';
import 'package:ekrili_karhba/features/vehicles/domain/enums.dart';
import 'package:ekrili_karhba/features/vehicles/domain/fleet_event.dart';
import 'package:ekrili_karhba/features/vehicles/domain/fleet_vehicle.dart';
import 'package:ekrili_karhba/features/vehicles/domain/vehicle_document.dart';
import 'package:ekrili_karhba/features/vehicles/notifications/fleet_push.dart';
import 'package:ekrili_karhba/features/vehicles/services/fleet_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Événements qui déclenchent les notifications push (FCM) :
/// nouvelle voiture -> clients ; modification par une agence et
/// problème de papiers -> administrateur.
void main() {
  final now = DateTime(2026, 10, 22, 10);
  const admin = Actor.admin();
  const tunis = Actor.agency('2'); // compte « Auto Mobility Tunis »

  late FleetService service;
  late List<FleetEvent> events;
  late List<FleetEvent> startupEvents;
  late StreamSubscription<FleetEvent> subscription;

  setUpAll(sqfliteFfiInit);

  /// Laisse passer les événements en attente.
  Future<void> flush() => Future<void>.delayed(Duration.zero);

  setUp(() async {
    service = FleetService(
      repository: FleetRepository(FleetDatabase(
        factory: databaseFactoryFfi,
        path: ':memory:',
        clock: () => now,
      )),
      clock: () => now,
    );
    events = [];
    subscription = service.events.listen(events.add);
    await service.ensureReady();
    await flush();
    // Événements de l'ouverture (contrôle des papiers), testés à part.
    startupEvents = List.of(events);
    events.clear();
  });

  tearDown(() async {
    await subscription.cancel();
    await service.closeDatabase();
  });

  FleetVehicle draft() => FleetVehicle(
        id: 'tmp',
        agencyId: '2',
        categoryId: 'cat_citadine',
        brand: 'Seat',
        model: 'Ibiza',
        year: 2024,
        registrationPlate: '260 TUN 1111',
        pricePerDay: 80,
        deposit: 300,
        mileage: 1000,
        createdAt: now,
        updatedAt: now,
      );

  test("assurance expirée à l'ouverture : notification à l'admin", () async {
    final event = startupEvents.singleWhere(
        (e) => e.kind == FleetEventKind.problemePapiers);
    expect(event.vehicle.id, 'veh_toyota_yaris');
    expect(event.detail, contains('Hors service'));
  });

  test("voiture ajoutée par l'admin : notification aux clients", () async {
    final created = await service.createVehicle(draft(), admin);
    await flush();
    final event =
        events.singleWhere((e) => e.kind == FleetEventKind.nouveauVehicule);
    expect(event.vehicle.id, created.id);
    final message = FleetPush.messageFor(event)!;
    expect(message.topic, FleetPush.clientsTopic);
    expect(message.title, 'Nouvelle voiture disponible');
    expect(message.body, contains('Seat Ibiza'));
  });

  test("statut changé par une agence : notification à l'admin", () async {
    await service.changeStatus('veh_bmw_3', VehicleStatus.maintenance, tunis);
    await flush();
    final event = events
        .singleWhere((e) => e.kind == FleetEventKind.modificationAgence);
    expect(event.detail, contains('Maintenance'));
    expect(FleetPush.messageFor(event)!.topic, FleetPush.adminsTopic);
  });

  test("une modification par l'admin ne prévient pas l'admin", () async {
    await service.changeStatus('veh_bmw_3', VehicleStatus.maintenance, admin);
    await flush();
    expect(
      events.where((e) => e.kind == FleetEventKind.modificationAgence),
      isEmpty,
    );
  });

  test("assurance qui expire bientôt : notification à l'admin", () async {
    final created = await service.createVehicle(draft(), admin);
    await service.saveDocument(
      VehicleDocument(
        vehicleId: created.id,
        type: DocumentType.assurance,
        expiryDate: now.add(const Duration(days: 10)),
      ),
      tunis,
    );
    await flush();
    final event =
        events.singleWhere((e) => e.kind == FleetEventKind.problemePapiers);
    expect(event.detail, contains('Assurance'));
    final message = FleetPush.messageFor(event)!;
    expect(message.topic, FleetPush.adminsTopic);
    expect(message.title, 'Problème de papiers');
  });
}
