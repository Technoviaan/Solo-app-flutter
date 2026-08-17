import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:http/http.dart' as http;
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
import '../widgets/solo_eye.dart';
import '../core/utils/app_size.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String selectedDialCode = "+91";
  String selectedIsoCode = "IN";

  String phone = "";
  String otp = "";
  bool isOtpSent = false;
  String error = "";

  String lastUsedDialCode = "";
  String lastUsedPhone = "";

  static const Map<String, String> _worldIsoToDialCode = {
    'IN': '+91',  'US': '+1',   'CA': '+1',   'NP': '+977', 'GB': '+44',
    'AU': '+61',  'AE': '+971', 'SA': '+966', 'PK': '+92',  'BD': '+880',
    'LK': '+94',  'DE': '+49',  'FR': '+33',  'JP': '+81',  'CN': '+86',
    'RU': '+7',   'BR': '+55',  'MX': '+52',  'ZA': '+27',  'IT': '+39',
    'ES': '+34',  'SG': '+65',  'MY': '+60',  'ID': '+62',  'TH': '+66',
    'PH': '+63',  'VN': '+84',  'KR': '+82',  'NZ': '+64',  'EG': '+20',
    'NG': '+234', 'KE': '+254', 'AR': '+54',  'CL': '+56',  'CO': '+57',
    'TR': '+90',  'UA': '+380', 'PL': '+48',  'NL': '+31',  'SE': '+46',
    'NO': '+47',  'FI': '+358', 'DK': '+45',  'CH': '+41',  'AT': '+43',
    'KW': '+965', 'QA': '+974', 'OM': '+968', 'BH': '+973', 'IE': '+353',
  };

  static const Map<String, int> _dialCodeToRequiredLength = {
    '+91': 10,
    '+1': 10,
    '+977': 10,
    '+44': 10,
    '+61': 9,
    '+971': 9,
    '+966': 9,
    '+92': 10,
    '+880': 10,
    '+94': 9,
    '+49': 10,
    '+33': 9,
    '+81': 10,
    '+86': 11,
    '+7': 10,
    '+55': 11,
    '+52': 10,
    '+27': 9,
    '+39': 10,
    '+34': 9,
    '+65': 8,
    '+60': 9,
    '+62': 10,
    '+66': 9,
    '+63': 10,
    '+84': 9,
    '+82': 10,
    '+64': 9,
    '+965': 8,
    '+974': 8,
    '+968': 8,
    '+973': 8,
    '+353': 9,
  };

  int get _currentRequiredPhoneLength => _dialCodeToRequiredLength[selectedDialCode] ?? 10;

  bool get _isNextButtonEnabled {
    if (!isOtpSent) {
      return phone.length == _currentRequiredPhoneLength;
    } else {
      return otp.length == 6;
    }
  }

  @override
  void initState() {
    super.initState();
    _autoFetchUserCountry();
  }

  // Multi-tier Auto Fetching (Fast Locale -> Geo IP) with debug console logs
  Future<void> _autoFetchUserCountry() async {
    // 1. Device Locale Check
    try {
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      final countryCode = locale.countryCode?.toUpperCase();
      debugPrint("📱 [Country Detect] Device Locale Code: $countryCode");

      if (countryCode != null && _worldIsoToDialCode.containsKey(countryCode)) {
        if (mounted) {
          setState(() {
            selectedIsoCode = countryCode;
            selectedDialCode = _worldIsoToDialCode[countryCode]!;
          });
          debugPrint("✅ [Country Detect] Initialized via Locale: $selectedIsoCode ($selectedDialCode)");
        }
      }
    } catch (e) {
      debugPrint("❌ [Country Detect] Locale Error: $e");
    }

    // 2. Real-time Network Location Check (Accurate according to actual country/Play Store region)
    try {
      final response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ipCountry = data['country_code']?.toString().toUpperCase();
        final ipCallingCode = data['country_calling_code']?.toString();
        debugPrint("🌐 [Country Detect] Primary Geo-IP Response: Country=$ipCountry, CallingCode=$ipCallingCode");

        if (ipCountry != null && mounted) {
          setState(() {
            selectedIsoCode = ipCountry;
            if (ipCallingCode != null && ipCallingCode.isNotEmpty) {
              selectedDialCode = ipCallingCode.startsWith('+') ? ipCallingCode : '+$ipCallingCode';
            } else if (_worldIsoToDialCode.containsKey(ipCountry)) {
              selectedDialCode = _worldIsoToDialCode[ipCountry]!;
            }
          });
          debugPrint("✅ [Country Detect] Final Country Selected: $selectedIsoCode ($selectedDialCode) | Required Digits: $_currentRequiredPhoneLength");
          return;
        }
      }
    } catch (e) {
      debugPrint("⚠️ [Country Detect] Primary IP check skipped/failed: $e");
      // Fallback secondary IP API
      try {
        final fallbackRes = await http
            .get(Uri.parse('http://ip-api.com/json'))
            .timeout(const Duration(seconds: 3));
        if (fallbackRes.statusCode == 200) {
          final data = jsonDecode(fallbackRes.body);
          final ipCountry = data['countryCode']?.toString().toUpperCase();
          debugPrint("🌐 [Country Detect] Fallback Geo-IP Response: Country=$ipCountry");
          if (ipCountry != null && _worldIsoToDialCode.containsKey(ipCountry) && mounted) {
            setState(() {
              selectedIsoCode = ipCountry;
              selectedDialCode = _worldIsoToDialCode[ipCountry]!;
            });
            debugPrint("✅ [Country Detect] Final Country via Fallback: $selectedIsoCode ($selectedDialCode)");
          }
        }
      } catch (_) {}
    }
  }

  void addDigit(String digit) {
    if (context.read<AuthBloc>().state is AuthLoading) return;

    HapticFeedback.lightImpact();
    setState(() {
      error = "";
      if (!isOtpSent) {
        if (phone.length < _currentRequiredPhoneLength) {
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
    if (phone.length != _currentRequiredPhoneLength) {
      setState(() => error = "Please enter complete $_currentRequiredPhoneLength digit number");
      return;
    }

    String sanitizedPhone = phone;
    if (sanitizedPhone.startsWith('+')) {
      sanitizedPhone = sanitizedPhone.replaceFirst(RegExp(r'^\+'), '');
      final dialDigits = selectedDialCode.replaceFirst('+', '');
      if (sanitizedPhone.startsWith(dialDigits)) {
        sanitizedPhone = sanitizedPhone.substring(dialDigits.length);
      }
    }

    error = "";
    lastUsedDialCode = selectedDialCode;
    lastUsedPhone = sanitizedPhone;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      SendOtpEvent(
        lastUsedDialCode,
        lastUsedPhone,
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

  Widget numberButton(String number, {VoidCallback? onTap}) {
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
        resizeToAvoidBottomInset: false,
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
                            ? error
                            : (otp.isEmpty ? "Enter 6 Digit Code" : otp),
                        style: TextStyle(
                          color: error.isNotEmpty
                              ? Colors.red
                              : (otp.isEmpty
                              ? const Color(0xFF859BAD)
                              : const Color(0xFFF5F5F5)),
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Container(
                        width: 322.w,
                        height: 1,
                        color: otp.isNotEmpty
                            ? const Color(0xFFF5F5F5)
                            : const Color(0xFF294256),
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CountryCodePicker(
                            key: ValueKey(selectedIsoCode),
                            onChanged: (country) {
                              setState(() {
                                selectedIsoCode = country.code ?? "IN";
                                selectedDialCode = country.dialCode ?? "+91";
                                if (phone.length > _currentRequiredPhoneLength) {
                                  phone = phone.substring(0, _currentRequiredPhoneLength);
                                }
                              });
                            },
                            initialSelection: selectedIsoCode,
                            favorite: const ['+91', 'IN', '+1', 'US', '+977', 'NP'],
                            showCountryOnly: false,
                            showOnlyCountryWhenClosed: false,
                            alignLeft: false,
                            showFlag: true,
                            showFlagDialog: true,
                            flagWidth: 24.w,
                            dialogSize: Size(
                              MediaQuery.of(context).size.width * 0.88,
                              MediaQuery.of(context).size.height * 0.70,
                            ),
                            textStyle: TextStyle(
                              color: const Color(0xFFF5F5F5),
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w400,
                            ),
                            dialogTextStyle: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.black,
                            ),
                            searchDecoration: InputDecoration(
                              hintText: "Search Country",
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF002C3E)),
                              filled: true,
                              fillColor: const Color(0xFFF0F4F8),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            phone.isEmpty ? "Your Phone Number" : phone,
                            style: TextStyle(
                              color: phone.isNotEmpty
                                  ? const Color(0xFFF5F5F5)
                                  : const Color(0xFF859BAD),
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
                        color: phone.isNotEmpty
                            ? const Color(0xFFF5F5F5)
                            : const Color(0xFF294256),
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
                          numberButton("+",
                              onTap: (isOtpSent || phone.isNotEmpty)
                                  ? null
                                  : () => addDigit("+")),
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
                              color: _isNextButtonEnabled
                                  ? const Color(0xFF6E97AE)
                                  : const Color(0xFF6E97AE).withOpacity(0.4),
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          SizedBox(width: 14.w),
                          GestureDetector(
                            onTap: () {
                              if (!_isNextButtonEnabled ||
                                  context.read<AuthBloc>().state is AuthLoading) {
                                return;
                              }
                              if (!isOtpSent) {
                                validateAndSend();
                              } else {
                                verifyOtp();
                              }
                            },
                            child: BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                if (state is AuthLoading) {
                                  return Container(
                                    width: 60.w,
                                    height: 60.w,
                                    decoration: BoxDecoration(
                                      color: _isNextButtonEnabled
                                          ? const Color(0xFFB5D43C)
                                          : const Color(0xFFB5D43C).withOpacity(0.4),
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
                                  opacity: _isNextButtonEnabled ? 1.0 : 0.4,
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
      ),
    );
  }
}