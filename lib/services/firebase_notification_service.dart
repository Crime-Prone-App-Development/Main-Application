// Remove dart:ffi import as it's not needed
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'alarm_Service.dart';

import 'package:mainapp/token_helper.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp();
  

  // Initialize Hive for background isolate
  await Hive.initFlutter(null);

  print("Handling a background message: ${message.messageId}");

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Error loading dotenv in background: $e");
  }

  // Process the message
  await FirebaseNotificationService.saveNotificationToHive(message);

  print(message);
  String startsAtString = message.data["startsAt"];
  DateTime startsAtUtc = DateTime.parse(startsAtString).toUtc();
  // await AlarmTester.testAlarmIn30Seconds();
  await AlarmService.setAlarm(
      alarmId: 1,
      utcTime: startsAtUtc,
      taskName: 'Office Check-in',
      taskData: message.data);
  // await FirebaseNotificationService.sendText(
  //     "Background: Hare Krishna Hare Krishna");

  // Show notification
  await FirebaseNotificationService.showLocalNotification(message);
}

class FirebaseNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initializeFCM() async {
    try {
      // Set background handler early
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Request permissions for iOS and Android 13+
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('User granted provisional permission');
      } else {
        print('User declined or has not accepted permission');
      }

      // Local notification setup
      await _initializeLocalNotifications();

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print("Received foreground message: ${message.messageId}");
        String startsAtString = message.data["startsAt"];
        DateTime startsAtUtc = DateTime.parse(startsAtString).toUtc();
        await showLocalNotification(message);

        // await AlarmTester.testAlarmIn30Seconds();
        await AlarmService.setAlarm(
            alarmId: 1,
            utcTime: startsAtUtc,
            taskName: 'Office Check-in',
            taskData: message.data);
        // await sendText("Foreground: Hare Krishna Hare Krishna");
        await saveNotificationToHive(message);
      });

      // Handle when app opened via notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print("App opened from notification: ${message.data}");
        _handleNotificationTap(message);
      });

      // Handle initial message (when app is terminated and opened via notification)
      RemoteMessage? initialMsg = await _messaging.getInitialMessage();
      if (initialMsg != null) {
        print("App opened from terminated state via notification");
        await saveNotificationToHive(initialMsg);
        _handleNotificationTap(initialMsg);
      }

      // Get and save FCM token (if you need to update it)
      String? token = await _messaging.getToken();
      // print("FCM Token: $token");

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((String token) {
        print("FCM Token refreshed");
        // You can send this updated token to your backend here
        // _sendTokenToBackend(token);
      });
    } catch (e) {
      print("Error initializing FCM: $e");
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    // Android settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        if (response.payload != null) {
          final data = jsonDecode(response.payload!);
          print("Notification tapped with data: $data");
          // Handle navigation based on data
        }
      },
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
      );

      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  // static Future<void> sendText(String text) async {
  //   final client = HttpClient();

  //   try {
  //     print("Attempting HTTP request...");

  //     // Use your machine's IP instead of localhost
  //     final url =
  //         "${dotenv.env["BACKEND_URI"]}/auth/check/${text ?? 'default'}";
  //     // final url = "http://192.168.245.155:8080/api/v1/auth/check/${text ?? 'default'}";

  //     // Create proper HTTP request
  //     final request = await client.postUrl(Uri.parse(url));
  //     request.headers.set('Content-Type', 'application/json');
  //     request.write(jsonEncode({"message": "success ho gaya"}));

  //     // Get and process response
  //     final response = await request.close();
  //     final responseBody = await response.transform(utf8.decoder).join();

  //     if (response.statusCode == 200) {
  //       print('Request successful: ${response.statusCode}');
  //       print('Response: $responseBody');
  //     } else {
  //       print('Request failed: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('HTTP request error: $e');
  //   } finally {
  //     client.close(); // Always close client
  //   }
  // }

  static Future<void> showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;

    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      notification.hashCode,
      notification?.title ?? 'No Title',
      notification?.body ?? 'No Message',
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  static Future<void> saveNotificationToHive(RemoteMessage message) async {
    try {
      final box = await Hive.openBox('notifications');
      final data = {
        'title': message.notification?.title ?? 'No Title',
        'body': message.notification?.body ?? 'No Message',
        'type': message.data['type'] ?? 'General',
        'timestamp': DateTime.now().toIso8601String(),
        'data': message.data,
        'messageId': message.messageId,
      };
      await box.add(data);
      print("Notification saved to Hive");
    } catch (e) {
      print('Error saving to Hive: $e');
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    // Handle navigation based on notification data
    final data = message.data;

    if (data.containsKey('route')) {
      // Navigate to specific route
      print("Navigate to: ${data['route']}");
      // NavigationService.navigateTo(data['route']);
    }

    // You can add more logic here based on your app's requirements
  }

  // Optional: Method to get current FCM token
  static Future<String?> getCurrentToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print("Error getting FCM token: $e");
      return null;
    }
  }

  // Optional: Method to send token to backend
  static Future<void> sendTokenToBackend(String token) async {
    try {
      final url = "${dotenv.env["BACKEND_URI"]}/auth/save-token";

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"fcm_token": token}),
      );

      if (response.statusCode == 200) {
        print('Token sent to backend successfully');
      } else {
        print('Failed to send token to backend: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending token to backend: $e');
    }
  }
}
