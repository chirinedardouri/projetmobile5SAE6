import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/reservation_controller.dart';
import '../../models/reservation.dart';
import '../../routes/app_routes.dart';
import 'reservation_ui.dart';

class ReservationListView extends StatelessWidget {
  final List<Reservation> items;
  final String emptyMessage;
  const ReservationListView(
      {super.key, required this.items, required this.emptyMessage});

  Future<void> _delete(
      BuildContext context, ReservationController c, Reservation r) async {
    final ok = await confirmDialog(
      context,
      title: 'Supprimer la réservation ?',
      message: 'La réservation #${r.id} sera définitivement supprimée.',
      confirmLabel: 'Supprimer',
    );
    if (ok) {
      await c.delete(r.id!);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Réservation supprimée')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReservationController>();
    if (items.isEmpty) return _empty(context);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      itemCount: items.length,
      itemBuilder: (_, i) => _card(context, c, items[i]),
    );
  }

  Widget _empty(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.event_busy, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(emptyMessage,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle réservation'),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.form),
          ),
        ]),
      );

  Widget _card(BuildContext context, ReservationController c, Reservation r) {
    final s = StatusStyle.of(r.status);
    final days = c.daysBetween(r.startDate, r.endDate);
    final fmt = DateFormat('dd MMM yyyy', 'fr_FR');

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 3,
      shadowColor: Colors.black26,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        // Navigation par route nommée + passage de paramètre (l'id)
        onTap: () =>
            Navigator.pushNamed(context, AppRoutes.detail, arguments: r.id),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: s.color), // bande de statut
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: s.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.directions_car_filled, color: s.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Véhicule #${r.vehicleId}',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('Réservation #${r.id}',
                                  style: TextStyle(
                                      color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        ),
                        StatusBadge(status: r.status),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Icon(Icons.calendar_month,
                            size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text('${fmt.format(r.startDate)} → ${fmt.format(r.endDate)}',
                            style: const TextStyle(fontSize: 13)),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${r.totalCost.toStringAsFixed(2)} TND',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.teal.shade700)),
                              Text('$days jour(s)',
                                  style: TextStyle(
                                      color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        ),
                        ActionIcon(
                          icon: Icons.edit_rounded,
                          color: const Color(0xFF1E88E5),
                          tooltip: 'Modifier',
                          onTap: c.canModify(r)
                              ? () => Navigator.pushNamed(context, AppRoutes.form,
                                  arguments: r) // paramètre : la réservation
                              : null,
                        ),
                        const SizedBox(width: 8),
                        ActionIcon(
                          icon: Icons.delete_rounded,
                          color: const Color(0xFFE53935),
                          tooltip: 'Supprimer',
                          onTap: () => _delete(context, c, r),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}