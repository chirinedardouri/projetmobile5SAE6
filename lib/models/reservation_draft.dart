import 'package:flutter/material.dart';

/// utilisé quand le client
/// choisit un véhicule dans « Véhicules disponibles par date ».
class ReservationDraft {
  final String vehicleId;
  final DateTimeRange range;
  const ReservationDraft({required this.vehicleId, required this.range});
}