import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solo_app/core/widgets/solo_logo.dart';
import 'package:solo_app/core/utils/app_size.dart';
import 'package:solo_app/home/checkin/local_storage.dart';
import 'package:solo_app/home/checkin/notification_service.dart';
import 'checkin_history_page.dart';
import 'alert_history_page.dart';
import 'clear_history_dialog.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool("missed_checkin_notification_enabled") ?? true;
    });
  }

  Future<void> _toggleNotifications(bool enabled) async {
    setState(() {
      _notificationsEnabled = enabled;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("missed_checkin_notification_enabled", enabled);

    if (!enabled) {
      // Disable notifications: cancel missed check-in reminders and check-in time notifications
      await NotificationService.cancelMissedCheckinRemindersOnly();
    } else {
      // Enable notifications: reschedule reminders if there is an active check-in scheduled
      final activeTime = await LocalStorage.getActiveCheckinTime();
      if (activeTime != null && activeTime.isAfter(DateTime.now())) {
        final alertWindowHours = await LocalStorage.getAlertWindowHours();
        await NotificationService.scheduleMissedCheckinFlow(
          dueTime: activeTime,
          alertWindowHours: alertWindowHours,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize AppSize context for responsive units if not already done
    AppSize.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SoloLogo(),
              const SizedBox(height: 24),

              const Text(
                "Notification",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF002C3E),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Missed Check-in Notification",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF002C3E),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Get a push notification after a missed check-in,\nbefore the alert is sent.",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8A99A6),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  customSwitch(
                    value: _notificationsEnabled,
                    onChanged: _toggleNotifications,
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Icon(
                    Icons.arrow_back,
                    color: Color(0xFF8A99A6),
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget customSwitch({required bool value, required Function(bool) onChanged}) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50.w,
        height: 28.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.w),
          color: value ? const Color(0xFFB5D43C) : const Color(0xFFD1DBE0),
        ),
        padding: EdgeInsets.all(2.w),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24.w,
            height: 24.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget historyTile(
    BuildContext context,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}