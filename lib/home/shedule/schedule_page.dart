import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:solo_app/core/storage/token_storage.dart';
import 'package:solo_app/home/checkin/checkin_api.dart';
import 'package:solo_app/home/checkin/local_storage.dart';
import 'package:solo_app/home/contact/contacts_page.dart';
import 'package:solo_app/home/home_page.dart';
import 'package:solo_app/home/profile/profile_api.dart';
import 'package:solo_app/subscription/subscription_api.dart';
import 'package:solo_app/subscription/subscription_page.dart';
import 'package:solo_app/core/utils/solo_sounds.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> with SingleTickerProviderStateMixin {
  List<TimeOfDay?> checkins = [null, null];
  List<bool> enabled = [false, false];

  int maxCheckins = 0;
  int credits = 0;
  int subscriptionStatus = 0;
  int selectedAlertHour = 2; // Default to 2 hours
  String selectedVoice = "Male";
  bool _isPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  AnimationController? _waveAnimationController;
  String userName = "User";

  // Check if trial user (allowed only 1 check-in time)
  bool get isTrialUser => subscriptionStatus <= 1;

  @override
  void initState() {
    super.initState();
    loadData();
    loadSchedule();

    _waveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        final playing = state == PlayerState.playing;
        setState(() {
          _isPlaying = playing;
        });
        if (playing) {
          _waveAnimationController?.repeat(reverse: true);
        } else {
          _waveAnimationController?.stop();
          _waveAnimationController?.reset();
        }
      }
    });
  }

  Future<void> loadData() async {
    await SubscriptionApi.getSubscriptionStatus();

    subscriptionStatus = await TokenStorage.getSubscriptionStatus();
    maxCheckins = await TokenStorage.getMaxCheckins();
    credits = await TokenStorage.getCredits();
    final voice = await LocalStorage.getVoice();

    final profile = await ProfileApi.getProfile();
    if (profile != null) {
      final userMap = profile["user"] ?? profile;
      userName = userMap["name"] ?? "User";
    }

    if (mounted) {
      setState(() {
        selectedVoice = voice;
      });
    }
  }

  /// ================= SAFE BACK NAVIGATION =================
  void _handleBackNavigation() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
      );
    }
  }

  /// ================= CUSTOM TIME PICKER POPUP (FIGMA SPEC) =================
  void pickTime(int index) async {
    // Restriction: Trial users can only use the first check-in
    if (index == 1 && isTrialUser) {
      goToSubscription();
      return;
    }

    int initialHour = TimeOfDay.now().hour;
    int tempHour = initialHour % 12;
    if (tempHour == 0) tempHour = 12;
    int tempMinute = TimeOfDay.now().minute;
    String tempPeriod = initialHour >= 12 ? "PM" : "AM";

    if (checkins[index] != null) {
      final t = checkins[index]!;
      tempHour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      tempMinute = t.minute;
      tempPeriod = t.period == DayPeriod.am ? "AM" : "PM";
    }

    int selectedHourIndex = tempHour - 1;
    int selectedMinuteIndex = tempMinute;
    int selectedPeriodIndex = tempPeriod == "AM" ? 0 : 1;

    final hourController = FixedExtentScrollController(initialItem: selectedHourIndex);
    final minuteController = FixedExtentScrollController(initialItem: selectedMinuteIndex);
    final periodController = FixedExtentScrollController(initialItem: selectedPeriodIndex);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                width: 402,
                constraints: const BoxConstraints(maxWidth: 402),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8F3),
                  borderRadius: BorderRadius.circular(32),
                ),
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // HEADER
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/svg/schudel.svg',
                          width: 34,
                          height: 34,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "Set Your Check-in Time",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF002C3E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(
                      color: Color(0x808A99A6),
                      thickness: 1,
                      height: 1,
                    ),
                    const SizedBox(height: 14),

                    // WHEEL PICKER AREA
                    SizedBox(
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Two selection lines spaced exactly 44px apart
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 1,
                                margin: const EdgeInsets.symmetric(horizontal: 12),
                                color: const Color(0x808A99A6),
                              ),
                              const SizedBox(height: 44),
                              Container(
                                height: 1,
                                margin: const EdgeInsets.symmetric(horizontal: 12),
                                color: const Color(0x808A99A6),
                              ),
                            ],
                          ),

                          // ShaderMask for soft vertical fade out
                          ShaderMask(
                            shaderCallback: (rect) {
                              return const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black,
                                  Colors.black,
                                  Colors.transparent,
                                ],
                                stops: [0.0, 0.22, 0.78, 1.0],
                              ).createShader(rect);
                            },
                            blendMode: BlendMode.dstIn,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // HOURS
                                _timeColumn(
                                  count: 12,
                                  selectedIndex: selectedHourIndex,
                                  controller: hourController,
                                  onChanged: (val) {
                                    setModalState(() {
                                      selectedHourIndex = val % 12;
                                      tempHour = selectedHourIndex + 1;
                                    });
                                  },
                                  isHour: true,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    " : ",
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 28,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF002C3E),
                                    ),
                                  ),
                                ),
                                // MINUTES
                                _timeColumn(
                                  count: 60,
                                  selectedIndex: selectedMinuteIndex,
                                  controller: minuteController,
                                  onChanged: (val) {
                                    setModalState(() {
                                      selectedMinuteIndex = val % 60;
                                      tempMinute = selectedMinuteIndex;
                                    });
                                  },
                                  isHour: false,
                                ),
                                const SizedBox(width: 14),
                                // AM / PM
                                SizedBox(
                                  width: 64,
                                  height: 200,
                                  child: ListWheelScrollView(
                                    itemExtent: 44,
                                    physics: const FixedExtentScrollPhysics(),
                                    controller: periodController,
                                    onSelectedItemChanged: (i) {
                                      setModalState(() {
                                        selectedPeriodIndex = i;
                                        tempPeriod = i == 0 ? "AM" : "PM";
                                      });
                                    },
                                    children: [
                                      _periodText("AM", isSelected: selectedPeriodIndex == 0),
                                      _periodText("PM", isSelected: selectedPeriodIndex == 1),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // BUTTONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 110,
                          height: 42,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF002C3E),
                              side: const BorderSide(
                                color: Color(0xFF002C3E),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        SizedBox(
                          width: 110,
                          height: 42,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF002C3E),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () async {
                              int finalHour = tempHour;
                              if (tempPeriod == "PM" && finalHour < 12) finalHour += 12;
                              if (tempPeriod == "AM" && finalHour == 12) finalHour = 0;
                              final time = TimeOfDay(hour: finalHour, minute: tempMinute);
                              setState(() {
                                checkins[index] = time;
                                enabled[index] = true;
                              });
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Confirm",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _timeColumn({
    required int count,
    required int selectedIndex,
    required FixedExtentScrollController controller,
    required Function(int) onChanged,
    bool isHour = true,
  }) {
    return SizedBox(
      width: 54,
      child: ListWheelScrollView.useDelegate(
        itemExtent: 44,
        physics: const FixedExtentScrollPhysics(),
        controller: controller,
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildLoopingListDelegate(
          children: List.generate(count, (index) {
            String val = isHour ? (index + 1).toString() : index.toString().padLeft(2, '0');
            return _pickerText(val, isSelected: index == selectedIndex);
          }),
        ),
      ),
    );
  }

  Widget _pickerText(String text, {bool isSelected = false}) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: isSelected ? 32 : 22,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          color: isSelected ? const Color(0xFF002C3E) : const Color(0xFF8A99A6),
          height: 1.0,
        ),
      ),
    );
  }

  Widget _periodText(String text, {bool isSelected = false}) {
    return Center(
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: isSelected ? 20 : 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? const Color(0xFF002C3E) : const Color(0xFF8A99A6),
          height: 1.0,
        ),
      ),
    );
  }

  /// ================= FORMAT TIME =================
  String formatTime(TimeOfDay? time) {
    if (time == null) return "No check-in time set";
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute $period";
  }

  /// ================= SOUND WAVE ANIMATION BUILDER =================
  Widget _buildSoundWave(bool isPlaying, double animValue) {
    const baseHeights = [18.0, 25.0, 19.0, 31.0, 12.0];
    const minHeights = [8.0, 12.0, 9.0, 14.0, 6.0];
    const maxHeights = [28.0, 38.0, 30.0, 42.0, 22.0];

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(5, (i) {
        double height;
        if (!isPlaying) {
          height = baseHeights[i];
        } else {
          final phase = i * (math.pi / 2.5);
          final sinVal = (math.sin(animValue * 2 * math.pi + phase) + 1) / 2;
          height = minHeights[i] + (maxHeights[i] - minHeights[i]) * sinVal;
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2.2),
          width: 4.8,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2.5),
          ),
        );
      }),
    );
  }

  /// ================= CHECK-IN TILE =================
  Widget checkinTile(int index) {
    final isInactive = (index == 1 && isTrialUser);

    return Opacity(
      opacity: isInactive ? 0.45 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF76BDCB),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  "${index + 1}",
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: isInactive ? goToSubscription : () => pickTime(index),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Check-in Time",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: Color(0xFF5A6C7D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatTime(checkins[index]),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: checkins[index] != null ? const Color(0xFF002C3E) : const Color(0xFF8A99A6),
                        fontSize: checkins[index] != null ? 17 : 14,
                        fontWeight: checkins[index] != null ? FontWeight.w500 : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: isInactive ? goToSubscription : () => pickTime(index),
              child: SvgPicture.asset(
                'assets/svg/plus.svg',
                width: 28,
                height: 28,
              ),
            ),
            const SizedBox(width: 8),
            customSwitch(
              value: !isInactive && enabled[index],
              onChanged: (val) async {
                if (isInactive) {
                  goToSubscription();
                  return;
                }

                setState(() {
                  enabled[index] = val;
                });
              },
            ),
          ],
        ),
      ),
    );
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
        backgroundColor: const Color(0xFFF7F8F3),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // BIG HEADLINE: Inter, 600, 44px, line-height 50px (#002C3E), break after 'your'
                      const Text(
                        "Set your\ndaily check-in\nschedule",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 44,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF002C3E),
                          height: 50 / 44,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Schedule up to 2 preferred check-in times daily.\n I'll be there to check on you, and you can change\n or pause reminders anytime.",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF5A6C7D),
                          height: 1.45,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 1px stroke, 50% opacity #8A99A6
                      const Divider(height: 1, thickness: 1, color: Color(0x808A99A6)),
                      checkinTile(0),
                      const Divider(height: 1, thickness: 1, color: Color(0x808A99A6)),
                      checkinTile(1),
                      const Divider(height: 1, thickness: 1, color: Color(0x808A99A6)),
                      const SizedBox(height: 16),
                      const Text(
                        "Send alert after missed check-in",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF5A6C7D),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          customRadio(1, selectedAlertHour, (val) => setState(() => selectedAlertHour = val!)),
                          const SizedBox(width: 8),
                          const Text("1 Hour", style: TextStyle(fontFamily: 'Inter', color: Color(0xFF5A6C7D), fontSize: 14)),
                          const SizedBox(width: 24),
                          customRadio(2, selectedAlertHour, (val) => setState(() => selectedAlertHour = val!)),
                          const SizedBox(width: 8),
                          const Text("2 Hours (Default)", style: TextStyle(fontFamily: 'Inter', color: Color(0xFF5A6C7D), fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, thickness: 1, color: Color(0x808A99A6)),
                      const SizedBox(height: 16),

                      // VOICE SELECTION SECTION (Icon height matches section via IntrinsicHeight)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 72,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8705B),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: AnimatedBuilder(
                                  animation: _waveAnimationController!,
                                  builder: (context, child) {
                                    return _buildSoundWave(_isPlaying, _waveAnimationController!.value);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      RichText(
                                        text: const TextSpan(
                                          text: "Voice ",
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            color: Color(0xFF5A6C7D),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: "(Optional)",
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                color: Color(0xFF5A6C7D),
                                                fontWeight: FontWeight.normal,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: _playVoice,
                                        child: Row(
                                          children: [
                                            Icon(
                                              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                              color: const Color(0xFFE8705B),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              _isPlaying ? "Pause" : "Play",
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                color: Color(0xFF5A6C7D),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "Choose a voice for your check-in reminder",
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: Color(0xFF5A6C7D),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      customRadioString(
                                        "Male",
                                        selectedVoice,
                                        (val) => setState(() => selectedVoice = val!),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text("Male", style: TextStyle(fontFamily: 'Inter', color: Color(0xFF5A6C7D), fontSize: 12)),
                                      const SizedBox(width: 16),
                                      customRadioString(
                                        "Female",
                                        selectedVoice,
                                        (val) => setState(() => selectedVoice = val!),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text("Female", style: TextStyle(fontFamily: 'Inter', color: Color(0xFF5A6C7D), fontSize: 12)),
                                      const SizedBox(width: 16),
                                      customRadioString(
                                        "None",
                                        selectedVoice,
                                        (val) => setState(() => selectedVoice = val!),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text("None", style: TextStyle(fontFamily: 'Inter', color: Color(0xFF5A6C7D), fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, thickness: 1, color: Color(0x808A99A6)),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // BOTTOM NAVIGATION BAR
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                color: Colors.transparent,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _handleBackNavigation,
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF5A6C7D), size: 26),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const Spacer(),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        final activeTimes = checkins
                            .asMap()
                            .entries
                            .where((entry) => enabled[entry.key] && entry.value != null)
                            .map((entry) => entry.value!)
                            .toList();

                        if (activeTimes.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please select and enable at least one check-in"),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        try {
                          final minutes = activeTimes
                              .map((time) => (time.hour * 60) + time.minute)
                              .toList()
                            ..sort();

                          await LocalStorage.saveScheduleMinutes(minutes);
                          await LocalStorage.saveAlertWindowHours(selectedAlertHour);
                          await LocalStorage.saveVoice(selectedVoice);
                          await LocalStorage.saveUserName(userName);

                          final List<String> formattedTimes = activeTimes.map((t) {
                            return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
                          }).toList();
                          await CheckinApi.saveCheckinTimes(formattedTimes);

                          if (!mounted) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ContactsPage(),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error saving schedule: $e")),
                          );
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Next",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: checkins.asMap().entries.any((e) => enabled[e.key] && e.value != null)
                                  ? const Color(0xFF002C3E)
                                  : const Color(0xFF002C3E).withValues(alpha: 0.3),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Opacity(
                            opacity: checkins.asMap().entries.any((e) => enabled[e.key] && e.value != null)
                                ? 1.0
                                : 0.3,
                            child: SvgPicture.asset(
                              'assets/svg/nextbutton.svg',
                              width: 60,
                              height: 60,
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
    );
  }

  Widget customRadio(int value, int groupValue, Function(int?) onChanged) {
    bool isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFD1DDE3),
            width: 2,
          ),
        ),
        child: isSelected
            ? Center(
          child: Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Color(0xFF76BDCB),
              shape: BoxShape.circle,
            ),
          ),
        )
            : null,
      ),
    );
  }

  Widget customRadioString(String value, String groupValue, Function(String?) onChanged) {
    bool isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFD1DDE3),
            width: 2,
          ),
        ),
        child: isSelected
            ? Center(
          child: Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Color(0xFF76BDCB),
              shape: BoxShape.circle,
            ),
          ),
        )
            : null,
      ),
    );
  }

  Widget customSwitch({required bool value, required Function(bool) onChanged}) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: value ? const Color(0xFFB5D43C) : const Color(0xFFD1DBE0),
        ),
        padding: const EdgeInsets.all(2),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void goToSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SubscriptionPage(),
      ),
    );
  }

  Future<void> loadSchedule() async {
    final saved = await LocalStorage.getSchedule();
    if (saved != null) {
      DateTime time = DateTime.parse(saved);
      setState(() {
        checkins[0] = TimeOfDay(hour: time.hour, minute: time.minute);
        enabled[0] = true;
      });
    }
  }

  void _playVoice() async {
    if (selectedVoice == "None") {
      if (_isPlaying) {
        await _audioPlayer.stop();
      }
      return;
    }

    if (_isPlaying) {
      await _audioPlayer.pause();
      return;
    }

    String assetPath;
    if (selectedVoice == "Male") {
      assetPath = SoloSounds.voiceSample("Male").replaceFirst('assets/', '');
    } else {
      assetPath = SoloSounds.voiceSample("Female").replaceFirst('assets/', '');
    }

    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource(assetPath));
  }

  @override
  void dispose() {
    _waveAnimationController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}