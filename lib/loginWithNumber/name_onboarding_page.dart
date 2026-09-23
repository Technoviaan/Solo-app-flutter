import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:solo_app/core/storage/token_storage.dart';
import '../core/utils/app_size.dart';
import '../home/privacy_policy_page.dart';
import '../home/terms_of_use_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'user_name_api.dart';
import 'registration_email_page.dart';
import '../widgets/solo_turquoise_animation.dart';

class NameOnboardingPage extends StatefulWidget {
  const NameOnboardingPage({super.key});

  @override
  State<NameOnboardingPage> createState() => _NameOnboardingPageState();
}

class _NameOnboardingPageState extends State<NameOnboardingPage> {
  final PageController controller = PageController();
  final TextEditingController nameController = TextEditingController();

  // SOLO button: one instance for the whole onboarding flow, lives in the
  // fixed overlay below (outside the PageView), controlled from here.
  final SoloButtonController soloController = SoloButtonController();

  int page = 0;
  String name = "";
  bool loading = false;
  String error = "";
  bool isNameEntered = false;
  final FocusNode nameFocusNode = FocusNode();
  bool isFocused = false;

  Timer? _typingTimer;

  // Height reserved at the top of every page for the fixed SOLO button +
  // "Hello" header overlay, so page content never overlaps it.
  double get _headerReserve => AppSize.h(240);

  @override
  void initState() {
    super.initState();
    nameController.addListener(() {
      setState(() {
        isNameEntered = nameController.text.trim().isNotEmpty;
      });

      // Spec: on field focus or when the user starts typing, SOLO looks
      // down at the field; it resumes wandering 1s after the last
      // keystroke (or on blur, handled below).
      soloController.lookDown();
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 1), () {
        soloController.resume();
      });
    });

    nameFocusNode.addListener(() {
      setState(() {
        isFocused = nameFocusNode.hasFocus;
      });
      if (nameFocusNode.hasFocus) {
        soloController.lookDown();
      } else {
        _typingTimer?.cancel();
        soloController.resume();
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    nameController.dispose();
    nameFocusNode.dispose();
    super.dispose();
  }

  void submitName() async {
    final enteredName = nameController.text.trim();

    if (enteredName.isEmpty) {
      setState(() => error = "Name required");
      return;
    }

    setState(() {
      loading = true;
      error = "";
    });

    FocusScope.of(context).unfocus();

    final res = await NameApi.saveName(enteredName);

    setState(() {
      loading = false;
    });

    if (res["status"] == 1) {
      await TokenStorage.saveNameCompleted(true);
      await TokenStorage.saveUserName(enteredName);

      setState(() {
        name = enteredName;
      });

      controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  void next() {
    FocusScope.of(context).unfocus();

    // Page 0 (Name input) par naam submit hoga
    if (page == 0) {
      submitName();
      return;
    }

    // Page 1 ya Page 2 par kahin bhi "Get Started" dabane par seedha RegistrationEmailPage par jayega
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const RegistrationEmailPage(),
      ),
    );
  }

  /// Fixed overlay: SOLO button + "Hello" header.
  /// Lives OUTSIDE the PageView so it is mounted exactly once and never
  /// moves, resizes, or re-renders when the page changes (per spec).
  /// "Hello" is shared by screens 1 & 2 only; screen 3 has its own
  /// "How SOLO works" heading, drawn as part of that page's own content.
  Widget _buildSharedHeader() {
    return SizedBox(
      height: _headerReserve,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: SoloTurquoiseAnimation(
              controller: soloController,
              width: AppSize.w(195.13),
              height: AppSize.w(195.13),
            ),
          ),
          if (page < 2)
            Positioned(
              left: 0,
              bottom: 0,
              child: Text(
                "Hello",
                style: TextStyle(
                  fontSize: AppSize.sp(48),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF002C3E),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    bool isKeyboardVisible = keyboardHeight > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF88C7CF),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: controller,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (p) {
                setState(() {
                  page = p;
                });
              },
              children: [
                /// PAGE 1
                SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: isKeyboardVisible ? keyboardHeight + 20 : AppSize.h(140),
                  ),
                  child: buildNamePage(),
                ),

                /// PAGE 2
                SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: AppSize.h(160)),
                  child: buildHelloPage(),
                ),

                /// PAGE 3
                SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: AppSize.h(160)),
                  child: buildHowSoloWorks(),
                ),
              ],
            ),

            // Fixed SOLO button + "Hello" header — mounted once, persists
            // across all 3 screens, unaffected by PageView transitions.
            Positioned(
              top: AppSize.h(20),
              left: AppSize.w(24),
              right: AppSize.w(24),
              child: IgnorePointer(child: _buildSharedHeader()),
            ),

            // Bottom navigation and Footer (Figma Aligned)
            Positioned(
              bottom: isKeyboardVisible ? keyboardHeight + 12 : AppSize.h(24),
              left: AppSize.w(24),
              right: AppSize.w(24),
              child: Container(
                color: const Color(0xFF88C7CF).withValues(alpha: 0.95),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox.shrink(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              page == 0 ? "Next" : "Get Started",
                              style: TextStyle(
                                fontSize: AppSize.sp(18),
                                color: const Color(0xFF5A6C7D).withValues(
                                    alpha: isNameEntered || page > 0 ? 0.8 : 0.2),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: AppSize.w(12)),
                            GestureDetector(
                              onTap: (isNameEntered || page > 0) && !loading
                                  ? next
                                  : null,
                              child: Opacity(
                                opacity: isNameEntered || page > 0 ? 1.0 : 0.3,
                                child: loading
                                    ? Container(
                                  height: AppSize.h(50),
                                  width: AppSize.h(50),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFB7D43A),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                        color: Color(0xFF002C3E)),
                                  ),
                                )
                                    : SvgPicture.asset(
                                  "assets/svg/nextbutton.svg",
                                  height: AppSize.h(52),
                                  width: AppSize.h(52),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: AppSize.h(12)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text.rich(
                        TextSpan(
                          text: "By continuing, you agree to our ",
                          children: [
                            TextSpan(
                              text: "Privacy Policy",
                              style: const TextStyle(
                                  color: Color(0xFF5A6C7D),
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const PrivacyPolicyPage()),
                                  );
                                },
                            ),
                            const TextSpan(text: " & "),
                            TextSpan(
                              text: "Terms of Service",
                              style: const TextStyle(
                                  color: Color(0xFF5A6C7D),
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const TermsOfUsePage()),
                                  );
                                },
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppSize.sp(9.5),
                          color: const Color(0xFF5A6C7D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// PAGE 1 — content below the shared "Hello" header only.
  Widget buildNamePage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSize.w(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: _headerReserve),
          SizedBox(height: AppSize.h(32)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: AppSize.w(16)),
            height: AppSize.h(56),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(5, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: AppSize.w(32),
                  height: AppSize.w(32),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0B3948),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                      child: Icon(Icons.add, color: Colors.white, size: 20)),
                ),
                SizedBox(width: AppSize.w(15)),
                Expanded(
                  child: TextField(
                    controller: nameController,
                    focusNode: nameFocusNode,
                    decoration: InputDecoration(
                      hintText: "Add First Name",
                      hintStyle: TextStyle(
                        color: const Color(0xFF8A99A6),
                        fontSize: AppSize.sp(16),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (error.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: AppSize.h(8), left: AppSize.w(15)),
              child: Text(
                error,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  /// PAGE 2 — content below the shared "Hello" header only. The name line
  /// is drawn here (not the word "Hello", which the fixed overlay already
  /// shows) so it lines up right underneath it.
  Widget buildHelloPage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSize.w(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: _headerReserve),
          Text(
            "$name...",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: AppSize.sp(48),
              color: const Color(0xFF002C3E),
              height: 1.1,
            ),
          ),
          SizedBox(height: AppSize.h(24)),
          Text.rich(
            TextSpan(
              text: "I’m ",
              style: TextStyle(
                fontSize: AppSize.sp(36),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF002C3E),
                height: 1.2,
              ),
              children: [
                TextSpan(
                  text: "SOLO",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: AppSize.sp(36),
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const TextSpan(text: "\nyour daily\n"),
                TextSpan(
                  text: "Check-in Buddy",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontWeight: FontWeight.bold,
                    fontSize: AppSize.sp(36),
                  ),
                ),
                const TextSpan(text: "\nI’ll be here for you"),
              ],
            ),
          ),
          SizedBox(height: AppSize.h(16)),
          GestureDetector(
            onTap: () {
              controller.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.ease,
              );
            },
            child: Text(
              "Learn how >",
              style: TextStyle(
                fontSize: AppSize.sp(16),
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                color: const Color(0xFF002C3E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// PAGE 3 — its own "How SOLO works" heading (not shared with pages 1/2),
  /// but starts at the same offset so it lines up under the fixed SOLO
  /// button, which is still visible via the overlay above.
  Widget buildHowSoloWorks() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: _headerReserve),
          Text.rich(
            const TextSpan(
              text: "How\n",
              children: [
                TextSpan(
                  text: "SOLO",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: " works"),
              ],
            ),
            style: TextStyle(
              fontSize: AppSize.sp(42),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF002C3E),
              height: 1.1,
            ),
          ),
          SizedBox(height: AppSize.h(20)),
          buildStep(
            "1",
            "Choose when I check in on you each day",
            "Tap SOLO’s button during check-ins",
          ),
          buildStep(
            "2",
            "Choose when I alert your contacts",
            "1 hour (fast) or 2 hours (default)",
          ),
          buildStep(
            "3",
            "I alert your contacts by SMS with your location",
            "Send straight to their phones",
          ),
          buildStep(
            "4",
            "I provide an SOS button for emergency alerts",
            "Activate it on the check-in screen",
          ),
        ],
      ),
    );
  }

  Widget buildStep(String number, String title, String subtitle) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.h(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSize.w(42),
            height: AppSize.w(42),
            decoration: const BoxDecoration(
              color: Color(0xFF002C3E),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppSize.sp(24),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSize.w(15)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppSize.sp(19),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF002C3E),
                  ),
                ),
                SizedBox(height: AppSize.h(4)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: AppSize.sp(13),
                    color: const Color(0xFF002C3E),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}