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

class ResumeCheckinPage extends StatefulWidget {
  const ResumeCheckinPage({super.key});

  @override
  State<ResumeCheckinPage> createState() => _ResumeCheckinPageState();
}

class _ResumeCheckinPageState extends State<ResumeCheckinPage>
    with SingleTickerProviderStateMixin {
  String _userName = "";
  String _greeting = "";
  bool _isResumed = false; // false = Paused Mode (Red), true = Resumed Mode (Teal)
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
        AssetSource(SoloSounds.screenTakeoverNotification.replaceFirst('assets/', '')),
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

    // After action and confirmation, app screen dismisses after short period
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    });
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
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
                headlineFontSize = 34.0;
                headlineLineHeight = 40.0 / 34.0;
                mascotSize = 140.0;
                verticalGap = 8.0;
              } else if (availableHeight < 760) {
                headlineFontSize = 38.0;
                headlineLineHeight = 44.0 / 38.0;
                mascotSize = 160.0;
                verticalGap = 12.0;
              } else {
                headlineFontSize = 44.0;
                headlineLineHeight = 50.0 / 44.0;
                mascotSize = 185.0;
                verticalGap = 16.0;
              }

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: availableHeight < 720 ? 12 : 18,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (availableHeight - (availableHeight < 720 ? 24 : 36) - 76).clamp(0, double.infinity),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // ── Heading & Text Copy ──
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: headlineFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF002C3E),
                                      height: headlineLineHeight,
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
                                SizedBox(height: verticalGap),
                                const Text(
                                  "I paused your check-ins after alerting your contacts earlier, as I was concerned. Let's restart when you're ready.",
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFF5A6C7D),
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                    height: 20 / 14,
                                    letterSpacing: 0,
                                  ),
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
                                      _isResumed ? "You're All Set" : "Tap to Resume",
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
                                  SizedBox(height: verticalGap + 4),

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
                                                  builder: (_) => const SchedulePage(),
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
                                            "Edit Scedule First",
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
                "Checkin Status",
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