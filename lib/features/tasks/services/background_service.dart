// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// Note: We import the 'android' specific part for v5
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart'; 
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'task_service.dart'; // Relative import
import 'package:my_todo_app/firebase_options.dart'; // Make sure you have this file

// --- (1) Notification Setup ---

// Helper to format duration
String _formatDuration(int totalSeconds) {
  final duration = Duration(seconds: totalSeconds);
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return "$hours:${twoDigits(minutes)}:${twoDigits(seconds)}";
  }
  return "${twoDigits(minutes)}:${twoDigits(seconds)}";
}

// Notification channel
const String notificationChannelId = 'prodloo_timer_channel';
const String notificationChannelName = 'Prodloo Timer';
const int notificationId = 888; // Static ID

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// --- (2) Background Task Entry Point ---

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final TaskService taskService = TaskService();

  // Service state
  Timer? timer;
  int remainingSeconds = 0;
  String taskName = "Prodloo Task";
  String taskId = "";

  // --- NEW HELPER FUNCTION FOR v5 ---
  // This helper updates the notification content
  Future<void> updateNotification(String content) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "Prodloo: Timer Running",
          content: content,
        );
      }
    }
  }
  // --- END HELPER ---


  // --- THIS IS THE FIX ---
  // The service is now running
  service.on('setAsForeground').listen((event) async {
    await updateNotification("$taskName - 00:00");
  });
  // --- END FIX ---


  // Stop the service
  service.on('stop').listen((event) {
    timer?.cancel();
    service.stopSelf();
  });

  // Listen for 'start' command from the UI
  service.on('start').listen((payload) {
    if (payload == null) return;

    timer?.cancel(); // Cancel any existing timer

    // Get data from the UI
    taskId = payload['taskId'];
    taskName = payload['taskName'];
    remainingSeconds = payload['remainingSeconds'];

    if (remainingSeconds <= 0) return; // Don't start a finished timer

    // Start the 1-second tick timer
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (remainingSeconds > 0) {
        remainingSeconds--;

        // Send 'update' message back to the UI
        service.invoke('update', {'remainingSeconds': remainingSeconds});

        // --- THIS IS THE OTHER FIX ---
        // Update the notification every second
        await updateNotification("$taskName - ${_formatDuration(remainingSeconds)}");
        // --- END FIX ---
        
      } else {
        // --- TIMER FINISHED ---
        timer.cancel();
        remainingSeconds = 0;

        // Send final update to UI
        service.invoke('update', {'remainingSeconds': 0});
        
        // Mark task as complete in Firestore
        await taskService.updateTaskCompletionNoContext(taskId, true);
        
        // Stop the foreground service
        await service.stopSelf();
      }
    });
  });

  // Listen for 'pause' command from the UI
  service.on('pause').listen((payload) async {
    timer?.cancel();
    if (taskId.isNotEmpty) {
      // Save the paused state to Firestore
      await taskService.updateTimerStateNoContext(
        taskId,
        remainingSeconds: remainingSeconds,
        isRunning: false,
      );
    }
  });

  // Listen for 'reset' command from the UI
  service.on('reset').listen((payload) async {
    timer?.cancel();
    if (payload == null) return;

    taskId = payload['taskId'];
    int fullDuration = payload['fullDuration'];
    remainingSeconds = fullDuration;
    
    // Save the reset state to Firestore
    await taskService.updateTimerStateNoContext(
      taskId,
      remainingSeconds: fullDuration,
      isRunning: false,
    );
    
    // Send update to UI
    service.invoke('update', {'remainingSeconds': remainingSeconds});
  });
}

// --- (3) Service Initialization Function (to be called from main.dart) ---
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // --- Notification Channel Setup ---
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    notificationChannelName,
    description: 'Notification channel for Prodloo timers',
    importance: Importance.low, // Use Low to avoid sound
    playSound: false,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
    ),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: notificationChannelId,
      // This is the notification that shows when the app first starts
      initialNotificationTitle: 'Prodloo service is running',
      initialNotificationContent: 'Tap to open app',
      foregroundServiceNotificationId: notificationId,
    ),
  );
}