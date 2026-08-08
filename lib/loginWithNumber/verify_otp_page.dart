import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solo_app/home/home_page.dart';
import 'package:solo_app/loginWithNumber/email_page.dart';
import 'package:solo_app/subscription/subscription_page.dart';
import 'package:solo_app/loginWithNumber/login_page.dart';
import 'package:solo_app/loginWithNumber/name_onboarding_page.dart';
import '../core/storage/token_storage.dart';
import 'auth_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../widgets/solo_eye.dart';
import '../core/utils/app_size.dart';

class VerifyOtpPage extends StatefulWidget {

  final String countryCode;
  final String phone;

  const VerifyOtpPage({
    super.key,
    required this.countryCode,
    required this.phone,
  });

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {

  String otp = "";
  String error = "";

  void addDigit(String digit) {
    setState(() {
      if (otp.length < 6) otp += digit;
    });
  }

  void deleteDigit() {
    if (otp.isNotEmpty) {
      setState(() {
        otp = otp.substring(0, otp.length - 1);
      });
    }
  }

  void verifyOtp() {
    if (otp.length < 6) {
      setState(() => error = "Enter valid OTP");
      return;
    }

    error = "";

    context.read<AuthBloc>().add(
      VerifyOtpEvent(
        widget.countryCode,
        widget.phone,
        otp,
      ),
    );
  }

  String get otpDisplay {
    if (otp.isEmpty) return "";
    return otp.split("").join(" ");
  }

  Widget numberButton(
    String number, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () => addDigit(number),
      child: Container(
        width: 56.w,
        height: 56.w,
        decoration: const BoxDecoration(
          color: Color(0xFF114C6A),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            number,
            style: TextStyle(
              color: const Color(0xFFC4D6E6),
              fontSize: 32.sp,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ),
    );
  }

  Widget iconKeyButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56.w,
        height: 56.w,
        decoration: const BoxDecoration(
          color: Color(0xFF114C6A),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            icon,
            color: const Color(0xFFC4D6E6),
            size: 24.sp,
          ),
        ),
      ),
    );
  }

  void resendOtp() {
    context.read<AuthBloc>().add(
      SendOtpEvent(
        widget.countryCode,
        widget.phone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF083B44),

      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) async {

          if (state is AuthVerified) {

            if (!state.nameCompleted) {

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const NameOnboardingPage(),
                ),
              );

            } else if (!state.emailCompleted) {

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const EmailPage(),
                ),
              );

            } else {
              final subStatus = await TokenStorage.getSubscriptionStatus();
              if (subStatus == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SubscriptionPage()),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomePage(),
                  ),
                );
              }
            }
          }

          if (state is AuthError) {
            setState(() => error = state.message);
          }
        },

        child: SafeArea(
          child: Column(
            children: [

              SizedBox(height: 42.h),
              Center(
                child: SoloLogoWidget(size: 58.w),
              ),
              SizedBox(height: 90.h),

              Text(
                "Enter 6 Digit Code",
                style: TextStyle(
                  color: const Color(0xFF859BAD),
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w300,
                ),
              ),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF16374E),
                  borderRadius: BorderRadius.circular(8.w),
                ),
                child: Text(
                  widget.countryCode,
                  style: TextStyle(
                    color: const Color(0xFF859BAD),
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              SizedBox(
                width: 325.w,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 325.w,
                      height: 1,
                      color: const Color(0xFF2A5D73),
                    ),
                    if (otp.isNotEmpty)
                      Container(
                        color: const Color(0xFF083B44),
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Text(
                          otpDisplay,
                          style: TextStyle(
                            color: const Color(0xFFBFD3DF),
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  children: [
                    Text(
                      "Code sent to ${widget.countryCode} ${widget.phone}",
                      style: TextStyle(
                        color: const Color(0xFF7DA1B5),
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: resendOtp,
                      child: Text(
                        "Resend",
                        style: TextStyle(
                          color: const Color(0xFF7DA1B5),
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(0xFF7DA1B5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (error.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 10.h),
                  child: Text(
                    error,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14.sp,
                    ),
                  ),
                ),

              SizedBox(height: 32.h),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        numberButton("1"),
                        numberButton("2"),
                        numberButton("3"),
                        numberButton("4"),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        numberButton("5"),
                        numberButton("6"),
                        numberButton("7"),
                        numberButton("8"),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        numberButton("+", onTap: () {}),
                        numberButton("9"),
                        numberButton("0"),
                        iconKeyButton(
                          icon: Icons.backspace_outlined,
                          onTap: deleteDigit,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              Padding(
                padding: EdgeInsets.only(
                  bottom: 24.h,
                  right: 24.w,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Next",
                      style: TextStyle(
                        color: const Color(0xFFE8EEF2),
                        fontSize: 42.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    GestureDetector(
                      onTap: verifyOtp,
                      child: SvgPicture.asset(
                        "assets/svg/nextbutton.svg",
                        width: 58.w,
                        height: 58.w,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

}