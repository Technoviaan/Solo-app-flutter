import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:solo_app/core/storage/token_storage.dart';
import '../core/utils/app_size.dart';
import '../home/privacy_policy_page.dart';
import '../home/terms_of_use_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'user_name_api.dart';
import 'registration_email_page.dart';

class NameOnboardingPage extends StatefulWidget {
  const NameOnboardingPage({super.key});

  @override
  State<NameOnboardingPage> createState() => _NameOnboardingPageState();
}

class _NameOnboardingPageState extends State<NameOnboardingPage> {
  final PageController controller = PageController();

  final TextEditingController nameController = TextEditingController();

  int page = 0;
  String name = "";
  bool loading = false;
  String error = "";
  bool isNameEntered = false;
  final FocusNode nameFocusNode = FocusNode();
  bool isFocused = false;

  @override
  void initState() {
    super.initState();
    nameController.addListener(() {
      setState(() {
        isNameEntered = nameController.text.trim().isNotEmpty;
      });
    });
    nameFocusNode.addListener(() {
      setState(() {
        isFocused = nameFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
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

    FocusScope.of(context).unfocus(); // Close keyboard

    final res = await NameApi.saveName(enteredName);

    setState(() {
      loading = false;
    });

    if (res["status"] == 1) {
      await TokenStorage.saveNameCompleted(true);
      await TokenStorage.saveUserName(enteredName);

      /// name state update
      setState(() {
        name = enteredName;
      });

      /// go to next onboarding page
      controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  void next() {
    FocusScope.of(context).unfocus();
    if (page == 0) {
      submitName();
      return;
    }

    if (page < 2) {
      controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const RegistrationEmailPage(),
      ),
    );
  }

  String _getMascotAsset() {
    if (page == 0) {
      return isFocused ? 'assets/svg/second.svg' : 'assets/svg/first.svg';
    } else if (page == 1) {
      return 'assets/svg/third.svg';
    } else {
      return 'assets/svg/fourth.svg';
    }
  }

  Widget _buildMascot() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: SvgPicture.asset(
        _getMascotAsset(),
        key: ValueKey(_getMascotAsset()),
        width: AppSize.w(195.13),
        height: AppSize.w(195.13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);
    bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF88C7CF),
      body: Stack(
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
              buildNamePage(),

              /// PAGE 2
              buildHelloPage(),

              /// PAGE 3
              buildHowSoloWorks(),
            ],
          ),

          // Bottom navigation and Footer
          Positioned(
            bottom: isKeyboardVisible ? 10 : AppSize.h(40),
            left: AppSize.w(24),
            right: AppSize.w(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      page == 0 ? "Next" : "Get Started",
                      style: TextStyle(
                        fontSize: AppSize.sp(20),
                        color: const Color(0xFF5A6C7D)
                            .withValues(alpha: isNameEntered || page > 0 ? 0.8 : 0.2),                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: AppSize.w(15)),
                    GestureDetector(
                      onTap:
                          (isNameEntered || page > 0) && !loading ? next : null,
                      child: Opacity(
                        opacity: isNameEntered || page > 0 ? 1.0 : 0.3,
                        child: loading
                            ? Container(
                                height: AppSize.h(60),
                                width: AppSize.h(60),
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
                                height: AppSize.h(60),
                                width: AppSize.h(60),
                              ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSize.h(15)),
                Text.rich(
                  TextSpan(
                    text: "By continuing, you agree to our ",
                    children: [
                      TextSpan(
                        text: "Privacy Policy",
                        style: const TextStyle(
                            color:  Color(0xFF5A6C7D),
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w600
                            ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                            );
                          },
                      ),
                      const TextSpan(text: " & "),
                      TextSpan(
                        text: "Terms of Service",
                        style: const TextStyle(
                            color:  Color(0xFF5A6C7D),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TermsOfUsePage()),
                            );
                          },
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppSize.sp(10),
                    color: const Color(0xFF5A6C7D),
                  ),
                ),
                // const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// PAGE 1
  Widget buildNamePage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSize.w(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppSize.h(60)),

          SizedBox(
            height: AppSize.h(200.13),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildMascot(),
                ),
                // SizedBox(height: AppSize.h(60)),
                Positioned(
                  bottom: -AppSize.h(53),

                  // Moves Hello up into the mascot area
                  left: 0,
                  child: Text(
                    "Hello",
                    style: TextStyle(
                      fontSize: AppSize.sp(60),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF002C3E),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: AppSize.h(50)),

          //  SizedBox(height: AppSize.h(5)),

          Container(
            padding: EdgeInsets.symmetric(horizontal: AppSize.w(16)),
            height: AppSize.h(56),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
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

  /// PAGE 2
  Widget buildHelloPage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSize.w(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppSize.h(60)),
          SizedBox(
            height: AppSize.h(200),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildMascot(),
                ),
                Positioned(
                  bottom: -AppSize.h(60),
                  left: 0,
                  child: Text.rich(
                    TextSpan(
                      text: "Hello\n",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: AppSize.sp(48),
                        color: const Color(0xFF002C3E),
                        height: 1.1,
                      ),
                      children: [
                        TextSpan(
                          text: "$name...",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSize.h(100)),
          Text.rich(
            TextSpan(
              text: "I’m ",
              children: [
                TextSpan(
                  text: "SOLO",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.bold,
                    fontSize: AppSize.sp(36),
                  ),
                ),
                const TextSpan(text: "\nyour daily\n"),
                TextSpan(
                  text: "Check-in Buddy",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: AppSize.sp(36),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: "\nI’ll be here for you\n"),
              ],
            ),
            style: TextStyle(
              fontSize: AppSize.sp(36),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF002C3E),
              height: 1.2,
            ),
          ),
          SizedBox(height: AppSize.h(8)),
          GestureDetector(
            onTap: () {
              controller.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.ease,
              );
            },
            child: const Text(
              "Learn how >",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                color: Color(0xFF002C3E),
              ),
            ),
          ),
        ],
      ),
    );
  }
  /// PAGE 3
  Widget buildHowSoloWorks() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSize.w(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppSize.h(60)),
          Align(
            alignment: Alignment.centerRight,
            child: _buildMascot(),
          ),
         // SizedBox(height: AppSize.h(10)),
          Text.rich(
            TextSpan(
              text: "How\n",
              children: [
                TextSpan(
                  text: "SOLO",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                ),
                const TextSpan(text: " works"),
              ],
            ),
            style: TextStyle(
              fontSize: AppSize.sp(42),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF002C3E),
              height: 1.1,
            ),
          ),
          SizedBox(height: AppSize.h(30)),
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
            "Works without Wi-Fi or mobile data",
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
      padding: EdgeInsets.only(bottom: AppSize.h(20)),
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
                    fontSize: AppSize.sp(17),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF002C3E),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: AppSize.sp(11),
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
