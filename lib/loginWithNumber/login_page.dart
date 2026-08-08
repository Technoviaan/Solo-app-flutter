import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:country_code_picker/country_code_picker.dart';
import 'package:solo_app/home/checkin/notification_service.dart';
import 'package:solo_app/home/home_page.dart';
import 'package:solo_app/core/storage/token_storage.dart';
import 'package:solo_app/loginWithNumber/email_page.dart';
import 'package:solo_app/loginWithNumber/name_onboarding_page.dart';
import 'package:solo_app/loginWithNumber/registration_email_page.dart';
import 'package:solo_app/subscription/subscription_page.dart';
import 'auth_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'verify_otp_page.dart';
import '../widgets/solo_eye.dart';
import '../core/utils/app_size.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String defaultDialCode = ""; 
  bool isFetchingCountry = true;

  String phone = "";
  String otp = "";
  bool isOtpSent = false;
  String error = "";

  String lastUsedDialCode = "";
  String lastUsedPhone = "";

  @override
  void initState() {
    super.initState();
    _fetchCountryCode();
  }

  Future<void> _fetchCountryCode() async {
    if (!mounted) return;
    setState(() {
      isFetchingCountry = true;
    });
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final countryCode = data['countryCode']; 
        final match = codes.firstWhere((c) => c['code'] == countryCode, orElse: () => {});
        if (match.isNotEmpty) {
          if (mounted) {
            setState(() {
              defaultDialCode = match['dial_code']!;
              isFetchingCountry = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      // ignore
    }
    
    if (mounted) {
      setState(() {
        defaultDialCode = "+1";
        isFetchingCountry = false;
      });
    }
  }

  String get activeDialCode {
    if (phone.startsWith('+')) {
      final matches = codes.where((c) => phone.startsWith(c['dial_code']!)).toList();
      if (matches.isNotEmpty) {
        matches.sort((a, b) => b['dial_code']!.length.compareTo(a['dial_code']!.length));
        return matches.first['dial_code']!;
      }
      return ""; 
    }
    
    if (phone.isNotEmpty) {
      final matches = codes.where((c) {
        String codeDigits = c['dial_code']!.replaceAll('+', '');
        return phone.startsWith(codeDigits);
      }).toList();
      if (matches.isNotEmpty) {
        matches.sort((a, b) => b['dial_code']!.length.compareTo(a['dial_code']!.length));
        return matches.first['dial_code']!;
      }
    }
    
    return defaultDialCode;
  }

  String get displayPhone {
    if (phone.isEmpty) return "";
    String code = activeDialCode;
    if (phone.startsWith('+')) {
      if (code.isNotEmpty && phone.startsWith(code)) {
        return phone.substring(code.length);
      }
      return phone; 
    } else {
      if (code.isNotEmpty && code != defaultDialCode) {
        String codeDigits = code.replaceAll('+', '');
        if (phone.startsWith(codeDigits)) {
          return phone.substring(codeDigits.length);
        }
      }
    }
    return phone;
  }

  void addDigit(String digit) {
    if (context.read<AuthBloc>().state is AuthLoading) return;
    
    HapticFeedback.lightImpact();
    setState(() {
      error = "";
      if (!isOtpSent) {
        if (phone.length < 16) {
          phone += digit;
        }
      } else {
        if (otp.length < 6) {
          otp += digit;
          if (otp.length == 6) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted && otp.length == 6) verifyOtp();
            });
          }
        }
      }
    });
  }

  void deleteDigit() {
    if (context.read<AuthBloc>().state is AuthLoading) return;
    
    HapticFeedback.lightImpact();
    setState(() {
      error = "";
      if (!isOtpSent) {
        if (phone.isNotEmpty) {
          phone = phone.substring(0, phone.length - 1);
        }
      } else {
        if (otp.isNotEmpty) {
          otp = otp.substring(0, otp.length - 1);
        }
      }
    });
  }

  void validateAndSend() {
    if (phone.isEmpty) {
      setState(() => error = "Phone number required");
      return;
    }

    String finalDialCode = defaultDialCode;
    String finalPhone = phone;

    String code = activeDialCode;
    if (code.isNotEmpty) {
      finalDialCode = code;
      if (phone.startsWith('+')) {
        finalPhone = phone.substring(code.length);
      } else {
        if (code != defaultDialCode) {
          String codeDigits = code.replaceAll('+', '');
          if (phone.startsWith(codeDigits)) {
            finalPhone = phone.substring(codeDigits.length);
          }
        }
      }
    } else if (phone.startsWith('+')) {
      setState(() => error = "Invalid country code");
      return;
    }

    if (finalPhone.length < 5) {
      setState(() => error = "Invalid phone number");
      return;
    }

    error = "";
    lastUsedDialCode = finalDialCode;
    lastUsedPhone = finalPhone;
    FocusScope.of(context).unfocus(); 
    context.read<AuthBloc>().add(
      SendOtpEvent(
        finalDialCode,
        finalPhone,
      ),
    );
  }

  void verifyOtp() {
    if (otp.length < 6) {
      setState(() => error = "Enter valid OTP");
      return;
    }
    error = "";
    FocusScope.of(context).unfocus(); 
    context.read<AuthBloc>().add(
      VerifyOtpEvent(
        lastUsedDialCode,
        lastUsedPhone,
        otp,
      ),
    );
  }

  void resendOtp() {
    setState(() {
      otp = "";
      error = "";
    });
    context.read<AuthBloc>().add(
      SendOtpEvent(
        lastUsedDialCode,
        lastUsedPhone,
      ),
    );
  }

  Widget numberButton(
    String number, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: const Color(0xFF16374E),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => addDigit(number),
        splashColor: const Color(0xFF1C4E76),
        highlightColor: const Color(0xFF1C4E76),
        child: Container(
          width: 64.w,
          height: 64.w,
          alignment: Alignment.center,
          child: Text(
            number,
            style: TextStyle(
              color: const Color(0xFF859BAD),
              fontSize: 24.sp,
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
    return Material(
      color: const Color(0xFF16374E),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0xFF1C4E76),
        highlightColor: const Color(0xFF1C4E76),
        child: Container(
          width: 64.w,
          height: 64.w,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: const Color(0xFF859BAD),
            size: 24.sp,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isOtpSent,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isOtpSent) {
          setState(() {
            isOtpSent = false;
            otp = "";
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF002C3E),

      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {

          if (state is OtpSent) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  isOtpSent = true;
                  error = "";
                });
              }
            });
          }

          if (state is AuthVerified) {
            NotificationService.getAndSaveFCMToken();
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (!mounted) return;
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
                    builder: (_) => const RegistrationEmailPage(),
                  ),
                );
              } else {
                final subStatus = await TokenStorage.getSubscriptionStatus();
                if (!mounted) return;
                if (subStatus == 0) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionPage(),
                    ),
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
            });
          }

          if (state is AuthError) {
            setState(() {
              error = state.message;
            });
          }

        },

        child: SafeArea(
          child: Column(
            children: [

              SizedBox(height: 42.h),

              Center(
                child: Hero(
                  tag: 'logo_hero',
                  child: Material(
                    color: Colors.transparent,
                    child: SoloLogoWidget(size: 72.w),
                  ),
                ),
              ),
 
              SizedBox(height: 120.h),

              if (isOtpSent)
                Column(
                  children: [
                    Text(
                      error.isNotEmpty
                          ? "Incorrect code, please try again"
                          : (otp.isEmpty ? "Enter 6 Digit Code" : otp),
                      style: TextStyle(
                        color: error.isNotEmpty
                            ? Colors.red
                            : (otp.isEmpty ? const Color(0xFF859BAD) : const Color(0xFFF5F5F5)),
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Container(
                      width: 322.w,
                      height: 1,
                      color: otp.isNotEmpty ? const Color(0xFFF5F5F5) : const Color(0xFF294256),
                    ),
                    SizedBox(height: 8.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Code sent to $lastUsedDialCode ${lastUsedPhone.length > 4 ? "${lastUsedPhone.substring(0, 4)} ${lastUsedPhone.substring(4)}" : lastUsedPhone}",
                            style: TextStyle(
                              color: const Color(0xFF8A99A6),
                              fontSize: 11.sp,
                            ),
                          ),
                          GestureDetector(
                            onTap: resendOtp,
                            child: Text(
                              "Resend",
                              style: TextStyle(
                                color: const Color(0xFF8A99A6),
                                fontSize: 11.sp,
                                decoration: TextDecoration.underline,
                                decorationColor: const Color(0xFF8A99A6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    if (error.isNotEmpty)
                      Text(
                        error,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14.sp,
                        ),
                      )
                    else
                      SizedBox(height: 14.h),
                    SizedBox(height: 14.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isFetchingCountry && phone.isNotEmpty)
                          SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              color: Color(0xFF859BAD),
                              strokeWidth: 2,
                            ),
                          )
                        else if (phone.isNotEmpty)
                          Text(
                            activeDialCode.isNotEmpty ? activeDialCode : defaultDialCode,
                            style: TextStyle(
                              color: const Color(0xFFF5F5F5),
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        if (phone.isNotEmpty) SizedBox(width: 10.w),
                        Text(
                          phone.isEmpty
                              ? "Your Phone Number"
                              : (displayPhone.length > 4
                                  ? "${displayPhone.substring(0, 4)} ${displayPhone.substring(4)}"
                                  : displayPhone),
                          style: TextStyle(
                            color: phone.isNotEmpty ? const Color(0xFFF5F5F5) : const Color(0xFF859BAD),
                            fontSize: 20.5.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: 322.w,
                      height: 1,
                      color: phone.isNotEmpty ? const Color(0xFFF5F5F5) : const Color(0xFF294256),
                    ),
                  ],
                ),

              SizedBox(height: 15.h),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 10.h),
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
                    SizedBox(height: 25.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        numberButton("5"),
                        numberButton("6"),
                        numberButton("7"),
                        numberButton("8"),
                      ],
                    ),
                    SizedBox(height: 25.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        numberButton("+", onTap: (isOtpSent || phone.isNotEmpty) ? null : () => addDigit("+")),
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
                  bottom: AppSize.bottom(24),
                  right: 24.w,
                  left: 24.w,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EmailPage(),
                          ),
                        );
                      },
                      child: Text( 
                        "Email Sign In",
                        style: TextStyle(
                          color: const Color(0xFF6E97AE),
                          fontSize: 16.sp, 
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "Next",
                          style: TextStyle(
                            color: (!isOtpSent && phone.length >= 5) || (isOtpSent && otp.length == 6)
                                ? const Color(0xFF6E97AE)
                                : const Color(0xFF6E97AE).withOpacity(0.5),
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        SizedBox(width: 14.w),
                        GestureDetector(
                          onTap: () {
                            if (context.read<AuthBloc>().state is AuthLoading) return;
                            if (!isOtpSent) {
                              if (phone.length >= 5) validateAndSend();
                            } else {
                              if (otp.length == 6) verifyOtp();
                            }
                          },
                          child: BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              final isEnabled = (!isOtpSent && phone.length >= 5) || (isOtpSent && otp.length == 6);
                              
                              if (state is AuthLoading) {
                                return Container(
                                  width: 60.w,
                                  height: 60.w,
                                  decoration: BoxDecoration(
                                    color: isEnabled ? const Color(0xFFB5D43C) : const Color(0xFFB5D43C).withOpacity(0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24.w,
                                      height: 24.w,
                                      child: const CircularProgressIndicator(
                                        color: Color(0xFF0A3D56),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              
                              return Opacity(
                                opacity: isEnabled ? 1.0 : 0.4,
                                child: SvgPicture.asset(
                                  "assets/svg/nextbutton.svg",
                                  width: 60.w,
                                  height: 60.w,
                                ),
                              );
                            },
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
      )
    );
  }
  
}
