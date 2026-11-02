import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../users/domain/user.dart';
import '../notifications/fleet_push.dart';
import '../services/fleet_service.dart';
import '../services/vehicle_session.dart';
import 'client/client_catalog_view.dart';
import 'role_home_view.dart';

/// Point d'entrée du module, affiché dans l'onglet « Véhicules ».
///
/// L'espace affiché dépend du rôle du compte connecté (module
/// Utilisateurs) : client -> catalogue ; agence et admin -> gestion de
/// la flotte (l'agence ne voit que la sienne, l'admin voit tout).
class VehiclesEntryScreen extends StatefulWidget {
  const VehiclesEntryScreen({super.key});

  @override
  State<VehiclesEntryScreen> createState() => _VehiclesEntryScreenState();
}

class _VehiclesEntryScreenState extends State<VehiclesEntryScreen> {
  @override
  void initState() {
    super.initState();
    // Notifications push (FCM) : abonnement selon le rôle du compte et
    // envoi des alertes. Démarré avant la base pour ne manquer aucun
    // problème de papiers détecté à l'ouverture.
    FleetPush.instance
      ..onForegroundMessage = _showPush
      ..start();
    // Prépare la base dès l'ouverture de l'app (création + démo au 1er
    // lancement), pour que l'onglet s'affiche sans attente. Une erreur
    // éventuelle est ignorée ici : l'écran de la flotte l'affichera.
    FleetService.instance.ensureReady().ignore();
  }

  @override
  void dispose() {
    if (FleetPush.instance.onForegroundMessage == _showPush) {
      FleetPush.instance.onForegroundMessage = null;
    }
    super.dispose();
  }

  /// Notification reçue pendant que l'appli est ouverte.
  void _showPush(String title, String body) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(body.isEmpty ? title : '$title\n$body'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = VehicleSession.instance;
    if (!session.isSignedIn) return const _SignedOutView();
    if (session.role == UserRole.client) {
      return const ClientCatalogView(key: ValueKey('client'));
    }
    return RoleHomeView(
      key: ValueKey('${session.role}-${session.agency?.id}'),
    );
  }
}

/// Personne n'est connecté : l'application affiche normalement l'écran de
/// connexion avant d'arriver ici.
class _SignedOutView extends StatelessWidget {
  const _SignedOutView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Connectez-vous pour accéder aux véhicules.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}
