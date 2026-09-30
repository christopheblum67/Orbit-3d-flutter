import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();
  FirebaseMessaging? _messaging;
  String? _fcmToken;

  /// Initialise Firebase Cloud Messaging et les notifications locales.
  /// Nom de la ressource d'icône de notification.
  ///
  /// flutter_local_notifications résout ce nom via
  /// `getIdentifier(nom, "drawable", package)` : c'est un `drawable`, SANS
  /// préfixe de type. Passer `@mipmap/ic_launcher` levait à chaque initialisation
  /// :
  /// `PlatformException(invalid_icon, The resource @mipmap/ic_launcher could
  /// not be found)` — les notifications ne partaient donc jamais.
  ///
  /// La ressource est `res/drawable/ic_stat_orbit.xml` : une silhouette
  /// blanche, seule forme lisible dans la barre d'état (Android ignore les
  /// couleurs et ne garde que le canal alpha).
  static const String _androidNotificationIcon = 'ic_stat_orbit';

  /// Ne bloque pas le lancement de l'application : en cas d'échec réseau
  /// ou d'absence de google-services.json, l'app continue sans FCM.
  Future<void> init() async {
    await safeAsync<void>(
      () async {
        // Comme pour l'analytics : si l'app Firebase existe deja (init par
        // un autre service, ou build precedent), on ne re-initialise pas.
        // Sinon `initializeApp()` sans config leve « No Firebase App
        // '[DEFAULT]' has been created ».
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp();
        }
        _messaging = FirebaseMessaging.instance;

        const androidSettings =
            AndroidInitializationSettings(_androidNotificationIcon);
        const settings = InitializationSettings(android: androidSettings);
        await _localPlugin.initialize(
          settings: settings,
          onDidReceiveNotificationResponse: (_) {},
        );

        // Autorisation des notifications (Android 13+ nécessite une permission runtime)
        final messaging = _messaging!;
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        // Récupération et persistance du token FCM
        _fcmToken = await messaging.getToken();
        debugPrint('[FCM] Token: $_fcmToken');
        await _storeToken(_fcmToken);

        // Refresh du token si il change
        messaging.onTokenRefresh.listen((token) {
          _fcmToken = token;
          debugPrint('[FCM] Token rafraîchi: $token');
          _storeToken(token);
        });

        // Gestion du message reçu en arrière-plan
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );

        // Écoute des messages en premier plan
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final notification = message.notification;
          if (notification != null) {
            showNotification(
              notification.title ?? 'Orbit IPTV',
              notification.body ?? '',
            );
          }
        });
      },
      context: 'NotificationService.init',
    );
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await Firebase.initializeApp();
    final notification = message.notification;
    if (notification != null) {
      final plugin = FlutterLocalNotificationsPlugin();
      const androidSettings =
          AndroidInitializationSettings(_androidNotificationIcon);
      const settings = InitializationSettings(android: androidSettings);
      await plugin.initialize(settings: settings);
      const androidDetails = AndroidNotificationDetails(
        'orbit_channel',
        'Orbit Notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: _androidNotificationIcon,
      );
      const details = NotificationDetails(android: androidDetails);
      await plugin.show(
        id: 0,
        title: notification.title ?? 'Orbit IPTV',
        body: notification.body ?? '',
        notificationDetails: details,
      );
    }
  }

  /// Token FCM à envoyer au serveur pour cibler ce device.
  String? get fcmToken => _fcmToken;

  /// Persiste le token côté serveur (via l'endpoint de l'API).
  Future<void> _storeToken(String? token) async {
    if (token == null) return;
    // TODO: envoyer vers l'endpoint backend /subscribe avec le token.
  }

  Future<void> showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'orbit_channel',
      'Orbit Notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: _androidNotificationIcon,
    );
    const details = NotificationDetails(android: androidDetails);
    await _localPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}
