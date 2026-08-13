import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alarm/alarm.dart';
import 'package:solo_app/home/checkin/check_in_page.dart';
import 'package:solo_app/home/checkin/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as fcm;
import 'package:http/http.dart' as http;
import 'package:solo_app/core/network/api_config.dart';
import 'package:solo_app/core/storage/token_storage.dart';
import 'dart:convert';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

/// ✅ GLOBAL NAVIGATOR KEY (ADD THIS)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static StreamSubscription<dynamic>? _ringSub;
  static bool _isNavigationInProgress = false;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static Future init() async {
    try {
      // Initialize Alarm with a timeout to prevent hanging the app on startup
      await Alarm.init().timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint("⚠️ Alarm initialization timed out");
      });
    } catch (e) {
      debugPrint("❌ Error initializing Alarm: $e");
    }

    try {
      // Initialize local notifications
      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings settings =
      InitializationSettings(android: androidSettings);

      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: (response) async {
          // 🚀 Prioritize active alarm, fallback to saved time
          final alarmSet = await Alarm.getAlarms();
          if (alarmSet.isNotEmpty) {
            await navigateToCheckin(alarmSet.first);
          } else {
            final activeTime = await LocalStorage.getActiveCheckinTime();
            if (activeTime != null) {
              await navigateToSavedCheckin(activeTime);
            }
          }
        },
      );
    } catch (e) {
      debugPrint("❌ Error initializing Local Notifications: $e");
    }

    await Alarm.setWarningNotificationOnKill(
      "SOLO alarm may not ring",
      "Please reopen SOLO to keep your alarms reliable.",
    );

    await _ringSub?.cancel();
    _ringSub = Alarm.ringing.listen((alarmSet) async {
      try {
        if (alarmSet.alarms.isEmpty) return;
        final active = alarmSet.alarms.first;

        print("🔔 ALARM RINGING TRIGGERED: id ${active.id}");

        // 🚀 Force app to foreground
        bringToForeground();

        // Show Full-Screen Intent Notification
        await _showFullScreenNotification(active);

        // Auto-stop alarm after 20 seconds
        Timer(const Duration(seconds: 20), () async {
          if (await Alarm.isRinging(active.id)) {
            print("⏱️ 20 seconds passed. Auto-stopping alarm ${active.id}");
            await Alarm.stop(active.id);
            await _localNotifications.cancel(active.id);
          }
        });

        await navigateToCheckin(active);
      } catch (e) {
        print("❌ Error in alarm listener: $e");
      }
    });
    print("✅ Alarm Ringing Listener Initialized");

    // Restore monitoring notification if schedule exists
    try {
      final nextDue = await resolveNextDueTime();
      if (nextDue != null && nextDue.isAfter(DateTime.now())) {
        await showOngoingMonitoringNotification(nextDue);
      }
    } catch (e) {
      debugPrint("⚠️ Error restoring monitoring notification: $e");
    }

    // 🚀 NEW: Check if an alarm is already ringing or if we have an active check-in session
    try {
      final alarms = await Alarm.getAlarms();
      bool ringing = false;
      for (final alarm in alarms) {
        if (await Alarm.isRinging(alarm.id)) {
          print("🔔 Alarm ${alarm.id} is ringing on startup! Navigating...");

          // 🚀 Auto-stop alarm after 20 seconds if it's still ringing
          Timer(const Duration(seconds: 20), () async {
            if (await Alarm.isRinging(alarm.id)) {
              print("⏱️ 20 seconds passed (startup). Auto-stopping alarm ${alarm.id}");
              await Alarm.stop(alarm.id);
              await _localNotifications.cancel(alarm.id);
            }
          });

          await navigateToCheckin(alarm);
          ringing = true;
          break;
        }
      }

      if (!ringing) {
        final activeTime = await LocalStorage.getActiveCheckinTime();
        if (activeTime != null) {
          // If the active checkin time is in the past, it means a check-in is overdue
          if (DateTime.now().isAfter(activeTime)) {
            print("🕒 Overdue check-in detected on startup! Navigating...");
            await navigateToSavedCheckin(activeTime);
          }
        }
      }
    } catch (e) {
      print("⚠️ Error checking ringing/active alarms on startup: $e");
    }

    // 🚀 NEW: Listen for foreground FCM messages to trigger full screen wake
    fcm.FirebaseMessaging.onMessage.listen((fcm.RemoteMessage message) {
      print("🔔 Foreground FCM message received: ${message.messageId}");
      triggerImmediateCheckinAlarm();
    });

    // 🛠️ FIX: These two were missing entirely, and they're exactly why
    // tapping a push notification could land you back on "whatever screen
    // was open" (the resume screen) instead of the SOS screen. Without
    // them, Android's default behaviour for a tapped FCM notification is
    // simply to bring the existing activity back to the front — no app
    // code runs, so nothing tells it to open the check-in screen.

    // App was in background (not killed) and the user tapped the
    // notification to open it.
    fcm.FirebaseMessaging.onMessageOpenedApp.listen((fcm.RemoteMessage message) {
      print("🔔 Notification tapped while app in background: ${message.messageId}");
      _goToCheckinFromNotificationTap();
    });

    // App was fully killed and got cold-started by tapping the notification.
    try {
      final initialMessage = await fcm.FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        print("🔔 App cold-started from notification tap: ${initialMessage.messageId}");
        _goToCheckinFromNotificationTap();
      }
    } catch (e) {
      debugPrint("⚠️ Error reading initial FCM message: $e");
    }
  }

  /// Shared handler for "user tapped a check-in related push notification":
  /// always route straight to the SOS/check-in screen, regardless of
  /// whatever screen the app happened to be showing.
  static Future<void> _goToCheckinFromNotificationTap() async {
    final alarms = await Alarm.getAlarms();
    for (final alarm in alarms) {
      if (await Alarm.isRinging(alarm.id)) {
        await navigateToCheckin(alarm);
        return;
      }
    }
    final activeTime = await LocalStorage.getActiveCheckinTime();
    if (activeTime != null) {
      await navigateToSavedCheckin(activeTime);
    }
  }

  static Future<void> triggerImmediateCheckinAlarm() async {
    print("🚀 Triggering immediate check-in alarm from FCM Push");

    // 🚀 Force screen to wake up immediately even if unlocked
    bringToForeground();

    final now = DateTime.now().add(const Duration(seconds: 1));
    await scheduleNotification(
      now,
      id: 9999, // Specific ID for push notification triggers
      title: "Incoming Check-in Request",
      body: "Please check in immediately to stay safe.",
    );
  }

  static Future<void> _showFullScreenNotification(AlarmSettings settings) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'solo_alarm_channel_v2', // Changed version to ensure fresh channel creation
      'Solo Alarm Alerts',
      channelDescription: 'Emergency and scheduled check-in alerts',
      importance: Importance.max,
      priority: Priority.max, // Changed to Priority.max for even higher visibility
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      ongoing: true,
      playSound: true, // 🔊 Enable sound/vibration to ensure high priority status
      enableVibration: true,
      visibility: NotificationVisibility.public,
      channelShowBadge: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      settings.id,
      'Check-in Required',
      'Please check in now to stay safe.',
      notificationDetails,
      payload: settings.id.toString(),
    );
  }

  static void bringToForeground() {
    if (Platform.isAndroid) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          package: 'com.solo.app',
          componentName: 'com.solo.app.MainActivity',
          flags: [
            Flag.FLAG_ACTIVITY_NEW_TASK,
            Flag.FLAG_ACTIVITY_REORDER_TO_FRONT,
            Flag.FLAG_ACTIVITY_SINGLE_TOP,
          ],
        );
        intent.launch();
        print("🚀 AndroidIntent launched to bring app to foreground");
      } catch (e) {
        print("❌ Error launching AndroidIntent: $e");
      }
    }
  }

  static Future<void> showOngoingMonitoringNotification(DateTime nextTime) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'solo_monitoring_channel',
      'Solo Monitoring',
      channelDescription: 'Shows that Solo is active and monitoring',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      category: AndroidNotificationCategory.service,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidDetails);

    final timeStr = "${nextTime.hour % 12 == 0 ? 12 : nextTime.hour % 12}:${nextTime.minute.toString().padLeft(2, '0')} ${nextTime.hour >= 12 ? 'PM' : 'AM'}";

    await _localNotifications.show(
      999,
      'SOLO is Monitoring',
      'Next check-in scheduled for $timeStr',
      notificationDetails,
    );
  }

  static Future<void> cancelOngoingMonitoringNotification() async {
    await _localNotifications.cancel(999);
  }

  static bool isHandlingAlarm = false;

  // 🛠️ FIX: Holds a scheduledTime whose navigation attempt timed out while
  // the app was frozen in the background. Call retryPendingNavigationIfAny()
  // from app.dart's WidgetsBindingObserver.didChangeAppLifecycleState when
  // state == AppLifecycleState.resumed, so we finish the deferred navigation
  // the moment the user actually looks at the app again.
  static DateTime? _pendingCheckinTime;

  static Future<void> retryPendingNavigationIfAny() async {
    final pending = _pendingCheckinTime;
    if (pending != null) {
      print("🔁 Retrying deferred check-in navigation for $pending");
      await navigateToSavedCheckin(pending);
    }
  }

  static Future<void> navigateToCheckin(AlarmSettings settings) async {
    isHandlingAlarm = true;

    // 🚀 CRITICAL: Use the stored active check-in time if available.
    // This ensures that even if a reminder notification (which triggers later)
    // opens the screen, the timer still shows progress from the ORIGINAL due time.
    final activeTime = await LocalStorage.getActiveCheckinTime();
    if (activeTime != null) {
      print("🔔 Navigating with stored active check-in time: $activeTime");
      await navigateToSavedCheckin(activeTime);
    } else {
      print("🔔 Navigating with notification time: ${settings.dateTime}");
      await navigateToSavedCheckin(settings.dateTime);
    }
  }

  static Future<void> navigateToSavedCheckin(DateTime scheduledTime) async {
    if (_isNavigationInProgress) {
      print("⏩ Navigation already in progress, skipping duplicate.");
      return;
    }
    _isNavigationInProgress = true;

    // 🚀 Extra safety: Force app to foreground before navigating
    bringToForeground();

    final hours = await LocalStorage.getAlertWindowHours();
    final name = await LocalStorage.getUserName();
    final testWindowSeconds = await LocalStorage.getTestWindowSeconds();

    // Wait for navigator to be ready.
    // 🛠️ FIX: In a release build, when the app has been frozen/throttled in
    // the background (Doze / app-standby), the Dart engine can take much
    // longer than the old 5s budget to resume and attach the navigator.
    // We now wait up to 20s (200 x 100ms) instead of 5s (50 x 100ms).
    int retryCount = 0;
    while (navigatorKey.currentState == null && retryCount < 200) {
      await Future.delayed(const Duration(milliseconds: 100));
      retryCount++;
    }

    if (navigatorKey.currentState == null) {
      // 🛠️ FIX: Don't just give up silently. Remember that a navigation is
      // still owed, so that when the app is actually brought to the
      // foreground (WidgetsBindingObserver in app.dart calls
      // retryPendingNavigationIfAny()), we finish the job instead of
      // leaving the user stuck on whatever screen was frozen on screen.
      print("❌ Navigator still not ready after 20 seconds. Deferring navigation.");
      _pendingCheckinTime = scheduledTime;
      _isNavigationInProgress = false;
      return;
    }
    _pendingCheckinTime = null;

    print("✅ Navigator ready. Pushing CheckinScreen for $scheduledTime...");

    try {
      // 🛠️ FIX: Previously used `(route) => route.isFirst`, which only
      // clears routes ABOVE the very first (root) route and leaves that
      // root route (e.g. Home, ResumeCheckinPage) sitting underneath the
      // SOS screen. That leftover screen is what could flash/pop back into
      // view (the "resume screen" the user kept landing on). We now clear
      // the ENTIRE navigation stack so the SOS check-in screen is always
      // the only screen, in every situation (foreground, background, or
      // cold start via notification tap).
      await navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => CheckinScreen(
            userName: name,
            scheduledTime: scheduledTime,
            alertWindowHours: hours,
            testWindowSeconds: testWindowSeconds,
          ),
        ),
            (route) => false,
      );
    } catch (e) {
      print("❌ Error during navigation: $e");
    } finally {
      _isNavigationInProgress = false;
    }
  }

  static Future<void> scheduleNotification(
      DateTime scheduledTime, {
        required int id,
        required String title,
        required String body,
      }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    final voice = await LocalStorage.getVoice();
    String audioPath = "assets/audio/alarm.mp3";
    if (voice == "Male") {
      audioPath = "assets/audio/male.mp3";
    } else if (voice == "Female") {
      audioPath = "assets/audio/Female.mp3";
    }

    final settings = AlarmSettings(
      id: id,
      dateTime: scheduledTime,
      assetAudioPath: audioPath,
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
      volumeSettings: VolumeSettings.fade(
        volume: 1.0,
        fadeDuration: Duration(seconds: 2),
        volumeEnforced: true,
      ),
      notificationSettings: NotificationSettings(
        title: title,
        body: body,
        stopButton: "Stop",
      ),
    );

    await Alarm.set(alarmSettings: settings);
  }

  static DateTime nextOccurrenceFromMinutes(int minuteOfDay) {
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      minuteOfDay ~/ 60,
      minuteOfDay % 60,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<DateTime?> resolveNextDueTime() async {
    final minutes = await LocalStorage.getScheduleMinutes();
    if (minutes.isNotEmpty) {
      final candidates = minutes.map(nextOccurrenceFromMinutes).toList()
        ..sort((a, b) => a.compareTo(b));
      return candidates.first;
    }

    final scheduleIso = await LocalStorage.getSchedule();
    if (scheduleIso == null) return null;
    final raw = DateTime.parse(scheduleIso);
    if (raw.isAfter(DateTime.now())) return raw;
    return DateTime.now().add(const Duration(minutes: 1));
  }

  static Future<void> scheduleMissedCheckinFlow({
    required DateTime dueTime,
    required int alertWindowHours,
  }) async {
    // Always clear any leftover TEST window override before scheduling a
    // real schedule, so a previous test run can never leak into real usage.
    await LocalStorage.saveTestWindowSeconds(null);

    // 🛠️ FIX: cancelAllCheckinNotifications() internally nulls out the
    // active check-in time. It must run BEFORE we save the real dueTime,
    // not after — otherwise the active check-in time would end up null in
    // storage, and the app-startup "overdue check-in" recovery check (used
    // when the app was killed and later relaunched) would never trigger.
    await cancelAllCheckinNotifications();
    await LocalStorage.saveActiveCheckinTime(dueTime);

    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool("missed_checkin_notification_enabled") ?? true;

    if (notificationsEnabled) {
      await scheduleNotification(
        dueTime,
        id: 1000,
        title: "Check-in Time",
        body: "Tap to check in now.",
      );
    }

    final totalMinutes = alertWindowHours * 60;
    final reminderMinutes = _buildReminderOffsets(totalMinutes);
    for (var i = 0; i < reminderMinutes.length; i++) {
      final minute = reminderMinutes[i];
      final triggerTime = dueTime.add(Duration(minutes: minute));
      final left = totalMinutes - minute;
      if (notificationsEnabled) {
        await scheduleNotification(
          triggerTime,
          id: 1100 + i,
          title: "Missed Check-in Reminder",
          body: left > 0
              ? "$left minutes left before emergency alert."
              : "Final reminder before emergency alert.",
        );
      }
    }

    await scheduleNotification(
      dueTime.add(Duration(minutes: totalMinutes)),
      id: 1200,
      title: "Emergency Alert Triggered",
      body: "No check-in received. Contacts will be alerted.",
    );

    await showOngoingMonitoringNotification(dueTime);
  }

  /// 🧪 DEV/TEST ONLY — triggers the exact same missed-checkin alert
  /// pipeline (same alarm ids, same full-screen notification, same
  /// navigation code) but compressed into seconds instead of hours, so you
  /// can validate background/killed-app behaviour in under a minute instead
  /// of waiting for a real schedule window.
  ///
  /// After calling this: lock the phone (or kill the app from recents) and
  /// wait `delaySeconds`. The full-screen check-in alarm should appear on
  /// the lock screen. If you don't tap check-in, a reminder fires at the
  /// halfway point and an "Emergency Alert Triggered" notification fires
  /// once `windowSeconds` elapses — mirroring the real missed-checkin flow.
  static Future<void> triggerQuickTestAlert({
    int delaySeconds = 15,
    int windowSeconds = 90,
  }) async {
    await cancelAllCheckinNotifications();

    final dueTime = DateTime.now().add(Duration(seconds: delaySeconds));
    await LocalStorage.saveTestWindowSeconds(windowSeconds);
    await LocalStorage.saveActiveCheckinTime(dueTime);

    await scheduleNotification(
      dueTime,
      id: 1000,
      title: "Check-in Time (TEST)",
      body: "Tap to check in now.",
    );

    final halfSeconds = (windowSeconds / 2).round();
    if (halfSeconds > 3 && halfSeconds < windowSeconds) {
      await scheduleNotification(
        dueTime.add(Duration(seconds: halfSeconds)),
        id: 1100,
        title: "Missed Check-in Reminder (TEST)",
        body: "Reminder before test emergency alert.",
      );
    }

    await scheduleNotification(
      dueTime.add(Duration(seconds: windowSeconds)),
      id: 1200,
      title: "Emergency Alert Triggered (TEST)",
      body: "TEST: no check-in received. Contacts would be alerted.",
    );

    await showOngoingMonitoringNotification(dueTime);
    print(
      "🧪 Quick test alert scheduled: due in ${delaySeconds}s, window ${windowSeconds}s",
    );
  }

  /// Clears whatever the quick test above scheduled and restores things to
  /// a clean, no-active-checkin state.
  static Future<void> clearQuickTestAlert() async {
    await LocalStorage.saveTestWindowSeconds(null);
    await cancelAllCheckinNotifications();
  }

  static Future<void> cancelMissedCheckinRemindersOnly() async {
    final idsToCancel = [
      1000, // Check-in Time
      ...List.generate(11, (i) => 1100 + i), // Reminders
    ];

    await Future.wait(idsToCancel.map((id) async {
      await Alarm.stop(id);
      await _localNotifications.cancel(id);
    }));
  }

  static Future<void> cancelAllCheckinNotifications() async {
    await LocalStorage.saveActiveCheckinTime(null);
    await cancelOngoingMonitoringNotification();

    // Use a more focused range of IDs and run them in parallel for speed
    final idsToCancel = [
      1000, // Check-in Time
      1200, // Emergency Alert
      ...List.generate(11, (i) => 1100 + i), // Reminders
    ];

    await Future.wait(idsToCancel.map((id) async {
      await Alarm.stop(id);
      await _localNotifications.cancel(id);
    }));
  }

  static List<int> _buildReminderOffsets(int totalMinutes) {
    final checkpoints = <int>{
      3, // 3 minutes after check-in
      (totalMinutes * 0.25).round(),
      (totalMinutes * 0.5).round(),
      (totalMinutes * 0.75).round(),
      totalMinutes - 2, // Changed from totalMinutes - 10 to totalMinutes - 2
    };
    final result = checkpoints.where((m) => m > 0 && m < totalMinutes).toList()
      ..sort();
    return result;
  }

  static DateTime nextOccurrenceFromTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
  static Future<void> getAndSaveFCMToken() async {
    try {
      fcm.FirebaseMessaging messaging = fcm.FirebaseMessaging.instance;

      // Request permission (especially for iOS)
      fcm.NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == fcm.AuthorizationStatus.authorized) {
        String? fcmToken = await messaging.getToken();
        print("FCM Token Generated: $fcmToken");

        if (fcmToken != null) {
          final authToken = await TokenStorage.getToken();
          final response = await http.post(
            Uri.parse("${ApiConfig.baseUrl}/user/save-token"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $authToken",
            },
            body: jsonEncode({"token": fcmToken}),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            print("✅ FCM Token saved successfully to terminal. Status: ${response.statusCode}");
          } else {
            print("❌ Failed to save FCM Token. Status: ${response.statusCode}");
            print("FCM Response: ${response.body}");
          }
        }
      } else {
        print("❌ User declined notification permissions for FCM");
      }
    } catch (e) {
      print("❌ Error generating/saving FCM Token: $e");
    }
  }
}