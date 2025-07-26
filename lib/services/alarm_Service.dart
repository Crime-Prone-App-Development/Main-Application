import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mainapp/token_helper.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(settings);
    await _createNotificationChannel();
  }

  @pragma('vm:entry-point')
  static Future<void> handleBackgroundTask(String task, Map<String, dynamic>? inputData) async {
    try {
      // Example: fetch location
      final position = await Geolocator.getCurrentPosition();

      // Example: trigger a local notification
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails('your_channel_id', 'Background Tasks',
              importance: Importance.max,
              priority: Priority.high,
              ticker: 'ticker');

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.show(
        0,
        'Location Fetched',
        'Lat: ${position.latitude}, Lng: ${position.longitude}',
        platformChannelSpecifics,
      );
    } catch (e) {
      print('Error in background task: $e');
    }
  }

  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'alarm_channel',
      'Alarm Notifications',
      description: 'Notifications for scheduled alarms',
      importance: Importance.max,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<bool> setAlarm({
    required int alarmId,
    required DateTime utcTime,
    required String taskName,
    Map<String, dynamic>? taskData,
  }) async {
    try {
      DateTime localTime = utcTime.toLocal();
      Duration delay = localTime.difference(DateTime.now());

      if (delay.isNegative) {
        print("❌ Alarm time is in the past");
        return false;
      }

      await Workmanager().registerOneOffTask(
        alarmId.toString(),
        taskName,
        initialDelay: delay,
        inputData: {
          'alarmId': alarmId,
          'taskName': taskName,
          ...?taskData,
        },
        constraints: Constraints(networkType: NetworkType.connected),
      );

      // await _showConfirmationNotification(alarmId, taskName, localTime);
      return true;
    } catch (e) {
      print('❌ Failed to schedule alarm: $e');
      return false;
    }
  }

  static Future<void> _showConfirmationNotification(
      int alarmId, String taskName, DateTime scheduledTime) async {
    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Notifications',
      channelDescription: 'Notifications for scheduled alarms',
      importance: Importance.high,
      priority: Priority.high,
    );
    const platformDetails = NotificationDetails(android: androidDetails);
    await _notifications.show(
      alarmId + 10000,
      '⏰ Alarm Set: $taskName',
      'Scheduled for ${scheduledTime.toString().split('.')[0]}',
      platformDetails,
    );
  }

  static Future<void> executeTask(Map<String, dynamic> inputData) async {

    await dotenv.load(fileName: ".env");
    print(inputData);
    try {
      final String taskName = inputData['taskName'] ?? 'Unknown';
      final int alarmId = inputData['alarmId'] ?? 0;
      print('🚨 Executing WorkManager task: $taskName');

      await initialize(); // ensure notifications are available
      // await _notifications.show(
      //   alarmId,
      //   '🚨 Alarm: $taskName',
      //   'Task executed at ${DateTime.now().toString().split('.')[0]}',
      //   const NotificationDetails(
      //     android: AndroidNotificationDetails('alarm_channel', 'Alarm Notifications',
      //         importance: Importance.max, priority: Priority.high),
      //   ),
      // );

      await _executeAlarmFunction(taskName, inputData);
    } catch (e) {
      print('❌ Error in executeTask: $e');
    }
  }

  static Future<void> _executeAlarmFunction(
      String taskName, Map<String, dynamic> taskData) async {
    print('⏰ Running logic for: $taskName');
    await _submitReportToBackend(taskName, taskData);
  }

  static Future<void> _submitReportToBackend(
      String taskName, Map<String, dynamic> taskData) async {
    try {
      LocationReportData locationData = await _getLocationData();
      final (shouldSubmit, reason) = _shouldSubmitReport(locationData, taskData);
      print(reason);
      if (!shouldSubmit) return;

      String description = 'Reason : $reason';
      String latitude = locationData.position?.latitude.toString() ?? "0";
      String longitude = locationData.position?.longitude.toString() ?? "0";
      String type = 'Task Delay Report';
      String? token = await TokenHelper.getToken();

      if (token == null) return;

      ByteData byteData = await rootBundle.load('assets/images/image.png');
      Uint8List imageBytes = byteData.buffer.asUint8List();
      String? backendUri = dotenv.env["BACKEND_URI"];

      if (backendUri == null) return;

      var request = http.MultipartRequest('POST', Uri.parse('$backendUri/report'));
      request.headers['authorization'] = 'Bearer $token';
      request.fields['description'] = description;
      request.fields['latitude'] = latitude;
      request.fields['longitude'] = longitude;
      request.fields['type'] = type;
      request.files.add(http.MultipartFile.fromBytes('images', imageBytes, filename: '${taskData['assignmentId']}_pic.jpg'));

      var response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Report submitted');
      } else {
        print('⚠️ Report failed');
      }
    } catch (e) {
      print('❌ Error submitting report: $e');
    }
  }

  static Future<LocationReportData> _getLocationData() async {
    LocationReportData data = LocationReportData();
    data.isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();
    data.hasLocationPermission = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    if (data.isLocationEnabled && data.hasLocationPermission) {
      try {
        data.position = await Geolocator.getCurrentPosition();
      } catch (_) {}
    }
    return data;
  }

  static (bool, String) _shouldSubmitReport(
    LocationReportData locationData, Map<String, dynamic> taskData) {
  
  if (!locationData.isLocationEnabled) {
    return (true, 'Location service is disabled');
  }
  
  if (!locationData.hasLocationPermission) {
    return (true, 'Location permission not granted');
  }

  if (locationData.position == null) {
    return (true, 'Location data is unavailable');
  }

  double? expectedLat = _parseCoordinate(taskData["latitude"]);
  double? expectedLon = _parseCoordinate(taskData['longitude']);
  if (expectedLat != null && expectedLon != null) {
    double distance = Geolocator.distanceBetween(
        locationData.position!.latitude,
        locationData.position!.longitude,
        expectedLat,
        expectedLon);
    double tolerance = _parseDouble(taskData['location_tolerance']) ?? 100.0;
    if (distance > tolerance) {
      return (true, 'User is $distance meters away from expected location (tolerance: $tolerance m)');
    } else {
      return (false, 'User is within allowed location tolerance');
    }
  }

  return (false, 'Expected coordinates not provided');
}


  static double? _parseCoordinate(dynamic value) {
    if (value == null) return null;
    try {
      return double.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  static double? _parseDouble(dynamic value) => _parseCoordinate(value);
}

class LocationReportData {
  bool isLocationEnabled = false;
  bool hasLocationPermission = false;
  Position? position;

  LocationReportData({this.isLocationEnabled = false, this.hasLocationPermission = false, this.position});
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await AlarmService.executeTask(inputData ?? {});
    return Future.value(true);
  });
}
