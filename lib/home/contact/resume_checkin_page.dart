import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:solo_app/core/utils/app_size.dart';
import 'package:solo_app/core/utils/solo_sounds.dart';
import 'package:solo_app/home/checkin/local_storage.dart';
import 'package:solo_app/home/checkin/notification_service.dart';
import 'package:solo_app/home/home_page.dart';
import 'package:solo_app/home/shedule/schedule_page.dart';
import 'package:solo_app/widgets/solo_turquoise_animation.dart';
import 'package:solo_app/core/widgets/solo_toast.dart';

class ResumeCheckinPage extends StatefulWidget {
  const ResumeCheckinPage({super.key});

  @override
  State<ResumeCheckinPage> createState() => _ResumeCheckinPageState();
}

class _ResumeCheckinPageState extends State<ResumeCheckinPage>
    with SingleTickerProviderStateMixin {
  String _userName = "";
  String _greeting = "";
  bool _isResumed =
      false; // false = Paused Mode (Red), true = Resumed Mode (Teal)
  bool _isDismissing = false;
  DateTime? _nextCheckinTime;
  DateTime? _previousCheckinTime;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _setGreeting();
    _loadUser();
    _loadNextTime();
    _loadPreviousCheckinTime();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) {
      _greeting = "Morning";
    } else if (hour >= 12 && hour < 17) {
      _greeting = "Afternoon";
    } else {
      _greeting = "Evening";
    }
  }

  Future<void> _loadUser() async {
    final name = await LocalStorage.getUserName();
    if (mounted) {
      setState(() {
        _userName = name;
      });
    }
  }

  Future<void> _loadNextTime() async {
    final due = await NotificationService.resolveNextDueTime();
    if (mounted) {
      setState(() {
        _nextCheckinTime = due;
      });
    }
  }

  Future<void> _loadPreviousCheckinTime() async {
    final prev = await LocalStorage.getPreviousCheckinTime();
    if (mounted) {
      setState(() {
        _previousCheckinTime = prev;
      });
    }
  }

  String get _lastCheckinDisplay => "11:00 PM";

  String _formatTime(DateTime? time) {
    if (time == null) return "--:-- --";
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final min = time.minute.toString().padLeft(2, '0');
    final ampm = time.hour >= 12 ? "PM" : "AM";
    return "$hour:$min $ampm";
  }

  Future<void> _playSound() async {
    try {
      final player = AudioPlayer();
      await player.play(
        AssetSource(
            SoloSounds.screenTakeoverNotification.replaceFirst('assets/', '')),
      );
    } catch (e) {
      debugPrint("⚠️ Error playing takeover sound: $e");
    }
  }

  Future<void> _onResumeTapped() async {
    if (_isResumed || _isDismissing) return;

    await _playSound();

    setState(() {
      _isResumed = true;
      _isDismissing = true;
    });

    await _resumeCheckinFlow();

    // After action and confirmation, dismiss seamlessly into HomePage
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomePage(),
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity:
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                child: child,
              );
            },
          ),
          (route) => false,
        );
      }
    });
  }

  void _handleBackNavigation() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomePage(),
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity:
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              child: child,
            );
          },
        ),
      );
    }
  }

  Future<void> _resumeCheckinFlow() async {
    final alertWindowHours = await LocalStorage.getAlertWindowHours();
    final dueTime = await NotificationService.resolveNextDueTime();
    if (dueTime == null) {
      if (!mounted) return;
      SoloToast.show(
        context,
        "Please set schedule first.",
        isDark: true,
      );
      return;
    }
    await LocalStorage.savePreviousCheckinTime(null);
    if (mounted) {
      setState(() {
        _previousCheckinTime = null;
      });
    }

    await LocalStorage.saveSchedule(dueTime.toIso8601String());
    await NotificationService.scheduleMissedCheckinFlow(
      dueTime: dueTime,
      alertWindowHours: alertWindowHours,
    );

    _loadNextTime();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9F5),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight = constraints.maxHeight;

              // Responsive scaling for single-screen fit across different device heights
              final double headlineFontSize;
              final double headlineLineHeight;
              final double mascotSize;
              final double verticalGap;

              if (availableHeight < 680) {
                headlineFontSize = 32.0;
                headlineLineHeight = 1.1;
                mascotSize = 150.0;
                verticalGap = 8.0;
              } else if (availableHeight < 760) {
                headlineFontSize = 36.0;
                headlineLineHeight = 1.1;
                mascotSize = 180.0;
                verticalGap = 12.0;
              } else {
                headlineFontSize = 40.0;
                headlineLineHeight = 1.1;
                mascotSize = 210.0;
                verticalGap = 14.0;
              }

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: availableHeight < 720 ? 10 : 16,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (availableHeight -
                                  (availableHeight < 720 ? 20 : 32) -
                                  76)
                              .clamp(0, double.infinity),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // ── Heading & Text Copy ──
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (Navigator.canPop(context)) ...[
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: _handleBackNavigation,
                                    child: const Padding(
                                      padding: EdgeInsets.only(bottom: 12),
                                      child: Icon(
                                        Icons.arrow_back,
                                        color: Color(0xFF5A6C7D),
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                ],
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    double screenWidth = MediaQuery.of(context).size.width;

                                    // Screen ke size ke hisaab se font size aur vertical spacing ko dynamic banana
                                    // (Aap apne existing variables 'headlineFontSize' aur 'verticalGap' ki jagah inko use kar sakte hain)
                                    double dynamicFontSize = screenWidth < 360 ? 28 : (headlineFontSize ?? 34);
                                    double dynamicGap = screenWidth < 360 ? 12 : (verticalGap ?? 16);

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start, // Left alignment hamesha fix rakhne ke liye
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              color: const Color(0xFF002C3E),
                                              fontSize: dynamicFontSize,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0,
                                              height: headlineLineHeight ?? 1.2,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: _userName.isNotEmpty
                                                    ? "$_greeting\n$_userName,\nready to\nresume your\ncheck-ins?"
                                                    : "$_greeting,\nready to\nresume your\ncheck-ins?",
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: dynamicGap),
                                        Text(
                                          "I paused your check-ins after alerting your contacts\nearlier, as I was concerned. Let's restart when\nyou're ready.",
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            color: const Color(0xFF5A6C7D),
                                            fontWeight: FontWeight.w400,
                                            // Chote phones par subtitle bhi thoda adjust ho sake
                                            fontSize: screenWidth < 360 ? 13 : 14,
                                            height: 1.45,
                                            letterSpacing: 0,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),

                            // ── Center: Animated Mascot & Actions ──
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ScaleTransition(
                                    scale: _pulseAnim,
                                    child: GestureDetector(
                                      onTap: _onResumeTapped,
                                      child: SoloMascotAnimation(
                                        size: mascotSize,
                                        isRed: !_isResumed,
                                        lookUpRight: _isResumed,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: verticalGap),

                                  // "Tap to Resume" / "You're All Set"
                                  GestureDetector(
                                    onTap: _onResumeTapped,
                                    behavior: HitTestBehavior.opaque,
                                    child: Text(
                                      _isResumed
                                          ? "You're All Set"
                                          : "Tap to Resume",
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: _isResumed
                                            ? const Color(0xFF8A99A6)
                                            : const Color(0xFF5A6C7D),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: verticalGap + 2),

                                  // "Edit Schedule First"
                                  Opacity(
                                    opacity: _isResumed ? 0.4 : 1.0,
                                    child: GestureDetector(
                                      onTap: _isResumed
                                          ? null
                                          : () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const SchedulePage(),
                                                ),
                                              ).then((_) => _loadNextTime());
                                            },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SvgPicture.asset(
                                            'assets/svg/Edit.svg',
                                            width: 20,
                                            height: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            "Edit Schedule First",
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Color(0xFF5A6C7D),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Bottom status pill ──
                  _buildBottomPill(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPill() {
    final lastDisplay = _previousCheckinTime != null
        ? _formatTime(_previousCheckinTime)
        : _lastCheckinDisplay;
    final nextDisplay = _formatTime(_nextCheckinTime);
    final timeStr = _isResumed ? nextDisplay : lastDisplay;
    final parts = timeStr.split(" ");
    final timeDigits = parts.isNotEmpty ? parts[0] : "--:--";
    final timeAmPm = parts.length > 1 ? parts[1] : "";

    return Container(
      margin: EdgeInsets.fromLTRB(16, 4, 16, AppSize.bottom(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF002C3E),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Checkin Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Check-in Status",
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFFA8B6C2),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _isResumed ? "Resumed" : "Paused",
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFFF5F5F5),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // Last / Next check-in time
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isResumed ? "Next" : "Last",
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFFA8B6C2),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: timeDigits,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFFF5F5F5),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (timeAmPm.isNotEmpty)
                      TextSpan(
                        text: " $timeAmPm",
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFFF5F5F5),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],

          ),
        ],
      ),
    );
  }
}
