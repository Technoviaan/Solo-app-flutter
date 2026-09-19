import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F3),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSize.w(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppSize.h(12)),

                // ── SOLO logo ──
                const SoloLogo(),

                SizedBox(height: AppSize.h(28)),

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
                    onTap: () => showSignOutDialog(context),
                  ),
                  settingTile(
                    "Delete Account",
                    onTap: () => showDeleteDialog(context),
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

                SizedBox(height: AppSize.h(20)),

                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 16, bottom: 24),
                    child: Icon(
                      Icons.arrow_back,
                      color: Color(0xFF8A99A6),
                      size: 26,
                    ),
                  ),
                ),
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
      padding: EdgeInsets.only(left: 4, bottom: AppSize.h(10)),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: Color(0xFF002C3E),
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  /// SETTINGS BOX (Equal container layout without extra dividers)
  Widget settingsBox(List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        color: const Color(0xFF7FB4BC),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }

  /// SETTINGS TILE (Balanced padding & responsive touch target)
  Widget settingTile(String title, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.1,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 22,
              ),
            ],
          ),
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
            borderRadius: BorderRadius.circular(28),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/svg/signout.svg',
                      width: 38,
                      height: 38,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Sign Out",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF002C3E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  "Are you sure you would like\nto sign out?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF002C3E),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "You'll need to sign in again to use SOLO.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8A99A6),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
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
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
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
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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
            borderRadius: BorderRadius.circular(28),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/svg/delete.svg',
                      width: 38,
                      height: 38,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Delete Account",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF002C3E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  "All your data will be erased\npermanently. This cannot be\nundone.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF002C3E),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Your subscription must be canceled separately\nin your app store settings.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8A99A6),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
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
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
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
                                  if (!context.mounted) return;
                                  if (success) {
                                    await TokenStorage.clear();
                                    if (!context.mounted) return;
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (_) => const LoginPage(),
                                      ),
                                      (route) => false,
                                    );
                                  } else {
                                    setState(() => deleting = false);
                                    if (!context.mounted) return;
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
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
  }
}