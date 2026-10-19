import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:solo_app/core/storage/token_storage.dart';
import 'package:solo_app/home/checkin/checkin_api.dart';
import 'package:solo_app/home/checkin/local_storage.dart';
import 'package:solo_app/home/contact/contacts_page.dart';
import 'package:solo_app/home/home_page.dart';
import 'package:solo_app/home/profile/profile_api.dart';
import 'package:solo_app/subscription/subscription_api.dart';
import 'package:solo_app/subscription/subscription_page.dart';
import 'package:solo_app/core/utils/solo_sounds.dart';
import 'package:solo_app/core/widgets/solo_toast.dart';
import 'package:solo_app/home/checkin/notification_service.dart';


const String _waveHtml = r'''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<style>
  html, body { margin: 0; padding: 0; width: 100%; height: 100%; background: transparent; overflow: hidden; }
  svg { display: block; width: 100%; height: 100%; }
</style>
</head>
<body>
<svg id="Icon_Box" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 2048 2048" width="100%" height="100%">
  <rect x="38.83" y="38.83" width="1970.34" height="1970.34" rx="397.74" ry="397.74" fill="#e86854"/>
  <g id="bar1">
    <rect x="467.84" width="135.58" rx="67.79" ry="67.79" fill="#f5f5f5">
      <animate attributeName="y" values="624.00; 774.00; 574.00; 674.00; 624.00" keyTimes="0; 0.25; 0.5; 0.75; 1" dur="1.32s" repeatCount="indefinite" calcMode="spline" keySplines="0.42 0 0.58 1; 0.42 0 0.58 1; 0.42 0 0.58 1; 0.42 0 0.58 1"/>
      <animate attributeName="height" values="800.00; 500.00; 900.00; 700.00; 800.00" keyTimes="0; 0.25; 0.5; 0.75; 1" dur="1.32s" repeatCount="indefinite" calcMode="spline" keySplines="0.42 0 0.58 1; 0.42 0 0.58 1; 0.42 0 0.58 1; 0.42 0 0.58 1"/>
    </rect>
  </g>
  <g id="bar2">
    <rect x="712.03" width="135.58" rx="67.79" ry="67.79" fill="#f5f5f5">
      <animate attributeName="y" values="724.00; 674.00; 794.00; 724.00" keyTimes="0; 0.33; 0.66; 1" dur="1.14s" repeatCount="indefinite" calcMode="spline" keySplines="0.42 0 0.58 1; 0.42 0 0.58 1; 0.42 0 0.58 1"/>
      <animate attributeName="height" values="600.00; 700.00; 460.00; 600.00" keyTimes="0; 0.33; 0.66; 1" dur="1.14s" repeatCount="indefinite" calcMode="spline" keySplines="0.42 0 0.58 1; 0.42 0 0.58 1; 0.42 0 0.58 1"/>
    </rect>
  </g>
  <g id="bar3">
    <rect x="956.21" width="135.58" rx="67.79" ry="67.79" fill="#f5f5f5">
      <animate attributeName="y" values="874.00; 624.00; 374.00; 624.00; 874.00" keyTimes="0; 0.25; 0.5; 0.75; 1" dur="1.50s" repeatCount="indefinite" calcMode="spline" keySplines="0.42 0 0.58 1; 0.42 0 0.58 1; 0.42 0 0.58 1; 0.42 0 0.58 1"/>
      <animate attributeName="height" values="300.00; 800.00; 1300.00; 800.00; 300.00" keyTimes="0; 0.25; 0.5; 0.75; 1" dur="1.50s" repeatCount="indefinite" calcMode="spline" keySplines="0.42 0 0.58 1; 0.42 0 0.58 1; 0.42 0 0.58 1; 0.42 0 0.58 1"/>
    </rect>
  </g>
  <g id="bar4">
    <rect x="1200.39" width="135.58" rx="67.79" ry="67.79" fill="#f5f5f5">
      <animate attributeName="y" values="754.00; 674.00; 794.00; 674.00; 754.00" keyTimes="0; 0.25; 0.5; 0.75; 1" dur="1.26s" repeatCount="indefinite" calcMode="spline" keySplines="0.42 0 0.58 1; 0.42 0 0.58 1; 0.42 0 0.58 1; 0.42 0 0.58 1"/>
      <animate attributeName="height" values="540.00; 700.00; 460.00; 700.00; 540.00" keyTimes="0; 0.25; 0.5; 0.75; 1" dur="1.26s" repeatCount="indefinite" calcMode="spline" keySplines="0.42 0 0.58 1; 0.42 0 0.58 1; 0.42 0 0.58 1; 0.42 0 0.58 1"/>
    </rect>
  </g>
  <g id="bar5">
    <rect x="1444.58" width="135.58" rx="67.79" ry="67.79" fill="#f5f5f5">
      <animate attributeName="y" values="674.00; 774.00; 624.00; 814.00; 674.00" keyTimes="0; 0.25; 0.5; 0.75; 1" dur="1.38s" repeatCount="indefinite" calcMode="spline" keySplines="0.42 0 0.58 1; 0.42 0 0.58 1; 0.42 0 0.58 1; 0.42 0 0.58 1"/>
      <animate attributeName="height" values="700.00; 500.00; 800.00; 420.00; 700.00" keyTimes="0; 0.25; 0.5; 0.75; 1" dur="1.38s" repeatCount="indefinite" calcMode="spline" keySplines="0.42 0 0.58 1; 0.42 0 0.58 1; 0.42 0 0.58 1; 0.42 0 0.58 1"/>
    </rect>
  </g>
</svg>
</body>
</html>
''';

// JS commands
const String _jsWavePlay =
    "document.querySelector('svg').unpauseAnimations();";
const String _jsWavePause =
    "document.querySelector('svg').pauseAnimations();";
const String _jsWaveReset =
    "var s=document.querySelector('svg');s.setCurrentTime(0);s.pauseAnimations();";

// =============================================================================
// SCHEDULE PAGE
// =============================================================================

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with WidgetsBindingObserver {
  List<TimeOfDay?> checkins = [null, null];
  List<bool> enabled = [false, false];

  int maxCheckins = 0;
  int credits = 0;
  int subscriptionStatus = 0;
  int selectedAlertHour = 2;
  String selectedVoice = "Male";
  String userName = "User";

  // ================= AUDIO + WAVE STATE =================
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;


  late final WebViewController _waveWeb;

  // Check if trial user
  bool get isTrialUser => subscriptionStatus <= 1;

  @override
  void initState() {
    super.initState();
    TokenStorage.userNameNotifier.addListener(_onUserNameChanged);
    if (TokenStorage.userNameNotifier.value.isNotEmpty) {
      userName = TokenStorage.userNameNotifier.value;
    }
    WidgetsBinding.instance.addObserver(this);
    loadData();
    loadSchedule();

    _waveWeb = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          // Load hote hi animation pause kar do (idle icon ke neeche chhupa hai)
          onPageFinished: (_) => _waveWeb.runJavaScript(_jsWaveReset),
        ),
      )
      ..loadHtmlString(_waveHtml);

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;

      final playing = state == PlayerState.playing;
      final paused = state == PlayerState.paused;

      setState(() {
        _isPlaying = playing;
      });

      if (playing) {
        _waveWeb.runJavaScript(_jsWavePlay);
      } else if (paused) {
        _waveWeb.runJavaScript(_jsWavePause);
      } else {
        _waveWeb.runJavaScript(_jsWaveReset);
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
      });
      _waveWeb.runJavaScript(_jsWaveReset);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadData();
    }
  }

  Future<void> loadData() async {
    try {
      final wasPending = await TokenStorage.getPendingCheckout();
      if (wasPending) {
        for (int i = 0; i < 3; i++) {
          await SubscriptionApi.getSubscriptionStatus();
          final status = await TokenStorage.getSubscriptionStatus();
          if (status >= 2) {
            await TokenStorage.savePendingCheckout(false);
            break;
          }
          if (i < 2) await Future.delayed(const Duration(seconds: 1));
        }
      } else {
        await SubscriptionApi.getSubscriptionStatus();
      }

      final freshStatus = await TokenStorage.getSubscriptionStatus();
      final freshMax = await TokenStorage.getMaxCheckins();
      final freshCredits = await TokenStorage.getCredits();
      final voice = await LocalStorage.getVoice();

      if (mounted) {
        setState(() {
          subscriptionStatus = freshStatus;
          maxCheckins = freshMax;
          credits = freshCredits;
          selectedVoice = voice;
        });
      }
    } catch (e) {
      debugPrint("Error loading subscription in SchedulePage: $e");
    }

    try {
      final localName = await TokenStorage.getUserName();
      if (mounted && localName.isNotEmpty && localName != "User") {
        setState(() {
          userName = localName;
        });
      }
      final profile = await ProfileApi.getProfile();
      if (profile != null && mounted) {
        final userMap = profile["user"] ?? profile;
        if (userMap["name"] != null && userMap["name"].toString().isNotEmpty) {
          final nameFromApi = userMap["name"].toString();
          setState(() {
            userName = nameFromApi;
          });
          await TokenStorage.saveUserName(nameFromApi);
        }
      }
    } catch (_) {}
  }

  void _onUserNameChanged() {
    if (mounted && TokenStorage.userNameNotifier.value.isNotEmpty) {
      setState(() {
        userName = TokenStorage.userNameNotifier.value;
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

    final hourController =
    FixedExtentScrollController(initialItem: selectedHourIndex);
    final minuteController =
    FixedExtentScrollController(initialItem: selectedMinuteIndex);
    final periodController =
    FixedExtentScrollController(initialItem: selectedPeriodIndex);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F8F3),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: EdgeInsets.fromLTRB(
                  22,
                  22,
                  22,
                  MediaQuery.of(context).padding.bottom + 20,
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // HEADER
                        Row(
                          children: [
                            SvgPicture.asset(
                              'assets/svg/schudel.svg',
                              width: 36,
                              height: 36,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                "Set Time",
                                style: TextStyle(
                                  fontSize: 26,
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
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    color: const Color(0x808A99A6),
                                  ),
                                  const SizedBox(height: 44),
                                  Container(
                                    height: 1,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 12),
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
                                      padding:
                                      EdgeInsets.symmetric(horizontal: 4),
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
                                        physics:
                                        const FixedExtentScrollPhysics(),
                                        controller: periodController,
                                        onSelectedItemChanged: (i) {
                                          setModalState(() {
                                            selectedPeriodIndex = i;
                                            tempPeriod = i == 0 ? "AM" : "PM";
                                          });
                                        },
                                        children: [
                                          _periodText("AM",
                                              isSelected:
                                              selectedPeriodIndex == 0),
                                          _periodText("PM",
                                              isSelected:
                                              selectedPeriodIndex == 1),
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
                              width: 101,
                              height: 46,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF002C3E),
                                  side: const BorderSide(
                                    color: Color(0xFF002C3E),
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(60),
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
                            const SizedBox(width: 14),
                            SizedBox(
                              width: 101,
                              height: 46,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF002C3E),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(60),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () async {
                                  int finalHour = tempHour;
                                  if (tempPeriod == "PM" && finalHour < 12) {
                                    finalHour += 12;
                                  }
                                  if (tempPeriod == "AM" && finalHour == 12) {
                                    finalHour = 0;
                                  }
                                  final time = TimeOfDay(
                                      hour: finalHour, minute: tempMinute);
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
                  ),
                ),
              );
            },
          ),
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
            String val = isHour
                ? (index + 1).toString()
                : index.toString().padLeft(2, '0');
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

  /// ================= VOICE ICON (ANIMATED SVG WAVE - WEBVIEW) =================
  Widget _buildVoiceIcon({double size = 76}) {
    return SizedBox(
      width: size,
      height: size,
      child: IgnorePointer(
        child: WebViewWidget(controller: _waveWeb),
      ),
    );
  }

  /// ================= VOICE SECTION (FIGMA + RESPONSIVE) =================
  Widget _buildVoiceSection() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double voiceIconSize = screenWidth < 360 ? 56 : 64;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildVoiceIcon(size: voiceIconSize),
            const SizedBox(width: 12),
            Expanded(
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
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
                  SizedBox(height: 2),
                  Text(
                    "Choose a voice for\nyour check-in reminder",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF5A6C7D),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _voicePlayButton(),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _voiceOption("Male", 14),
            const SizedBox(width: 24),
            _voiceOption("Female", 14),
            const SizedBox(width: 24),
            _voiceOption("None", 14),
          ],
        ),
      ],
    );
  }

  Widget _voiceOption(String value, double fontSize) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => selectedVoice = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            customRadioString(
              value,
              selectedVoice,
              (val) => setState(() => selectedVoice = val!),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontFamily: 'Inter',
                color: const Color(0xFF5A6C7D),
                fontSize: fontSize,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _voicePlayButton() {
    final bool disabled = selectedVoice == "None";
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _playVoice,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFD1DBE0) : const Color(0xFFE8705B),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
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
                onTap: isInactive
                    ? goToSubscription
                    : () => pickTime(index),
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
                        color: checkins[index] != null
                            ? const Color(0xFF002C3E)
                            : const Color(0xFF8A99A6),
                        fontSize: checkins[index] != null ? 17 : 14,
                        fontWeight: checkins[index] != null
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: isInactive
                  ? goToSubscription
                  : () {
                      if (checkins[index] != null) {
                        // Minus tapped – remove the time
                        setState(() {
                          checkins[index] = null;
                          enabled[index] = false;
                        });
                      } else {
                        pickTime(index);
                      }
                    },
              child: checkins[index] != null
                  ? Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFF002C3E),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 12,
                          height: 1.8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    )
                  : SvgPicture.asset(
                      'assets/svg/plus.svg',
                      width: 28,
                      height: 28,
                    ),
            ),
            const SizedBox(width: 8),
            customSwitch(
              value: !isInactive && checkins[index] != null && enabled[index],
              onChanged: (val) async {
                if (isInactive) {
                  goToSubscription();
                  return;
                }

                if (checkins[index] == null) {
                  SoloToast.show(
                    context,
                    "Please set a check-in time first",
                  );
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          double screenWidth =
                              MediaQuery.of(context).size.width;

                          double titleFontSize = screenWidth < 360 ? 36 : 44;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Set your\ndaily check-in\nschedule",
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF002C3E),
                                  letterSpacing: 0,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Schedule up to 2 preferred check-in times daily. I’ll be there to check on you, and you can change or pause reminders anytime.",
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: screenWidth < 360 ? 13 : 14,
                                  color: const Color(0xFF5A6C7D),
                                  height: 1.45,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          );
                        },
                      ),
                      // 1px stroke, 50% opacity #8A99A6
                      const Divider(
                          height: 1, thickness: 1, color: Color(0x808A99A6)),
                      checkinTile(0),
                      const Divider(
                          height: 1, thickness: 1, color: Color(0x808A99A6)),
                      checkinTile(1),
                      const Divider(
                          height: 1, thickness: 1, color: Color(0x808A99A6)),
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
                          customRadio(
                              1,
                              selectedAlertHour,
                                  (val) =>
                                  setState(() => selectedAlertHour = val!)),
                          const SizedBox(width: 8),
                          const Text("1 Hour",
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Color(0xFF5A6C7D),
                                  fontSize: 14)),
                          const SizedBox(width: 24),
                          customRadio(
                              2,
                              selectedAlertHour,
                                  (val) =>
                                  setState(() => selectedAlertHour = val!)),
                          const SizedBox(width: 8),
                          const Text("2 Hours (Default)",
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Color(0xFF5A6C7D),
                                  fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(
                          height: 1, thickness: 1, color: Color(0x808A99A6)),
                      const SizedBox(height: 16),

                      // VOICE SELECTION SECTION (Figma design, responsive)
                      _buildVoiceSection(),

                      const SizedBox(height: 16),
                      const Divider(
                          height: 1, thickness: 1, color: Color(0x808A99A6)),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // BOTTOM NAVIGATION BAR
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                color: Colors.transparent,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _handleBackNavigation,
                      icon: const Icon(Icons.arrow_back,
                          color: Color(0xFF5A6C7D), size: 26),
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
                            .where((entry) =>
                        enabled[entry.key] && entry.value != null)
                            .map((entry) => entry.value!)
                            .toList();

                        if (activeTimes.isEmpty) {
                          SoloToast.show(
                            context,
                            "Please set at least one check-in time",
                            isDark: false,
                          );
                          return;
                        }

                        try {
                          final minutes = activeTimes
                              .map((time) => (time.hour * 60) + time.minute)
                              .toList()
                            ..sort();

                          await LocalStorage.saveScheduleMinutes(minutes);
                          await LocalStorage.saveAlertWindowHours(
                              selectedAlertHour);
                          await LocalStorage.saveVoice(selectedVoice);
                          final latestUserName =
                          TokenStorage.userNameNotifier.value.isNotEmpty
                              ? TokenStorage.userNameNotifier.value
                              : (userName.isNotEmpty
                              ? userName
                              : await TokenStorage.getUserName());
                          await LocalStorage.saveUserName(latestUserName);

                          final List<String> formattedTimes =
                          activeTimes.map((t) {
                            return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
                          }).toList();
                          await CheckinApi.saveCheckinTimes(formattedTimes);

                          final dueTime =
                          await NotificationService.resolveNextDueTime();
                          if (dueTime != null) {
                            await NotificationService.scheduleMissedCheckinFlow(
                              dueTime: dueTime,
                              alertWindowHours: selectedAlertHour,
                            );
                          }

                          if (!context.mounted) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ContactsPage(),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text("Error saving schedule: $e")),
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
                              color: checkins.asMap().entries.any(
                                      (e) => enabled[e.key] && e.value != null)
                                  ? const Color(0xFF5A6C7D)
                                  : const Color(0xFF5A6C7D)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Opacity(
                            opacity: checkins.asMap().entries.any(
                                    (e) => enabled[e.key] && e.value != null)
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

  Widget customRadioString(
      String value, String groupValue, Function(String?) onChanged) {
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

  Widget customSwitch(
      {required bool value, required Function(bool) onChanged}) {
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

  Future<void> goToSubscription() async {
    SoloToast.show(
      context,
      "Please upgrade your plan to add a second check-in time",
      isDark: false,
    );
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SubscriptionPage(
          initialToastMessage:
          "Please upgrade your plan to add a second check-in time",
        ),
      ),
    );
    if (mounted) {
      await loadData();
    }
  }

  Future<void> loadSchedule() async {
    final hours = await LocalStorage.getAlertWindowHours();
    final minutes = await LocalStorage.getScheduleMinutes();
    final saved = await LocalStorage.getSchedule();

    if (!mounted) return;
    setState(() {
      selectedAlertHour = hours;
      if (minutes.isNotEmpty) {
        checkins[0] =
            TimeOfDay(hour: minutes[0] ~/ 60, minute: minutes[0] % 60);
        enabled[0] = true;
        if (minutes.length > 1) {
          checkins[1] =
              TimeOfDay(hour: minutes[1] ~/ 60, minute: minutes[1] % 60);
          enabled[1] = true;
        }
      } else if (saved != null) {
        DateTime time = DateTime.parse(saved);
        checkins[0] = TimeOfDay(hour: time.hour, minute: time.minute);
        enabled[0] = true;
      }
    });
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
    TokenStorage.userNameNotifier.removeListener(_onUserNameChanged);
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    super.dispose();
  }
}