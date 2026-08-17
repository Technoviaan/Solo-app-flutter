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
  // Batch request — Prevents "A request for permissions is already running" PlatformException
  await [
    Permission.notification,
    Permission.scheduleExactAlarm,
    Permission.systemAlertWindow,
    Permission.ignoreBatteryOptimizations,
  ].request();
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

  await Alarm.init();
  await NotificationService.triggerImmediateCheckinAlarm();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await NotificationService.init();
    await requestPermissions();
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