import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:solo_app/home/checkin/notification_service.dart';
import 'package:solo_app/core/network/delete_account_api.dart';
import 'package:solo_app/core/storage/token_storage.dart';
import 'package:solo_app/core/widgets/solo_logo.dart';
import 'package:solo_app/home/history_page.dart';
import 'package:solo_app/home/profile/profile_page.dart';
import 'package:solo_app/home/notification/notification_page.dart';
import 'package:solo_app/loginWithNumber/login_page.dart';
import 'package:solo_app/home/common_questions_page.dart';
import 'package:solo_app/home/about_us_page.dart';
import 'package:solo_app/home/contact_us_page.dart';
import 'package:solo_app/home/privacy_policy_page.dart';
import 'package:solo_app/home/terms_of_use_page.dart';
import '../core/utils/app_size.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {

  bool deleting = false;

  Future<void> _runQuickTestAlert(
    BuildContext context,
    int delaySeconds,
    int windowSeconds,
  ) async {
    await NotificationService.triggerQuickTestAlert(
      delaySeconds: delaySeconds,
      windowSeconds: windowSeconds,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Text(
          "Test alert set — check-in screen fires in ${delaySeconds}s. "
          "Lock the phone (or kill the app) now.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    AppSize.init(context);

    return Scaffold(

      backgroundColor: const Color(0xFFF7F8F3),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSize.w(20),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                SizedBox(height: AppSize.h(10)),

                // ── SOLO logo ──
                const SoloLogo(),

                SizedBox(height: AppSize.h(30)),

                /// ACCOUNT SETTINGS
                sectionTitle("Account Settings"),

                settingsBox([
                  settingTile(
                    "Profile",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfilePage(),
                        ),
                      );
                    },
                  ),


                  settingTile(
                    "Sign Out",
                    onTap: () {
                      showSignOutDialog(context);
                    },
                  ),

                  settingTile(
                    "Delete Account",
                    onTap: () {
                      showDeleteDialog(context);
                    },
                  ),
                ]),

                SizedBox(height: AppSize.h(24)),

                /// PREFERENCES
                sectionTitle("Preferences"),

                settingsBox([
                  settingTile(
                    "Notifications",
                    onTap: () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationPage(),
                        ),
                      );

                    },
                  ),

                  settingTile(
                    "History",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HistoryPage(),
                        ),
                      );
                    },
                  ),
                ]),

                SizedBox(height: AppSize.h(24)),

                // ── DEVELOPER TOOLS (debug builds only — never shown in release) ──
                if (kDebugMode) ...[
                  sectionTitle("Developer Tools"),
                  settingsBox([
                    settingTile(
                      "Test Alert (15s)",
                      onTap: () => _runQuickTestAlert(context, 15, 90),
                    ),
                    settingTile(
                      "Test Alert (60s)",
                      onTap: () => _runQuickTestAlert(context, 60, 180),
                    ),
                    settingTile(
                      "Clear Test Alert",
                      onTap: () async {
                        await NotificationService.clearQuickTestAlert();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Test alert cleared."),
                            ),
                          );
                        }
                      },
                    ),
                  ]),
                  SizedBox(height: AppSize.h(24)),
                ],

                /// SUPPORT
                sectionTitle("Support"),

                settingsBox([
                  settingTile(
                    "Common Question",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CommonQuestionsPage(),
                        ),
                      );
                    },
                  ),
                  settingTile(
                    "Contact Us",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ContactUsPage(),
                        ),
                      );
                    },
                  ),
                  settingTile(
                    "About Us",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AboutUsPage(),
                        ),
                      );
                    },
                  ),
                  settingTile(
                    "Privacy Policy",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyPage(),
                        ),
                      );
                    },
                  ),
                  settingTile(
                    "Terms of Use",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TermsOfUsePage(),
                        ),
                      );
                    },
                  ),
                ]),

                SizedBox(height: AppSize.h(40)),

                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 32, bottom: 16),
                    child: Icon(Icons.arrow_back, color: Color(0xFF8A99A6), size: 24),
                  ),
                ),

                SizedBox(height: AppSize.h(10)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// SECTION TITLE
  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF002C3E),
        ),
      ),
    );
  }

  /// SETTINGS BOX
  Widget settingsBox(List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF7FB4BC),
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        child: Column(children: children),
      ),
    );
  }

  /// SETTINGS TILE
  Widget settingTile(String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// SIGN OUT DIALOG
  void showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: EdgeInsets.zero, // allows perfect exact sizing
          child: SizedBox(
            width: AppSize.w(342),
            height: AppSize.h(295),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSize.w(24),
                vertical: AppSize.h(24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ── Icon + "Sign Out" title in one row ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/svg/signout.svg',
                        width: 50,
                        height: 50,
                      ),
                      const SizedBox(width: 10),
                      const Text( 
                        "Sign Out",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF002C3E),
                        ),
                      ),
                    ],
                  ),

                  // ── Main question ──
                  const Text(
                    "Are you sure you would like\nto sign out?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF002C3E),
                      height: 1.4,
                    ),
                  ),

                  // ── Sub-caption ──
                  const Text(
                    "You'll need to sign in again to use SOLO.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF002C3E),
                    ),
                  ),

                  // ── Buttons ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cancel — outlined
                      SizedBox(
                        width: AppSize.w(111),
                        height: AppSize.h(46),
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
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
                            Navigator.pop(dialogContext);
                            await TokenStorage.clear();
                            if (!context.mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                              (route) => false,
                            );
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
    );

  }

  /// DELETE ACCOUNT DIALOG
  void showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          insetPadding: EdgeInsets.zero, // allows perfect exact sizing
          child: SizedBox(
            width: AppSize.w(335),
            child: Padding( 
              padding: EdgeInsets.symmetric(
                horizontal: AppSize.w(20),
                vertical: AppSize.h(24), 
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Icon + "Delete Account" title in one row ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/svg/delete.svg',
                        width: 50,
                        height: 50,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Delete Account",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF002C3E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Main warning text ──
                  const Text(
                    "All your data will be erased\npermanently. This cannot be\nundone.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B3A4B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Sub-caption ──
                  const Text(
                    "Your subscription must be canceled separately\nin your app store settings.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8A99A6),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Buttons ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cancel — outlined
                      SizedBox(
                        width: AppSize.w(111),
                        height: AppSize.h(46),
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
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
                          onPressed: deleting
                              ? null
                              : () async {
                                  setState(() => deleting = true);
                                  final success =
                                      await DeleteAccountApi.deleteAccount();
                                  if (!mounted) return;
                                  if (success) {
                                    await TokenStorage.clear();
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (_) => const LoginPage(),
                                      ),
                                      (route) => false,
                                    );
                                  } else {
                                    setState(() => deleting = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("Delete failed")),
                                    );
                                  }
                                },
                          child: deleting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
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
    );
  }
}
