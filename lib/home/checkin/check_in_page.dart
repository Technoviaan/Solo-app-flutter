import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:alarm/alarm.dart';
import 'package:solo_app/home/checkin/local_storage.dart';
import 'package:solo_app/home/notification/history_store.dart';
import 'package:solo_app/home/notification/notification_api.dart';
import 'package:solo_app/home/checkin/checkin_api.dart';
import 'package:solo_app/home/checkin/notification_service.dart';
import 'package:solo_app/core/utils/app_size.dart';
import 'package:solo_app/core/utils/solo_sounds.dart';
import 'package:solo_app/core/widgets/solo_toast.dart';
import 'package:solo_app/widgets/solo_turquoise_animation.dart';
import 'package:solo_app/widgets/sos_radar_button.dart';

class CheckinScreen extends StatefulWidget {
  final String userName;
  final DateTime scheduledTime;
  final int alertWindowHours;
  final int? testWindowSeconds;

  const CheckinScreen({
    super.key,
    required this.userName,
    required this.scheduledTime,
    this.alertWindowHours = 2,
    this.testWindowSeconds,
  });

  Duration get _alertWindowDuration => testWindowSeconds != null
      ? Duration(seconds: testWindowSeconds!)
      : Duration(hours: alertWindowHours);

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  late int remainingSeconds;
  late int totalSeconds;
  Timer? timer;

  String state = "normal";
  bool isSOSPending = false;
  int sosSeconds = 20;
  Timer? sosTimer;

  int _radarPulseCount = 0;
  Timer? _radarSoundTimer;
  AudioPlayer? _radarAudioPlayer;
  AudioPlayer? _cuePlayer;
  final Set<int> _playedPhases = {};

  @override
  void initState() {
    super.initState();

    NotificationService.isCheckinScreenActive = true;

    // Silence only the currently ringing alarm (e.g. Phase 1 checkin alarm)
    // so background audio doesn't clash, but keep future reminder alarms alive!
    unawaited(() async {
      try {
        await Alarm.stop(1000);
        final alarms = await Alarm.getAlarms();
        for (final a in alarms) {
          if (await Alarm.isRinging(a.id)) {
            await Alarm.stop(a.id);
          }
        }
      } catch (e) {
        debugPrint("⚠️ Error stopping ringing alarm: $e");
      }
    }());

    // Enable immersive full screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Lock orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _calculateRemainingTime();
    _initPhasePlaybackOnStartup();
    startTimer();
  }

  void _initPhasePlaybackOnStartup() {
    if (state == "waiting") return;

    final elapsedSeconds = totalSeconds - remainingSeconds;
    final t2 = (totalSeconds * 0.25).round();
    final t3 = (totalSeconds * 0.50).round();
    final t4 = (totalSeconds * 0.75).round();
    final warningWindow = widget.testWindowSeconds != null ? 10 : 120;
    final t5 = totalSeconds - warningWindow;

    // Suppress past phases if user entered the screen late (e.g. opened at 1:25 PM after 1:04 PM)
    if (elapsedSeconds >= 15) _playedPhases.add(1);
    if (elapsedSeconds >= t2) _playedPhases.add(2);
    if (elapsedSeconds >= t3) _playedPhases.add(3);
    if (elapsedSeconds >= t4) _playedPhases.add(4);
    if (elapsedSeconds >= t5) _playedPhases.add(5);

    // ONLY play the takeover chime + Phase 1 voice if we are within the first 15 seconds of takeover!
    if (elapsedSeconds < 15 && !_playedPhases.contains(1)) {
      _playedPhases.add(1);
      _playCue(
        effectAsset: SoloSounds.screenTakeoverNotification,
        voiceAssetFor: (voice) => SoloSounds.phaseReminder(voice, 1),
      );
    }
  }


  Future<void> _playCue({
    String? effectAsset,
    required String Function(String voice) voiceAssetFor,
  }) async {
    try {
      _cuePlayer ??= AudioPlayer();
      await _cuePlayer?.stop();
      await _cuePlayer?.setReleaseMode(ReleaseMode.stop);

      if (effectAsset != null) {
        await _cuePlayer?.play(AssetSource(effectAsset.replaceFirst('assets/', '')));
        // Allow chime notification sound to complete cleanly before voice speaks
        await Future.delayed(const Duration(milliseconds: 1400));
      }

      final voice = await LocalStorage.getVoice();
      if (voice != "None" && mounted) {
        await _cuePlayer?.stop();
        await _cuePlayer?.play(
          AssetSource(voiceAssetFor(voice).replaceFirst('assets/', '')),
        );
      }
    } catch (e) {
      debugPrint("⚠️ [CheckinScreen] Error playing SOLO voice cue: $e");
    }
  }

  void _calculateRemainingTime() {
    final now = DateTime.now();
    final deadline = widget.scheduledTime.add(widget._alertWindowDuration);

    totalSeconds = widget._alertWindowDuration.inSeconds;

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
    debugPrint("🟢 [CheckinScreen] startTimer() called | scheduledTime=${widget.scheduledTime} | alertWindow=${widget._alertWindowDuration}");
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        final now = DateTime.now();
        final deadline = widget.scheduledTime.add(widget._alertWindowDuration);

        if (now.isBefore(widget.scheduledTime)) {
          state = "waiting";
          remainingSeconds = widget.scheduledTime.difference(now).inSeconds;
        } else {
          remainingSeconds = deadline.difference(now).inSeconds;
          _updateStateByTime();
          _checkPhaseTriggers();

          if (remainingSeconds % 10 == 0) {
            debugPrint("⏱️ [CheckinScreen] state=$state | remainingSeconds=$remainingSeconds | now=$now");
          }

          if (remainingSeconds <= 0) {
            state = "alert";
            remainingSeconds = 0;
            debugPrint("🚨 [CheckinScreen] Deadline passed with NO check-in -> calling triggerAlert()");
            triggerAlert();
            t.cancel();
          }
        }
      });
    });
  }

  void _checkPhaseTriggers() {
    if (state == "confirmed" || state == "alert" || isSOSPending) return;

    final elapsedSeconds = totalSeconds - remainingSeconds;
    final t2 = (totalSeconds * 0.25).round();
    final t3 = (totalSeconds * 0.50).round();
    final t4 = (totalSeconds * 0.75).round();
    final warningWindow = widget.testWindowSeconds != null ? 10 : 120;
    final t5 = totalSeconds - warningWindow;

    // Phase 2: 25% past scheduled time (+15m in 1hr, +30m in 2hr)
    if (elapsedSeconds >= t2 && !_playedPhases.contains(2)) {
      _playedPhases.add(2);
      debugPrint("🎙️ [CheckinScreen] Playing Phase 2 Voice Reminder (elapsed=$elapsedSeconds s)");
      Alarm.isRinging(1100).then((isAlarmRinging) {
        if (!isAlarmRinging && mounted) {
          unawaited(_playCue(
            voiceAssetFor: (voice) => SoloSounds.phaseReminder(voice, 2),
          ));
        }
      });
    }

    // Phase 3: 50% past scheduled time (+30m in 1hr, +60m in 2hr)
    if (elapsedSeconds >= t3 && !_playedPhases.contains(3)) {
      _playedPhases.add(3);
      debugPrint("🎙️ [CheckinScreen] Playing Phase 3 Voice Reminder (elapsed=$elapsedSeconds s)");
      Alarm.isRinging(1101).then((isAlarmRinging) {
        if (!isAlarmRinging && mounted) {
          unawaited(_playCue(
            voiceAssetFor: (voice) => SoloSounds.phaseReminder(voice, 3),
          ));
        }
      });
    }

    // Phase 4: 75% past scheduled time (+45m in 1hr, +90m in 2hr)
    if (elapsedSeconds >= t4 && !_playedPhases.contains(4)) {
      _playedPhases.add(4);
      debugPrint("🎙️ [CheckinScreen] Playing Phase 4 Voice Reminder (elapsed=$elapsedSeconds s)");
      Alarm.isRinging(1102).then((isAlarmRinging) {
        if (!isAlarmRinging && mounted) {
          unawaited(_playCue(
            voiceAssetFor: (voice) => SoloSounds.phaseReminder(voice, 4),
          ));
        }
      });
    }

    // Phase 5: Final Warning (2 Mins Before Alert: +58m in 1hr, +118m in 2hr)
    if (elapsedSeconds >= t5 && !_playedPhases.contains(5)) {
      _playedPhases.add(5);
      debugPrint("🎙️ [CheckinScreen] Playing Phase 5 Final Warning Voice Reminder (remaining=$remainingSeconds s)");
      Alarm.isRinging(1103).then((isAlarmRinging) {
        if (!isAlarmRinging && mounted) {
          unawaited(_playCue(
            voiceAssetFor: (voice) => SoloSounds.phaseFinalWarning(voice),
          ));
        }
      });
    }
  }

  void _updateStateByTime() {
    if (state == "alert" && !isSOSPending) return;
    final warningWindow = widget.testWindowSeconds != null ? 10 : 120;
    if (remainingSeconds <= warningWindow) {
      state = "warning";
    } else {
      state = "normal";
    }
  }

  Future<void> onCheckin() async {
    debugPrint("👉 [CheckinScreen] onCheckin() tapped | current state=$state");
    if (state == "waiting") {
      debugPrint("⚠️ [CheckinScreen] onCheckin() blocked -> still in 'waiting' state (too early)");
      SoloToast.show(
        context,
        "Too early to check in!",
        isDark: true,
      );
      return;
    }

    await NotificationService.cancelAllCheckinNotifications();

    unawaited(_playCue(
      effectAsset: SoloSounds.checkinButtonTapped,
      voiceAssetFor: (voice) => SoloSounds.checkinConfirmed(voice),
    ));

    final apiOk = await CheckinApi.confirmCheckin();
    debugPrint("📡 [CheckinScreen] CheckinApi.confirmCheckin() -> success=$apiOk");
    await LocalStorage.savePreviousCheckinTime(DateTime.now());

    timer?.cancel();
    await HistoryStore.logCheckin(
      status: "CHECKED_IN",
      scheduledTime: widget.scheduledTime,
    );
    debugPrint("✅ [CheckinScreen] Check-in CONFIRMED and logged. Showing confirmed state, then closing.");

    if (!mounted) return;

    setState(() {
      state = "confirmed";
    });

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    NotificationService.isHandlingAlarm = false;
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else {
      exit(0);
    }
  }

  Future<void> triggerAlert() async {
    debugPrint("🚨 [CheckinScreen] triggerAlert() STARTED (missed check-in, no manual SOS)");
    final contacts = await LocalStorage.getContacts();
    final contactNames = contacts
        .map((e) => e["name"] ?? "")
        .where((e) => e.trim().isNotEmpty)
        .toList();
    debugPrint("👥 [CheckinScreen] triggerAlert() contacts to notify = $contactNames");
    await HistoryStore.logCheckin(
      status: "MISSED",
      scheduledTime: widget.scheduledTime,
    );
    await HistoryStore.logAlert(
      type: "MISSED",
      contacts: contactNames,
    );
    debugPrint("⚠️ [CheckinScreen] triggerAlert() FINISHED");

    if (!_playedPhases.contains(6)) {
      _playedPhases.add(6);
      Alarm.isRinging(1200).then((isAlarmRinging) {
        if (!isAlarmRinging && mounted) {
          unawaited(_playCue(
            voiceAssetFor: (voice) => SoloSounds.phaseAlertSent(voice),
          ));
        }
      });
    }
    unawaited(NotificationService.showPausedNotification());
  }

  void _startRadarSoundLoop() {
    _stopRadarSoundLoop();
    _radarPulseCount = 1;
    _playRadarPing();
    _radarSoundTimer = Timer.periodic(const Duration(milliseconds: 2550), (t) {
      if (!mounted || !isSOSPending || _radarPulseCount >= 8) {
        t.cancel();
        return;
      }
      _radarPulseCount++;
      _playRadarPing();
    });
  }

  Future<void> _playRadarPing() async {
    try {
      _radarAudioPlayer ??= AudioPlayer();
      await _radarAudioPlayer?.play(
        AssetSource(SoloSounds.sosButtonTapped.replaceFirst('assets/', '')),
      );
    } catch (e) {
      debugPrint("⚠️ [CheckinScreen] Error playing radar ping: $e");
    }
  }

  void _stopRadarSoundLoop() {
    _radarSoundTimer?.cancel();
    _radarSoundTimer = null;
    _radarPulseCount = 0;
    try {
      _radarAudioPlayer?.stop();
      _radarAudioPlayer?.dispose();
    } catch (_) {}
    _radarAudioPlayer = null;
  }

  void onSOS() {
    debugPrint("🔴 [CheckinScreen] onSOS() tapped | isSOSPending(before)=$isSOSPending | sosSeconds=$sosSeconds");
    if (state == "alert" && !isSOSPending) {
      // Button inactive after alert sent
      return;
    }

    if (!isSOSPending) {
      debugPrint("🕐 [CheckinScreen] SOS 1st tap -> starting 20s confirm countdown");
      setState(() {
        isSOSPending = true;
        sosSeconds = 20;
      });
      _startRadarSoundLoop();
      unawaited(_playCue(
        voiceAssetFor: (voice) => SoloSounds.sosTappedOnce(voice),
      ));

      sosTimer?.cancel();
      sosTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        if (sosSeconds > 0) {
          setState(() {
            sosSeconds--;
          });
        }
        debugPrint("⏳ [CheckinScreen] SOS countdown: $sosSeconds s left");

        if (sosSeconds <= 0) {
          t.cancel();
          debugPrint("⌛ [CheckinScreen] SOS countdown expired with NO 2nd tap -> holding 1s then resetSOS()");
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted && isSOSPending) {
              resetSOS();
            }
          });
        }
      });
    } else {
      debugPrint("🔴 [CheckinScreen] SOS 2nd tap within 20s -> cancelling timer, calling triggerSosAlert()");
      sosTimer?.cancel();
      _stopRadarSoundLoop();
      triggerSosAlert();
    }
  }

  Future<void> triggerSosAlert() async {
    debugPrint("🚨 [CheckinScreen] triggerSosAlert() STARTED");
    timer?.cancel();
    _stopRadarSoundLoop();
    final contacts = await LocalStorage.getContacts();
    final contactNames = contacts
        .map((e) => e["name"] ?? "")
        .where((e) => e.trim().isNotEmpty)
        .toList();
    debugPrint("👥 [CheckinScreen] triggerSosAlert() contacts to notify = $contactNames");

    final apiOk = await NotificationApi.triggerSos();
    debugPrint("📡 [CheckinScreen] NotificationApi.triggerSos() -> backend call success=$apiOk");

    await HistoryStore.logAlert(
      type: "SOS",
      contacts: contactNames,
    );
    debugPrint("✅ [CheckinScreen] triggerSosAlert() FINISHED");
    unawaited(_playCue(
      voiceAssetFor: (voice) => SoloSounds.phaseAlertSent(voice),
    ));
    unawaited(NotificationService.showPausedNotification());

    if (!mounted) return;
    setState(() {
      state = "alert";
      isSOSPending = false;
      sosSeconds = 20;
    });
  }

  void resetSOS() {
    debugPrint("↩️ [CheckinScreen] resetSOS() called | state before=$state");
    _stopRadarSoundLoop();
    if (!mounted) return;
    setState(() {
      isSOSPending = false;
      sosSeconds = 20;
      _updateStateByTime();
    });
    debugPrint("↩️ [CheckinScreen] resetSOS() done | state after=$state");
  }

  String _getStatusText() {
    if (state == "confirmed") {
      return "Check-in confirmed\nGlad you're OK";
    }
    if (state == "alert" && !isSOSPending) {
      return "Your contacts have been alerted\nIf you're safe, please let them know";
    }
    if (isSOSPending) {
      return "Tap SOS again to confirm";
    }
    final displayName = LocalStorage.userNameNotifier.value.isNotEmpty
        ? LocalStorage.userNameNotifier.value
        : (widget.userName.isNotEmpty ? widget.userName : "User");
    return "Hi $displayName, tap to check-in!";
  }

  String _formatAmPm(DateTime time) => time.hour >= 12 ? "PM" : "AM";

  String _formatTimeOnly(DateTime time) {
    int hour = time.hour % 12;
    if (hour == 0) hour = 12;
    return "$hour:${time.minute.toString().padLeft(2, "0")}";
  }

  double getProgress() {
    if (state == "waiting" || state == "confirmed") return 1.0;
    return (remainingSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${now.day} ${months[now.month - 1]}";
  }

  @override
  void dispose() {
    NotificationService.isHandlingAlarm = false;
    NotificationService.isCheckinScreenActive = false;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    timer?.cancel();
    sosTimer?.cancel();
    _stopRadarSoundLoop();
    _cuePlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002C3E),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
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
                        SizedBox(height: 6.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatTimeOnly(widget.scheduledTime),
                              style: TextStyle(
                                color: const Color(0xFFB5D43C),
                                fontSize: 58.sp,
                                fontWeight: FontWeight.w500,
                                height: 0.95,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
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
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w400,
                            height: 0.95,
                          ),
                        ),

                        const Spacer(flex: 2),

                        /// CIRCLE + BUTTON
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                height: 280.w,
                                width: 280.w,
                                child: CircularProgressIndicator(
                                  value: getProgress(),
                                  strokeWidth: 6.w,
                                  strokeCap: StrokeCap.round,
                                  backgroundColor: const Color(0xFF2D6F81),
                                  valueColor: const AlwaysStoppedAnimation(Color(0xFF78AEBE)),
                                ),
                              ),
                              SoloTurquoiseAnimation(
                                size: 236.w,
                                enablePulse: true,
                                isHappy: state == "confirmed",
                                isSad: state == "alert" && !isSOSPending,
                                isRed: isSOSPending || state == "alert",
                                isYellow: state == "warning" && !isSOSPending,
                                onTap: onCheckin,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 14.h),

                        /// TEXT
                        Center(
                          child: Text(
                            _getStatusText(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFFD1D9E0),
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        /// TIMER & SOS BUTTON
                        const Spacer(flex: 3),
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
                            SosRadarButton(
                              active: isSOSPending,
                              seconds: sosSeconds,
                              confirmed: state == "alert" && !isSOSPending,
                              onTap: onSOS,
                              size: 104.w,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}