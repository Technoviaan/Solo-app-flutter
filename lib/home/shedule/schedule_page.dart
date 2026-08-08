import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:solo_app/core/storage/token_storage.dart';
import 'package:solo_app/core/utils/app_size.dart';
import 'package:solo_app/home/checkin/check_in_page.dart';
import 'package:solo_app/home/checkin/local_storage.dart';
import 'package:solo_app/home/checkin/notification_service.dart';
import 'package:solo_app/home/checkin/checkin_api.dart';
import 'package:solo_app/home/contact/contacts_page.dart';
import 'package:solo_app/home/profile/profile_api.dart';
import 'package:solo_app/subscription/subscription_page.dart';
import 'package:audioplayers/audioplayers.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<TimeOfDay?> checkins = [null, null];
  List<bool> enabled = [false, false];

  int maxCheckins = 0;
  int credits = 0;
  int subscriptionStatus = 0;
  int selectedAlertHour = 2; // Default to 2 hours
  String selectedVoice = "Male";
  bool _isPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    loadData();
    loadSchedule();
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  Future<void> loadData() async {
    subscriptionStatus = await TokenStorage.getSubscriptionStatus();
    maxCheckins = await TokenStorage.getMaxCheckins();
    credits = await TokenStorage.getCredits();
    final voice = await LocalStorage.getVoice();
    
    final profile = await ProfileApi.getProfile();
    if (profile != null) {
      final userMap = profile["user"] ?? profile;
      userName = userMap["name"] ?? "User";
    }
    
    setState(() {
      selectedVoice = voice;
    });
  }

  String userName = "User";

  /// ================= CUSTOM TIME PICKER =================
  void pickTime(int index) async {
    // Restriction: 7-day trial users (Status 1) can only use the first check-in
    if (index == 1 && subscriptionStatus == 1) {
      goToSubscription();
      return;
    }

    int initialHour = TimeOfDay.now().hour;
    int tempHour = initialHour % 12;
    if (tempHour == 0) tempHour = 12;
    int tempMinute = TimeOfDay.now().minute;
    String tempPeriod = initialHour >= 12 ? "PM" : "AM";

    int selectedHourIndex = tempHour - 1;
    int selectedMinuteIndex = tempMinute;
    int selectedPeriodIndex = tempPeriod == "AM" ? 0 : 1;

    final hourController = FixedExtentScrollController(initialItem: selectedHourIndex);
    final minuteController = FixedExtentScrollController(initialItem: selectedMinuteIndex);
    final periodController = FixedExtentScrollController(initialItem: selectedPeriodIndex);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 440,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 24),
              child: Column(
                children: [
                  // HEADER
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          //color: Color(0xFFE0F2F1), // Light teal background
                          //shape: BoxShape.circle, 
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/svg/schudel.svg',
                            width: 36,
                            height: 36,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        "Set Your Check-in Time",
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF002C3E), 
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Divider(color: Color(0xFF8A99A6), thickness: 1),
                  
                  // WHEEL PICKER AREA
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Selection Indicators (Dark Navy Lines)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(height: 1.2, color: Color(0xFF8A99A6)),
                            const SizedBox(height: 60),
                            Container(height: 1.2, color: Color(0xFF8A99A6)),
                          ],
                        ),
                        // THE PICKER
                        ShaderMask(
                          shaderCallback: (rect) {
                            return const LinearGradient( 
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xFF8A99A6),Color(0xFF8A99A6), Colors.transparent],
                              stops: [0.0, 0.2, 0.8, 1.0],
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
                              const Text(" : ", style: TextStyle(fontSize: 34, fontWeight: FontWeight.w400, color: Color(0xFF002C3E))),
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
                              const SizedBox(width: 15),
                              // PERIOD
                              SizedBox(
                                width: 70,
                                height: 180, // Explicit height for the picker
                                child: ListWheelScrollView(
                                  itemExtent: 60,
                                  physics: const FixedExtentScrollPhysics(),
                                  controller: periodController,
                                  onSelectedItemChanged: (i) {
                                    setModalState(() {
                                      selectedPeriodIndex = i;
                                      tempPeriod = i == 0 ? "AM" : "PM";
                                    });
                                  },
                                  children: [
                                    _pickerText("AM", isSelected: selectedPeriodIndex == 0),
                                    _pickerText("PM", isSelected: selectedPeriodIndex == 1),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // BUTTONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cancel — outlined
                      SizedBox(
                        width: AppSize.w(111),
                        height: AppSize.h(46),
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF002C3E),
                            side: const BorderSide(
                              color: Color(0xFF002C3E),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: AppSize.w(12)),

                      // Confirm — filled navy
                      SizedBox(
                        width: AppSize.w(111),
                        height: AppSize.h(46),
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
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
      width: 60,
      child: ListWheelScrollView.useDelegate(
        itemExtent: 60,
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
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        style: TextStyle(
          fontSize: isSelected ? 42 : 30,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          color: isSelected ? const Color(0xFF002C3E) : const Color(0xFF8A99A6),
        ),
        child: Text(text),
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

  /// ================= CHECK-IN TILE =================
  Widget checkinTile(int index) {
    return Container(
      //margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.only(left: 0, right: 0, top: 14, bottom: 14),
      decoration: BoxDecoration(
       // color: (index == 1 && subscriptionStatus == 1) ? Colors.black.withOpacity(0.02) : Colors.transparent,
        //borderRadius: BorderRadius.circular(16),
       // border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF76BDCB), // Teal color from design
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "${index + 1}",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Check-in Time",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF5A6C7D),
                  ),
                ),
                Text(
                  formatTime(checkins[index]),
                  style: const TextStyle(
                    color: Color(0xFF8A99A6), // Lighter gray for placeholder/result
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // const SizedBox(width: 8),
          GestureDetector(
            onTap: () => pickTime(index),
            child: (index == 1 && subscriptionStatus == 1)
                ? const Icon(Icons.lock, color: Colors.black26, size: 28)
                : SvgPicture.asset(
                    'assets/svg/plus.svg',
                    width: 28.w,
                    height: 28.w,
                  ),
          ),
          const SizedBox(width: 8),
          customSwitch(
            value: enabled[index],
            onChanged: (val) async {
              // Restriction: 7-day trial users (Status 1) can only use the first check-in
              if (val && index == 1 && subscriptionStatus == 1) {
                goToSubscription();
                return;
              }
              
              if (val) {
                // If turning ON, open picker
                pickTime(index);
              } else {
                // If turning OFF, just update state
                setState(() {
                  enabled[index] = false;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F5),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 27.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Set your\ndaily check-in\nschedule",
                      style: TextStyle(
                        fontSize: 44.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF002C3E),
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      "Schedule up to 2 preferred check-in times daily. I'll be there to check on you, and you can change or pause reminders anytime.",
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(0xFF5A6C7D),
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    const Divider(height: 1, color: Color(0xFF8A99A6)),
                    checkinTile(0),
                    const Divider(height: 1, color:Color(0xFF8A99A6)),
                    checkinTile(1),
                    const Divider(height: 1, color: Color(0xFF8A99A6)),

                    SizedBox(height: 16.h),
                    Text(
                      "Send alert after missed check-in", 
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF5A6C7D),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        customRadio(1, selectedAlertHour, (val) => setState(() => selectedAlertHour = val!)),
                        SizedBox(width: 8.w),
                        Text("1 Hour", style: TextStyle(color: const Color(0xFF5A6C7D), fontSize: 14.sp)),
                        SizedBox(width: 24.w),
                        customRadio(2, selectedAlertHour, (val) => setState(() => selectedAlertHour = val!)),
                        SizedBox(width: 8.w),
                        Text("2 Hours (Default)", style: TextStyle(color: const Color(0xFF5A6C7D), fontSize: 14.sp)),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    const Divider(height: 1, color: Color(0xFF8A99A6)),

                    SizedBox(height: 15.h),
                    // VOICE SELECTION SECTION
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 73.w,
                          height: 73.w,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8705B),
                            borderRadius: BorderRadius.circular(16.w),
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/svg/play.svg',
                              width: 32.w,
                              height: 32.w,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 13.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      text: "Voice ",
                                      style: TextStyle(
                                        color: const Color(0xFF5A6C7D),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.sp,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: "(Optional)",
                                          style: TextStyle(
                                            color: const Color(0xFF5A6C7D),
                                            fontWeight: FontWeight.normal,
                                            fontSize: 12.sp,
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
                                          size: 20.sp,
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          _isPlaying ? "Pause" : "Play",
                                          style: TextStyle(color: const Color(0xFF5A6C7D), fontSize: 14.sp),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 5.h),
                              Text(
                                "Choose a voice for your check-in reminder",
                                style: TextStyle(color: const Color(0xFF5A6C7D), fontSize: 12.sp),
                              ),
                              SizedBox(height: 5.h),
                              Row(
                                children: [
                                  customRadioString("Male", selectedVoice, (val) => setState(() => selectedVoice = val!)),
                                  SizedBox(width: 6.w),
                                  Text("Male", style: TextStyle(color: const Color(0xFF5A6C7D), fontSize: 12.sp)),
                                  SizedBox(width: 16.w),
                                  customRadioString("Female", selectedVoice, (val) => setState(() => selectedVoice = val!)),
                                  SizedBox(width: 6.w),
                                  Text("Female", style: TextStyle(color: const Color(0xFF5A6C7D), fontSize: 12.sp)),
                                  SizedBox(width: 16.w),
                                  customRadioString("None", selectedVoice, (val) => setState(() => selectedVoice = val!)),
                                  SizedBox(width: 6.w),
                                  Text("None", style: TextStyle(color: const Color(0xFF5A6C7D), fontSize: 12.sp)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    const Divider(height: 1, color: Color(0xFF8A99A6)),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),

            // BOTTOM NAVIGATION BAR
            Container(
              //padding: EdgeInsets.fromLTRB(24.w, 0.h, 24.w, AppSize.bottom(0)),
              padding: EdgeInsets.only(left: 24.w, right: 24.w),
              color: Colors.transparent,
              child: Row(  
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, color: Colors.black45, size: 28.sp),
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
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w400,
                            color: checkins.asMap().entries.any((e) => enabled[e.key] && e.value != null)
                                ? const Color(0xFF5A6C7D)
                                : Colors.black26,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Opacity(
                          opacity: checkins.asMap().entries.any((e) => enabled[e.key] && e.value != null)
                              ? 1.0
                              : 0.3,
                          child: SvgPicture.asset(
                            'assets/svg/nextbutton.svg',
                            width: 60.w,
                            height: 60.w,
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
    );
  }

  Widget customRadio(int value, int groupValue, Function(int?) onChanged) {
    bool isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        width: 24.w,
        height: 24.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFD1DDE3),
            width: 2.w,
          ),
        ),
        child: isSelected 
          ? Center(
              child: Container(
                width: 14.w,
                height: 14.w,
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
        width: 24.w,
        height: 24.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFD1DDE3),
            width: 2.w,
          ),
        ),
        child: isSelected 
          ? Center(
              child: Container(
                width: 14.w,
                height: 14.w,
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
    if (_isPlaying) {
      await _audioPlayer.pause();
      return;
    }

    String assetPath = "";
    if (selectedVoice == "Male") {
      assetPath = "audio/male.mp3";
    } else if (selectedVoice == "Female") {
      assetPath = "audio/Female.mp3";
    } else {
      assetPath = "audio/alarm.mp3";
    }
    
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource(assetPath));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

