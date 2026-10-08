import 'package:flutter/material.dart';

/// Couleurs, icônes et libellés pour chaque statut.
class StatusStyle {
  final Color color;
  final IconData icon;
  final String label;
  const StatusStyle(this.color, this.icon, this.label);

  static StatusStyle of(String status) {
    switch (status) {
      case 'CONFIRMEE':
        return const StatusStyle(Color(0xFF2E7D32), Icons.check_circle, 'Confirmée');
      case 'EN_COURS':
        return const StatusStyle(Color(0xFF1565C0), Icons.directions_car, 'En cours');
      case 'TERMINEE':
        return const StatusStyle(Color(0xFF6A1B9A), Icons.flag, 'Terminée');
      case 'ANNULEE':
        return const StatusStyle(Color(0xFFC62828), Icons.cancel, 'Annulée');
      default: // EN_ATTENTE
        return const StatusStyle(Color(0xFFEF6C00), Icons.hourglass_top, 'En attente');
    }
  }
}

/// Petite pastille colorée affichant le statut.
class StatusBadge extends StatelessWidget {
  final String status;
  final bool onDark;
  const StatusBadge({super.key, required this.status, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final s = StatusStyle.of(status);
    final fg = onDark ? Colors.white : s.color;
    final bg = onDark ? Colors.white24 : s.color.withValues(alpha: 0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(s.icon, size: 14, color: fg),
        const SizedBox(width: 4),
        Text(s.label,
            style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// Bouton icône arrondi (modifier / supprimer).
class ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;
  const ActionIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = onTap == null ? Colors.grey : color;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: c, size: 20),
          ),
        ),
      ),
    );
  }
}

/// Boîte de dialogue de confirmation. Retourne true si confirmé.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  Color color = Colors.red,
}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Retour')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return res == true;
}