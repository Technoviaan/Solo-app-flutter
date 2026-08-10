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
    _checkBatteryOptimization();
  }

  Future<void> _checkBatteryOptimization() async {
    // Check Battery Optimization
    final isIgnored = await Permission.ignoreBatteryOptimizations.isGranted;
    if (!isIgnored && mounted) {
      _showPermissionSnackBar(
        "Please disable battery optimization for SOLO to ensure alarms work properly.",
        openBatteryOptimizationSettings,
      );
    }

    // Check Exact Alarm (Android 12+)
    final isExactAlarmGranted = await Permission.scheduleExactAlarm.isGranted;
    if (!isExactAlarmGranted && mounted) {
      _showPermissionSnackBar(
        "Please allow 'Alarms & reminders' for SOLO to ensure timely alerts.",
            () => openAppSettings(),
      );
    }

    // Check Overlay Permission (for auto-opening screen)
    final isOverlayGranted = await Permission.systemAlertWindow.isGranted;
    if (!isOverlayGranted && mounted) {
      _showPermissionSnackBar(
        "Please allow 'Display over other apps' to open the alarm screen automatically.",
            () => openAppSettings(),
      );
    }
  }

  void _showPermissionSnackBar(String message, VoidCallback onAction) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: "Settings",
          onPressed: onAction,
        ),
      ),
    );
  }

  Future<void> loadUser() async {
    // Load from local storage first for immediate display
    final localName = await TokenStorage.getUserName();
    if (mounted) {
      setState(() {
        userName = localName;
      });
    }

    // Then update from API
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
    if (hour < 12) {
      return "Good morning";
    } else if (hour < 17) {
      return "Good afternoon";
    } else {
      return "Good evening";
    }
  }

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F5), // Light gray/off-white bottom
      body: Column(
        children: [
          // TOP SECTION (NAVY WITH CURVE)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 76, // Exact Figma top
              left: 28, // Exact Figma left
              right: 30,
              bottom: 40,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF002C3E),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(100),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SoloLogoWidget(size: 74),
                SizedBox(height: AppSize.h(90)),
                Text(
                  userName.isNotEmpty ? "$_greeting,\n$userName" : "$_greeting,",
                  style: const TextStyle(
                    color: Color(0xFF78BCC4), // Teal color from design
                    fontSize: 44,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
                const Text(
                  "How can we\nsupport you\ntoday?",
                  style: TextStyle(
                    color: Color(0xFF78BCC4),
                    fontSize: 44,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              padding: EdgeInsets.fromLTRB(AppSize.w(24), 20, AppSize.w(24), 0),
              child: Column(
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
                            MaterialPageRoute(
                                builder: (_) => const SchedulePage()),
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
                            MaterialPageRoute(
                                builder: (_) => const ContactsPage()),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: AppSize.h(6)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      imageActionCard(
                        imagePath: 'assets/images/subcription.png',
                        label: 'Subscription',
                        color: const Color(0xFF00C9C8), // Matching cyan color
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SubscriptionPage()),
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

  /// Card with rounded container + centered SVG icon + label text below it.
  Widget svgActionCard({
    required String svgPath,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppSize.w(160),
        height: AppSize.h(105),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              svgPath,
              width: AppSize.w(44),
              height: AppSize.w(44),
            ),
            SizedBox(height: AppSize.h(8)),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
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
        width: AppSize.w(160),
        height: AppSize.h(105),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: AppSize.w(44),
              height: AppSize.w(44),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover, // Image bina kisi extra padding ke circle me fully fit hogi
                ),
              ),
            ),
            SizedBox(height: AppSize.h(8)), // Schedule card ke exact same height gap (8)
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

}