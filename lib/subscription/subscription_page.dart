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
  double _currentPage = 1.0;

  final List<Map<String, dynamic>> _plans = [
    {
      "id": "monthly",
      "big": "1",
      "title": "Month",
      "price": "\$8/Month",
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
      "priceId": "price_1TZ8zgH682jITs1wzNptVVi0",
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

    const int startFactor = 1000;
    int initialPage = (_plans.length * startFactor) + 1;
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
      debugPrint("Subscription status sync error: $e");
    }
  }

  /// ================= 1. CARD TAP PAYMENT HANDLER =================
  /// Card click par direct checkout session banega ya ALREADY ACTIVE wala Alert aayega.
  /// (Yahan se Portal open nahi hoga)
  Future<void> _handlePayment(Map<String, dynamic> plan) async {
    final planId = plan["id"] as String;
    final priceId = plan["priceId"] as String?;
    final isTopup = planId.startsWith("credit_");

    // 1. Top-up Restriction Check
    if (isTopup) {
      if (_subscriptionStatus != 2 && _subscriptionStatus != 3) {
        showTopupRestrictedDialog(context);
        return;
      }
    }

    // 2. Trial Plan Selection Check (Agar user pehle se trial ya paid sub pe hai)
    if (planId == "trial") {
      if (_subscriptionStatus >= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You have already used the Free Trial.")),
        );
        return;
      }
    }

    // 3. Same Plan / Active Subscription Check (Card click pe alert aayega)
    if ((planId == "monthly" && _subscriptionStatus == 2) ||
        (planId == "yearly" && _subscriptionStatus == 3)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You are already on the ${planId == 'monthly' ? 'Monthly' : 'Yearly'} plan.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? sessionUrl;

    if (isTopup) {
      sessionUrl = await StripeApi.createTopupSession(priceId!);
    } else if (planId == "trial" && _subscriptionStatus == 0) {
      sessionUrl = await StripeApi.createTrialSession(priceId!);
    } else {
      // New direct checkout
      sessionUrl = await StripeApi.createSubscriptionSession(priceId!);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (sessionUrl != null && sessionUrl.isNotEmpty) {
      final uri = Uri.parse(sessionUrl);
      try {
        // 🛠️ FIX: Record that a real Stripe checkout is now in flight
        // BEFORE handing off to the external browser. `launchUrl(...,
        // mode: LaunchMode.externalApplication)` below opens the full
        // system browser (a separate app/task), not an in-app custom tab.
        // While the user is entering card details there — which can take
        // 30s-2min — Android is free to kill our process for memory, and
        // on some OEM builds the solo://payment-success deep link doesn't
        // get redelivered reliably when that happens. This flag lets
        // SplashScreen fall back to showing PaymentResultPage on the next
        // app open even if the OS-level deep link never arrives. See the
        // doc comment on TokenStorage.getPendingCheckout() for the full
        // explanation.
        await TokenStorage.savePendingCheckout(true);

        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // 🛠️ FIX: Removed the old "wait 3.5s, optimistically add credits
        // locally, then immediately re-sync with the backend" logic here.
        // It was actively harmful: the re-sync call almost always ran
        // BEFORE the Stripe webhook had actually landed on the backend
        // (webhooks routinely take longer than 3.5s), so it fetched STALE
        // pre-purchase data and overwrote the optimistic local credit
        // add with the old (wrong) number. The only reason credits ever
        // ended up correct was that the LATER solo://payment-success deep
        // link (PaymentResultPage) happened to re-poll and fix it — but if
        // that deep link is ever missed (the cold-start case fixed above),
        // credits would stay stuck at the stale value even though the
        // user was actually charged.
        //
        // PaymentResultPage (reached via the deep link, or via the
        // TokenStorage.pendingCheckout fallback in SplashScreen if the
        // deep link itself doesn't arrive) is the single source of truth
        // for confirming a purchase now — it polls the real backend up to
        // 5 times over 10s specifically so it catches the webhook. This
        // page just needs to hand off to Stripe and get out of the way.
        if (mounted) {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not open payment page: $e")),
          );
        }
      }
    } else {
      final errorMsg = StripeApi.lastErrorMessage;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMsg != null && errorMsg.isNotEmpty
                  ? errorMsg
                  : "Failed to initiate payment session. Please try again.",
            ),
          ),
        );
      }
    }
  }

  /// ================= 2. UPGRADE TEXT / BUTTON TAP HANDLER =================
  /// Sirf "Upgrade plan / Upgrade your plan" text ya arrow par click karne se Stripe Customer Portal khulega
  Future<void> _handleBottomActionTap(Map<String, dynamic> plan) async {
    final planId = plan["id"].toString();
    final isTopup = planId.startsWith("credit_");

    if (isTopup) {
      await _handlePayment(plan);
      return;
    }

    // 🔥 Agar user Trial (status 1) ya Paid Plan (status 2, 3) par hai:
    // Toh "Upgrade plan" par click karne par seedha Stripe Customer Portal open hoga!
    if (_subscriptionStatus >= 1) {
      debugPrint("💳 [SubscriptionPage] Opening Stripe Portal for upgrade (status $_subscriptionStatus)...");
      await _openManagePortal();
      return;
    }

    // Status 0 wale fresh user ke liye checkout flow
    await _handlePayment(plan);
  }

  Future<void> _openManagePortal() async {
    // Status 1, 2 aur 3 teeno ke liye allow karein
    if (_subscriptionStatus < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a plan first to start subscription."),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final portalUrl = await StripeApi.openPortal();

    if (portalUrl != null && portalUrl.isNotEmpty) {
      final uri = Uri.parse(portalUrl);
      try {
        // NOTE: intentionally NOT setting TokenStorage.savePendingCheckout()
        // here — the Stripe Customer Portal is for managing an existing
        // subscription, not a new checkout, and doesn't redirect back via
        // solo://payment-success. Setting the flag here would make Splash
        // wrongly show PaymentResultPage next time the app opens.
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        await Future.delayed(const Duration(milliseconds: 2000));
        await SubscriptionApi.getSubscriptionStatus();
        await _loadPromoState();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not open subscription portal: $e")),
          );
        }
      }
    } else {
      if (mounted) {
        final errorMsg = StripeApi.lastErrorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMsg != null && errorMsg.isNotEmpty
                  ? errorMsg
                  : "Failed to open subscription portal. Please try again.",
            ),
          ),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  String _formatDate(DateTime date) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  void _applyPromoCode() async {
    final code = _promoInput.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _promoError = null;
    });

    final res = await SubscriptionApi.redeemPromoCode(code);

    setState(() => _isLoading = false);

    final isSuccess = (res != null) &&
        (res['statusCode'] == 200 || res['statusCode'] == 201) &&
        (res['success'] == true);

    if (isSuccess) {
      final message = res["message"] ?? "Promo applied successfully";
      final plan = res["plan"]?.toString().toUpperCase() ?? "MONTHLY";

      String promoType = "1 Month Free Access";
      int subStatus = 2;

      if (plan == "YEARLY") {
        promoType = "1 Year Free Access";
        subStatus = 3;
      } else if (plan == "LIFETIME" || plan == "UNLIMITED") {
        promoType = "Unlimited Free Access";
        subStatus = 4;
      }

      _usedPromoCodes.add(code.toUpperCase());
      await TokenStorage.saveSubscriptionStatus(subStatus);

      final now = DateTime.now();
      await LocalStorage.saveString("active_promo_plan", promoType);
      await LocalStorage.saveString("promo_activation_time", now.toIso8601String());
      await LocalStorage.saveStringList("used_promo_codes", _usedPromoCodes);
      await LocalStorage.saveBool("hide_disclaimer", true);

      await SubscriptionApi.getSubscriptionStatus();
      await _loadPromoState();

      setState(() {
        _activePromoPlan = promoType;
        _promoActivationTime = now;
        _hideDisclaimer = true;
        _promoSuccess = true;
        _promoSuccessMessage = "✓ $message";
        _promoError = null;
        _promoInput = "";
        _promoController.clear();
      });
    } else {
      final errorText = res?["error"] ?? res?["message"] ?? "Invalid Promo Code";

      setState(() {
        _promoError = errorText;
      });
      _clearErrorAfterDelay();
    }
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          _promoSuccessMessage ?? "Free Access Activated",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
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

  /// ================= UNIFIED CARD WIDGET =================
  Widget dynamicCard({
    required String id,
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
    final bool isMonthly = (id == "monthly");

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
                color: Color(0xFF001D2B),
                offset: Offset(8, 8),
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        height: 1.2,
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 0.5,
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
              SizedBox(height: isMonthly ? 37 : 4),
              Row(
                children: [
                  const Text(
                    "Benefits",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
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
                  child: RefreshIndicator(
                    onRefresh: _loadPromoState,
                    color: const Color(0xFF78BCC4),
                    backgroundColor: const Color(0xFF114B5F),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSize.w(20)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(Icons.arrow_back, color: Color(0xFFA8B6C2)),
                              ),
                              padding: const EdgeInsets.only(right: 1250),
                              alignment: Alignment.centerLeft,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                "Keep Your\nCheck-ins\nActive",
                                style: TextStyle(
                                  color: Color(0xFF78BCC4),
                                  fontSize: 44,
                                  height: 1.1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                "Subscribe so I can look out for\nyou every day",
                                style: TextStyle(
                                    color: Color(0xFFD1D9E0), fontSize: 22, fontWeight: FontWeight.w400),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: SizedBox(
                                width: 84,
                                height: 7,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (int i = 0; i < _plans.length; i++)
                                      Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: (i == (_currentPage.round() % _plans.length))
                                              ? const Color(0xFFF28D7D)
                                              : Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Divider(color: Colors.white24),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Plans",
                                    style: TextStyle(
                                        color: Colors.white54, fontSize: 18, fontWeight: FontWeight.w600),
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
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Divider(color: Colors.white24),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 265,
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: 10000,
                                clipBehavior: Clip.none,
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final plan = _plans[index % _plans.length];

                                  double diff = (index - _currentPage).abs().clamp(0.0, 1.0);
                                  double scale = 1.0 - (diff * 0.165);
                                  double opacity = 1.0 - (diff * 0.5);

                                  return Opacity(
                                    opacity: opacity,
                                    child: dynamicCard(
                                      id: plan["id"] ?? "",
                                      bigNumber: plan["big"],
                                      title: plan["title"],
                                      price: plan["price"],
                                      saveText: plan["saveText"],
                                      backgroundColor: plan["color"],
                                      benefits: List<String>.from(plan["benefits"]),
                                      progress: plan["progress"] ?? 0.6,
                                      scale: scale,
                                      // Card click uses regular flow (alerts on active plan)
                                      onTap: () => _handlePayment(plan),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 27),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: _buildPromoCodeField(),
                            ),
                            if (!_hideDisclaimer) ...[
                              const SizedBox(height: 24),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  "Start your 7‑day free trial. Auto‑renews after trial until cancelled. Cancel anytime in your App Store settings.",
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Divider(color: Colors.white24),
                            ),
                            const SizedBox(height: 16),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                "Your credits at a glance",
                                style: TextStyle(
                                  color: Color(0xFF78BCC4),
                                  fontSize: 26,
                                  fontWeight: FontWeight.w600,
                                ),
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

                                final String creditStr = "$credits";
                                final double dynamicFontSize = creditStr.length <= 1
                                    ? 100.0
                                    : creditStr.length == 2
                                    ? 75.0
                                    : 52.0;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF114B5F),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              flex: 5,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text(
                                                    "Available\nCredits",
                                                    style: TextStyle(
                                                      color: Color(0xFFA8B6C2),
                                                      fontSize: 26,
                                                      fontWeight: FontWeight.w600,
                                                      height: 1.1,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  const Text(
                                                    "This Month",
                                                    style: TextStyle(
                                                      color: Color(0xff89BCC8),
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Text(
                                                    planLabel,
                                                    style: const TextStyle(
                                                      color: Color(0xFFA8B6C2),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w400,
                                                    ),
                                                  ),
                                                  if (renewalText != null) ...[
                                                    const SizedBox(height: 2),
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
                                              height: 90,
                                              color: const Color(0xff8A99A6),
                                              margin: const EdgeInsets.symmetric(horizontal: 12),
                                            ),
                                            Expanded(
                                              flex: 4,
                                              child: Center(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    creditStr,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: const Color(0xFFA8B6C2),
                                                      fontSize: dynamicFontSize,
                                                      fontWeight: FontWeight.w500,
                                                      height: 1.0,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
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

                    bool isTrialDisabled = (planId == "trial") && (_subscriptionStatus >= 1);
                    bool isUpgradeText = buttonText.toLowerCase().contains("upgrade");
                    bool shouldDisableClick = (isCtaDisabled || isTrialDisabled) && !isUpgradeText;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                      color: const Color(0xFF002C3E),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        // 🔥 YAHAN: Bottom "Upgrade" Text / Button pe tap karne se seedha Portal khulega
                        onTap: shouldDisableClick ? null : () => _handleBottomActionTap(activePlan),
                        child: Row(
                          children: [
                            const Spacer(),
                            Text(
                              buttonText,
                              style: TextStyle(
                                color: shouldDisableClick ? const Color(0xFF8A99A6) : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            shouldDisableClick
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
                          ],
                        ),
                      ),
                    );
                  },
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