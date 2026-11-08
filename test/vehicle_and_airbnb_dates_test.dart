import 'package:flutter_test/flutter_test.dart';
import 'package:ekrili_karhba/controllers/reservation_controller.dart';
import 'package:ekrili_karhba/models/reservation.dart';

void main() {
  group('Airbnb Date Blocking & Overlap Detection Tests', () {
    late ReservationController ctrl;

    setUp(() {
      ctrl = ReservationController();
      // Simule des réservations en mémoire
      ctrl.reservations = [
        Reservation(
          id: 1,
          userId: 1,
          vehicleId: 'veh_a',
          startDate: DateTime(2026, 11, 10),
          endDate: DateTime(2026, 11, 15),
          totalCost: 475.0,
          status: 'CONFIRMEE',
        ),
        Reservation(
          id: 2,
          userId: 1,
          vehicleId: 'veh_a',
          startDate: DateTime(2026, 11, 20),
          endDate: DateTime(2026, 11, 25),
          totalCost: 475.0,
          status: 'ANNULEE', // Doit être ignorée (non bloquante)
        ),
        Reservation(
          id: 3,
          userId: 2,
          vehicleId: 'veh_b',
          startDate: DateTime(2026, 11, 12),
          endDate: DateTime(2026, 11, 18),
          totalCost: 840.0,
          status: 'EN_ATTENTE',
        ),
      ];
    });

    test('isDateOccupied identifies booked days like Airbnb', () {
      expect(ctrl.isDateOccupied('veh_a', DateTime(2026, 11, 9)), isFalse);
      expect(ctrl.isDateOccupied('veh_a', DateTime(2026, 11, 10)), isTrue);
      expect(ctrl.isDateOccupied('veh_a', DateTime(2026, 11, 12)), isTrue);
      expect(ctrl.isDateOccupied('veh_a', DateTime(2026, 11, 15)), isTrue);
      expect(ctrl.isDateOccupied('veh_a', DateTime(2026, 11, 16)), isFalse);

      // La réservation annulée (20 au 25 Nov) ne bloque pas les dates
      expect(ctrl.isDateOccupied('veh_a', DateTime(2026, 11, 22)), isFalse);

      expect(ctrl.isDateOccupied('veh_b', DateTime(2026, 11, 10)), isFalse);
      expect(ctrl.isDateOccupied('veh_b', DateTime(2026, 11, 14)), isTrue);
    });

    test('hasOverlap detects range conflicts correctly', () {
      expect(
        ctrl.hasOverlap('veh_a', DateTime(2026, 11, 8), DateTime(2026, 11, 12)),
        isTrue,
      );
      expect(
        ctrl.hasOverlap('veh_a', DateTime(2026, 11, 14), DateTime(2026, 11, 18)),
        isTrue,
      );
      expect(
        ctrl.hasOverlap('veh_a', DateTime(2026, 11, 1), DateTime(2026, 11, 5)),
        isFalse,
      );
      expect(
        ctrl.hasOverlap('veh_a', DateTime(2026, 11, 16), DateTime(2026, 11, 19)),
        isFalse,
      );
    });

    test('excludeId allows editing the same reservation without self-conflict', () {
      expect(
        ctrl.isDateOccupied('veh_a', DateTime(2026, 11, 12), excludeId: 1),
        isFalse,
      );
      expect(
        ctrl.hasOverlap('veh_a', DateTime(2026, 11, 10), DateTime(2026, 11, 15),
            excludeId: 1),
        isFalse,
      );
    });
  });
}