import 'dart:async'; // Required for Timer
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:solo_app/core/storage/token_storage.dart';
import 'package:solo_app/home/home_page.dart';
import 'package:solo_app/home/privacy_policy_page.dart';
import 'package:solo_app/home/terms_of_use_page.dart';
import 'package:solo_app/loginWithNumber/user_email_api.dart';
import 'package:solo_app/subscription/subscription_page.dart';
import '../core/utils/app_size.dart';
import '../widgets/solo_mascot.dart';
import 'package:solo_app/loginWithNumber/login_page.dart';

class RegistrationEmailPage extends StatefulWidget {
  const RegistrationEmailPage({super.key});

  @override
  State<RegistrationEmailPage> createState() => _RegistrationEmailPageState();
}

class _RegistrationEmailPageState extends State<RegistrationEmailPage> {
  final TextEditingController emailController = TextEditingController();

  String emailError = "";
  String termsError = "";

  bool loading = false;
  bool agree = false;
  late TapGestureRecognizer _privacyRecognizer;
  late TapGestureRecognizer _termsRecognizer;

  Timer? _errorTimer;

  @override
  void initState() {
    super.initState();
    _privacyRecognizer = TapGestureRecognizer()..onTap = _openPrivacyPolicy;
    _termsRecognizer = TapGestureRecognizer()..onTap = _openTermsOfUse;
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    _privacyRecognizer.dispose();
    _termsRecognizer.dispose();
    emailController.dispose();
    super.dispose();
  }

  void _triggerError({String? email, String? terms}) {
    _errorTimer?.cancel();
    setState(() {
      emailError = email ?? "";
      termsError = terms ?? "";
    });

    _errorTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          emailError = "";
          termsError = "";
        });
      }
    });
  }

  void _openPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
    );
  }

  void _openTermsOfUse() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TermsOfUsePage()),
    );
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    return emailRegex.hasMatch(email);
  }

  void submitEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _triggerError(email: "Email required");
      return;
    }

    if (!isValidEmail(email)) {
      _triggerError(email: "Invalid email");
      return;
    }

    if (!agree) {
      _triggerError(terms: "Please accept terms");
      return;
    }

    setState(() {
      loading = true;
      emailError = "";
      termsError = "";
    });

    final res = await UserApi.saveEmail(email);

    setState(() => loading = false);

    if (res["status"] == 1) {
      await TokenStorage.saveEmailCompleted(true);

      final subscriptionStatus = await TokenStorage.getSubscriptionStatus();

      if (!mounted) return;
      if (subscriptionStatus == 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } else if (res["status"] == 2) {
      _triggerError(email: "Email already exists");
    } else {
      _triggerError(email: "Something went wrong");
    }
  }

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final emailFilled = emailController.text.trim().isNotEmpty;

    // Mascot ke liye form validity — email valid + terms accepted

    final isEmailValid = isValidEmail(emailController.text.trim());
    final isFormValid =
        isEmailValid && agree && emailError.isEmpty && termsError.isEmpty;

    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700; // tweak threshold as needed

    final titleFontSize = isSmallScreen ? AppSize.sp(32) : AppSize.sp(44);
    final topSpacing = isSmallScreen ? AppSize.h(24) : AppSize.h(70);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: keyboardOpen
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: AppSize.w(0),
                right: AppSize.w(24),
                bottom: keyboardOpen ? AppSize.h(40) : AppSize.h(16),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 30,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: topSpacing),
                      Padding(
                        padding: EdgeInsets.only(
                          left: AppSize.w(24),
                        ),
                        child: Text(
                          "Let's keep \nyou connected \nand cared for",
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF002C3E),
                            height: 1.2,
                          ),
                        ),
                      ),
                      SizedBox(height: AppSize.h(35)),

                      // Email Error container
                      SizedBox(
                        height: AppSize.h(20),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: AppSize.w(24)),
                            child: Text(
                              emailError,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: AppSize.sp(12),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSize.h(4)),

                      Padding(
                        padding: EdgeInsets.only(
                          left: AppSize.w(24),
                        ),
                        child: Container(
                          width: double.infinity,
                          height: AppSize.h(56),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(34),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.12),
                                blurRadius: 0,
                                offset: const Offset(5, 8),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: emailController,
                            textAlign: TextAlign.start,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (_) => setState(() {}),
                            textAlignVertical: TextAlignVertical.center,
                            style: TextStyle(
                              color: const Color(0xFF5A6C7D),
                              fontSize: AppSize.sp(16),
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: InputDecoration(
                              hintText: "Email",
                              hintStyle: const TextStyle(
                                color: Color(0xFF5A6C7D),
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                              ),
                              prefixIcon: SizedBox(
                                width: 55,
                                child: Center(
                                  child: Container(
                                    width: 35,
                                    height: 35,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF002C3E),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.email_outlined,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSize.h(14)),
                      Padding(
                        padding: EdgeInsets.only(left: AppSize.w(24)),
                        child: Text(
                          "For notifications, account recovery, updates",
                          style: TextStyle(
                            color: const Color(0xFF8A99A6),
                            fontSize: AppSize.sp(12),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(height: AppSize.h(10)),
                      Padding(
                        padding: EdgeInsets.only(
                          left: AppSize.w(24),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => agree = !agree),
                              child: Container(
                                width: AppSize.w(24),
                                height: AppSize.w(24),
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFD9E2E8),
                                    width: 2,
                                  ),
                                  color: Colors.white,
                                ),
                                child: agree
                                    ? Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF78BCC4),
                                  ),
                                )
                                    : null,
                              ),
                            ),
                            SizedBox(width: AppSize.w(12)),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  text: "I agree to our ",
                                  children: [
                                    TextSpan(
                                      text: "Privacy Policy",
                                      recognizer: _privacyRecognizer,
                                      style: const TextStyle(
                                        color: Color(0xFF5A6C7D),
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const TextSpan(text: " & "),
                                    TextSpan(
                                      text: "Terms of Service",
                                      recognizer: _termsRecognizer,
                                      style: const TextStyle(
                                        color: Color(0xFF5A6C7D),
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                style: TextStyle(
                                  fontSize: AppSize.sp(12),
                                  color: const Color(0xFF5A6C7D),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Terms Error container
                      SizedBox(
                        height: AppSize.h(20),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding:
                            EdgeInsets.only(top: AppSize.h(4), left: AppSize.w(24)),
                            child: Text(
                              termsError,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: AppSize.sp(12),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: AppSize.h(12)),

                      if (!keyboardOpen)
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: FractionalTranslation(
                              translation: const Offset(-0.15, 0),
                              child: FittedBox(
                                fit: BoxFit.contain,
                                alignment: Alignment.bottomLeft,
                                child: SizedBox(
                                  width: 260,
                                  height: 260,
                                  child: IgnorePointer(
                                    child: SoloMascot(isFormValid: isFormValid),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      Padding(
                        padding: EdgeInsets.only(bottom: AppSize.h(10)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                ),
                              ),
                              child: const SizedBox(width: 18),
                            ),
                            Row(
                              children: [
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    color: emailFilled
                                        ? const Color(0xFF8A99A6)
                                        : const Color(0xFF8A99A6)
                                        .withValues(alpha: 0.2),
                                    fontSize: AppSize.sp(20),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  child: const Text("Continue"),
                                ),
                                SizedBox(width: AppSize.w(18)),
                                GestureDetector(
                                  onTap: loading ? null : submitEmail,
                                  child: loading
                                      ? Container(
                                    width: AppSize.w(62),
                                    height: AppSize.w(62),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFB7D43A),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF002C3E),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                      : SvgPicture.asset(
                                    "assets/svg/nextbutton.svg",
                                    width: AppSize.w(62),
                                    height: AppSize.w(62),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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