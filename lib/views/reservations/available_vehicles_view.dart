import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/reservation_controller.dart';
import '../../features/vehicles/domain/fleet_vehicle.dart';
import '../../models/reservation_draft.dart';
import '../../routes/app_routes.dart';

/// Recherche inversée : le client choisit une date (ou une période) et voit
/// uniquement les véhicules libres, avec le prix et le total estimé.
class AvailableVehiclesView extends StatefulWidget {
  const AvailableVehiclesView({super.key});

  @override
  State<AvailableVehiclesView> createState() => _AvailableVehiclesViewState();
}

class _AvailableVehiclesViewState extends State<AvailableVehiclesView> {
  final _fmt = DateFormat('dd MMM yyyy', 'fr_FR');
  DateTimeRange? _range; // fin = début + 1 jour si une seule date choisie
  List<FleetVehicle>? _results;
  bool _loading = false;
  String? _error;

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDateRange: _range,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: 'Choisissez une date (ou une période)',
      saveText: 'Rechercher',
    );
    if (picked == null) return;

    final start = DateUtils.dateOnly(picked.start);
    var end = DateUtils.dateOnly(picked.end);
    // Une seule date choisie = location d'une journée (retour le lendemain)
    if (!end.isAfter(start)) end = start.add(const Duration(days: 1));

    setState(() {
      _range = DateTimeRange(start: start, end: end);
      _loading = true;
      _error = null;
    });
    await _search();
  }

  Future<void> _search() async {
    final r = _range!;
    try {
      final list = await context
          .read<ReservationController>()
          .searchAvailableVehicles(r.start, r.end);
      if (!mounted) return;
      setState(() {
        _results = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = null;
        _loading = false;
        _error = 'Impossible de charger les véhicules. Réessayez.';
      });
    }
  }

  void _reserve(FleetVehicle v) {
    Navigator.pushNamed(
      context,
      AppRoutes.form,
      arguments: ReservationDraft(vehicleId: v.id, range: _range!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<ReservationController>();
    final r = _range;
    final days = r == null ? 0 : ctrl.daysBetween(r.start, r.end);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Véhicules disponibles',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // ---------- Choix de la date ----------
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                      color: r == null ? Colors.indigo.shade200 : Colors.indigo,
                      width: r == null ? 1 : 1.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_available,
                        color: r == null ? Colors.indigo : Colors.teal),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r == null
                                ? 'Choisir une date ou une période'
                                : days == 1
                                    ? _fmt.format(r.start)
                                    : '${_fmt.format(r.start)}  →  ${_fmt.format(r.end)}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  r == null ? FontWeight.normal : FontWeight.w600,
                              color: r == null
                                  ? Colors.grey.shade700
                                  : Colors.black87,
                            ),
                          ),
                          Text(
                            r == null
                                ? 'Même jour de début et de fin = 1 jour'
                                : 'Durée : $days jour(s)',
                            style: TextStyle(
                                fontSize: 12, color: Colors.teal.shade800),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.indigo),
                  ],
                ),
              ),
            ),
          ),

          // ---------- Résultats ----------
          Expanded(child: _buildResults(ctrl, days)),
        ],
      ),
    );
  }

  Widget _buildResults(ReservationController ctrl, int days) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    if (_results == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 56, color: Colors.indigo.shade200),
              const SizedBox(height: 8),
              const Text(
                'Choisissez une date pour voir les véhicules libres.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (_results!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Aucun véhicule disponible sur cette période.',
              textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _results!.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('${_results!.length} véhicule(s) disponible(s)',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          );
        }
        final v = _results![i - 1];
        final total = ctrl.calculateCost(_range!.start, _range!.end, v.pricePerDay);
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.directions_car_filled,
                          color: Colors.indigo),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.fullName,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('${v.year}  |  ${v.registrationPlate}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${v.pricePerDay.toStringAsFixed(0)} TND/j',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo)),
                        Text('Total ${total.toStringAsFixed(2)} TND',
                            style: TextStyle(
                                fontSize: 12, color: Colors.teal.shade800)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Réserver ce véhicule'),
                    onPressed: () => _reserve(v),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}