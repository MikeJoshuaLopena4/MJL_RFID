import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static String? fcmToken;
  static bool _notificationsEnabled = true;

  // Background handler
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_enabled') ?? true;
    
    if (enabled) {
      debugPrint("🔔 Background: ${message.notification?.title}");
    }
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Permissions (iOS only, safe on Android)
    if (_notificationsEnabled) {
      await _messaging.requestPermission();
    }

    // Get FCM token
    fcmToken = await _messaging.getToken();
    debugPrint("📱 FCM Token: $fcmToken");

    // 🔹 Save token to Firestore if logged in
    if (fcmToken != null) {
      await _saveTokenToFirestore(fcmToken!);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      fcmToken = newToken;
      await _saveTokenToFirestore(newToken);
    });

    // Setup local notifications (for foreground)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(initSettings);

    // Foreground messages
    if (_notificationsEnabled) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("🔔 Foreground: ${message.notification?.title}");
        debugPrint("Data: ${message.data}");
        _showLocalNotification(message);
      });
    }

    // When user taps a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("🔔 Opened via notification: ${message.notification?.title}");
    });
  }

  // 🔹 Save token to Firestore under current user
  static Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint("✅ Saved FCM token for user: ${user.uid}");
      } catch (e) {
        debugPrint("⚠️ Failed to save token: $e");
      }
    } else {
      debugPrint("⚠️ No logged-in user, skipping token save.");
    }
  }

  // Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    if (!_notificationsEnabled) return;
    
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fcm_channel',
      'Push Notifications',
      channelDescription: 'Channel for FCM notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title ?? "No title",
      notification.body ?? "No body",
      platformDetails,
    );
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    _notificationsEnabled = enabled;

    if (enabled) {
      await _messaging.requestPermission();
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("🔔 Foreground: ${message.notification?.title}");
        _showLocalNotification(message);
      });
    } else {
      await _localNotifications.cancelAll();
    }
  }

  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }
}
