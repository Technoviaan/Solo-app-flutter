import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:solo_app/core/storage/token_storage.dart';
import 'package:solo_app/home/home_page.dart';
import 'package:solo_app/subscription/subscription_page.dart';
import 'package:solo_app/home/checkin/notification_service.dart';
import '../core/utils/app_size.dart';
import 'auth_api.dart';
import 'login_page.dart';

class EmailPage extends StatefulWidget {
  const EmailPage({super.key});

  @override
  State<EmailPage> createState() => _EmailPageState();
}

class _EmailPageState extends State<EmailPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  String error = "";
  bool loading = false;
  bool isOtpSent = false;
  String email = "";
  String otp = "";

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    return emailRegex.hasMatch(email);
  }

  void submitEmail() async {
    final enteredEmail = emailController.text.trim();

    if (enteredEmail.isEmpty) {
      setState(() => error = "Email required");
      return;
    }

    if (!isValidEmail(enteredEmail)) {
      setState(() => error = "Invalid email");
      return;
    }

    setState(() {
      loading = true;
      error = "";
    });

    FocusScope.of(context).unfocus();

    try {
      final res = await AuthApi.sendEmailOtp(enteredEmail);
      if (res['message'] != null && res['message'] == "OTP sent successfully") {
        setState(() {
          loading = false;
          isOtpSent = true;
          email = enteredEmail;
        });
      } else {
        String msg = res['message'] ?? "Account not signed up yet";
        if (msg.toLowerCase().contains("not found") ||
            msg.toLowerCase().contains("does not exist") ||
            msg.toLowerCase().contains("unregistered")) {
          msg = "Account not signed up yet";
        }
        setState(() {
          loading = false;
          error = msg;
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        error = "Account not signed up yet";
      });
    }
  }

  void verifyOtp() async {
    if (otp.length < 6) {
      setState(() => error = "Enter valid OTP");
      return;
    }

    setState(() {
      loading = true;
      error = "";
    });

    try {
      final res = await AuthApi.verifyEmailOtp(email, otp);
      if (res['token'] != null) {
        await TokenStorage.saveToken(res['token']);
        setState(() => loading = false);
        await TokenStorage.saveEmailCompleted(true);
        if (!mounted) return;
        NotificationService.getAndSaveFCMToken();
        final subStatus = await TokenStorage.getSubscriptionStatus();
        if (subStatus == 0) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SubscriptionPage()),
          );
        } else {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        setState(() {
          loading = false;
          error = res['message'] ?? "Incorrect code, please try again";
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        error = "An error occurred. Please try again.";
      });
    }
  }

  void _navigateToPhoneSignIn() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: AppSize.w(28)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppSize.h(40)),
                    Text(
                      "Hi Ehtesham,\ngood to see\nyou again",
                      style: TextStyle(
                        fontSize: AppSize.sp(44),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF002C3E),
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 14.0),
                        child: Text(
                          error,
                          style: TextStyle(
                            color: const Color(0xFFE86B56),
                            fontSize: AppSize.sp(14),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    SizedBox(height: error.isNotEmpty ? AppSize.h(25) : AppSize.h(45)),
                    if (!isOtpSent)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
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
                                const BoxShadow(
                                  color: Color(0xFFB8C2C8),
                                  blurRadius: 0,
                                  offset: Offset(5, 8),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: emailController,
                              textAlign: TextAlign.start,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(
                                  color: const Color(0xFF5A6C7D),
                                  fontSize: AppSize.sp(16),
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400),
                              decoration: InputDecoration(
                                hintText: "Your Email",
                                hintStyle: const TextStyle(
                                  color: Color(0xFF8A99A6),
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                ),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Container(
                                    width: 35,
                                    height: 42,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF002C3E),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.email_outlined,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                                border: InputBorder.none,
                                suffixIcon: const SizedBox(width: 40),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: AppSize.h(14)),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: _navigateToPhoneSignIn,
                              child: Text.rich(
                                const TextSpan(
                                  text: "Sign in with ",
                                  children: [
                                    TextSpan(
                                      text: "Phone Number",
                                      style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w700,
                                        decorationColor: Color(0xFF8A99A6),
                                      ),
                                    ),
                                  ],
                                ),
                                style: TextStyle(
                                  fontSize: AppSize.sp(12),
                                  color: const Color(0xFF8A99A6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
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
                                const BoxShadow(
                                  color: Color(0xFFB8C2C8),
                                  blurRadius: 0,
                                  offset: Offset(5, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 10),
                                Container(
                                    width: 42,
                                    height: 42,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF002C3E),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.smartphone,
                                        color: Colors.white, size: 20)),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: TextField(
                                    controller: otpController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    onChanged: (val) =>
                                        setState(() => otp = val),
                                    style: TextStyle(
                                      color: const Color(0xFF5A6C7D),
                                      fontSize: AppSize.sp(18),
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w400,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: "Enter 6-digit Code",
                                      hintStyle: TextStyle(
                                        color: const Color(0xFF5A6C7D)
                                            .withValues(alpha: 0.5),
                                        fontSize: AppSize.sp(18),
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w400,
                                      ),
                                      border: InputBorder.none,
                                      counterText: "",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: AppSize.h(12)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Code sent to $email",
                                  style: TextStyle(
                                    fontSize: AppSize.sp(11.5),
                                    color: const Color(0xFF8A99A6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: submitEmail,
                                  child: Text(
                                    "Resend",
                                    style: TextStyle(
                                      fontSize: AppSize.sp(11.5),
                                      color: const Color(0xFF8A99A6),
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: AppSize.h(60)),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Transform.translate(
                              offset: Offset(-AppSize.w(30), 0),
                              child: SvgPicture.asset(
                                'assets/svg/email.svg',
                                width: AppSize.w(210),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            if (isOtpSent) SizedBox(height: AppSize.h(20)),

            // Footer Section with updated "New User? Sign Up With Phone Number"
            Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSize.w(28), 10, AppSize.w(28), AppSize.bottom(24)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _navigateToPhoneSignIn,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "New User?",
                          style: TextStyle(
                            color: const Color(0xFF8A99A6),
                            fontSize: AppSize.sp(13),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          "Sign Up With\nPhone Number",
                          style: TextStyle(
                            color: const Color(0xFF8A99A6),
                            fontSize: AppSize.sp(13),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFF8A99A6),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "Sign In",
                        style: TextStyle(
                          color: const Color(0xFF002C3E).withValues(alpha: 0.7),
                          fontSize: AppSize.sp(20),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: AppSize.w(18)),
                      GestureDetector(
                        onTap: loading
                            ? null
                            : (isOtpSent ? verifyOtp : submitEmail),
                        child: loading
                            ? Container(
                          width: AppSize.w(62),
                          height: AppSize.w(62),
                          decoration: const BoxDecoration(
                            color: Color(0xFFB5D43C),
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
    );
  }
}