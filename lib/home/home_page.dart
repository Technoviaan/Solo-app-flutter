import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:solo_app/home/contact/contacts_page.dart';
import 'package:solo_app/home/more_page.dart';
import 'package:solo_app/home/profile/profile_api.dart';
import 'package:solo_app/home/shedule/schedule_page.dart';
import 'package:solo_app/subscription/subscription_page.dart';
import 'package:solo_app/widgets/solo_eye.dart';
import 'package:solo_app/core/storage/token_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:solo_app/main.dart';
import '../core/utils/app_size.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = "";

  @override
  void initState() {
    super.initState();
    loadUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAllPermissions();
    });
  }

  Future<void> _checkAllPermissions() async {
    // 1. Check Location Permission
    final locationStatus = await Permission.location.status;
    if (!locationStatus.isGranted && mounted) {
      _showLocationBottomSheetToast();
    }

    // 2. Battery Optimization
    final isIgnored = await Permission.ignoreBatteryOptimizations.isGranted;
    if (!isIgnored && mounted) {
      _showPermissionSnackBar(
        "Please disable battery optimization for SOLO to ensure alarms work properly.",
        openBatteryOptimizationSettings,
      );
    }

    // 3. Exact Alarm
    final isExactAlarmGranted = await Permission.scheduleExactAlarm.isGranted;
    if (!isExactAlarmGranted && mounted) {
      _showPermissionSnackBar(
        "Please allow 'Alarms & reminders' for SOLO to ensure timely alerts.",
            () => openAppSettings(),
      );
    }

    // 4. System Alert Window Overlay
    final isOverlayGranted = await Permission.systemAlertWindow.isGranted;
    if (!isOverlayGranted && mounted) {
      _showPermissionSnackBar(
        "Please allow 'Display over other apps' to open the alarm screen automatically.",
            () => openAppSettings(),
      );
    }
  }

  void _showLocationBottomSheetToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF002C3E),
        duration: const Duration(seconds: 12),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16.w),
        content: Row(
          children: [
            const Icon(Icons.location_off, color: Color(0xFFF5B13F), size: 22),
            SizedBox(width: 10.w),
            const Expanded(
              child: Text(
                "Enable location to send your coordinates in emergency alerts.",
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: "Allow",
          textColor: const Color(0xFF0BB3AA),
          onPressed: () async {
            final res = await Permission.location.request();
            if (res.isPermanentlyDenied) {
              await openAppSettings();
            }
          },
        ),
      ),
    );
  }

  void _showPermissionSnackBar(String message, VoidCallback onAction) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: "Settings",
          onPressed: onAction,
        ),
      ),
    );
  }

  Future<void> loadUser() async {
    final localName = await TokenStorage.getUserName();
    if (mounted) {
      setState(() {
        userName = localName;
      });
    }

    final data = await ProfileApi.getProfile();
    if (data != null) {
      final userMap = data["user"] ?? data;
      if (userMap["name"] != null) {
        final nameFromApi = userMap["name"].toString();
        if (mounted) {
          setState(() {
            userName = nameFromApi;
          });
        }
        await TokenStorage.saveUserName(nameFromApi);
      }
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "Good morning";
    } else if (hour >= 12 && hour < 17) {
      return "Good afternoon";
    } else {
      return "Hello";
    }
  }

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F5),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(28.w, 56.h, 28.w, 24.h),
              decoration: const BoxDecoration(
                color: Color(0xFF002C3E),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(90),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SoloLogoWidget(size: 70),
                  const Spacer(),
                  Text(
                    userName.isNotEmpty ? "$_greeting,\n$userName" : "$_greeting,",
                    style: TextStyle(
                      color: const Color(0xFF78BCC4),
                      fontSize: 36.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    "How can we\nsupport you\ntoday?",
                    style: TextStyle(
                      color: const Color(0xFF78BCC4),
                      fontSize: 36.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      svgActionCard(
                        svgPath: 'assets/svg/shedule.svg',
                        label: 'Schedule',
                        color: const Color(0xFF04BADE),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SchedulePage()),
                          );
                        },
                      ),
                      svgActionCard(
                        svgPath: 'assets/svg/contacs.svg',
                        label: 'Contacts',
                        color: const Color(0xFFE86854),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ContactsPage()),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      imageActionCard(
                        imagePath: 'assets/images/subcription.png',
                        label: 'Subscription',
                        color: const Color(0xFF00C9C8),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SubscriptionPage()),
                          );
                        },
                      ),
                      svgActionCard(
                        svgPath: 'assets/svg/mores.svg',
                        label: 'More',
                        color: const Color(0xFFF5B13E),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MorePage()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget svgActionCard({
    required String svgPath,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 155.w,
        height: 98.h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(svgPath, width: 40.w, height: 40.w),
            SizedBox(height: 6.h),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget imageActionCard({
    required String imagePath,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 155.w,
        height: 98.h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(imagePath, fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}