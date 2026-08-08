import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:solo_app/home/checkin/notification_service.dart';
import 'package:alarm/alarm.dart';

import 'app.dart';
import 'loginWithNumber/auth_bloc.dart';

Future<void> requestPermissions() async {
  // Request basic notification permission
  await Permission.notification.request();

  // Request exact alarm permission (Android 13+)
  if (await Permission.scheduleExactAlarm.isDenied) {
    await Permission.scheduleExactAlarm.request();
  }

  // Request System Alert Window (to show over other apps)
  if (await Permission.systemAlertWindow.isDenied) {
    await Permission.systemAlertWindow.request();
  }
  
  // Request Battery Optimization exclusion
  if (!await Permission.ignoreBatteryOptimizations.isGranted) {
    await Permission.ignoreBatteryOptimizations.request();
  }
}

void openBatteryOptimizationSettings() {
  const intent = AndroidIntent(
    action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
    data: 'package:com.solo.app',
  );
  intent.launch();
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
  
  // Initialize Alarm so it can schedule and show the intent
  await Alarm.init();

  // Trigger immediate check-in alarm using NotificationService
  await NotificationService.triggerImmediateCheckinAlarm();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    await NotificationService.init();
    // We call this but don't strictly await it to block the app from starting
    // if the OS is slow to respond to permission requests.
    requestPermissions();
  } catch (e) {
    debugPrint("Startup Error: $e");
  }

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(),
        ),
      ],
      child: const SoloApp(),
    ),
  );
}