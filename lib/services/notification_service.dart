import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Constants.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  Future<void> initialize() async {
    // Request permission for notifications
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap
        print('Notification tapped: ${details.payload}');
      },
    );

    // Handle incoming messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Get the token and send it to backend
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _updateFCMToken(token);
    }

    // Listen to token refresh
    _firebaseMessaging.onTokenRefresh.listen(_updateFCMToken);
  }

  Future<void> _updateFCMToken(String token) async {
    if (Constants.userId == null) return;
    
    try {
      final response = await http.post(
        Uri.parse('${Constants.apiUrl}/api/notifications/token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': Constants.userId,
          'fcmToken': token,
        }),
      );

      if (response.statusCode != 200) {
        print('Failed to update FCM token: ${response.body}');
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final androidDetails = AndroidNotificationDetails(
      'pool_mate_channel',
      'Pool Mate Notifications',
      channelDescription: 'Notifications for Pool Mate app',
      importance: Importance.max,
      priority: Priority.high,
    );

    final iosDetails = const DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body,
      details,
      payload: json.encode(message.data),
    );
  }

  Future<List<dynamic>> getNotifications() async {
    if (Constants.userId == null) return [];
    
    try {
      final response = await http.get(
        Uri.parse('${Constants.apiUrl}/api/notifications/${Constants.userId}'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await http.put(
        Uri.parse('${Constants.apiUrl}/api/notifications/$notificationId/read'),
      );
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
}
