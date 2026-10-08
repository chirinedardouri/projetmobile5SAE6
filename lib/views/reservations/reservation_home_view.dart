import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/reservation_controller.dart';
import '../../routes/app_routes.dart';
import 'reservation_drawer.dart';
import 'reservation_list_view.dart';
import 'reservation_stats_view.dart';
import 'reservation_ui.dart';

/// Écran principal : AppBar + Drawer + TabBar + BottomNavigationBar.
class ReservationHomeView extends StatefulWidget {
  const ReservationHomeView({super.key});
  @override
  State<ReservationHomeView> createState() => _ReservationHomeViewState();
}

class _ReservationHomeViewState extends State<ReservationHomeView> {
  int _index = 0; // onglet du BottomNavigationBar
  static const _titles = ['Mes réservations', 'Historique', 'Statistiques'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ReservationController>().load());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReservationController>();
    const statuses = ReservationController.statuses;

    return DefaultTabController(
      length: statuses.length + 1, // "Toutes" + 5 statuts
      child: Scaffold(
        // ---------- AppBar ----------
        appBar: AppBar(
          title: Text(_titles[_index],
              style: const TextStyle(fontWeight: FontWeight.bold)),
          // ---------- TabBar (seulement sur "Mes réservations") ----------
          bottom: _index == 0
              ? TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  tabs: [
                    const Tab(text: 'Toutes'),
                    ...statuses.map((s) => Tab(text: StatusStyle.of(s).label)),
                  ],
                )
              : null,
        ),

        // ---------- Drawer ----------
        drawer: AppDrawer(
          currentIndex: _index,
          onSelect: (i) => setState(() => _index = i),
        ),

        body: _buildBody(c, statuses),

        floatingActionButton: _index == 0
            ? FloatingActionButton.extended(
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle'),
                // pushNamed sans argument = création
                onPressed: () => Navigator.pushNamed(context, AppRoutes.form),
              )
            : null,

        // ---------- BottomNavigationBar ----------
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          selectedItemColor: Colors.indigo,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.event_note), label: 'Réservations'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history), label: 'Historique'),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart), label: 'Statistiques'),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ReservationController c, List<String> statuses) {
    if (c.isLoading && c.reservations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (_index) {
      case 1:
        return ReservationListView(
          items: c.history,
          emptyMessage: 'Aucune réservation dans l\'historique',
        );
      case 2:
        return const ReservationStatsView();
      default:
        // ---------- TabBarView : une liste par statut ----------
        return TabBarView(
          children: [
            ReservationListView(
                items: c.reservations, emptyMessage: 'Aucune réservation'),
            ...statuses.map((s) => ReservationListView(
                  items: c.withStatus(s),
                  emptyMessage:
                      'Aucune réservation « ${StatusStyle.of(s).label} »',
                )),
          ],
        );
    }
  }
}