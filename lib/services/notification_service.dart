import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();
  FirebaseMessaging? _messaging;
  String? _fcmToken;

  /// Initialise Firebase Cloud Messaging et les notifications locales.
  /// Ne bloque pas le lancement de l'application : en cas d'échec réseau
  /// ou d'absence de google-services.json, l'app continue sans FCM.
  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: androidSettings);
      await _localPlugin.initialize(
        settings,
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
          _firebaseMessagingBackgroundHandler,);

      // Écoute des messages en premier plan
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          showNotification(
              notification.title ?? 'Orbit 3D', notification.body ?? '',);
        }
      });
    } catch (e) {
      // Firebase n'est pas configuré ou le réseau est indisponible :
      // l'application continue sans notifications push.
      debugPrint('[FCM] Init différée/échouée : $e');
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message,) async {
    await Firebase.initializeApp();
    final notification = message.notification;
    if (notification != null) {
      final plugin = FlutterLocalNotificationsPlugin();
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: androidSettings);
      await plugin.initialize(settings);
      const androidDetails = AndroidNotificationDetails(
        'orbit_channel',
        'Orbit Notifications',
        importance: Importance.high,
        priority: Priority.high,
      );
      const details = NotificationDetails(android: androidDetails);
      await plugin.show(0, notification.title ?? 'Orbit 3D',
          notification.body ?? '', details,);
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
    );
    const details = NotificationDetails(android: androidDetails);
    await _localPlugin.show(0, title, body, details);
  }
}
