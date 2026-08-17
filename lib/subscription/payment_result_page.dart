import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/storage/token_storage.dart';
import '../core/utils/app_size.dart';
import '../home/shedule/schedule_page.dart';
import 'subscription_api.dart';
import 'subscription_page.dart';

class AnimatedResultIcon extends StatefulWidget {
  final bool success;
  final double size;

  const AnimatedResultIcon({
    super.key,
    required this.success,
    this.size = 110,
  });

  @override
  State<AnimatedResultIcon> createState() => _AnimatedResultIconState();
}

class _AnimatedResultIconState extends State<AnimatedResultIcon>
    with TickerProviderStateMixin {
  late final AnimationController _drawController;
  late final Animation<double> _circleProgress;
  late final Animation<double> _markProgress;
  late final Animation<double> _bounceScale;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();

    _drawController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Circle ring draws first (0% → 55% of total time)
    _circleProgress = CurvedAnimation(
      parent: _drawController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );

    // Check / cross traces itself right after (50% → 88%)
    _markProgress = CurvedAnimation(
      parent: _drawController,
      curve: const Interval(0.50, 0.88, curve: Curves.easeOut),
    );

    // Tiny settle-bounce once the mark finishes drawing (85% → 100%)
    _bounceScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _drawController,
      curve: const Interval(0.85, 1.0, curve: Curves.easeOut),
    ));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _pulseScale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.25, end: 0.55).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _drawController.forward().whenComplete(() {
      if (mounted) _pulseController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _drawController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color glowColor =
    widget.success ? const Color(0xFFA2D071) : const Color(0xFFF28D7D);
    final Color glowBg =
    widget.success ? const Color(0xFF1B3B2B) : const Color(0xFF3B1E22);

    return SizedBox(
      width: widget.size + 40,
      height: widget.size + 40,
      child: AnimatedBuilder(
        animation: Listenable.merge([_drawController, _pulseController]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Soft pulsing glow behind everything
              Transform.scale(
                scale: _pulseScale.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withOpacity(_pulseOpacity.value),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),

              // Filled background circle (fades in with the ring)
              Opacity(
                opacity: _circleProgress.value.clamp(0.0, 1.0),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: glowBg,
                  ),
                ),
              ),

              // Ring that draws itself, then mark that traces itself
              Transform.scale(
                scale: _bounceScale.value,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _RingAndMarkPainter(
                    ringProgress: _circleProgress.value,
                    markProgress: _markProgress.value,
                    color: glowColor,
                    isSuccess: widget.success,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RingAndMarkPainter extends CustomPainter {
  final double ringProgress; // 0 → 1
  final double markProgress; // 0 → 1
  final Color color;
  final bool isSuccess;

  _RingAndMarkPainter({
    required this.ringProgress,
    required this.markProgress,
    required this.color,
    required this.isSuccess,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.045;

    // ── 1) Ring trace ──
    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * ringProgress;
    canvas.drawArc(rect, startAngle, sweepAngle, false, ringPaint);

    // ── 2) Mark trace (check or cross) ──
    if (markProgress <= 0) return;

    final markPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.05
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    if (isSuccess) {
      // check mark: short down-stroke then long up-stroke
      path.moveTo(size.width * 0.27, size.height * 0.52);
      path.lineTo(size.width * 0.43, size.height * 0.67);
      path.lineTo(size.width * 0.75, size.height * 0.33);
    } else {
      // cross: two diagonals
      path.moveTo(size.width * 0.30, size.height * 0.30);
      path.lineTo(size.width * 0.70, size.height * 0.70);
      path.moveTo(size.width * 0.70, size.height * 0.30);
      path.lineTo(size.width * 0.30, size.height * 0.70);
    }

    final drawPath = _trimPath(path, markProgress);
    canvas.drawPath(drawPath, markPaint);
  }

  Path _trimPath(Path source, double t) {
    final metrics = source.computeMetrics().toList();
    final totalLength =
    metrics.fold<double>(0, (sum, m) => sum + m.length);
    double remaining = totalLength * t.clamp(0.0, 1.0);

    final result = Path();
    for (final metric in metrics) {
      if (remaining <= 0) break;
      final len = metric.length < remaining ? metric.length : remaining;
      result.addPath(metric.extractPath(0, len), Offset.zero);
      remaining -= len;
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant _RingAndMarkPainter oldDelegate) {
    return oldDelegate.ringProgress != ringProgress ||
        oldDelegate.markProgress != markProgress ||
        oldDelegate.color != color;
  }
}

class PaymentResultPage extends StatefulWidget {
  final bool success;

  const PaymentResultPage({super.key, required this.success});

  @override
  State<PaymentResultPage> createState() => _PaymentResultPageState();
}

class _PaymentResultPageState extends State<PaymentResultPage>
    with TickerProviderStateMixin {
  bool _isChecking = true;
  bool _confirmed = false;

  int _statusBefore = 0;
  int _creditsBefore = 0;
  int _statusAfter = 0;
  int _creditsAfter = 0;

  // ── Staggered entrance for text/card/buttons (icon handles itself) ──
  late final AnimationController _entranceController;

  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;

  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;

  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  late final Animation<double> _actionsFade;
  late final Animation<Offset> _actionsSlide;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _titleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.10, 0.40, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.10, 0.40, curve: Curves.easeOut),
    ));

    _subtitleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
    ));

    _cardFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.45, 0.80, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.45, 0.80, curve: Curves.easeOut),
    ));

    _actionsFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
    );
    _actionsSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
    ));

    _entranceController.forward();

    if (widget.success) {
      _confirmSubscriptionUpdate();
    } else {
      _isChecking = false;
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _confirmSubscriptionUpdate() async {
    _statusBefore = await TokenStorage.getSubscriptionStatus();
    _creditsBefore = await TokenStorage.getCredits();

    const maxAttempts = 5;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      await SubscriptionApi.getSubscriptionStatus();

      final newStatus = await TokenStorage.getSubscriptionStatus();
      final newCredits = await TokenStorage.getCredits();

      _statusAfter = newStatus;
      _creditsAfter = newCredits;

      if (newStatus != _statusBefore || newCredits != _creditsBefore) {
        _confirmed = true;
        break;
      }

      if (attempt < maxAttempts) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  String _getPlanName(int status) {
    switch (status) {
      case 1:
        return "SOLO Trial";
      case 2:
        return "SOLO Monthly";
      case 3:
        return "SOLO Yearly";
      case 4:
        return "SOLO Lifetime";
      default:
        return "SOLO Premium";
    }
  }

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);
    final success = widget.success;

    final int addedCredits = (_creditsAfter - _creditsBefore) > 0
        ? (_creditsAfter - _creditsBefore)
        : (_creditsAfter > 0 ? _creditsAfter : 3);

    final int totalCredits =
    _creditsAfter > 0 ? _creditsAfter : (_creditsBefore + addedCredits);
    final String planName =
    _getPlanName(_statusAfter > 0 ? _statusAfter : _statusBefore);

    return Scaffold(
      backgroundColor: const Color(0xFF002C3E),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSize.w(24), vertical: AppSize.h(16)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // --- Top Section ---
                      Column(
                        children: [
                          // --- Paytm-style draw-on Glow Icon ---
                          Center(
                            child: AnimatedResultIcon(
                              success: success,
                              size: 110,
                            ),
                          ),
                          SizedBox(height: AppSize.h(24)),

                          // --- Title ---
                          FadeTransition(
                            opacity: _titleFade,
                            child: SlideTransition(
                              position: _titleSlide,
                              child: Text(
                                success
                                    ? "Payment Successful!"
                                    : "Payment Cancelled",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: AppSize.h(12)),

                          // --- Subtitle / Polling Loader (crossfades) ---
                          FadeTransition(
                            opacity: _subtitleFade,
                            child: SlideTransition(
                              position: _subtitleSlide,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                transitionBuilder: (child, anim) =>
                                    FadeTransition(opacity: anim, child: child),
                                child: (success && _isChecking)
                                    ? const Column(
                                  key: ValueKey('checking'),
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Color(0xFF78BCC4),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "Confirming your subscription details...",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFFA8B6C2),
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                )
                                    : Text(
                                  success
                                      ? (_confirmed
                                      ? "Thank you for your subscription! Your SOLO account is now active and ready."
                                      : "Payment received! We are setting up your account credits automatically.")
                                      : "It looks like you canceled your payment process. No charges have been made to your account.",
                                  key: const ValueKey('result-text'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFA8B6C2),
                                    fontSize: 14,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: AppSize.h(24)),

                          // --- Summary Card Container ---
                          FadeTransition(
                            opacity: _cardFade,
                            child: SlideTransition(
                              position: _cardSlide,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                transitionBuilder: (child, anim) =>
                                    FadeTransition(opacity: anim, child: child),
                                child: Container(
                                  key: ValueKey('card-${_isChecking}-$_confirmed'),
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 18),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF07384D)
                                        .withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color:
                                      const Color(0xFF1B556D).withOpacity(0.5),
                                    ),
                                  ),
                                  child: success
                                      ? Column(
                                    children: [
                                      _buildSummaryRow("Plan:", planName),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 10),
                                        child: Divider(
                                            color: Color(0xFF1B556D),
                                            height: 1),
                                      ),
                                      _buildSummaryRow(
                                          "Credits:", "+$addedCredits added"),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 10),
                                        child: Divider(
                                            color: Color(0xFF1B556D),
                                            height: 1),
                                      ),
                                      _buildSummaryRow("Total:",
                                          "$totalCredits credits",
                                          isBold: true),
                                    ],
                                  )
                                      : const Padding(
                                    padding:
                                    EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      "You can retry anytime to get access to SOLO Premium and alert credits.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFFD1D9E0),
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: AppSize.h(32)),

                      // --- Bottom Actions ---
                      FadeTransition(
                        opacity: _actionsFade,
                        child: SlideTransition(
                          position: _actionsSlide,
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A6B8A),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (_) => success
                                            ? const SchedulePage()
                                            : const SubscriptionPage(),
                                      ),
                                          (route) => false,
                                    );
                                  },
                                  child: Text(
                                    success ? "Continue to Schedule" : "Return to Plans",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) => const SubscriptionPage(),
                                    ),
                                        (route) => false,
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Text(
                                    success
                                        ? "View Subscription Details"
                                        : "Explore Other Plans",
                                    style: const TextStyle(
                                      color: Color(0xFF78BCC4),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
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

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFA8B6C2),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}