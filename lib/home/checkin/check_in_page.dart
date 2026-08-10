import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:solo_app/home/checkin/local_storage.dart';
import 'package:solo_app/home/notification/history_store.dart';
import 'package:solo_app/home/notification/notification_api.dart';
import 'package:solo_app/home/checkin/checkin_api.dart';
import 'package:solo_app/home/checkin/notification_service.dart';
import 'package:solo_app/core/utils/app_size.dart';

class CheckinScreen extends StatefulWidget {
  final String userName;
  final DateTime scheduledTime;
  final int alertWindowHours;

  const CheckinScreen({
    super.key,
    required this.userName,
    required this.scheduledTime,
    this.alertWindowHours = 2,
  });

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  late int remainingSeconds;
  late int totalSeconds;
  Timer? timer;

  String state = "normal"; // normal | warning | alert | waiting
  bool isSOSPending = false;
  int sosSeconds = 20;
  Timer? sosTimer;

  @override
  void initState() {
    super.initState();

    // Enable immersive full screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Lock orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _calculateRemainingTime();
    startTimer();
  }

  void _calculateRemainingTime() {
    final now = DateTime.now();
    final deadline = widget.scheduledTime.add(Duration(hours: widget.alertWindowHours));

    totalSeconds = widget.alertWindowHours * 60 * 60;

    if (now.isBefore(widget.scheduledTime)) {
      remainingSeconds = widget.scheduledTime.difference(now).inSeconds;
      state = "waiting";
    } else {
      remainingSeconds = deadline.difference(now).inSeconds;
      _updateStateByTime();
    }
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        final now = DateTime.now();
        final deadline = widget.scheduledTime.add(Duration(hours: widget.alertWindowHours));

        if (now.isBefore(widget.scheduledTime)) {
          state = "waiting";
          remainingSeconds = widget.scheduledTime.difference(now).inSeconds;
        } else {
          remainingSeconds = deadline.difference(now).inSeconds;
          _updateStateByTime();

          if (remainingSeconds <= 0) {
            state = "alert";
            remainingSeconds = 0;
            triggerAlert();
            t.cancel();
          }
        }
      });
    });
  }

  void _updateStateByTime() {
    if (state == "alert" && !isSOSPending) return;
    if (remainingSeconds <= 300) { // 5 minutes warning
      state = "warning";
    } else {
      state = "normal";
    }
  }

  Future<void> onCheckin() async {
    if (state == "waiting") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Too early to check in!")),
      );
      return;
    }

    await NotificationService.cancelAllCheckinNotifications();

    try {
      final player = AudioPlayer();
      await player.play(AssetSource('audio/checkin.mp3'));
    } catch (e) {
      print("Error playing check-in sound: $e");
    }

    await CheckinApi.confirmCheckin();
    await LocalStorage.savePreviousCheckinTime(DateTime.now());

    timer?.cancel();
    await HistoryStore.logCheckin(
      status: "CHECKED_IN",
      scheduledTime: widget.scheduledTime,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Check-in successful")),
    );

    NotificationService.isHandlingAlarm = false;
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else {
      exit(0);
    }
  }

  Future<void> triggerAlert() async {
    final contacts = await LocalStorage.getContacts();
    final contactNames = contacts
        .map((e) => e["name"] ?? "")
        .where((e) => e.trim().isNotEmpty)
        .toList();
    await HistoryStore.logCheckin(
      status: "MISSED",
      scheduledTime: widget.scheduledTime,
    );
    await HistoryStore.logAlert(
      type: "MISSED",
      contacts: contactNames,
    );
  }

  void onSOS() {
    if (!isSOSPending) {
      setState(() {
        isSOSPending = true;
        state = "alert";
      });

      sosTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() {
          sosSeconds--;
        });

        if (sosSeconds == 0) {
          t.cancel();
          resetSOS();
        }
      });
    } else {
      sosTimer?.cancel();
      triggerSosAlert();
    }
  }

  Future<void> triggerSosAlert() async {
    final contacts = await LocalStorage.getContacts();
    final contactNames = contacts
        .map((e) => e["name"] ?? "")
        .where((e) => e.trim().isNotEmpty)
        .toList();
    await NotificationApi.triggerSos();
    await HistoryStore.logAlert(
      type: "SOS",
      contacts: contactNames,
    );
    setState(() {
      state = "alert";
      isSOSPending = false;
      sosSeconds = 20;
    });
  }

  void resetSOS() {
    setState(() {
      isSOSPending = false;
      sosSeconds = 20;
      _updateStateByTime();
    });
  }

  String _formatAmPm(DateTime time) => time.hour >= 12 ? "PM" : "AM";

  String _formatTimeOnly(DateTime time) {
    int hour = time.hour % 12;
    if (hour == 0) hour = 12;
    return "$hour:${time.minute.toString().padLeft(2, "0")}";
  }

  double getProgress() {
    if (state == "waiting") return 1.0;
    return (remainingSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  String getSvg() {
    if (state == "waiting") return "assets/images/Green.svg";
    if (state == "alert" || remainingSeconds <= 0) return "assets/svg/alert.svg";

    final elapsed = totalSeconds - remainingSeconds;
    final progress = elapsed / totalSeconds;

    if (remainingSeconds <= 120) {
      // Less than 2 minutes left
      return "assets/svg/-2min.svg";
    } else if (progress >= 0.75) {
      return "assets/svg/75%1.svg";
    } else if (progress >= 0.50) {
      return "assets/svg/50%1.svg";
    } else if (progress >= 0.25) {
      return "assets/svg/25%1.svg";
    }

    // Default for the first 25% of the window
    return "assets/images/Green.svg";
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${now.day} ${months[now.month - 1]}";
  }

  @override
  void dispose() {
    NotificationService.isHandlingAlarm = false;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    timer?.cancel();
    sosTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002C3E),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 18.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today, ${_getFormattedDate()}",
                style: TextStyle(
                  color: const Color(0xFF68A8AF),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTimeOnly(widget.scheduledTime),
                    style: TextStyle(
                      color: const Color(0xFFB5D43C),
                      fontSize: 64.sp,
                      fontWeight: FontWeight.w500,
                      height: 0.95,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
                    child: Text(
                      _formatAmPm(widget.scheduledTime),
                      style: TextStyle(
                        color: const Color(0xFFB5D43C),
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                "Next Scheduled Check-in",
                style: TextStyle(
                  color: const Color(0xFF68A8AF),
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w400,
                  height: 0.95,
                ),
              ),

              SizedBox(height: 100.h),

              /// CIRCLE + BUTTON
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: -math.pi / 2,
                      child: SizedBox(
                        height: 308.w,
                        width: 308.w,
                        child: CircularProgressIndicator(
                          value: getProgress(),
                          strokeWidth: 6.w,
                          strokeCap: StrokeCap.round,
                          backgroundColor: const Color(0xFF2D6F81),
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF78AEBE)),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onCheckin,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 258.w,
                        width: 259.w,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                        ),
                        child: SvgPicture.asset(
                          getSvg(),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 18.h),

              /// TEXT
              Center(
                child: Text(
                  state == "alert"
                      ? "Your contacts have been alerted"
                      : isSOSPending
                      ? "Tap SOS again to confirm"
                      : "Check-in confirmed\nGlad you’re OK",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFD1D9E0),
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              /// TIMER
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Alert In",
                          style: TextStyle(
                            color: const Color(0xFF6DA0AF),
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${remainingSeconds ~/ 3600}",
                              style: TextStyle(
                                color: const Color(0xFF6DA0AF),
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: 6.h, left: 4.w),
                              child: Text(
                                "HR",
                                style: TextStyle(
                                  color: const Color(0xFF6DA0AF),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              "${(remainingSeconds % 3600) ~/ 60}".padLeft(2, '0'),
                              style: TextStyle(
                                color: const Color(0xFF6DA0AF),
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: 6.h, left: 4.w),
                              child: Text(
                                "MIN",
                                style: TextStyle(
                                  color: const Color(0xFF6DA0AF),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              "${remainingSeconds % 60}".padLeft(2, '0'),
                              style: TextStyle(
                                color: const Color(0xFF6DA0AF),
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: 6.h, left: 4.w),
                              child: Text(
                                "SEC",
                                style: TextStyle(
                                  color: const Color(0xFF6DA0AF),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onSOS,
                    child: Container(
                      width: 90.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8695C),
                        borderRadius: BorderRadius.circular(30.w),
                      ),
                      alignment: Alignment.center,
                      child: isSOSPending
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "S",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Container(
                            width: 26.w,
                            height: 26.w,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "$sosSeconds",
                              style: TextStyle(
                                color: const Color(0xFF002C3E),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            "S",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      )
                          : SvgPicture.asset(
                        "assets/svg/sos.svg",
                        width: 60.w,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}