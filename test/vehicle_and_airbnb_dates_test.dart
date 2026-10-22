import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_reserv/controllers/reservation_controller.dart';
import 'package:gestion_reserv/models/mock_vehicles.dart';
import 'package:gestion_reserv/models/reservation.dart';

void main() {
  group('Hardcoded Vehicles Tests', () {
    test('Contains exactly 5 vehicles with proper IDs and attributes', () {
      expect(hardcodedVehicles.length, 5);
      final ids = hardcodedVehicles.map((v) => v.id).toList();
      expect(ids, [101, 102, 103, 104, 105]);

      final v101 = MockVehicle.findById(101);
      expect(v101, isNotNull);
      expect(v101!.brand, 'Toyota');
      expect(v101.model, 'Yaris');
      expect(v101.defaultPricePerDay, 95.0);

      final v105 = MockVehicle.findById(105);
      expect(v105, isNotNull);
      expect(v105!.brand, 'Hyundai');
      expect(v105.model, 'Tucson');
    });
  });

  group('Airbnb Date Blocking & Overlap Detection Tests', () {
    late ReservationController ctrl;

    setUp(() {
      ctrl = ReservationController();
      // Simule des réservations en mémoire
      ctrl.reservations = [
        Reservation(
          id: 1,
          userId: 1,
          vehicleId: 101,
          startDate: DateTime(2026, 11, 10),
          endDate: DateTime(2026, 11, 15),
          totalCost: 475.0,
          status: 'CONFIRMEE',
        ),
        Reservation(
          id: 2,
          userId: 1,
          vehicleId: 101,
          startDate: DateTime(2026, 11, 20),
          endDate: DateTime(2026, 11, 25),
          totalCost: 475.0,
          status: 'ANNULEE', // Doit être ignorée (non bloquante)
        ),
        Reservation(
          id: 3,
          userId: 2,
          vehicleId: 102,
          startDate: DateTime(2026, 11, 12),
          endDate: DateTime(2026, 11, 18),
          totalCost: 840.0,
          status: 'EN_ATTENTE',
        ),
      ];
    });

    test('isDateOccupied identifies booked days like Airbnb', () {
      // Pour le véhicule 101 :
      // 10 Nov au 15 Nov est réservé (Confirmée)
      expect(ctrl.isDateOccupied(101, DateTime(2026, 11, 9)), isFalse);
      expect(ctrl.isDateOccupied(101, DateTime(2026, 11, 10)), isTrue);
      expect(ctrl.isDateOccupied(101, DateTime(2026, 11, 12)), isTrue);
      expect(ctrl.isDateOccupied(101, DateTime(2026, 11, 15)), isTrue);
      expect(ctrl.isDateOccupied(101, DateTime(2026, 11, 16)), isFalse);

      // La réservation annulée (20 au 25 Nov) ne bloque pas les dates
      expect(ctrl.isDateOccupied(101, DateTime(2026, 11, 22)), isFalse);

      // Pour le véhicule 102 :
      expect(ctrl.isDateOccupied(102, DateTime(2026, 11, 10)), isFalse);
      expect(ctrl.isDateOccupied(102, DateTime(2026, 11, 14)), isTrue);
    });

    test('hasOverlap detects range conflicts correctly', () {
      // Véhicule 101 réservé du 10 au 15
      // Période [8 Nov, 12 Nov] chevauche
      expect(
        ctrl.hasOverlap(101, DateTime(2026, 11, 8), DateTime(2026, 11, 12)),
        isTrue,
      );

      // Période [14 Nov, 18 Nov] chevauche
      expect(
        ctrl.hasOverlap(101, DateTime(2026, 11, 14), DateTime(2026, 11, 18)),
        isTrue,
      );

      // Période [1 Nov, 5 Nov] est libre
      expect(
        ctrl.hasOverlap(101, DateTime(2026, 11, 1), DateTime(2026, 11, 5)),
        isFalse,
      );

      // Période [16 Nov, 19 Nov] est libre
      expect(
        ctrl.hasOverlap(101, DateTime(2026, 11, 16), DateTime(2026, 11, 19)),
        isFalse,
      );
    });

    test('excludeId allows editing the same reservation without self-conflict', () {
      // Si on modifie la réservation #1 elle-même, elle ne doit pas se bloquer elle-même
      expect(
        ctrl.isDateOccupied(101, DateTime(2026, 11, 12), excludeId: 1),
        isFalse,
      );
      expect(
        ctrl.hasOverlap(101, DateTime(2026, 11, 10), DateTime(2026, 11, 15),
            excludeId: 1),
        isFalse,
      );
    });
  });
}
