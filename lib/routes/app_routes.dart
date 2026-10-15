import 'package:flutter/material.dart';
import '../models/reservation.dart';
import '../views/recommendations/ai_car_recommender_view.dart';
import '../views/reservations/reservation_detail_view.dart';
import '../views/reservations/reservation_form_view.dart';
import '../views/reservations/reservation_home_view.dart';

/// Toutes les routes nommées de l'application.
class AppRoutes {
  static const home = '/';
  static const detail = '/reservation/detail';
  static const form = '/reservation/form';
  static const aiRecommender = '/recommendations/ai';

  static Map<String, WidgetBuilder> get routes => {
        home: (_) => const ReservationHomeView(),

        // Conseiller IA Véhicules
        aiRecommender: (_) => const AiCarRecommenderView(),

        // Paramètre reçu : l'id de la réservation (int)
        detail: (context) {
          final id = ModalRoute.of(context)!.settings.arguments as int;
          return ReservationDetailView(reservationId: id);
        },

        // Paramètre reçu : la réservation à modifier (null = création)
        form: (context) {
          final existing =
              ModalRoute.of(context)?.settings.arguments as Reservation?;
          return ReservationFormView(existing: existing);
        },
      };
}