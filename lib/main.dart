import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:SS_Pool/authentication/PhoneNumber.dart';
import 'package:flutter/services.dart';

FirebaseMessaging messaging = FirebaseMessaging.instance;

/// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  String? globalSource;
  String? globalDestination;

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Register the background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Foreground notification handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Foreground notification received: ${message.notification?.title}');
    // You can show a dialog, update the UI, or use a local notification here
    if (message.notification != null) {
      _showForegroundNotification(message);
    }
  });

  runApp(MyApp());
}

void _showForegroundNotification(RemoteMessage message) {
  // Here you can show a local notification using a package like flutter_local_notifications
  // or you can show an alert dialog as an example

  showDialog(
    context: navigatorKey.currentContext!,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(message.notification?.title ?? 'No Title'),
        content: Text(message.notification?.body ?? 'No Body'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Close'),
          ),
        ],
      );
    },
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Phone Verification',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NotificationPermissionScreen(),
      navigatorKey: navigatorKey, // Add navigator key to handle dialog from any screen
    );
  }
}

class NotificationPermissionScreen extends StatefulWidget {
  @override
  _NotificationPermissionScreenState createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen> {
  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
  }

  /// Check and request notification permission
  Future<void> _checkNotificationPermission() async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("Notification permissions granted.");
      setState(() {
        _isPermissionGranted = true;
      });
    } else {
      print("Notification permissions denied.");
      _showPermissionDialog();
    }
  }

  /// Show a dialog explaining the importance of notifications
  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enable Notifications'),
          content: Text(
              'This app requires notification permissions to function. Please enable notifications from settings.'),
          actions: [
            TextButton(
              onPressed: () {
                // Close the app or redirect as notifications are essential
                Navigator.of(context).pop();
                _exitApp();
              },
              child: Text('Exit App'),
            ),
            TextButton(
              onPressed: () {
                _openAppSettings();
              },
              child: Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  /// Open device app settings
  void _openAppSettings() {
    FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);
  }

  /// Exit the app
  void _exitApp() {
    Future.delayed(Duration(milliseconds: 500), () {
      SystemNavigator.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isPermissionGranted
          ? SignUpScreen() // Load the main screen if permission is granted
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
