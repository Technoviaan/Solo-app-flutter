import 'package:flutter/material.dart';
import 'package:solo_app/home/home_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:solo_app/core/utils/app_size.dart';
import 'package:solo_app/home/checkin/local_storage.dart';
import 'package:solo_app/home/checkin/notification_service.dart';
import 'package:solo_app/home/shedule/schedule_page.dart';

class ResumeCheckinPage extends StatefulWidget {
  const ResumeCheckinPage({super.key});

  @override
  State<ResumeCheckinPage> createState() => _ResumeCheckinPageState();
}

class _ResumeCheckinPageState extends State<ResumeCheckinPage>
    with SingleTickerProviderStateMixin {
  String _userName = "";
  String _greeting = "";
  bool _isResumed = false; // false = Paused (Red), true = Resumed (Teal)
  DateTime? _nextCheckinTime;
  DateTime? _previousCheckinTime;

  // Subtle pulse animation for the big button
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

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
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
    if (hour < 12) {
      _greeting = "Good morning";
    } else if (hour < 17) {
      _greeting = "Good afternoon";
    } else {
      _greeting = "Good evening";
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

  // Last check-in time (placeholder)
  String get _lastCheckinDisplay => "11:00 PM";

  String _formatTime(DateTime? time) {
    if (time == null) return "--:-- --";
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final min = time.minute.toString().padLeft(2, '0');
    final ampm = time.hour >= 12 ? "PM" : "AM";
    return "$hour:$min $ampm";
  }

  Future<void> _resumeCheckinFlow() async {
    final alertWindowHours = await LocalStorage.getAlertWindowHours();
    final dueTime = await NotificationService.resolveNextDueTime();
    if (dueTime == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please set schedule first.")),
      );
      return;
    }
    // Delete previous check-in time when a new check-in is scheduled!
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

    // We stay on this screen to show "You're All Set" as per the user's image
    _loadNextTime();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9F5),
        body: SafeArea(
          child: Column(
            children: [
              // ── Scrollable body ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Heading ──
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF002C3E),
                            height: 1.15,
                            letterSpacing: -0.5,
                          ),
                          children: [
                            TextSpan(text: _greeting),
                            if (_userName.isNotEmpty)
                              TextSpan(text: " $_userName,"),
                            const TextSpan(
                              text: "\nready to\nresume your\ncheck-ins?",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Subtitle ──
                      const Text(
                        "I paused your check-ins after alerting your contacts "
                            "earlier, as I was concerned. Let's restart when "
                            "you're ready.",
                        style: TextStyle(
                          color: Color(0xFF5A6C7D),
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // ── Big Red SOLO Eye button ──
                      Center(
                        child: Column(
                          children: [
                            ScaleTransition(
                              scale: _pulseAnim,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _isResumed = !_isResumed);
                                  if (!_isResumed) {
                                    NotificationService
                                        .cancelAllCheckinNotifications();
                                  } else {
                                    _resumeCheckinFlow();
                                  }
                                },
                                child: SvgPicture.asset(
                                  _isResumed
                                      ? 'assets/images/Green.svg'
                                      : 'assets/images/Red.svg',
                                  width: 214,
                                  height: 214,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // "Tap to Resume" / "Check-ins Active"
                            Text(
                              _isResumed ? "You're All Set" : "Tap to Resume",
                              style: TextStyle(
                                color: _isResumed
                                    ? const Color(0xFF8A99A6)
                                    : const Color(0xFF5A6C7D),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 25),

                            // "Edit Schedule First"
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const SchedulePage()),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(
                                    'assets/svg/Edit.svg',
                                    width: 22.w,
                                    height: 22.w,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Edit Scedule First",
                                    style: TextStyle(
                                      color: Color(0xFF5A6C7D),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Bottom status bar ──
              Container(
                margin: EdgeInsets.fromLTRB(16, 0, 16, AppSize.bottom(14)),
                padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
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
                      children: [
                        const Text(
                          "Checkin Status",
                          style: TextStyle(
                            color: Color(0xFFA8B6C2),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        //const SizedBox(height: 4),
                        Text(
                          _isResumed ? "Resumed" : "Paused",
                          style: const TextStyle(
                            color: Color(0xFFF5F5F5),
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // // Vertical divider
                    // Container(
                    //   width: 1,
                    //   height: 44,
                    //   color: Colors.white24,
                    // ),

                    // Last check-in time
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isResumed ? "Next" : "Last",
                          style: const TextStyle(
                            color: Color(0xFFA8B6C2),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: (_isResumed
                                    ? _formatTime(_nextCheckinTime)
                                    : (_previousCheckinTime != null
                                    ? _formatTime(_previousCheckinTime)
                                    : _lastCheckinDisplay))
                                    .split(" ")[0],
                                style: const TextStyle(
                                  color: Color(0xFFF5F5F5),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text:
                                " ${(_isResumed ? _formatTime(_nextCheckinTime) : (_previousCheckinTime != null ? _formatTime(_previousCheckinTime) : _lastCheckinDisplay)).split(" ")[1]}",
                                style: const TextStyle(
                                  color: Color(0xFFF5F5F5),
                                  fontSize: 16,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}