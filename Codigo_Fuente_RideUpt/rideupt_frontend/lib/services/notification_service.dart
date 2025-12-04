// services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Manejando un mensaje en segundo plano: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _requestPermissions();
    await _initLocalNotifications();
    _configureFirebaseListeners();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> initWithoutPermissions() async {
    await _initLocalNotifications();
    _configureFirebaseListeners();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<String?> getFcmToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> requestPermissions() async {
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: initSettingsAndroid);
    await _localNotifications.initialize(initSettings);
  }

  void _configureFirebaseListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('¡Recibí un mensaje mientras estaba en primer plano!');
      debugPrint('Datos del mensaje: ${message.data}');

      if (message.notification != null) {
        debugPrint('El mensaje también contenía una notificación: ${message.notification}');
        _showLocalNotification(message.notification!);
      }
      
      // Notificar a los listeners sobre actualizaciones de viaje
      if (message.data.containsKey('tripId') || message.data.containsKey('type')) {
        _onTripUpdate(message.data);
      }
    });
  }
  
  // Callback para actualizaciones de viaje
  Function(Map<String, dynamic>)? onTripUpdate;
  
  void _onTripUpdate(Map<String, dynamic> data) {
    if (onTripUpdate != null) {
      onTripUpdate!(data);
    }
  }

  void _showLocalNotification(RemoteNotification notification) {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel', // id
      'Notificaciones Importantes', // title
      channelDescription: 'Este canal se usa para notificaciones importantes.',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformDetails,
    );
  }
}