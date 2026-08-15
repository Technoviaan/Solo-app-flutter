import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/storage/token_storage.dart';
import '../core/utils/app_size.dart';
import '../home/home_page.dart';
import 'subscription_api.dart';
import 'subscription_page.dart';

/// ── Same Logo Widget used across SplashScreen ──
class SoloLogoWidget extends StatelessWidget {
  final double size;

  const SoloLogoWidget({super.key, this.size = 70});

  @override
  Widget build(BuildContext context) {
    final scale = size / 74.0;

    return SizedBox(
      width: 278.w * scale,
      height: 130.h * scale,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SvgPicture.asset(
          'assets/svg/solo.svg',
          width: 281,
          height: 131,
        ),
      ),
    );
  }
}

class PaymentResultPage extends StatefulWidget {
  final bool success;

  const PaymentResultPage({super.key, required this.success});

  @override
  State<PaymentResultPage> createState() => _PaymentResultPageState();
}

class _PaymentResultPageState extends State<PaymentResultPage> {
  bool _isChecking = true;
  bool _confirmed = false;

  int _statusBefore = 0;
  int _creditsBefore = 0;
  int _statusAfter = 0;
  int _creditsAfter = 0;

  @override
  void initState() {
    super.initState();
    if (widget.success) {
      _confirmSubscriptionUpdate();
    } else {
      _isChecking = false;
    }
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

    final int totalCredits = _creditsAfter > 0 ? _creditsAfter : (_creditsBefore + addedCredits);
    final String planName = _getPlanName(_statusAfter > 0 ? _statusAfter : _statusBefore);

    return Scaffold(
      backgroundColor: const Color(0xFF002C3E),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSize.w(24), vertical: AppSize.h(16)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // --- Top Section ---
                      Column(
                        children: [
                          SizedBox(height: AppSize.h(10)),

                          // ── Splash Screen Wala Exact SoloLogoWidget ──
                          const Center(
                            child: SoloLogoWidget(size: 60),
                          ),

                          SizedBox(height: AppSize.h(24)),

                          // --- Glow Icon (Success / Cancel) ---
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: success
                                  ? const Color(0xFF1B3B2B)
                                  : const Color(0xFF3B1E22),
                              border: Border.all(
                                color: success
                                    ? const Color(0xFFA2D071)
                                    : const Color(0xFFF28D7D),
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (success
                                      ? const Color(0xFFA2D071)
                                      : const Color(0xFFF28D7D))
                                      .withOpacity(0.35),
                                  blurRadius: 30,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(
                              success ? Icons.check : Icons.close,
                              color: success
                                  ? const Color(0xFFA2D071)
                                  : const Color(0xFFF28D7D),
                              size: 58,
                            ),
                          ),
                          SizedBox(height: AppSize.h(24)),

                          // --- Title ---
                          Text(
                            success ? "Payment Successful!" : "Payment Cancelled",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: AppSize.h(12)),

                          // --- Subtitle / Polling Loader ---
                          if (success && _isChecking) ...[
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF78BCC4),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Confirming your subscription details...",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFA8B6C2),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ] else ...[
                            Text(
                              success
                                  ? (_confirmed
                                  ? "Thank you for your subscription! Your SOLO account is now active and ready."
                                  : "Payment received! We are setting up your account credits automatically.")
                                  : "It looks like you canceled your payment process. No charges have been made to your account.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFA8B6C2),
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                          ],
                          SizedBox(height: AppSize.h(24)),

                          // --- Summary Card Container ---
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF07384D).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFF1B556D).withOpacity(0.5),
                              ),
                            ),
                            child: success
                                ? Column(
                              children: [
                                _buildSummaryRow("Plan:", planName),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(color: Color(0xFF1B556D), height: 1),
                                ),
                                _buildSummaryRow("Credits:", "+$addedCredits added"),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Divider(color: Color(0xFF1B556D), height: 1),
                                ),
                                _buildSummaryRow("Total:", "$totalCredits credits", isBold: true),
                              ],
                            )
                                : const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
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
                        ],
                      ),

                      // --- Bottom Actions ---
                      Column(
                        children: [
                          SizedBox(height: AppSize.h(20)),
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
                                    builder: (_) =>
                                    success ? const HomePage() : const SubscriptionPage(),
                                  ),
                                      (route) => false,
                                );
                              },
                              child: Text(
                                success ? "Continue to Home" : "Return to Plans",
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
                                success ? "View Subscription Details" : "Explore Other Plans",
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