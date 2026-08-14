import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:libphonenumber_plugin/libphonenumber_plugin.dart';
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
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String selectedDialCode = "+91"; // Initial Default

  String phone = "";
  String otp = "";
  bool isOtpSent = false;
  String error = "";

  String lastUsedDialCode = "";
  String lastUsedPhone = "";

  // 🚀 Full World Major ISO-to-DialCode Mapping
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
  };

  @override
  void initState() {
    super.initState();
    _fetchDefaultCountryCode(); // App start hote hi user country detect karega
  }

  // 🚀 App Start: Detect device country location / IP region
  Future<void> _fetchDefaultCountryCode() async {
    try {
      // Step 1: Device Locale (Instant & Offline)
      final locale = View.of(context).platformDispatcher.locale;
      final countryCode = locale.countryCode;

      if (countryCode != null && _worldIsoToDialCode.containsKey(countryCode.toUpperCase())) {
        if (mounted) {
          setState(() {
            selectedDialCode = _worldIsoToDialCode[countryCode.toUpperCase()]!;
          });
        }
        return;
      }

      // Step 2: Fallback to Fast IP Geolocation
      final response = await http.get(Uri.parse('http://ip-api.com/json')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ipCountry = data['countryCode'];
        if (ipCountry != null && _worldIsoToDialCode.containsKey(ipCountry.toString().toUpperCase())) {
          if (mounted) {
            setState(() {
              selectedDialCode = _worldIsoToDialCode[ipCountry.toString().toUpperCase()]!;
            });
          }
        }
      }
    } catch (_) {
      // Default retained (+91) if detection fails
    }
  }

  // 🚀 Dynamic Auto-Detect Logic on keypress
  Future<void> _autoDetectCountryCode(String inputNumber) async {
    if (inputNumber.isEmpty) return;

    // Fast local rule check
    if (inputNumber.length == 1) {
      if (['6', '7', '8', '9'].contains(inputNumber)) {
        setState(() => selectedDialCode = "+91");
        return;
      } else if (inputNumber == '1') {
        setState(() => selectedDialCode = "+1");
        return;
      }
    }

    // Nepal Mobiles (980x, 981x, 982x, 984x, 986x)
    if (inputNumber.length >= 3) {
      if (inputNumber.startsWith('980') ||
          inputNumber.startsWith('981') ||
          inputNumber.startsWith('982') ||
          inputNumber.startsWith('984') ||
          inputNumber.startsWith('986')) {
        setState(() => selectedDialCode = "+977");
        return;
      }
    }

    // Australia Mobiles
    if (inputNumber.startsWith('4') && inputNumber.length >= 2) {
      setState(() => selectedDialCode = "+61");
      return;
    }

    try {
      final regionInfo = await PhoneNumberUtil.getRegionInfo(
        inputNumber,
        'IN',
      );

      final isoCode = regionInfo.isoCode;

      if (isoCode != null && isoCode.isNotEmpty) {
        final dialCode = _worldIsoToDialCode[isoCode.toUpperCase()];
        if (dialCode != null && mounted) {
          setState(() {
            selectedDialCode = dialCode;
          });
        }
      }
    } catch (_) {
      // Ignore
    }
  }

  void addDigit(String digit) {
    if (context.read<AuthBloc>().state is AuthLoading) return;

    HapticFeedback.lightImpact();
    setState(() {
      error = "";
      if (!isOtpSent) {
        if (phone.length < 15) {
          phone += digit;
          _autoDetectCountryCode(phone);
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
          if (phone.isNotEmpty) {
            _autoDetectCountryCode(phone);
          }
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

    if (phone.length < 5) {
      setState(() => error = "Invalid phone number");
      return;
    }

    // 🛠️ GUARD: the "+" key can only be pressed as the very first digit
    // (see numberButton("+", ...) above), so `phone` could end up holding a
    // manually-typed leading "+" (and even the dial code itself) even
    // though `selectedDialCode` is already sent as a separate field. Strip
    // that here so the backend never receives the country code twice.
    String sanitizedPhone = phone;
    if (sanitizedPhone.startsWith('+')) {
      debugPrint(
        "⚠️ [LoginPage] phone had a manually-typed '+' ($sanitizedPhone) — "
            "stripping it so countryCode isn't duplicated in the request.",
      );
      sanitizedPhone = sanitizedPhone.replaceFirst(RegExp(r'^\+'), '');
      // If the user typed the dial code digits themselves too (e.g. dial
      // code +91 and phone "919876543210"), drop that duplicate prefix.
      final dialDigits = selectedDialCode.replaceFirst('+', '');
      if (sanitizedPhone.startsWith(dialDigits)) {
        sanitizedPhone = sanitizedPhone.substring(dialDigits.length);
      }
    }

    error = "";
    lastUsedDialCode = selectedDialCode;
    lastUsedPhone = sanitizedPhone;
    debugPrint(
      "📞 [LoginPage] sending OTP with countryCode=$lastUsedDialCode phone=$lastUsedPhone",
    );
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
                        // 🔑 Pehle yahan hamesha hardcoded "Incorrect code"
                        // dikhta tha, chahe backend ne kuch bhi bheja ho —
                        // isliye banned user ko bhi "incorrect OTP" dikhta
                        // tha. Ab asli backend message (ban message included)
                        // yahan dikhta hai; sirf jab error generic/empty ho
                        // tabhi default "Incorrect code" fallback use hota hai.
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
                            onChanged: (country) {
                              setState(() {
                                selectedDialCode = country.dialCode ?? "+91";
                              });
                            },
                            initialSelection: selectedDialCode,
                            favorite: const ['+91', 'IN', '+1', 'US', '+977', 'NP'],
                            showCountryOnly: false,
                            showOnlyCountryWhenClosed: false,
                            alignLeft: false,
                            textStyle: TextStyle(
                              color: const Color(0xFFF5F5F5),
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w400,
                            ),
                            dialogTextStyle: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.black,
                            ),
                            searchDecoration: const InputDecoration(
                              hintText: "Search Country",
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
                  padding:
                  EdgeInsets.symmetric(horizontal: 30.w, vertical: 10.h),
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
                              color: (!isOtpSent && phone.length >= 5) ||
                                  (isOtpSent && otp.length == 6)
                                  ? const Color(0xFF6E97AE)
                                  : const Color(0xFF6E97AE).withOpacity(0.5),
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          SizedBox(width: 14.w),
                          GestureDetector(
                            onTap: () {
                              if (context.read<AuthBloc>().state is AuthLoading) {
                                return;
                              }
                              if (!isOtpSent) {
                                if (phone.length >= 5) validateAndSend();
                              } else {
                                if (otp.length == 6) verifyOtp();
                              }
                            },
                            child: BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                final isEnabled =
                                    (!isOtpSent && phone.length >= 5) ||
                                        (isOtpSent && otp.length == 6);

                                if (state is AuthLoading) {
                                  return Container(
                                    width: 60.w,
                                    height: 60.w,
                                    decoration: BoxDecoration(
                                      color: isEnabled
                                          ? const Color(0xFFB5D43C)
                                          : const Color(0xFFB5D43C)
                                          .withOpacity(0.4),
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
      ),
    );
  }
}