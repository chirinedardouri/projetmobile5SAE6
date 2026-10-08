import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/reservation_controller.dart';
import '../../models/reservation.dart';
import '../../routes/app_routes.dart';
import 'reservation_ui.dart';

class ReservationDetailView extends StatelessWidget {
  final int reservationId;
  const ReservationDetailView({super.key, required this.reservationId});

  Future<void> _cancel(
      BuildContext context, ReservationController c, int id) async {
    final ok = await confirmDialog(
      context,
      title: 'Annuler la réservation ?',
      message:
          'La réservation sera marquée comme annulée mais gardée dans votre historique.',
      confirmLabel: 'Annuler',
      color: Colors.orange.shade800,
    );
    if (ok) await c.cancel(id);
  }

  Future<void> _delete(
      BuildContext context, ReservationController c, int id) async {
    final ok = await confirmDialog(
      context,
      title: 'Supprimer la réservation ?',
      message: 'Cette action supprime définitivement la réservation.',
      confirmLabel: 'Supprimer',
    );
    if (!ok || !context.mounted) return;
    Navigator.pop(context); // on quitte l'écran d'abord, puis on supprime
    await c.delete(id);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReservationController>();
    final r = c.findById(reservationId);

    if (r == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Détails')),
          body: const Center(child: Text('Réservation introuvable')));
    }

    final s = StatusStyle.of(r.status);
    final fmt = DateFormat('dd MMM yyyy', 'fr_FR');
    final days = c.daysBetween(r.startDate, r.endDate);
    final perDay = r.totalCost / days;

    return Scaffold(
      body: Column(
        children: [
          _header(context, r, s),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _section('Période de location', [
                  Row(children: [
                    Expanded(
                        child: _dateBox(
                            'PRISE', fmt.format(r.startDate), Icons.login)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward_rounded,
                          color: Colors.grey.shade400),
                    ),
                    Expanded(
                        child: _dateBox(
                            'RETOUR', fmt.format(r.endDate), Icons.logout)),
                  ]),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                      child: _stat(Icons.timelapse, 'Durée', '$days jour(s)',
                          Colors.indigo)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _stat(Icons.sell, 'Prix / jour',
                          '${perDay.toStringAsFixed(2)} TND',
                          Colors.orange.shade800)),
                ]),
                const SizedBox(height: 14),
                _section('Informations', [
                  _infoRow(Icons.tag, 'N° réservation', '#${r.id}'),
                  _infoRow(Icons.directions_car, 'N° véhicule', '#${r.vehicleId}'),
                  _infoRow(Icons.person, 'N° client', '#${r.userId}'),
                  _infoRow(Icons.schedule, 'Créée le', fmt.format(r.createdAt)),
                ]),
                const SizedBox(height: 14),
                _section('Changer le statut', [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: ReservationController.statuses.map((st) {
                      final style = StatusStyle.of(st);
                      final selected = r.status == st;
                      return ChoiceChip(
                        avatar: Icon(style.icon,
                            size: 16,
                            color: selected ? Colors.white : style.color),
                        label: Text(style.label),
                        selected: selected,
                        selectedColor: style.color,
                        labelStyle:
                            TextStyle(color: selected ? Colors.white : null),
                        showCheckmark: false,
                        onSelected: (_) => c.changeStatus(r.id!, st),
                      );
                    }).toList(),
                  ),
                ]),
              ],
            ),
          ),
          _bottomBar(context, c, r),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, Reservation r, StatusStyle s) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          8, MediaQuery.of(context).padding.top + 4, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [s.color, s.color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.directions_car_filled,
                      color: Colors.white, size: 30),
                  const SizedBox(width: 10),
                  Text('Véhicule #${r.vehicleId}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 10),
                StatusBadge(status: r.status, onDark: true),
                const SizedBox(height: 18),
                const Text('Coût total',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text('${r.totalCost.toStringAsFixed(2)} TND',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(
      BuildContext context, ReservationController c, Reservation r) {
    final canModify = c.canModify(r);
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -3)),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Modifier'),
              onPressed: canModify
                  ? () => Navigator.pushNamed(context, AppRoutes.form,
                      arguments: r)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.delete_rounded),
              label: const Text('Supprimer'),
              onPressed: () => _delete(context, c, r.id!),
            ),
          ),
        ]),
        if (canModify)
          TextButton.icon(
            icon: Icon(Icons.block, color: Colors.orange.shade800, size: 18),
            label: Text('Annuler la réservation',
                style: TextStyle(color: Colors.orange.shade800)),
            onPressed: () => _cancel(context, c, r.id!),
          ),
      ]),
    );
  }

  Widget _section(String title, List<Widget> children) => Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style:
                      const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      );

  Widget _dateBox(String label, String value, IconData icon) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, letterSpacing: 1, color: Colors.grey.shade600)),
          ]),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ]),
      );

  Widget _stat(IconData icon, String label, String value, Color color) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ]),
      );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label, style: TextStyle(color: Colors.grey.shade700))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      );
}