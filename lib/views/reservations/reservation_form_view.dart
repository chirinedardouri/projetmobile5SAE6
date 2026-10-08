import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/reservation_controller.dart';
import '../../models/reservation.dart';

class ReservationFormView extends StatefulWidget {
  final Reservation? existing; // null = création, sinon modification
  const ReservationFormView({super.key, this.existing});
  @override
  State<ReservationFormView> createState() => _ReservationFormViewState();
}

class _ReservationFormViewState extends State<ReservationFormView> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(); // TEMP en attendant le module Véhicules
  DateTimeRange? _range;
  final _fmt = DateFormat('dd MMM yyyy', 'fr_FR');

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _vehicleCtrl.text = e.vehicleId.toString();
      _range = DateTimeRange(start: e.startDate, end: e.endDate);
      final days = e.endDate.difference(e.startDate).inDays;
      _priceCtrl.text = (e.totalCost / (days < 1 ? 1 : days)).toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _vehicleCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final first = _range != null && _range!.start.isBefore(now)
        ? _range!.start
        : now.subtract(const Duration(days: 1));
    final picked = await showDateRangePicker(
      context: context,
      locale: const Locale('fr', 'FR'),
      helpText: 'Choisir la période',
      saveText: 'Valider',
      firstDate: first,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  double? get _estimate {
    final p = double.tryParse(_priceCtrl.text);
    if (_range == null || p == null) return null;
    return context
        .read<ReservationController>()
        .calculateCost(_range!.start, _range!.end, p);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _range == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez remplir tous les champs et choisir les dates')));
      return;
    }
    final error = await context.read<ReservationController>().save(
          existing: widget.existing,
          userId: widget.existing?.userId ?? 1, // TODO: id de l'utilisateur connecté
          vehicleId: int.parse(_vehicleCtrl.text),
          start: _range!.start,
          end: _range!.end,
          pricePerDay: double.parse(_priceCtrl.text),
        );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      Navigator.pop(context);
    }
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    final estimate = _estimate;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier la réservation' : 'Nouvelle réservation',
            style: const TextStyle(fontWeight: FontWeight.bold)),
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
                child: Column(children: [
                  TextFormField(
                    controller: _vehicleCtrl,
                    decoration: _deco('N° du véhicule', Icons.directions_car),
                    // text + digitsOnly : contourne le bug clavier PC de l'émulateur
                    keyboardType: TextInputType.text,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => int.tryParse(v ?? '') == null
                        ? 'Entrez un nombre valide'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _priceCtrl,
                    decoration: _deco('Prix par jour (TND)', Icons.sell),
                    keyboardType: TextInputType.text,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                    ],
                    onChanged: (_) => setState(() {}),
                    validator: (v) => double.tryParse(v ?? '') == null
                        ? 'Entrez un prix valide'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _pickDates,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(14)),
                      child: Row(children: [
                        const Icon(Icons.date_range, color: Colors.indigo),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _range == null
                                ? 'Choisir les dates de location'
                                : '${_fmt.format(_range!.start)}  →  ${_fmt.format(_range!.end)}',
                            style: TextStyle(
                                fontSize: 15,
                                color: _range == null ? Colors.grey.shade600 : null,
                                fontWeight: _range == null
                                    ? FontWeight.normal
                                    : FontWeight.w600),
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            if (estimate != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total estimé',
                        style: TextStyle(color: Colors.teal.shade900)),
                    Text('${estimate.toStringAsFixed(2)} TND',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.teal.shade800)),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                elevation: 4,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.check_rounded),
              label: Text(_isEdit ? 'Enregistrer les modifications' : 'Créer la réservation'),
              onPressed: _submit,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
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
}