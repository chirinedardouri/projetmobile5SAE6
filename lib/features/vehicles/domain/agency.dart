import '../../users/domain/user.dart';

/// Agence de location propriétaire d'une partie de la flotte.
///
/// Une agence est un compte du module Utilisateurs ayant le rôle AGENCE
/// (table `users`). Le module Véhicules lit ces comptes et les présente
/// sous cette forme ; la création, la modification et l'activation des
/// comptes se font dans le module Utilisateurs.
class Agency {
  const Agency({
    required this.id,
    required this.name,
    required this.city,
    this.address = '',
    this.phone = '',
    this.email = '',
    this.isActive = true,
    required this.createdAt,
  });

  /// Construit l'agence à partir de son compte utilisateur.
  ///
  /// L'adresse du compte (« rue, quartier, ville ») est découpée :
  /// la dernière partie donne la ville, le reste l'adresse.
  factory Agency.fromUser(User user) {
    final parts = (user.adresseAgence ?? '')
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    return Agency(
      id: '${user.id}',
      name: user.displayName,
      city: parts.isEmpty ? '' : parts.last,
      address: parts.length < 2
          ? ''
          : parts.sublist(0, parts.length - 1).join(', '),
      phone: user.telephone,
      email: user.email,
      isActive: user.isActif,
      createdAt: user.createdAt,
    );
  }

  /// Ligne de la table `users` (rôle AGENCE).
  factory Agency.fromUserRow(Map<String, Object?> row) =>
      Agency.fromUser(User.fromMap(row));

  /// Identifiant du compte utilisateur de l'agence (en texte).
  final String id;
  final String name;
  final String city;
  final String address;
  final String phone;
  final String email;

  /// Une agence désactivée n'apparaît plus côté client,
  /// ses véhicules non plus.
  final bool isActive;
  final DateTime createdAt;

  /// Initiales pour l'avatar (ex. « Auto Mobility Tunis » -> « AM »).
  String get initials {
    final words =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }
}
