import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/reservation_controller.dart';
import '../../features/vehicles/domain/fleet_vehicle.dart';
import '../../models/reservation.dart';
import '../../models/reservation_draft.dart';
import 'airbnb_date_picker_dialog.dart';

class ReservationFormView extends StatefulWidget {
  final Reservation? existing; // null = création, sinon modification
  final ReservationDraft? draft; // pré-remplissage (recherche par date)
  const ReservationFormView({super.key, this.existing, this.draft});

  @override
  State<ReservationFormView> createState() => _ReservationFormViewState();
}

class _ReservationFormViewState extends State<ReservationFormView> {
  final _formKey = GlobalKey<FormState>();
  FleetVehicle? _selected; // véhicule choisi (prix = _selected.pricePerDay)
  DateTimeRange? _range;
  bool _initializing = true;
  final _fmt = DateFormat('dd MMM yyyy', 'fr_FR');

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final d = widget.draft;
    if (e != null) {
      _range = DateTimeRange(start: e.startDate, end: e.endDate);
    } else if (d != null) {
      _range = d.range;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadVehicles());
  }

  /// Charge les véhicules depuis VehicleApi puis présélectionne celui
  /// de la réservation (modification) ou du brouillon (recherche par date).
  Future<void> _loadVehicles() async {
    final ctrl = context.read<ReservationController>();
    await ctrl.loadVehicles();
    final wantedId = widget.existing?.vehicleId ?? widget.draft?.vehicleId;
    FleetVehicle? chosen;
    if (wantedId != null) chosen = await ctrl.vehicleById(wantedId);
    chosen ??= ctrl.rentableVehicles.isEmpty ? null : ctrl.rentableVehicles.first;
    if (!mounted) return;
    setState(() {
      _selected = chosen;
      _initializing = false;
    });
  }

  /// Liste du dropdown : véhicules louables (+ le véhicule choisi s'il n'y est pas).
  List<FleetVehicle> _dropdownVehicles(ReservationController ctrl) {
    final list = [...ctrl.rentableVehicles];
    final sel = _selected;
    if (sel != null && !list.any((v) => v.id == sel.id)) list.insert(0, sel);
    return list;
  }

  Future<void> _onVehicleChanged(String? newId) async {
    if (newId == null) return;
    final ctrl = context.read<ReservationController>();
    final v = await ctrl.vehicleById(newId);
    if (v == null || !mounted) return;
    setState(() {
      _selected = v;
      // Contrôle de saisie : si une plage est déjà sélectionnée,
      // vérifier si le nouveau véhicule est disponible sur cette plage
      if (_range != null &&
          ctrl.hasOverlap(newId, _range!.start, _range!.end,
              excludeId: widget.existing?.id)) {
        _range = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⚠️ Les dates ont été réinitialisées car ce véhicule est déjà réservé sur cette période.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    });
  }

  Future<void> _pickDatesAirbnb() async {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez d\'abord choisir un véhicule.')),
      );
      return;
    }

    final ctrl = context.read<ReservationController>();
    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (ctx) => AirbnbDatePickerDialog(
        vehicleId: _selected!.id,
        vehicleName: _selected!.fullName,
        controller: ctrl,
        initialRange: _range,
        excludeReservationId: widget.existing?.id,
      ),
    );

    if (picked != null) {
      setState(() => _range = picked);
    }
  }

  double? get _estimate {
    final v = _selected;
    if (_range == null || v == null) return null;
    return context
        .read<ReservationController>()
        .calculateCost(_range!.start, _range!.end, v.pricePerDay);
  }

  Future<void> _submit() async {
    // 1. Contrôle de saisie du formulaire Flutter
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Contrôle de saisie du véhicule
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un véhicule.')),
      );
      return;
    }

    // 3. Contrôle de saisie des dates
    if (_range == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez choisir les dates de location sur le calendrier.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!_range!.end.isAfter(_range!.start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La date de fin doit être strictement après la date de début.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 4. Contrôle de saisie de non-chevauchement (Double sécurité style Airbnb)
    final ctrl = context.read<ReservationController>();
    final isBlocked = ctrl.hasOverlap(
      _selected!.id,
      _range!.start,
      _range!.end,
      excludeId: widget.existing?.id,
    );
    if (isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ce véhicule est déjà réservé pour une partie ou la totalité de ces dates.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 5. Enregistrement en base de données
    final error = await ctrl.save(
      existing: widget.existing,
      userId: widget.existing?.userId ?? 1,
      vehicleId: _selected!.id,
      start: _range!.start,
      end: _range!.end,
    );

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit
              ? 'Réservation modifiée avec succès.'
              : 'Réservation créée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.indigo),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ReservationController>();
    final estimate = _estimate;
    final selectedVehicle = _selected;
    final activeReservations = selectedVehicle == null
        ? <Reservation>[]
        : ctrl.getActiveReservationsForVehicle(
            selectedVehicle.id,
            excludeId: widget.existing?.id,
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Modifier la réservation' : 'Nouvelle réservation',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _initializing
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sélection du véhicule (liste fournie par VehicleApi)
                    DropdownButtonFormField<String>(
                      key: ValueKey(_selected?.id),
                      initialValue: _selected?.id,
                      decoration: _deco(
                          'Véhicule à louer (${_dropdownVehicles(ctrl).length} disponibles)',
                          Icons.directions_car),
                      isExpanded: true,
                      items: _dropdownVehicles(ctrl).map((v) {
                        return DropdownMenuItem<String>(
                          value: v.id,
                          child: Text(
                            '${v.fullName} (${v.pricePerDay.toStringAsFixed(0)} TND/j)',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _onVehicleChanged,
                      validator: (v) => v == null ? 'Veuillez sélectionner un véhicule' : null,
                    ),

                    const SizedBox(height: 12),

                    // Badge récapitulatif du véhicule
                    if (selectedVehicle != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Colors.indigo),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${selectedVehicle.year}  |  Immat : ${selectedVehicle.registrationPlate}  |  Caution : ${selectedVehicle.deposit.toStringAsFixed(0)} TND',
                                style: const TextStyle(fontSize: 12, color: Colors.indigo),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 14),

                    // Encadré de disponibilité Airbnb du véhicule sélectionné
                    _buildAvailabilityInfoCard(activeReservations),

                    const SizedBox(height: 14),

                    // Prix par jour : fourni par le module Véhicules (lecture seule)
                    InputDecorator(
                      decoration: _deco('Prix par jour (TND)', Icons.sell),
                      child: Text(
                        selectedVehicle == null
                            ? '—'
                            : '${selectedVehicle.pricePerDay.toStringAsFixed(2)} TND / jour',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Bouton de sélection des dates avec Calendrier style Airbnb
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _pickDatesAirbnb,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: _range == null
                                ? Colors.indigo.shade200
                                : Colors.indigo,
                            width: _range == null ? 1 : 1.5,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.date_range,
                              color: _range == null ? Colors.indigo : Colors.teal,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _range == null
                                        ? 'Choisir les dates (Calendrier Airbnb)'
                                        : '${_fmt.format(_range!.start)}  →  ${_fmt.format(_range!.end)}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: _range == null ? Colors.grey.shade700 : Colors.black87,
                                      fontWeight: _range == null
                                          ? FontWeight.normal
                                          : FontWeight.w600,
                                    ),
                                  ),
                                  if (_range != null)
                                    Text(
                                      'Durée : ${ctrl.daysBetween(_range!.start, _range!.end)} jour(s)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.teal.shade800,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.indigo),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Estimation du total
            if (estimate != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total estimé',
                            style: TextStyle(color: Colors.teal.shade900)),
                        Text(
                          '${ctrl.daysBetween(_range!.start, _range!.end)} jours × ${selectedVehicle!.pricePerDay.toStringAsFixed(2)} TND',
                          style: TextStyle(fontSize: 11, color: Colors.teal.shade700),
                        ),
                      ],
                    ),
                    Text(
                      '${estimate.toStringAsFixed(2)} TND',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.teal.shade800,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Bouton de confirmation
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                elevation: 3,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                _isEdit ? 'Enregistrer les modifications' : 'Créer la réservation',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: _submit,
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.close),
              label: const Text('Annuler'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityInfoCard(List<Reservation> activeReservations) {
    if (activeReservations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, size: 18, color: Colors.green),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ce véhicule est 100% disponible (aucune date réservée).',
                style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_clock, size: 18, color: Color(0xFFE65100)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${activeReservations.length} période(s) déjà réservée(s) (bloquées sur le calendrier) :',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...activeReservations.map((r) => Padding(
                padding: const EdgeInsets.only(left: 26, top: 2),
                child: Text(
                  '• Du ${_fmt.format(r.startDate)} au ${_fmt.format(r.endDate)} (${r.status})',
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                ),
              )),
        ],
      ),
    );
  }
}