import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/storage/token_storage.dart';
import '../core/utils/app_size.dart';
import '../home/shedule/schedule_page.dart';
import '../home/checkin/local_storage.dart';
import 'stripe_api.dart';
import 'subscription_api.dart';
import '../home/home_page.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  late PageController _pageController;
  double _currentPage = 1.0; // Start with the 7 Days Trial (Index 1)

  final List<Map<String, dynamic>> _plans = [
    {
      "id": "monthly",
      "big": "1",
      "title": "Month\n/Month",
      "price": "\$8/month",
      "color": const Color(0xFF00AED6),
      "benefits": ["3 Alert Credits per month", "Add up to 2 contacts", "Auto-renew monthly"],
      "progress": 0.9,
      "priceId": "price_1TZ8zgH682jITs1wzNptVVi0",
    },
    {
      "id": "trial",
      "big": "7",
      "title": "Days\nFree Trial",
      "price": "(Cancel Anytime)",
      "color": const Color(0xFFA2D071),
      "benefits": ["1 Alert Credit", "Add 1 contact", "First-time users only"],
      "progress": 0.9,
      "priceId": null,
    },
    {
      "id": "yearly",
      "big": "1",
      "title": "Year\n\$50/Year",
      "price": "(Save \$46)",
      "color": const Color(0xFFD4AF64),
      "benefits": ["36 Alert Credits per year", "Add up to 2 contacts", "Auto-renew yearly"],
      "progress": 0.9,
      "priceId": "price_1TZ97RH682jITs1w0gc0XrBX",
    },
    {
      "id": "credit_3",
      "big": "3",
      "title": "Alert\nCredits",
      "price": "\$3",
      "color": const Color(0xFFF28D7D),
      "benefits": ["Keep daily check-ins", "Stay connected", "For subscribers only"],
      "progress": 0.9,
      "priceId": "price_1TZ993H682jITs1wc1kGxKlC",
    },
    {
      "id": "credit_5",
      "big": "5",
      "title": "Alert\nCredits",
      "price": "\$6",
      "color": const Color(0xFFE651A3),
      "benefits": ["Keep daily check-ins", "Stay connected", "For subscribers only"],
      "progress": 0.9,
      "priceId": "price_1TZ9AaH682jITs1wrJafUO7C",
    },
  ];

  String? _activePromoPlan;
  DateTime? _promoActivationTime;
  bool _hideDisclaimer = false;
  List<String> _usedPromoCodes = [];
  String _promoInput = "";
  String? _promoError;
  bool _promoSuccess = false;
  String? _promoSuccessMessage;
  final TextEditingController _promoController = TextEditingController();

  int _subscriptionStatus = 0;
  int _credits = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPromoState();

    // Use a large initial page to allow "infinite" scrolling in both directions
    const int startFactor = 1000;
    int initialPage = (_plans.length * startFactor) + 1; // Index 1 is the trial
    _pageController = PageController(
      viewportFraction: 0.5,
      initialPage: initialPage,
    );
    _currentPage = initialPage.toDouble();

    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _currentPage = _pageController.page ?? initialPage.toDouble();
        });
      }
    });
  }

  Future<void> _loadPromoState() async {
    final activePlan = await LocalStorage.getString("active_promo_plan");
    final activationTimeStr = await LocalStorage.getString("promo_activation_time");
    final hideDisclaimer = await LocalStorage.getBool("hide_disclaimer");
    final usedCodes = await LocalStorage.getStringList("used_promo_codes");

    final status = await TokenStorage.getSubscriptionStatus();
    final creditsVal = await TokenStorage.getCredits();

    setState(() {
      _activePromoPlan = activePlan;
      if (activationTimeStr != null) {
        _promoActivationTime = DateTime.parse(activationTimeStr);
      }
      _hideDisclaimer = hideDisclaimer;
      _usedPromoCodes = usedCodes;
      _subscriptionStatus = status;
      _credits = creditsVal;
    });

    try {
      final data = await SubscriptionApi.getSubscriptionStatus();
      if (data != null && mounted) {
        final freshStatus = await TokenStorage.getSubscriptionStatus();
        final freshCredits = await TokenStorage.getCredits();
        setState(() {
          _subscriptionStatus = freshStatus;
          _credits = freshCredits;
        });
      }
    } catch (e) {
      print("Stripe page background subscription status sync error: $e");
    }
  }

  Future<void> _handlePayment(Map<String, dynamic> plan) async {
    final planId = plan["id"] as String;
    final priceId = plan["priceId"] as String?;
    final isTopup = planId.startsWith("credit_");

    if (isTopup) {
      if (_subscriptionStatus != 2 && _subscriptionStatus != 3) {
        showTopupRestrictedDialog(context);
        return;
      }
    }

    if (planId == "trial") {
      if (_subscriptionStatus == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You are already on the Free Trial")),
        );
        return;
      }

      setState(() => _isLoading = true);
      final res = await SubscriptionApi.startTrial();
      setState(() => _isLoading = false);

      if (!mounted) return;
      if (res != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Free Trial Activated Successfully!")),
        );
        await _loadPromoState();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to activate Free Trial. Please try again.")),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    String? sessionUrl;
    if (isTopup) {
      sessionUrl = await StripeApi.createTopupSession(priceId!);
    } else {
      if (_subscriptionStatus == 2 || _subscriptionStatus == 3) {
        sessionUrl = await StripeApi.openPortal();
      } else {
        sessionUrl = await StripeApi.createSubscriptionSession(priceId!);
      }
    }

    setState(() => _isLoading = false);

    if (sessionUrl != null && sessionUrl.isNotEmpty) {
      final uri = Uri.parse(sessionUrl);
      debugPrint("💳 [SubscriptionPage] Attempting to launch Stripe URL: $sessionUrl");
      try {
        final canLaunch = await canLaunchUrl(uri);
        debugPrint("💳 [SubscriptionPage] canLaunchUrl() = $canLaunch");
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint("✅ [SubscriptionPage] launchUrl() returned without throwing");

        setState(() => _isLoading = true);
        await Future.delayed(const Duration(milliseconds: 2500));

        await SubscriptionApi.getSubscriptionStatus();
        await _loadPromoState();

        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Subscription status updated successfully")),
          );
        }
      } catch (e) {
        debugPrint("❌ [SubscriptionPage] launchUrl() FAILED with error: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not open payment page: $e")),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to initiate payment session. Please try again.")),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  void _applyPromoCode() async {
    final code = _promoInput.toUpperCase();

    if (_usedPromoCodes.contains(code)) {
      setState(() {
        _promoError = "Promo Code Already Used";
      });
      _clearErrorAfterDelay();
      return;
    }

    String? promoType;
    int subStatus = 0;
    int grantCredits = 0;

    if (code == "SOLO1MONTH" || code == "SOLOXXXXXX") {
      promoType = "1 Month Free Access";
      subStatus = 2;
      grantCredits = 3;
    } else if (code == "SOLO1YEAR") {
      promoType = "1 Year Free Access";
      subStatus = 3;
      grantCredits = 36;
    } else if (code == "SOLOUNLIMITED" || code == "SOLOLIFETIME") {
      promoType = "Unlimited Free Access";
      subStatus = 4;
      grantCredits = 999;
    } else {
      setState(() {
        _promoError = "Invalid Promo Code";
      });
      _clearErrorAfterDelay();
      return;
    }

    _usedPromoCodes.add(code);
    await TokenStorage.saveSubscriptionStatus(subStatus);

    int currentCredits = await TokenStorage.getCredits();
    await TokenStorage.saveCredits(currentCredits + grantCredits);

    final now = DateTime.now();
    await LocalStorage.saveString("active_promo_plan", promoType);
    await LocalStorage.saveString("promo_activation_time", now.toIso8601String());
    await LocalStorage.saveStringList("used_promo_codes", _usedPromoCodes);
    await LocalStorage.saveBool("hide_disclaimer", true);

    setState(() {
      _activePromoPlan = promoType;
      _promoActivationTime = now;
      _hideDisclaimer = true;
      _promoSuccess = true;
      _promoSuccessMessage = "✓ $promoType Activated";
      _promoError = null;
      _promoInput = "";
      _promoController.clear();
    });
  }

  void _clearErrorAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _promoError = null;
          _promoInput = "";
          _promoController.clear();
        });
      }
    });
  }

  Widget _buildPromoCodeField() {
    if (_promoSuccess) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFEE6A59),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Color(0xFFF5F5F5),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _promoSuccessMessage ?? "Free Access Activated",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    bool hasText = _promoInput.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFD1D9E0),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  style: const TextStyle(
                    color: Color(0xFF5A6C7D),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: "Promo Code",
                    hintStyle: TextStyle(
                      color: Color(0xFF8A99A6),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _promoInput = val.trim();
                    });
                  },
                ),
              ),
              GestureDetector(
                onTap: hasText ? _applyPromoCode : null,
                child: Text(
                  "Apply",
                  style: TextStyle(
                    color: hasText ? const Color(0xFF5A6C7D) : const Color(0xFF8A99A6),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_promoError != null) ...[
          const SizedBox(height: 6),
          Text(
            _promoError!,
            style: const TextStyle(
              color: Color(0xFFEE6A59),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  /// ================= DUMMY PURCHASE LOGIC =================
  Future<void> handleDummyPurchase(String plan) async {
    if (plan == "trial") {
      await TokenStorage.saveSubscriptionStatus(1);
      await TokenStorage.saveCredits(1);
      await TokenStorage.saveMaxContacts(1);
      await TokenStorage.saveMaxCheckins(2);
    } else if (plan == "monthly") {
      await TokenStorage.saveSubscriptionStatus(2);
      await TokenStorage.saveCredits(3);
      await TokenStorage.saveMaxContacts(2);
      await TokenStorage.saveMaxCheckins(2);
    } else if (plan == "yearly") {
      await TokenStorage.saveSubscriptionStatus(3);
      await TokenStorage.saveCredits(36);
      await TokenStorage.saveMaxContacts(2);
      await TokenStorage.saveMaxCheckins(2);
    } else if (plan == "credit_3") {
      int current = await TokenStorage.getCredits();
      await TokenStorage.saveCredits(current + 3);
    } else if (plan == "credit_5") {
      int current = await TokenStorage.getCredits();
      await TokenStorage.saveCredits(current + 5);
    }
  }

  /// ================= PURCHASE POPUP =================
  void showPurchaseDialog(BuildContext context, String plan) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Enter Purchase Code"),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: "Enter 1234",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text == "1234") {
                  await handleDummyPurchase(plan);
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SchedulePage(),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid code")),
                  );
                }
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  /// ================= UNIFIED CARD WIDGET =================
  Widget dynamicCard({
    required String bigNumber,
    required String title,
    required String price,
    String? saveText,
    required Color backgroundColor,
    required List<String> benefits,
    required VoidCallback onTap,
    required double scale,
    double progress = 0.6,
  }) {
    return Transform.scale(
      scale: scale,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 175,
          height: 254,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF001D2B), // Dark offset shadow color
                offset: Offset(8, 8), // Shifted exactly down and right
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
          ),
          // Use a Column with no mainAxisSize.min so children can fill the height
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top number + title + price ──
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      bigNumber,
                      style: const TextStyle(
                        fontSize: 70,
                        height: 0.9,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 28,
                        height: 1.3,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      price,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (saveText != null)
                      Text(
                        saveText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // ── Benefits label + fully filled line ──
              Row(
                children: [
                  const Text(
                    "Benefits",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // ── Benefits list — Flexible so it doesn't overflow ──
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: benefits
                      .map((benefit) => Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "• ",
                          style: TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            benefit,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              letterSpacing: -0.5,
                              color: Colors.black87,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFF002C3E),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSize.w(20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //const SizedBox(height: 10),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, color: Color(0xFFA8B6C2)),
                            padding: EdgeInsets.only(right: 1250),
                            alignment: Alignment.centerLeft,
                          ),
                          //const SizedBox(height: 7),
                          const Text(
                            "Keep Your\nCheck-ins\nActive",
                            style: TextStyle(
                              color: Color(0xFF78BCC4),
                              fontSize: 44,
                              height: 1.1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Subscribe so I can look out for\nyou every day",
                            style: TextStyle(
                                color: Color(0xFFD1D9E0),
                                fontSize: 22,
                                fontWeight: FontWeight.w400
                            ),
                          ),
                          const SizedBox(height: 24),
                          // PAGE INDICATOR DOTS
                          Center(
                            child: SizedBox(
                              width: 84, // Exact Figma total width
                              height: 7, // Exact Figma height
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (int i = 0; i < _plans.length; i++)
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: (i == (_currentPage.round() % _plans.length)) ? const Color(0xFFF28D7D) : Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Divider(color: Colors.white24),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Plans",
                                  style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  "Add Credits",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 24),

                          // CAROUSEL SECTION
                          SizedBox(
                            height: 260, // Accommodates the 260px highlighted height
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: 10000, // Large number for infinite loop
                              clipBehavior: Clip.none,
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                final plan = _plans[index % _plans.length];

                                // Scale logic: Still works with large indices
                                double diff = (index - _currentPage).abs().clamp(0.0, 1.0);
                                double scale = 1.0 - (diff * 0.165);
                                double opacity = 1.0 - (diff * 0.5);

                                return Opacity(
                                  opacity: opacity,
                                  child: dynamicCard(
                                    bigNumber: plan["big"],
                                    title: plan["title"],
                                    price: plan["price"],
                                    backgroundColor: plan["color"],
                                    benefits: List<String>.from(plan["benefits"]),
                                    progress: plan["progress"] ?? 0.6,
                                    scale: scale,
                                    onTap: () => _handlePayment(plan),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 27),
                          _buildPromoCodeField(),
                          if (!_hideDisclaimer) ...[
                            const SizedBox(height: 24),
                            const Text(
                              "Purchase confirms auto-renewal and agreement to Terms. Cancel anytime in your App Store settings.",
                              style: TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                          const SizedBox(height: 20),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 16),
                          const Text(
                            "Your credits at a glance",
                            style: TextStyle(
                              color: Color(0xFF78BCC4),
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FutureBuilder<int>(
                            future: Future.value(_credits),
                            builder: (context, snapshot) {
                              final credits = _credits;

                              String planLabel = "1 free credit to start";
                              String? renewalText;

                              if (_activePromoPlan != null) {
                                planLabel = _activePromoPlan!;
                                if (_promoActivationTime != null) {
                                  if (_activePromoPlan == "1 Month Free Access") {
                                    final exp = _promoActivationTime!.add(const Duration(days: 30));
                                    renewalText = "Next renewal ${_formatDate(exp)}";
                                  } else if (_activePromoPlan == "1 Year Free Access") {
                                    final exp = _promoActivationTime!.add(const Duration(days: 365));
                                    renewalText = "Next renewal ${_formatDate(exp)}";
                                  } else if (_activePromoPlan == "Unlimited Free Access") {
                                    renewalText = "No Expiry";
                                  }
                                }
                              } else if (_subscriptionStatus == 1) {
                                planLabel = "Free Trial Plan";
                              } else if (_subscriptionStatus == 2) {
                                planLabel = "Monthly Subscription";
                              } else if (_subscriptionStatus == 3) {
                                planLabel = "Yearly Subscription";
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.only(left: 20, right: 10, top: 0, bottom: 0),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF114B5F),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "Available\nCredits",
                                                style: TextStyle(
                                                  color: Color(0xFFA8B6C2),
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.1,
                                                ),
                                              ),
                                              const Text(
                                                "This Month",
                                                style: TextStyle(
                                                  color: Color(0xff89BCC8),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                planLabel,
                                                style: const TextStyle(
                                                  color: Color(0xFFA8B6C2),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              if (renewalText != null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  renewalText,
                                                  style: const TextStyle(
                                                    color: Color(0xff89BCC8),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 1,
                                          height: 115,
                                          color: const Color(0xff8A99A6),
                                          margin: const EdgeInsets.symmetric(horizontal: 30),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(right: 10),
                                          child: Text(
                                            "$credits",
                                            style: const TextStyle(
                                              color: Color(0xFFA8B6C2),
                                              fontSize: 128,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
                Builder(
                    builder: (context) {
                      final activePlanIndex = _currentPage.round() % _plans.length;
                      final activePlan = _plans[activePlanIndex];
                      final planId = activePlan["id"].toString();
                      final isTopup = planId.startsWith("credit_");
                      final isCtaDisabled = (_activePromoPlan != null) && !isTopup;

                      String buttonText = "Start 7-Day Free Trial";
                      if (isTopup) {
                        buttonText = "Purchase ${activePlan['big']} Credits";
                      } else if (_subscriptionStatus == 1) {
                        if (planId == "trial") {
                          buttonText = "Free Trial (Current)";
                        } else {
                          buttonText = "Upgrade plan";
                        }
                      } else if (_subscriptionStatus == 2 || _subscriptionStatus == 3) {
                        if (planId == "trial") {
                          buttonText = "Free Trial (Used)";
                        } else {
                          buttonText = "Upgrade your plan";
                        }
                      } else {
                        if (planId == "trial") {
                          buttonText = "Start 7-Day Free Trial";
                        } else {
                          buttonText = "Subscribe to ${planId == 'monthly' ? 'Monthly' : 'Yearly'}";
                        }
                      }

                      if (_activePromoPlan != null && !isTopup) {
                        buttonText = _activePromoPlan!;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        color: const Color(0xFF002C3E),
                        child: Row(
                          children: [
                            // IconButton(
                            //   onPressed: () => Navigator.pop(context),
                            //   icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 28),
                            // ),
                            const SizedBox(),
                            const Spacer(),
                            Text(
                              buttonText,
                              style: TextStyle(
                                color: isCtaDisabled ? const Color(0xFF8A99A6) : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: isCtaDisabled
                                  ? null
                                  : () => _handlePayment(activePlan),
                              child: isCtaDisabled
                                  ? Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4A5A6A),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward,
                                  color: Color(0xFF8A99A6),
                                  size: 32,
                                ),
                              )
                                  : SvgPicture.asset(
                                "assets/svg/nextbutton.svg",
                                width: 64,
                                height: 64,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                ),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFF78BCC4),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Connecting with Stripe...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> canUseTopup() async {
    int status = await TokenStorage.getSubscriptionStatus();
    return status == 2 || status == 3;
  }

  void showTopupRestrictedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Subscription Required"),
          content: const Text(
            "Please purchase a Monthly or Yearly plan to use top-up credits.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}