import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:http/http.dart' as http;
import 'notification_service.dart';
import 'dart:io';

class BackgroundService {
  
  // Handle WorkManager background tasks
  static Future<void> handleBackgroundTask(String task, Map<String, dynamic>? inputData) async {
    switch (task) {
      case 'periodic_task':
        await _executePeriodicTask(inputData);
        break;
      case 'one_time_task':
        await _executeOneTimeTask(inputData);
        break;
      default:
        print('Unknown task: $task');
    }
  }

  // Execute scheduled task for AndroidAlarmManager
  static Future<void> executeScheduledTask() async {
    final prefs = await SharedPreferences.getInstance();
    final taskData = prefs.getString('scheduled_task_data');
    
    await NotificationService.showInstantNotification(
      title: 'Scheduled Task Executed',
      body: 'Your scheduled task has been completed at ${DateTime.now()}',
      payload: taskData,
    );
    
    // Perform your custom task logic here
    await _performCustomTask();
  }

  // Schedule a one-time task using WorkManager
  static Future<void> scheduleOneTimeTask({
    required String taskId,
    required Duration delay,
    Map<String, dynamic>? inputData,
  }) async {
    await Workmanager().registerOneOffTask(
      taskId,
      'one_time_task',
      initialDelay: delay,
      inputData: inputData ?? {},
    );
  }

  // Schedule a periodic task using WorkManager
  static Future<void> schedulePeriodicTask({
    required String taskId,
    required Duration frequency,
    Map<String, dynamic>? inputData,
  }) async {
    await Workmanager().registerPeriodicTask(
      taskId,
      'periodic_task',
      frequency: frequency,
      inputData: inputData ?? {},
    );
  }

  // Schedule exact alarm using AndroidAlarmManager
  static Future<void> scheduleExactAlarm({
    required int alarmId,
    required DateTime scheduledTime,
    String? taskData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (taskData != null) {
      await prefs.setString('scheduled_task_data', taskData);
    }

    final duration = scheduledTime.difference(DateTime.now());
    
    await AndroidAlarmManager.oneShot(
      duration,
      alarmId,
      executeScheduledTask,
      exact: true,
      wakeup: true,
    );
  }

  // Schedule periodic alarm using AndroidAlarmManager
  static Future<void> schedulePeriodicAlarm({
    required int alarmId,
    required Duration period,
    DateTime? startTime,
  }) async {
    await AndroidAlarmManager.periodic(
      period,
      alarmId,
      executeScheduledTask,
      startAt: startTime,
      exact: true,
      wakeup: true,
    );
  }

  // Cancel all scheduled tasks
  static Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
    await AndroidAlarmManager.cancel(0); // Cancel with specific ID
  }

  // Private helper methods
  static Future<void> _executePeriodicTask(Map<String, dynamic>? inputData) async {
    await NotificationService.showInstantNotification(
      title: 'Periodic Task',
      body: 'Periodic background task executed at ${DateTime.now()}',
      payload: inputData?.toString(),
    );
    
    // Add your periodic task logic here
    print('Executing periodic task: ${inputData}');
  }

static Future<void> _executeOneTimeTask(Map<String, dynamic>? inputData) async {
  print("Before HTTP request");
  final client = HttpClient();
  
  try {
    print("Attempting HTTP request...");
    
    // Use your machine's IP instead of localhost
    final url = "http://192.168.246.155:8080/api/v1/auth/check/${inputData?['taskName'] ?? 'default'}";
    
    // Create proper HTTP request
    final request = await client.postUrl(Uri.parse(url));
    request.headers.set('Content-Type', 'application/json');
    request.write(jsonEncode({"message": "success ho gaya"}));
    
    // Get and process response
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      print('Request successful: ${response.statusCode}');
      print('Response: $responseBody');
    } else {
      print('Request failed: ${response.statusCode}');
    }
  } catch (e) {
    print('HTTP request error: $e');
  } finally {
    client.close(); // Always close client
  }


  await NotificationService.showInstantNotification(
    title: 'One-Time Task',
    body: 'One-time background task executed at ${DateTime.now()}',
    payload: inputData?.toString(),
  );

  // Function to send request to your server
  
  
  // Add your one-time task logic here
  print('Executing one-time task: $inputData');
}

static Future<void> _performCustomTask() async {
    // Simulate some background work
    await Future.delayed(Duration(seconds: 2));
    
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt('task_execution_count') ?? 0;
    await prefs.setInt('task_execution_count', currentCount + 1);
    
    print('Custom task completed. Execution count: ${currentCount + 1}');
  }
}
