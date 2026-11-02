import '../../users/api/user_api.dart';
import '../../users/domain/user.dart';
import '../domain/actor.dart';
import '../domain/agency.dart';

/// Profil avec lequel on utilise le module Véhicules : celui du compte
/// connecté dans le module Utilisateurs (lu via UserApi).
///
/// Remplace l'ancien sélecteur de démonstration (DemoSession) : le rôle
/// et l'agence viennent maintenant du vrai login.
class VehicleSession {
  VehicleSession._();

  static final VehicleSession instance = VehicleSession._();

  /// Notifications « papiers » fermées pendant cette connexion
  /// (clés DocumentAlert.key). Elles réapparaissent à la connexion suivante.
  final Set<String> _dismissedAlerts = {};
  int? _alertsOwnerId;

  /// Compte connecté (null si personne n'est connecté).
  User? get user => UserApi.instance.currentUser;

  UserRole? get role => user?.role;
  bool get isSignedIn => user != null;

  /// Fiche de l'agence connectée ; null pour un client ou un admin.
  Agency? get agency {
    final current = user;
    if (current == null || !current.isAgence) return null;
    return Agency.fromUser(current);
  }

  /// L'acteur utilisé pour les droits et l'historique.
  Actor get actor {
    final current = user;
    if (current == null) return const Actor.client();
    return switch (current.role) {
      UserRole.admin => const Actor.admin(),
      UserRole.agence => Actor.agency('${current.id}'),
      UserRole.client => const Actor.client(),
    };
  }

  bool isAlertDismissed(String key) {
    _resetAlertsIfUserChanged();
    return _dismissedAlerts.contains(key);
  }

  /// Ferme les notifications données jusqu'à la prochaine connexion.
  void dismissAlerts(Iterable<String> keys) {
    _resetAlertsIfUserChanged();
    _dismissedAlerts.addAll(keys);
  }

  void _resetAlertsIfUserChanged() {
    final id = user?.id;
    if (id != _alertsOwnerId) {
      _alertsOwnerId = id;
      _dismissedAlerts.clear();
    }
  }
}
