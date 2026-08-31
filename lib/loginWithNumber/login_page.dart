import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
  // Default to Singapore (+65) as requested fallback
  String selectedDialCode = "+65";
  String selectedIsoCode = "SG";

  String phone = "";
  String otp = "";
  bool isOtpSent = false;
  String error = "";

  String lastUsedDialCode = "";
  String lastUsedPhone = "";

  // ---- Resend OTP timer ----
  static const int _resendDuration = 60;
  Timer? _resendTimer;
  int _resendSecondsLeft = _resendDuration;
  bool _canResend = false;

  // Document ke anusار Excluded / Sanctioned Countries list
  static const Set<String> _excludedIsoCodes = {
    // APAC Excluded: North Korea, Iran, Myanmar, USA
    'KP', 'IR', 'MM', 'US',
    // EMEA Excluded: Belarus, CAR, DR Congo, Iraq, Lebanon, Liberia, Libya, Russia, Somalia, Sudan, Syria, Yemen, Zimbabwe
    'BY', 'CF', 'CD', 'IQ', 'LB', 'LR', 'LY', 'RU', 'SO', 'SD', 'SY', 'YE', 'ZW',
    // LATAM Excluded: Cuba, Nicaragua, Venezuela
    'CU', 'NI', 'VE',
  };

  // Supported Country Codes from PDF (APAC, EMEA, LATAM, Other)
  static const Map<String, String> _worldIsoToDialCode = {
    // --- APAC ---
    'AF': '+93', 'AS': '+1684', 'AU': '+61', 'BD': '+880', 'BT': '+975',
    'BN': '+673', 'KH': '+855', 'CN': '+86', 'CK': '+682', 'TL': '+670',
    'FJ': '+679', 'PF': '+689', 'GU': '+1671', 'HK': '+852', 'IN': '+91',
    'ID': '+62', 'JP': '+81', 'KI': '+686', 'LA': '+856', 'MO': '+853',
    'MY': '+60', 'MV': '+960', 'MH': '+692', 'FM': '+691', 'MN': '+976',
    'NR': '+674', 'NP': '+977', 'NC': '+687', 'NZ': '+64', 'NU': '+683',
    'MP': '+1670', 'PK': '+92', 'PW': '+680', 'PG': '+675', 'PH': '+63',
    'WS': '+685', 'SG': '+65', 'SB': '+677', 'KR': '+82', 'LK': '+94',
    'TW': '+886', 'TH': '+66', 'TO': '+676', 'TV': '+688', 'VU': '+678',
    'VN': '+84',

    // --- EMEA ---
    'AL': '+355', 'DZ': '+213', 'AD': '+376', 'AO': '+244', 'AT': '+43',
    'AZ': '+994', 'BH': '+973', 'BE': '+32', 'BJ': '+229', 'BA': '+387',
    'BW': '+267', 'BG': '+359', 'BF': '+226', 'BI': '+257', 'CV': '+238',
    'CM': '+237', 'TD': '+235', 'KM': '+269', 'CG': '+242', 'CI': '+225',
    'HR': '+385', 'CY': '+357', 'CZ': '+420', 'DK': '+45', 'DJ': '+253',
    'EG': '+20', 'GQ': '+240', 'ER': '+291', 'EE': '+372', 'SZ': '+268',
    'ET': '+251', 'FI': '+358', 'FR': '+33', 'GA': '+241', 'GM': '+220',
    'GE': '+995', 'DE': '+49', 'GH': '+233', 'GR': '+30', 'GN': '+224',
    'GW': '+245', 'HU': '+36', 'IS': '+354', 'IE': '+353', 'IL': '+972',
    'IT': '+39', 'JO': '+962', 'KZ': '+7', 'KE': '+254', 'XK': '+383',
    'KW': '+965', 'KG': '+996', 'LV': '+371', 'LS': '+266', 'LI': '+423',
    'LT': '+370', 'LU': '+352', 'MG': '+261', 'MW': '+265', 'ML': '+223',
    'MT': '+356', 'MR': '+222', 'MU': '+230', 'MD': '+373', 'MC': '+377',
    'ME': '+382', 'MA': '+212', 'MZ': '+258', 'NA': '+264', 'NL': '+31',
    'NE': '+227', 'NG': '+234', 'MK': '+389', 'NO': '+47', 'OM': '+968',
    'PS': '+970', 'PL': '+48', 'PT': '+351', 'QA': '+974', 'RO': '+40',
    'RW': '+250', 'SM': '+378', 'ST': '+239', 'SA': '+966', 'SN': '+221',
    'RS': '+381', 'SC': '+248', 'SL': '+232', 'SK': '+421', 'SI': '+386',
    'ZA': '+27', 'SS': '+211', 'ES': '+34', 'SE': '+46', 'CH': '+41',
    'TJ': '+992', 'TZ': '+255', 'TG': '+228', 'TN': '+216', 'TR': '+90',
    'TM': '+993', 'UG': '+256', 'UA': '+380', 'AE': '+971', 'GB': '+44',
    'UZ': '+998', 'VA': '+379', 'ZM': '+260',

    // --- LATAM ---
    'AG': '+1268', 'AR': '+54', 'BS': '+1242', 'BB': '+1246', 'BZ': '+501',
    'BO': '+591', 'BR': '+55', 'CL': '+56', 'CO': '+57', 'CR': '+506',
    'DM': '+1767', 'DO': '+1809', 'EC': '+593', 'SV': '+503', 'GD': '+1473',
    'GT': '+502', 'GY': '+592', 'HT': '+509', 'HN': '+504', 'JM': '+1876',
    'MX': '+52', 'PA': '+507', 'PY': '+595', 'PE': '+51', 'KN': '+1869',
    'LC': '+1758', 'VC': '+1784', 'SR': '+597', 'TT': '+1868', 'UY': '+598',

    // --- OTHER ---
    'CA': '+1', 'GL': '+299', 'PM': '+508', 'BM': '+1441',
  };

  static const Map<String, int> _dialCodeToRequiredLength = {
    '+91': 10, '+1': 10, '+977': 10, '+44': 10, '+61': 9,
    '+971': 9, '+966': 9, '+92': 10, '+880': 10, '+94': 9,
    '+49': 10, '+33': 9, '+81': 10, '+86': 11, '+55': 11,
    '+52': 10, '+27': 9, '+39': 10, '+34': 9, '+65': 8,
    '+60': 9, '+62': 10, '+66': 9, '+63': 10, '+84': 9,
    '+82': 10, '+64': 9, '+965': 8, '+974': 8, '+968': 8,
    '+973': 8, '+353': 9, '+31': 9, '+46': 9, '+47': 8,
    '+41': 9, '+43': 10, '+32': 9, '+351': 9, '+48': 9,
    '+90': 10, '+234': 10, '+254': 9, '+20': 10, '+54': 10,
    '+56': 9, '+57': 10, '+51': 9,
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

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _resendSecondsLeft = _resendDuration;
      _canResend = false;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSecondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _resendSecondsLeft = 0;
          _canResend = true;
        });
      } else {
        setState(() {
          _resendSecondsLeft--;
        });
      }
    });
  }

  String _formatResendTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _autoFetchUserCountry() async {
    try {
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      final countryCode = locale.countryCode?.toUpperCase();

      if (countryCode != null &&
          !_excludedIsoCodes.contains(countryCode) &&
          _worldIsoToDialCode.containsKey(countryCode)) {
        if (mounted) {
          setState(() {
            selectedIsoCode = countryCode;
            selectedDialCode = _worldIsoToDialCode[countryCode]!;
          });
        }
      }
    } catch (_) {}

    try {
      final response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ipCountry = data['country_code']?.toString().toUpperCase();
        final ipCallingCode = data['country_calling_code']?.toString();

        if (ipCountry != null &&
            !_excludedIsoCodes.contains(ipCountry) &&
            mounted) {
          setState(() {
            selectedIsoCode = ipCountry;
            if (ipCallingCode != null && ipCallingCode.isNotEmpty) {
              selectedDialCode =
              ipCallingCode.startsWith('+') ? ipCallingCode : '+$ipCallingCode';
            } else if (_worldIsoToDialCode.containsKey(ipCountry)) {
              selectedDialCode = _worldIsoToDialCode[ipCountry]!;
            }
          });
          return;
        }
      }
    } catch (_) {
      try {
        final fallbackRes = await http
            .get(Uri.parse('http://ip-api.com/json'))
            .timeout(const Duration(seconds: 3));

        if (fallbackRes.statusCode == 200) {
          final data = jsonDecode(fallbackRes.body);
          final ipCountry = data['countryCode']?.toString().toUpperCase();
          if (ipCountry != null &&
              !_excludedIsoCodes.contains(ipCountry) &&
              _worldIsoToDialCode.containsKey(ipCountry) &&
              mounted) {
            setState(() {
              selectedIsoCode = ipCountry;
              selectedDialCode = _worldIsoToDialCode[ipCountry]!;
            });
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

  bool _isValidPhoneNumber(String number, String dialCode, String isoCode) {
    if (number.length != _currentRequiredPhoneLength) return false;
    if (Regz.isRepeatingDigits(number) || number == "1234567890" || number == "9876543210") {
      return false;
    }
    if (dialCode == "+91") {
      if (!RegExp(r'^[6-9]').hasMatch(number)) return false;
    } else if (dialCode == "+65") {
      if (!RegExp(r'^[389]').hasMatch(number)) return false;
    }
    if (!RegExp(r'^\d+$').hasMatch(number)) return false;
    return true;
  }

  void validateAndSend() {
    if (_excludedIsoCodes.contains(selectedIsoCode)) {
      setState(() => error = "Service is not available in your region");
      return;
    }

    if (phone.length != _currentRequiredPhoneLength) {
      setState(() =>
      error = "Please enter complete $_currentRequiredPhoneLength digit number");
      return;
    }

    if (!_isValidPhoneNumber(phone, selectedDialCode, selectedIsoCode)) {
      setState(() => error = "Invalid Phone Number");
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
    if (!_canResend) return;

    setState(() {
      otp = "";
      error = "";
    });
    _startResendTimer();
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
          _resendTimer?.cancel();
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
                  _startResendTimer();
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          SizedBox(height: 40.h),

                          // Logo & Tagline Section
                          Center(
                            child: Column(
                              children: [
                                Hero(
                                  tag: 'logo_hero',
                                  child: Material(
                                    color: Colors.transparent,
                                    child: SoloLogoWidget(size: 64.w),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 63.h),

                          if (isOtpSent)
                            Column(
                              children: [
                                SizedBox(
                                  height: 35.h,
                                  child: Center(
                                    child: SizedBox(
                                      width: 322.w,
                                      child: error.isNotEmpty
                                          ? Text(
                                        error,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 14.sp,
                                        ),
                                      )
                                          : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (otp.isEmpty) ...[
                                            Container(
                                              width: 2.w,
                                              height: 20.sp,
                                              color: const Color(0xFFB5D43C),
                                            ),
                                            SizedBox(width: 6.w),
                                          ],
                                          Text(
                                            otp.isEmpty ? "Enter 6-Digit Code" : otp,
                                            style: TextStyle(
                                              color: otp.isEmpty
                                                  ? const Color(0xFF859BAD)
                                                  : const Color(0xFFF5F5F5),
                                              fontSize: 20.sp,
                                              fontWeight: FontWeight.w400,
                                              letterSpacing: otp.isEmpty ? 0 : 4,
                                            ),
                                          ),
                                          if (otp.isNotEmpty) ...[
                                            SizedBox(width: 6.w),
                                            Container(
                                              width: 2.w,
                                              height: 20.sp,
                                              color: const Color(0xFFB5D43C),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
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
                                        onTap: _canResend ? resendOtp : null,
                                        behavior: HitTestBehavior.opaque,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              "Resend",
                                              style: TextStyle(
                                                color: _canResend
                                                    ? const Color(0xFFF5F5F5)
                                                    : const Color(0xFF8A99A6),
                                                fontSize: 11.sp,
                                                fontWeight: _canResend
                                                    ? FontWeight.w700
                                                    : FontWeight.w400,
                                                decoration: _canResend
                                                    ? TextDecoration.underline
                                                    : TextDecoration.none,
                                                decorationColor: const Color(0xFFF5F5F5),
                                              ),
                                            ),
                                            if (!_canResend) ...[
                                              SizedBox(width: 4.w),
                                              Text(
                                                _formatResendTime(_resendSecondsLeft),
                                                style: TextStyle(
                                                  color: const Color(0xFF8A99A6),
                                                  fontSize: 11.sp,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ],
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
                                SizedBox(
                                  height: 35.h,
                                  child: Center(
                                    child: SizedBox(
                                      width: 322.w,
                                      child: error.isNotEmpty
                                          ? Text(
                                        error,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 14.sp,
                                        ),
                                      )
                                          : const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 14.h),
                                Center(
                                  child: SizedBox(
                                    width: 322.w,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            CountryCodePicker(
                                              key: ValueKey(selectedIsoCode),
                                              countryFilter: _worldIsoToDialCode.keys.toList(),
                                              onChanged: (country) {
                                                setState(() {
                                                  selectedIsoCode = country.code ?? "SG";
                                                  selectedDialCode = country.dialCode ?? "+65";
                                                  if (phone.length > _currentRequiredPhoneLength) {
                                                    phone = phone.substring(0, _currentRequiredPhoneLength);
                                                  }
                                                });
                                              },
                                              initialSelection: selectedIsoCode,
                                              favorite: const ['SG', 'AU', 'KR', 'JP', 'IN', 'GB'],
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
                                            Expanded(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.centerLeft,
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (phone.isEmpty) ...[
                                                      Container(
                                                        width: 2.w,
                                                        height: 20.sp,
                                                        color: const Color(0xFFB5D43C),
                                                      ),
                                                      SizedBox(width: 2.w),
                                                    ],
                                                    Text(
                                                      phone.isEmpty ? "Phone Number" : phone,
                                                      maxLines: 1,
                                                      style: TextStyle(
                                                        color: phone.isNotEmpty
                                                            ? const Color(0xFFF5F5F5)
                                                            : const Color(0xFF859BAD),
                                                        fontSize: 20.5.sp,
                                                        fontWeight: FontWeight.w400,
                                                      ),
                                                    ),
                                                    if (phone.isNotEmpty) ...[
                                                      SizedBox(width: 2.w),
                                                      Container(
                                                        width: 2.w,
                                                        height: 20.sp,
                                                        color: const Color(0xFFB5D43C),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            )
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
                                  ),
                                ),
                              ],
                            ),

                          SizedBox(height: 30.h),

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


                          Padding(
                            padding: EdgeInsets.only(
                              top: 10.h,
                              bottom: AppSize.bottom(20),
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
                                      color: const Color(0xFFD1D9E0),
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w400,
                                      height: 1.0,
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
                                            ? const Color(0xFFD1D9E0)
                                            : const Color(0xFFD1D9E0).withOpacity(0.4),
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w400,
                                        height: 1.0,
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class Regz {
  static bool isRepeatingDigits(String str) {
    if (str.isEmpty) return false;
    return str.split('').every((char) => char == str[0]);
  }
}