import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/reservation_controller.dart';
import '../../models/mock_vehicles.dart';
import '../../models/reservation.dart';
import 'airbnb_date_picker_dialog.dart';

class ReservationFormView extends StatefulWidget {
  final Reservation? existing; // null = création, sinon modification
  const ReservationFormView({super.key, this.existing});

  @override
  State<ReservationFormView> createState() => _ReservationFormViewState();
}

class _ReservationFormViewState extends State<ReservationFormView> {
  final _formKey = GlobalKey<FormState>();
  final _priceCtrl = TextEditingController();
  int? _selectedVehicleId;
  DateTimeRange? _range;
  final _fmt = DateFormat('dd MMM yyyy', 'fr_FR');

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _selectedVehicleId = e.vehicleId;
      _range = DateTimeRange(start: e.startDate, end: e.endDate);
      final days = e.endDate.difference(e.startDate).inDays;
      _priceCtrl.text = (e.totalCost / (days < 1 ? 1 : days)).toStringAsFixed(2);
    } else {
      // Par défaut, sélectionner le 1er véhicule parmi les 5 hardcodés
      final first = hardcodedVehicles.first;
      _selectedVehicleId = first.id;
      _priceCtrl.text = first.defaultPricePerDay.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  void _onVehicleChanged(int? newId) {
    if (newId == null) return;
    setState(() {
      _selectedVehicleId = newId;
      final v = MockVehicle.findById(newId);
      if (v != null) {
        _priceCtrl.text = v.defaultPricePerDay.toStringAsFixed(2);
      }
      // Contrôle de saisie : si une plage est déjà sélectionnée,
      // vérifier si le nouveau véhicule est disponible sur cette plage
      if (_range != null) {
        final ctrl = context.read<ReservationController>();
        if (ctrl.hasOverlap(newId, _range!.start, _range!.end,
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
      }
    });
  }

  Future<void> _pickDatesAirbnb() async {
    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez d\'abord choisir un véhicule.')),
      );
      return;
    }

    final ctrl = context.read<ReservationController>();
    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (ctx) => AirbnbDatePickerDialog(
        vehicleId: _selectedVehicleId!,
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
    final p = double.tryParse(_priceCtrl.text);
    if (_range == null || p == null) return null;
    return context
        .read<ReservationController>()
        .calculateCost(_range!.start, _range!.end, p);
  }

  Future<void> _submit() async {
    // 1. Contrôle de saisie du formulaire Flutter
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Contrôle de saisie du véhicule
    if (_selectedVehicleId == null) {
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
      _selectedVehicleId!,
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
      vehicleId: _selectedVehicleId!,
      start: _range!.start,
      end: _range!.end,
      pricePerDay: double.parse(_priceCtrl.text),
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
    final selectedVehicle = MockVehicle.findById(_selectedVehicleId);
    final activeReservations = _selectedVehicleId == null
        ? <Reservation>[]
        : ctrl.getActiveReservationsForVehicle(
            _selectedVehicleId!,
            excludeId: widget.existing?.id,
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Modifier la réservation' : 'Nouvelle réservation',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
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
                    // Sélection du véhicule parmi les 5 véhicules hardcodés
                    DropdownButtonFormField<int>(
                      initialValue: _selectedVehicleId,
                      decoration: _deco('Véhicule à louer (5 disponibles)', Icons.directions_car),
                      isExpanded: true,
                      items: hardcodedVehicles.map((v) {
                        return DropdownMenuItem<int>(
                          value: v.id,
                          child: Text(
                            '${v.fullName} (N° ${v.id} - ${v.defaultPricePerDay.toInt()} TND/j)',
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
                                'Catégorie : ${selectedVehicle.category}  |  Immat : ${selectedVehicle.plateNumber}',
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

                    // Prix par jour
                    TextFormField(
                      controller: _priceCtrl,
                      decoration: _deco('Prix par jour (TND)', Icons.sell),
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                      ],
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final val = double.tryParse(v ?? '');
                        if (val == null || val <= 0) {
                          return 'Entrez un prix journalier valide supérieur à 0';
                        }
                        return null;
                      },
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
                                      'Durée : ${_range!.end.difference(_range!.start).inDays} jour(s)',
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
                          '${_range!.end.difference(_range!.start).inDays} jours × ${_priceCtrl.text} TND',
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
