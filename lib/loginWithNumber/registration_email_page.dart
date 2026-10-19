import 'dart:async'; // Required for Timer
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:solo_app/core/storage/token_storage.dart';
import 'package:solo_app/home/home_page.dart';
import 'package:solo_app/home/privacy_policy_page.dart';
import 'package:solo_app/home/terms_of_use_page.dart';
import 'package:solo_app/loginWithNumber/user_email_api.dart';
import 'package:solo_app/subscription/subscription_page.dart';
import '../core/utils/app_size.dart';

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

  // Sirf aur sirf strict @gmail.com validation
  bool isValidEmail(String email) {
    final value = email.trim().toLowerCase();

    if (!value.endsWith('@gmail.com')) return false;

    final parts = value.split('@');
    if (parts.length != 2) return false;

    final username = parts[0];
    final usernameRegex = RegExp(r'^[\w.+-]+$');
    if (username.isEmpty || !usernameRegex.hasMatch(username)) return false;

    return true;
  }

  void submitEmail() async {
    final email = emailController.text.trim();

    // Strict validation check before proceeding
    if (email.isEmpty) {
      _triggerError(email: "Email required");
      return;
    }

    // Agar @gmail.com format nahi hai toh turant "Invalid Email" aayega
    if (!isValidEmail(email)) {
      _triggerError(email: "Invalid Email");
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

    final isFormValid = emailController.text.trim().isNotEmpty;

    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    final topSpacing = isSmallScreen ? AppSize.h(24) : AppSize.h(30);
    final mascotSize = isSmallScreen ? 255.0 : 275.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double screenWidth = MediaQuery.of(context).size.width;
            double titleFontSize = screenWidth < 360 ? 36 : 44;

            return SingleChildScrollView(
              physics: keyboardOpen
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.only(
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
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Let’s keep\nyou connected\nand cared for",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF002C3E),
                              height: 1.1,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSize.h(20)),
                      // Email Error
                      SizedBox(
                        height: AppSize.h(20),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: AppSize.w(24)),
                            child: Text(
                              emailError,
                              style: TextStyle(
                                color: const Color(0xFFEE6A59),
                                fontSize: AppSize.sp(12),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSize.h(4)),

                      // Email Field Container
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
                                color: const Color(0xFFB8C2C8)
                                    .withValues(alpha: 0.5),
                                blurRadius: 0,
                                offset: const Offset(5, 5),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: emailController,
                            textAlign: TextAlign.start,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (val) {
                              setState(() {
                                if (emailError.isNotEmpty) {
                                  emailError = "";
                                }
                              });
                            },
                            textAlignVertical: TextAlignVertical.center,
                            style: TextStyle(
                              color: const Color(0xFF5A6C7D),
                              fontSize: AppSize.sp(16),
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                            ),
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
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF002C3E),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.email_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSize.h(8)),
                      Padding(
                        padding: EdgeInsets.only(left: AppSize.w(35)),
                        child: Text(
                          "For notifications, account recovery, updates",
                          style: TextStyle(
                            color: const Color(0xFF8A99A6),
                            fontSize: AppSize.sp(12),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(height: AppSize.h(8)),

                      // Terms Checkbox Row
                      Padding(
                        padding: EdgeInsets.only(
                          left: AppSize.w(35),
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
                                        color: Color(0xFF8A99A6),
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Color(0xFF8A99A6),
                                      ),
                                    ),
                                    const TextSpan(text: " & "),
                                    TextSpan(
                                      text: "Terms of Use",
                                      recognizer: _termsRecognizer,
                                      style: const TextStyle(
                                        color: Color(0xFF8A99A6),
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Color(0xFF8A99A6),
                                      ),
                                    ),
                                  ],
                                ),
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: AppSize.sp(12),
                                  color: const Color(0xFF8A99A6),
                                  fontWeight: FontWeight.w500,
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
                            padding: EdgeInsets.only(
                                top: AppSize.h(4), left: AppSize.w(35)),
                            child: Text(
                              termsError,
                              style: TextStyle(
                                color: const Color(0xFFEE6A59),
                                fontSize: AppSize.sp(12),
                              ),
                            ),
                          ),
                        ),
                      ),

                      if (!keyboardOpen) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Transform.translate(
                              offset: const Offset(-78, 0),
                              child: Padding(
                                padding: EdgeInsets.only(top: AppSize.h(10)),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: AnimatedSoloEmailButton(size: mascotSize),
                                ),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ],
                      const Spacer(),
                      Padding(
                        padding: EdgeInsets.only(
                          right: AppSize.w(0),
                          bottom: AppSize.h(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox.shrink(),
                            Row(
                              children: [
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: isFormValid
                                        ? const Color(0xFF5A6C7D)
                                        : const Color(0xFF5A6C7D)
                                        .withValues(alpha: 0.3),
                                    fontSize: AppSize.sp(20),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  child: const Text("Continue"),
                                ),
                                SizedBox(width: AppSize.w(14)),
                                GestureDetector(
                                  onTap: (loading || !isFormValid)
                                      ? null
                                      : submitEmail,
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
                                      : AnimatedOpacity(
                                    duration:
                                    const Duration(milliseconds: 200),
                                    opacity: isFormValid ? 1.0 : 0.4,
                                    child: SvgPicture.asset(
                                      "assets/svg/nextbutton.svg",
                                      width: AppSize.w(62),
                                      height: AppSize.w(62),
                                    ),
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

// animated_solo_email_button.dart
class AnimatedSoloEmailButton extends StatefulWidget {
  const AnimatedSoloEmailButton({super.key, this.size});

  final double? size;

  @override
  State<AnimatedSoloEmailButton> createState() =>
      _AnimatedSoloEmailButtonState();
}

class _AnimatedSoloEmailButtonState extends State<AnimatedSoloEmailButton>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _seconds = ValueNotifier<double>(0);

  static final DateTime _epoch = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      _seconds.value =
          DateTime.now().difference(_epoch).inMicroseconds / 1000000.0;
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(child: CustomPaint(painter: _StaticPainter())),
          RepaintBoundary(
            child: CustomPaint(painter: _AnimatedPainter(_seconds)),
          ),
        ],
      ),
    );
    if (widget.size != null) {
      child = SizedBox(width: widget.size, height: widget.size, child: child);
    }
    return child;
  }
}

const Rect _viewBox = Rect.fromLTWH(0, 0, 2048, 2048);

void _applyViewBox(Canvas canvas, Size size) {
  final s =
  math.min(size.width / _viewBox.width, size.height / _viewBox.height);
  canvas.translate(
    (size.width - _viewBox.width * s) / 2,
    (size.height - _viewBox.height * s) / 2,
  );
  canvas.scale(s, s);
}

void _applyOuterRotate(Canvas canvas) {
  canvas.translate(_G.outerCx, _G.outerCy);
  canvas.rotate(_G.outerRotRad);
  canvas.translate(-_G.outerCx, -_G.outerCy);
}

const Cubic _ease = Cubic(0.42, 0.0, 0.58, 1.0);

double _sample(double u, List<double> times, List<double> vals,
    {bool eased = false}) {
  if (u <= times.first) return vals.first;
  if (u >= times.last) return vals.last;
  var i = 0;
  while (i < times.length - 2 && u >= times[i + 1]) {
    i++;
  }
  final span = times[i + 1] - times[i];
  var f = span <= 0 ? 1.0 : (u - times[i]) / span;
  if (eased) f = _ease.transform(f);
  return vals[i] + (vals[i + 1] - vals[i]) * f;
}

class _Shape {
  _Shape.path(String d, this.color) : path = parseSvgPathData(d);
  _Shape.circle(double cx, double cy, double r, this.color)
      : path = Path()
    ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));

  final Path path;
  final Color color;
}

class _StaticPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    _applyViewBox(canvas, size);
    _applyOuterRotate(canvas);

    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    paint.color = _G.shadowColor;
    canvas.drawCircle(_G.shadowCenter, _G.shadowR, paint);

    for (final shape in _G.buttonShapes) {
      paint.color = shape.color;
      canvas.drawPath(shape.path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StaticPainter oldDelegate) => false;
}

class _AnimatedPainter extends CustomPainter {
  _AnimatedPainter(this.seconds) : super(repaint: seconds);
  final ValueNotifier<double> seconds;

  @override
  void paint(Canvas canvas, Size size) {
    final t = seconds.value;
    canvas.save();
    _applyViewBox(canvas, size);
    _applyOuterRotate(canvas);
    _paintEyes(canvas, t);
    canvas.restore();
  }

  void _paintEyes(Canvas canvas, double t) {
    final u = (t % _G.loopSec) / _G.loopSec;

    final blinkY = _sample(u, _G.blinkTimes, _G.blinkY);
    final blinkH = _sample(u, _G.blinkTimes, _G.blinkH);

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(_G.blinkX, blinkY, _G.blinkW, blinkH));

    final white = Paint()
      ..isAntiAlias = true
      ..color = _G.eyeWhite;
    canvas.drawPath(_G.eyeLPath, white);
    canvas.drawPath(_G.eyeRPath, white);

    final tx = _sample(u, _G.pupilTimes, _G.pupilTx, eased: true);
    final ty = _sample(u, _G.pupilTimes, _G.pupilTy, eased: true);
    final black = Paint()
      ..isAntiAlias = true
      ..color = const Color(0xFF000000);

    _drawPupil(canvas, _G.eyeLCenter, _G.eyeLPath, tx, ty, black);
    _drawPupil(canvas, _G.eyeRCenter, _G.eyeRPath, tx, ty, black);

    canvas.restore();
  }

  void _drawPupil(Canvas canvas, Offset center, Path eyeClip, double tx,
      double ty, Paint paint) {
    canvas.save();
    canvas.clipPath(eyeClip);
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-_G.outerRotRad);
    canvas.translate(-center.dx, -center.dy);
    canvas.translate(tx, ty);
    canvas.drawCircle(center, _G.pupilR, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AnimatedPainter oldDelegate) => true;
}

class _G {
  static const double outerCx = 1023.98;
  static const double outerCy = 1024;
  static final double outerRotRad = 15 * math.pi / 180;

  static const Offset shadowCenter = Offset(1082.85, 1082.87);
  static const double shadowR = 890.78;
  static const Color shadowColor = Color(0x40002C3E);

  static final List<_Shape> buttonShapes = <_Shape>[
    _Shape.circle(1023.98, 1024, 890.78, const Color(0xFF0AA298)),
    _Shape.path(
        r'M1914.76,1024c0-43.11-3.13-85.49-9.05-126.96l-390.33-390.33-1008.16,1008.16,391.03,391.03c41.08,5.81,83.05,8.88,125.73,8.88,491.96,0,890.78-398.82,890.78-890.78Z',
        const Color(0xFF0A8980)),
    _Shape.circle(1023.98, 1024, 712.54, const Color(0xFF0CB4AB)),
    _Shape.path(
        r'M448.54,648.32c214.3-328,652.92-421.16,981.89-209.55-5.51-3.82-11.07-7.59-16.72-11.28-329.45-215.24-771-122.66-986.24,206.78-215.24,329.44-122.66,771,206.78,986.24,1.44.94,2.9,1.83,4.34,2.76-315.79-219.08-401.6-651.16-190.05-974.95Z',
        const Color(0xFF1AC7BE)),
    _Shape.path(
        r'M1537.3,529.61c225.65,233.87,268.48,600.52,83.2,884.12-215.24,329.44-656.8,422.02-986.24,206.78-39.13-25.56-74.86-54.35-107.19-85.72,36.48,37.81,77.73,72.16,123.57,102.11,329.44,215.24,771,122.66,986.24-206.78,189.68-290.32,140.27-667.66-99.58-900.5Z',
        const Color(0xFF046A64)),
    _Shape.path(
        r'M180.22,1064.3c0-491.96,398.81-890.78,890.78-890.78,210.17,0,403.31,72.83,555.65,194.57-158.61-145.81-370.22-234.87-602.66-234.87-491.96,0-890.78,398.82-890.78,890.78,0,281.79,130.88,532.98,335.13,696.2-177.1-162.81-288.12-396.38-288.12-655.91Z',
        const Color(0xFF067E78)),
  ];

  static const double loopSec = 15.12;
  static const double blinkX = 578.83;
  static const double blinkW = 889.87;
  static const List<double> blinkTimes = [
    0.0,
    0.2417,
    0.25,
    0.2583,
    0.5194,
    0.5278,
    0.5361,
    0.8250,
    0.8333,
    0.8417,
    1.0,
  ];
  static const List<double> blinkY = [
    664.54,
    664.54,
    853.15,
    664.54,
    664.54,
    853.15,
    664.54,
    664.54,
    853.15,
    664.54,
    664.54,
  ];
  static const List<double> blinkH = [
    377.22,
    377.22,
    0.0,
    377.22,
    377.22,
    0.0,
    377.22,
    377.22,
    0.0,
    377.22,
    377.22,
  ];

  static const Offset eyeLCenter = Offset(767.44, 853.15);
  static const Offset eyeRCenter = Offset(1280.09, 853.15);
  static const double eyeR = 188.61;
  static const double pupilR = 125.1;
  static const Color eyeWhite = Color(0xFFF5F5F5);

  static final Path eyeLPath = Path()
    ..addOval(Rect.fromCircle(center: eyeLCenter, radius: eyeR));
  static final Path eyeRPath = Path()
    ..addOval(Rect.fromCircle(center: eyeRCenter, radius: eyeR));

  static const List<double> pupilTimes = [
    0.0,
    0.0556,
    0.1111,
    0.1667,
    0.2222,
    0.2778,
    0.3333,
    0.3889,
    0.4444,
    0.5,
    0.5556,
    0.6111,
    0.6667,
    0.7222,
    0.7778,
    0.8333,
    0.8889,
    0.9444,
    1.0,
  ];
  static const List<double> pupilTx = [
    0,
    139,
    0,
    -139,
    0,
    0,
    30,
    0,
    139,
    0,
    0,
    -139,
    0,
    98,
    0,
    0,
    0,
    30,
    0,
  ];
  static const List<double> pupilTy = [
    0,
    0,
    0,
    0,
    0,
    0,
    -135,
    0,
    0,
    0,
    0,
    0,
    0,
    98,
    0,
    0,
    0,
    -135,
    0,
  ];
}