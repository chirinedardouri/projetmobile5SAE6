import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/reservation_controller.dart';
import 'reservation_ui.dart';

class ReservationStatsView extends StatelessWidget {
  const ReservationStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReservationController>();
    final total = c.reservations.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Expanded(
              child: _tile(Icons.event_note, 'Total', '$total', Colors.indigo)),
          const SizedBox(width: 12),
          Expanded(
              child: _tile(Icons.bolt, 'Actives', '${c.activeCount}',
                  Colors.green.shade700)),
        ]),
        const SizedBox(height: 12),
        _tile(Icons.payments, 'Montant total (hors annulées)',
            '${c.totalSpent.toStringAsFixed(2)} TND', Colors.teal.shade700),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Répartition par statut',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                ...ReservationController.statuses.map((s) {
                  final st = StatusStyle.of(s);
                  final n = c.countOf(s);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(children: [
                      Row(children: [
                        Icon(st.icon, size: 18, color: st.color),
                        const SizedBox(width: 8),
                        Expanded(child: Text(st.label)),
                        Text('$n',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: st.color)),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : n / total,
                          minHeight: 8,
                          color: st.color,
                          backgroundColor: st.color.withValues(alpha: 0.12),
                        ),
                      ),
                    ]),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tile(IconData icon, String label, String value, Color color) => Card(
        elevation: 0,
        color: color.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                  Text(value,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: color)),
                ],
              ),
            ),
          ]),
        ),
      );
}