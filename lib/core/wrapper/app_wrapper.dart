import 'package:flutter/material.dart';
import 'package:solo_app/subscription/no_credits_page.dart';
import '../../core/storage/token_storage.dart';
import '../../subscription/subscription_api.dart';
import '../../subscription/subscription_page.dart';

class AppWrapper extends StatefulWidget {

  final Widget child;

  const AppWrapper({super.key, required this.child});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {

  int credits = 0;
  int subscriptionStatus = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {

    // Refresh from the backend first so an admin credit adjustment (or any
    // other server-side change) is reflected as soon as the app opens,
    // instead of showing whatever was cached on the device.
    await SubscriptionApi.getSubscriptionStatus();

    final c = await TokenStorage.getCredits();
    final s = await TokenStorage.getSubscriptionStatus();

    if (!mounted) return;

    setState(() {
      credits = c;
      subscriptionStatus = s;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    /// LOADING
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    /// ❌ NO CREDITS → BLOCK
    if (credits == 0) {
      return const NoCreditsPage();
    }

    /// ✅ NORMAL FLOW
    return Stack(
      children: [

        widget.child,

        /// ⚠️ LOW CREDIT BANNER
        if (credits <= 1)
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "⚠️ Low credits, please top-up",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}