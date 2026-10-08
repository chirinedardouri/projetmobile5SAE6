import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

/// Menu latéral (Drawer) de l'écran principal.
class AppDrawer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect; // change l'onglet du BottomNavigationBar

  const AppDrawer({super.key, required this.currentIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 24, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3949AB), Color(0xFF5C6BC0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.directions_car_filled,
                      size: 32, color: Colors.indigo),
                ),
                SizedBox(height: 14),
                Text('Ekrili Karhba',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text('Gestion des réservations',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _item(context, Icons.event_note, 'Mes réservations', 0),
          _item(context, Icons.history, 'Historique', 1),
          _item(context, Icons.bar_chart, 'Statistiques', 2),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add_circle, color: Colors.teal),
            title: const Text('Nouvelle réservation'),
            onTap: () {
              Navigator.pop(context); // ferme le drawer
              Navigator.pushNamed(context, AppRoutes.form);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('À propos'),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'Ekrili Karhba',
                applicationVersion: '1.0.0',
                applicationIcon:
                    const Icon(Icons.directions_car_filled, color: Colors.indigo),
                children: const [Text('Application de location de voitures.')],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label, int index) =>
      ListTile(
        leading: Icon(icon),
        title: Text(label),
        selected: currentIndex == index,
        selectedTileColor: Colors.indigo.withValues(alpha: 0.08),
        onTap: () {
          Navigator.pop(context); // ferme le drawer
          onSelect(index);
        },
      );
}