import 'dart:async'; // Required for Timer
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_drawing/path_drawing.dart';
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

  // Timer Variables
  Timer? _timer;
  Timer? _errorTimer; // Error auto-dismiss timer
  int _start = 60;
  bool _isResendButtonEnabled = true;

  @override
  void dispose() {
    _timer?.cancel();
    _errorTimer?.cancel(); // Cancel error timer on dispose
    emailController.dispose();
    otpController.dispose();
    super.dispose();
  }

  // Har word ka pehla letter capital: "email not found" -> "Email Not Found".
  String _toTitleCase(String text) {
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  void _setError(String errorMessage, {bool autoDismiss = true}) {
    setState(() {
      error = errorMessage;
      loading = false;
    });

    _errorTimer?.cancel();
    if (autoDismiss && errorMessage.isNotEmpty) {
      _errorTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            error = "";
          });
        }
      });
    }
  }

  // Start Resend Timer
  void _startResendTimer() {
    setState(() {
      _start = 60;
      _isResendButtonEnabled = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _timer?.cancel();
          _isResendButtonEnabled = true;
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  // Dynamic Greeting Logic split with a newline
  String get _dynamicGreeting {
    final hour = DateTime.now().hour;
    String timeGreeting;
    if (hour >= 6 && hour < 12) {
      timeGreeting = "Morning";
    } else if (hour >= 12 && hour < 17) {
      timeGreeting = "Afternoon";
    } else {
      timeGreeting = "Evening";
    }
    return "$timeGreeting,\nwelcome back \nto SOLO";
  }

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
    final enteredEmail = emailController.text.trim();

    if (enteredEmail.isEmpty) {
      _setError("Email Required");
      return;
    }

    // Agar @gmail.com nahi hai toh turant "Invalid Email" aayega
    if (!isValidEmail(enteredEmail)) {
      _setError("Invalid Email", autoDismiss: false);
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
        _startResendTimer();
      } else {
        String msg = res['message'] ?? "Account Not Signed Up Yet";
        if (msg.toLowerCase().contains("not found") ||
            msg.toLowerCase().contains("does not exist") ||
            msg.toLowerCase().contains("unregistered")) {
          msg = "Account Not Signed Up Yet";
        }
        _setError(_toTitleCase(msg));
      }
    } catch (e) {
      _setError("Account Not Signed Up Yet");
    }
  }

  void resendOtp() async {
    if (!_isResendButtonEnabled) return;

    setState(() {
      loading = true;
      error = "";
    });

    try {
      final res = await AuthApi.sendEmailOtp(email);
      if (res['message'] != null && res['message'] == "OTP sent successfully") {
        setState(() => loading = false);
        _startResendTimer();
      } else {
        _setError(_toTitleCase(res['message'] ?? "Failed To Resend Code"));
      }
    } catch (e) {
      _setError("An Error Occurred. Please Try Again");
    }
  }

  void verifyOtp() async {
    if (otp.length < 6) {
      _setError("Enter Valid OTP");
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
        _setError(_toTitleCase(res['message'] ?? "Incorrect Code, Please Try Again"));
      }
    } catch (e) {
      _setError("An Error Occurred. Please Try Again");
    }
  }

  void _navigateToPhoneSignIn() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginPage(),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);

    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final mascotSize = isSmallScreen ? 280.0 : 300.0;

    final isEmailNotEmpty = emailController.text.trim().isNotEmpty;
    final isOtpValid = otp.length == 6;
    final isFormValid = isOtpSent ? isOtpValid : isEmailNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 19.h),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppSize.h(24)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSize.h(24)),
                      child: Text(
                        _dynamicGreeting,
                        style: TextStyle(
                          fontSize: AppSize.sp(44),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF002C3E),
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSize.h(24)),
                      child: SizedBox(
                        height: AppSize.h(28),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: error.isNotEmpty
                              ? FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4.0, left: 7),
                              child: Text(
                                error,
                                style: TextStyle(
                                  color: const Color(0xFFE86B56),
                                  fontSize: AppSize.sp(14),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSize.h(2)),

                    if (!isOtpSent)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSize.h(24)),
                        child: Column(
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
                                    color: const Color(0xFFB8C2C8).withValues(alpha: 0.5),
                                    blurRadius: 0,
                                    offset: const Offset(5, 5),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: emailController,
                                textAlign: TextAlign.start,
                                textAlignVertical: TextAlignVertical.center,
                                maxLines: 1,
                                keyboardType: TextInputType.emailAddress,
                                onChanged: (val) {
                                  if (error.isNotEmpty) {
                                    setState(() {
                                      error = "";
                                    });
                                  } else {
                                    setState(() {});
                                  }
                                },
                                style: TextStyle(
                                  color: const Color(0xFF5A6C7D),
                                  fontSize: AppSize.sp(16),
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
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
                                      child: const Icon(
                                        Icons.email_outlined,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 0,
                                    horizontal: 16,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: AppSize.h(12)),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: _navigateToPhoneSignIn,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text.rich(
                                    const TextSpan(
                                      text: "Sign in with ",
                                      children: [
                                        TextSpan(
                                          text: "Phone Number",
                                          style: TextStyle(
                                            decoration: TextDecoration.underline,
                                            decorationColor: Color(0xFF8A99A6),
                                          ),
                                        ),
                                      ],
                                    ),
                                    style: TextStyle(
                                      fontSize: AppSize.sp(11),
                                      color: const Color(0xFF8A99A6),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: AppSize.h(24)),
                            child: Container(
                              width: double.infinity,
                              height: AppSize.h(56),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(34),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFB8C2C8).withValues(alpha: 0.5),
                                    blurRadius: 0,
                                    offset: const Offset(5, 5),
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
                                        color: Colors.white, size: 20),
                                  ),
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
                          ),
                          SizedBox(height: AppSize.h(8)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: AppSize.h(28)),
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
                                  onTap: _isResendButtonEnabled ? resendOtp : null,
                                  behavior: HitTestBehavior.opaque,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Resend",
                                        style: TextStyle(
                                          fontSize: AppSize.sp(11.5),
                                          color: _isResendButtonEnabled
                                              ? const Color(0xFF8A99A6)
                                              : const Color(0xFF8A99A6)
                                              .withValues(alpha: 0.5),
                                          fontWeight: FontWeight.w600,
                                          decoration: _isResendButtonEnabled
                                              ? TextDecoration.underline
                                              : TextDecoration.none,
                                        ),
                                      ),
                                      if (!_isResendButtonEnabled) ...[
                                        SizedBox(width: AppSize.w(4)),
                                        Text(
                                          "${_start}s",
                                          key: ValueKey<int>(_start),
                                          style: TextStyle(
                                            fontSize: AppSize.sp(11.5),
                                            color: const Color(0xFF8A99A6)
                                                .withValues(alpha: 0.5),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: AppSize.h(20)),
                        ],
                      ),

                    if (!keyboardOpen) ...[
                      SizedBox(height: AppSize.h(10)),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: ClipRect(
                          child: FractionalTranslation(
                            translation: const Offset(-0.25, 0),
                            child: AnimatedSoloEmailButton(size: mascotSize),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer Section with minimized bottom padding
            Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSize.w(28), 4, AppSize.w(28), AppSize.bottom(6)),
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
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "New User?",
                                style: TextStyle(
                                  color: const Color(0xFF8A99A6),
                                  fontSize: AppSize.sp(11),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                "Sign Up With\nPhone Number",
                                style: TextStyle(
                                  color: const Color(0xFF8A99A6),
                                  fontSize: AppSize.sp(11),
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                  decorationColor: const Color(0xFF8A99A6),
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: isFormValid
                              ? const Color(0xFF5A6C7D)
                              : const Color(0xFF5A6C7D).withValues(alpha: 0.3),
                          fontSize: AppSize.sp(20),
                          fontWeight: FontWeight.w400,
                        ),
                        child: const Text("Continue"),
                      ),
                      SizedBox(width: AppSize.w(14)),
                      GestureDetector(
                        onTap: (loading || !isFormValid)
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
                            : AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
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
    );
  }
}

// ───────────────────────── Animated Eye Mascot Widget ─────────────────────────

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
    0.0, 0.2417, 0.25, 0.2583, 0.5194, 0.5278, 0.5361, 0.8250, 0.8333, 0.8417, 1.0,
  ];
  static const List<double> blinkY = [
    664.54, 664.54, 853.15, 664.54, 664.54, 853.15, 664.54, 664.54, 853.15, 664.54, 664.54,
  ];
  static const List<double> blinkH = [
    377.22, 377.22, 0.0, 377.22, 377.22, 0.0, 377.22, 377.22, 0.0, 377.22, 377.22,
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
    0.0, 0.0556, 0.1111, 0.1667, 0.2222, 0.2778, 0.3333, 0.3889, 0.4444, 0.5,
    0.5556, 0.6111, 0.6667, 0.7222, 0.7778, 0.8333, 0.8889, 0.9444, 1.0,
  ];
  static const List<double> pupilTx = [
    0, 139, 0, -139, 0, 0, 30, 0, 139, 0, 0, -139, 0, 98, 0, 0, 0, 30, 0,
  ];
  static const List<double> pupilTy = [
    0, 0, 0, 0, 0, 0, -135, 0, 0, 0, 0, 0, 0, 98, 0, 0, 0, -135, 0,
  ];
}