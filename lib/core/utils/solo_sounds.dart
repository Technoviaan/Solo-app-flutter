/// Central registry of every voice line and sound effect that shipped in
/// "Final SOLO Voice Design - Sound Effects For app - 17 May 2026".
///
/// Keeping every asset path in one place means notification_service.dart,
/// check_in_page.dart and schedule_page.dart all agree on exactly which
/// file plays for which moment, instead of each screen guessing its own
/// path string.
class SoloSounds {
  SoloSounds._();

  // ---------------------------------------------------------------------
  // Preset voice lines (Male / Female), used for:
  //  1) the 2-hour missed check-in "screen take over" reminder flow
  //  2) the voice sample preview on the schedule/voice-selection screen
  //  3) the SOS button + successful check-in confirmations
  // ---------------------------------------------------------------------

  /// "Hello, I'm SOLO, your daily Check-in Buddy." — played when the user
  /// previews a voice on the schedule / voice-selection screen.
  static String voiceSample(String voice) =>
      'assets/audio/voices/${_folder(voice)}/voice_sample.mp3';

  /// Successive missed-check-in reminder phases, phase 1 to 4 (regular
  /// reminders repeated roughly every 30 minutes while check-in is due).
  static String phaseReminder(String voice, int phase) {
    assert(phase >= 1 && phase <= 4);
    return 'assets/audio/voices/${_folder(voice)}/phase${phase}_reminder.mp3';
  }

  /// 5th phase — final warning, played ~2 minutes before the SMS/emergency
  /// alert is triggered.
  static String phaseFinalWarning(String voice) =>
      'assets/audio/voices/${_folder(voice)}/phase5_final_warning.mp3';

  /// 6th phase — played once the emergency alert has actually been sent to
  /// the user's emergency contacts (missed check-in OR manual SOS).
  static String phaseAlertSent(String voice) =>
      'assets/audio/voices/${_folder(voice)}/phase6_alert_sent.mp3';

  /// "Glad you're okay. Take care." — played right after a successful
  /// check-in is confirmed.
  static String checkinConfirmed(String voice) =>
      'assets/audio/voices/${_folder(voice)}/checkin_confirmed.mp3';

  /// "Please tap SOS again to confirm the emergency alert." — played on the
  /// first SOS tap, before the 20 second confirmation countdown.
  static String sosTappedOnce(String voice) =>
      'assets/audio/voices/${_folder(voice)}/sos_tapped_once.mp3';

  static String _folder(String voice) =>
      voice.toLowerCase() == 'female' ? 'female' : 'male';

  // ---------------------------------------------------------------------
  // Short, voice-independent sound effects.
  // ---------------------------------------------------------------------

  /// Plays when the scheduled check-in "screen take over" pops up, right
  /// before/alongside the phase voice reminder.
  static const String screenTakeoverNotification =
      'assets/audio/effects/screen_takeover_notification.mp3';

  /// Plays the moment the big Check-in button is tapped, right before the
  /// "Glad you're okay" voice confirmation.
  static const String checkinButtonTapped =
      'assets/audio/effects/checkin_button_tapped.mp3';

  /// SOS radar alert sound, plays the moment the SOS button is tapped or
  /// triggered.
  static const String sosButtonTapped =
      'assets/audio/effects/sos_button_tapped.mp3';

  /// Fallback tone used only when the user has selected "None" for voice —
  /// a plain alarm/beep with no spoken voice line.
  static const String silentAlarmFallback = 'assets/audio/alarm.mp3';
}
