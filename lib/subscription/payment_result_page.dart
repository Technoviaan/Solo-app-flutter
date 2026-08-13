import 'package:flutter/material.dart';
import '../core/storage/token_storage.dart';
import '../home/home_page.dart';
import 'subscription_api.dart';
import 'subscription_page.dart';

/// Shown after Stripe Checkout redirects back into the app via the
/// solo://payment-success or solo://payment-cancel deep link.
///
/// NOTE: This screen does NOT itself activate the subscription. Actual
/// activation only ever happens on the backend via the Stripe webhook
/// (as agreed with Sonu). All this screen does is:
///   1. Tell the user whether Stripe reported success or cancel.
///   2. If success, poll GET /subscription/status a few times so the UI
///      catches up as soon as the webhook has processed, and print clear
///      🧾 [PaymentResult] log lines the whole way through so it's easy to
///      confirm from `flutter run` / device logs whether local data
///      actually updated after a real subscription purchase.
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
      debugPrint("🧾 [PaymentResult] Deep link says payment CANCELLED. No status refresh needed.");
      _isChecking = false;
    }
  }

  Future<void> _confirmSubscriptionUpdate() async {
    debugPrint("🧾 [PaymentResult] Deep link says payment SUCCESS (solo://payment-success). "
        "Verifying backend webhook actually updated subscription data...");

    _statusBefore = await TokenStorage.getSubscriptionStatus();
    _creditsBefore = await TokenStorage.getCredits();
    debugPrint("🧾 [PaymentResult] Local state BEFORE refresh -> status=$_statusBefore, credits=$_creditsBefore");

    const maxAttempts = 5;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      debugPrint("🧾 [PaymentResult] Polling /subscription/status (attempt $attempt/$maxAttempts)...");

      final data = await SubscriptionApi.getSubscriptionStatus();

      final newStatus = await TokenStorage.getSubscriptionStatus();
      final newCredits = await TokenStorage.getCredits();
      debugPrint("🧾 [PaymentResult] Local state AFTER attempt $attempt -> "
          "status=$newStatus, credits=$newCredits, rawResponse=$data");

      _statusAfter = newStatus;
      _creditsAfter = newCredits;

      if (newStatus != _statusBefore || newCredits != _creditsBefore) {
        debugPrint("✅ [PaymentResult] Subscription data CHANGED after purchase — "
            "webhook has updated the backend and the app has picked it up.");
        _confirmed = true;
        break;
      }

      if (attempt < maxAttempts) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    if (!_confirmed) {
      debugPrint("⚠️ [PaymentResult] No change detected after $maxAttempts attempts "
          "(still status=$_statusAfter, credits=$_creditsAfter). Either the Stripe webhook "
          "hasn't landed on the backend yet, or it landed with identical values. Re-check by "
          "reopening the Subscription page, which also calls getSubscriptionStatus().");
    }

    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final success = widget.success;

    return Scaffold(
      backgroundColor: const Color(0xFF002C3E),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.cancel,
                  color: success ? const Color(0xFFA2D071) : const Color(0xFFF28D7D),
                  size: 80,
                ),
                const SizedBox(height: 24),
                Text(
                  success ? "Payment Successful" : "Payment Cancelled",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (success && _isChecking) ...[
                  const CircularProgressIndicator(color: Color(0xFF78BCC4)),
                  const SizedBox(height: 12),
                  const Text(
                    "Confirming your subscription...",
                    style: TextStyle(color: Color(0xFFA8B6C2), fontSize: 15),
                  ),
                ] else if (success) ...[
                  Text(
                    _confirmed
                        ? "Your subscription is now active."
                        : "Payment received. It can take a little longer to activate — "
                            "we'll keep it up to date automatically.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFA8B6C2), fontSize: 15),
                  ),
                ] else ...[
                  const Text(
                    "No charge was made. You can try again anytime from the subscription screen.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFA8B6C2), fontSize: 15),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF114B5F),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => success ? const HomePage() : const SubscriptionPage(),
                      ),
                      (route) => false,
                    );
                  },
                  child: Text(
                    success ? "Continue" : "Back to Plans",
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
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
