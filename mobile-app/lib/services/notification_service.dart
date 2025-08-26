import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static initialize() async {
    // Request permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      // Store token in Supabase
      final supabase = Supabase.instance.client;
      if (supabase.auth.currentUser != null) {
        await supabase.from('users').update({'fcm_token': token}).eq(
            'id', supabase.auth.currentUser!.id);
      }
    }

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notificationsPlugin.initialize(initializationSettings);

    // Handle background messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  static _handleForegroundMessage(RemoteMessage message) {
    _showNotification(message);
  }

  static _handleBackgroundMessage(RemoteMessage message) {
    _showNotification(message);
  }

  static _showNotification(RemoteMessage message) {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'rfid_channel',
      'RFID Notifications',
      channelDescription: 'Notifications for RFID tap events',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    _notificationsPlugin.show(
      0,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
    );
  }
}
