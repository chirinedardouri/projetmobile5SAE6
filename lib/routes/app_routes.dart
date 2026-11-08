import 'package:flutter/material.dart';
import '../models/reservation.dart';
import '../models/reservation_draft.dart';
import '../views/recommendations/ai_car_recommender_view.dart';
import '../views/reservations/available_vehicles_view.dart';
import '../views/reservations/reservation_detail_view.dart';
import '../views/reservations/reservation_form_view.dart';
import '../views/reservations/reservation_home_view.dart';

/// Toutes les routes nommées de l'application.
class AppRoutes {
  static const home = '/reservations';
  static const detail = '/reservation/detail';
  static const form = '/reservation/form';
  static const aiRecommender = '/recommendations/ai';
  static const availableVehicles = '/reservation/available';

  static Map<String, WidgetBuilder> get routes => {
        home: (_) => const ReservationHomeView(),

        // Conseiller IA Véhicules
        aiRecommender: (_) => const AiCarRecommenderView(),

        // Paramètre reçu : l'id de la réservation (int)
        detail: (context) {
          final id = ModalRoute.of(context)!.settings.arguments as int;
          return ReservationDetailView(reservationId: id);
        },

        // Véhicules libres à une date donnée
        availableVehicles: (_) => const AvailableVehiclesView(),

        // Paramètre reçu : Reservation (modification), ReservationDraft
        // (création pré-remplie depuis la recherche par date) ou rien (création)
        form: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return ReservationFormView(
            existing: args is Reservation ? args : null,
            draft: args is ReservationDraft ? args : null,
          );
        },
      };
}