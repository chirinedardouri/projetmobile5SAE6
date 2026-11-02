import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

import '../../users/domain/user.dart';
import '../domain/fleet_dates.dart';
import '../domain/fleet_event.dart';
import '../services/fleet_service.dart';
import '../services/vehicle_session.dart';

/// Contenu d'une notification push : à qui (sujet FCM), titre et texte.
class PushMessage {
  const PushMessage(this.topic, this.title, this.body, this.data);

  final String topic;
  final String title;
  final String body;
  final Map<String, String> data;
}

/// Notifications push (Firebase Cloud Messaging) du module Véhicules.
///
/// - Clients (sujet `ekrili_clients`) : nouvelle voiture disponible.
/// - Administrateurs (sujet `ekrili_admins`) : voiture modifiée par une
///   agence, papiers expirés ou qui expirent bientôt.
///
/// L'application n'a pas de serveur : l'envoi part de l'appareil où
/// l'action a lieu, avec la clé du compte de service Firebase
/// (assets/fcm/service_account.json, jamais publiée sur GitHub).
/// Sans cette clé, ou sans Firebase, l'appli fonctionne normalement
/// mais n'envoie ni ne reçoit rien.
///
/// Affichage : canal Android « haute importance » ([channelId]), pour que
/// la notification apparaisse en bannière en haut de l'écran, comme
/// Messenger, que l'appli soit ouverte, en arrière-plan ou fermée.
class FleetPush {
  FleetPush._();

  static final FleetPush instance = FleetPush._();

  static const String clientsTopic = 'ekrili_clients';
  static const String adminsTopic = 'ekrili_admins';
  static const String keyAsset = 'assets/fcm/service_account.json';

  /// Canal Android des alertes (déclaré aussi dans AndroidManifest.xml).
  static const String channelId = 'ekrili_alertes';
  static const String _channelName = 'Alertes Ekrili Karhba';
  static const String _channelDescription =
      'Nouvelles voitures, véhicules modifiés et papiers à renouveler';

  /// Petite icône des notifications (android/app/src/main/res/drawable).
  static const String _icon = 'ic_notification';
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/firebase.messaging',
  ];

  StreamSubscription<FleetEvent>? _fleetEvents;
  StreamSubscription<RemoteMessage>? _foreground;
  Future<bool>? _firebaseReady;
  Future<_Sender?>? _sender;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _localReady = false;
  int _nextLocalId = 1;

  /// Affiche une notification reçue pendant que l'appli est ouverte
  /// (titre, texte). Branché par l'écran Véhicules.
  void Function(String title, String body)? onForegroundMessage;

  /// À appeler quand le compte connecté est connu (écran Véhicules) :
  /// écoute la flotte et abonne l'appareil au sujet de son rôle.
  void start() {
    _fleetEvents ??= FleetService.instance.events.listen(_onFleetEvent);
    _syncTopics().ignore();
  }

  /// Notification à envoyer pour cet événement (null : aucune).
  static PushMessage? messageFor(FleetEvent event) {
    final v = event.vehicle;
    final data = {'vehicleId': v.id, 'type': event.kind.name};
    return switch (event.kind) {
      FleetEventKind.nouveauVehicule => PushMessage(
          clientsTopic,
          'Nouvelle voiture disponible',
          '${v.fullName} · ${FleetFormat.dt(v.pricePerDay)} par jour',
          data,
        ),
      FleetEventKind.modificationAgence => PushMessage(
          adminsTopic,
          'Véhicule modifié par une agence',
          '${v.fullName} (${v.registrationPlate}) · ${event.detail}',
          data,
        ),
      FleetEventKind.problemePapiers => PushMessage(
          adminsTopic,
          'Problème de papiers',
          '${v.fullName} (${v.registrationPlate}) · ${event.detail}',
          data,
        ),
    };
  }

  void _onFleetEvent(FleetEvent event) {
    // Un client ne fait que consulter : son appareil n'envoie rien.
    final role = VehicleSession.instance.role;
    if (role == null || role == UserRole.client) return;
    final message = messageFor(event);
    if (message != null) _send(message).ignore();
  }

  Future<bool> _ensureFirebase() => _firebaseReady ??= _initFirebase();

  Future<bool> _initFirebase() async {
    if (kIsWeb) return false;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      await _initLocalNotifications();
      _foreground ??= FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      return true;
    } catch (e) {
      debugPrint('FCM désactivé : $e');
      return false;
    }
  }

  /// Crée le canal « haute importance » (bannière en haut de l'écran).
  /// Les notifications reçues appli fermée l'utilisent aussi.
  Future<void> _initLocalNotifications() async {
    try {
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(_icon),
        ),
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              channelId,
              _channelName,
              description: _channelDescription,
              importance: Importance.max,
            ),
          );
      _localReady = true;
    } catch (e) {
      debugPrint('Notifications locales indisponibles : $e');
    }
  }

  /// Appli ouverte : Android n'affiche pas lui-même la notification FCM,
  /// on l'affiche donc en bannière (ou en bandeau si le canal manque).
  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    final title = notification.title ?? 'Ekrili Karhba';
    final body = notification.body ?? '';
    if (!_localReady) {
      onForegroundMessage?.call(title, body);
      return;
    }
    _local
        .show(
          id: _nextLocalId++,
          title: title,
          body: body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              _channelName,
              channelDescription: _channelDescription,
              importance: Importance.max,
              priority: Priority.high,
              icon: _icon,
            ),
          ),
        )
        .catchError((Object e) {
      debugPrint('Notification locale impossible : $e');
      onForegroundMessage?.call(title, body);
    });
  }

  /// Client -> sujet clients ; admin -> sujet admins ; agence -> aucun.
  Future<void> _syncTopics() async {
    if (!await _ensureFirebase()) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final role = VehicleSession.instance.role;
      if (role == UserRole.client) {
        await messaging.subscribeToTopic(clientsTopic);
      } else {
        await messaging.unsubscribeFromTopic(clientsTopic);
      }
      if (role == UserRole.admin) {
        await messaging.subscribeToTopic(adminsTopic);
      } else {
        await messaging.unsubscribeFromTopic(adminsTopic);
      }
    } catch (e) {
      debugPrint('FCM : abonnement impossible ($e)');
    }
  }

  Future<void> _send(PushMessage message) async {
    try {
      if (!await _ensureFirebase()) return;
      final sender = await (_sender ??= _loadSender());
      if (sender == null) {
        _sender = null; // nouvel essai au prochain événement
        return;
      }
      final response = await sender.client.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/'
            '${sender.projectId}/messages:send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': {
            'topic': message.topic,
            'notification': {'title': message.title, 'body': message.body},
            'data': message.data,
            // Bannière en haut de l'écran, même appli fermée.
            'android': {
              'priority': 'high',
              'notification': {
                'channel_id': channelId,
                'notification_priority': 'PRIORITY_HIGH',
                'default_sound': true,
                'icon': _icon,
              },
            },
          },
        }),
      );
      if (response.statusCode != 200) {
        debugPrint('FCM : envoi refusé (${response.statusCode}) '
            '${response.body}');
      }
    } catch (e) {
      debugPrint('FCM : envoi impossible ($e)');
    }
  }

  Future<_Sender?> _loadSender() async {
    try {
      final raw = await rootBundle.loadString(keyAsset);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final credentials = auth.ServiceAccountCredentials.fromJson(json);
      final client = await auth.clientViaServiceAccount(credentials, _scopes);
      return _Sender(json['project_id'] as String, client);
    } catch (e) {
      debugPrint("FCM : pas de clé d'envoi ($keyAsset) : $e");
      return null;
    }
  }
}

class _Sender {
  const _Sender(this.projectId, this.client);

  final String projectId;
  final http.Client client;
}
