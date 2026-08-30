import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/storage/token_storage.dart';
import '../core/utils/app_size.dart';
import '../home/checkin/local_storage.dart';
import 'stripe_api.dart';
import 'subscription_api.dart';

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
      "priceId": "price_1TZ8zgH682jITs1wzNptVVi0",
    },
    {
      "id": "yearly",
      "big": "1",
      "title": "Year",
      "price": "\$50/year",
      "saveText": "(Save \$46)",
      "color": const Color(0xFFD4AF64),
      "benefits": ["36 Alert Credits per year", "Add up to 2 contacts", "Auto-renew yearly"],
      "progress": 0.9,
      "priceId": "price_1TZ97RH682jITs1w0gc0XrBX",
    },
    {
      "id": "credit_3",
      "big": "3",
      "title": "Top-Up\nCredits",
      "price": "\$3",
      "color": const Color(0xFFF28D7D),
      "benefits": ["Keep daily check-ins", "Stay confident and covered", "For subscribing users only"],
      "progress": 0.9,
      "priceId": "price_1TZ993H682jITs1wc1kGxKlC",
    },
    {
      "id": "credit_5",
      "big": "5",
      "title": "Top-Up\nCredits",
      "price": "\$6",
      "color": const Color(0xFFE651A3),
      "benefits": ["Keep daily check-ins", "Stay confident and covered", "For subscribing users only"],
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
  int _credits = 1;
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
      _hideDisclaimer = hideDisclaimer ?? false;
      _usedPromoCodes = usedCodes;
      _subscriptionStatus = status;
      _credits = (creditsVal != null && creditsVal > 0) ? creditsVal : 1;

      if (activePlan != null) {
        _promoSuccess = true;
        _promoSuccessMessage = activePlan;
        _hideDisclaimer = true;
      }
    });

    try {
      final data = await SubscriptionApi.getSubscriptionStatus();
      if (data != null && mounted) {
        final freshStatus = await TokenStorage.getSubscriptionStatus();
        final freshCredits = await TokenStorage.getCredits();
        setState(() {
          _subscriptionStatus = freshStatus;
          _credits = (freshCredits != null && freshCredits > 0) ? freshCredits : 1;
        });
      }
    } catch (e) {
      debugPrint("Subscription status sync error: $e");
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
      if (_subscriptionStatus >= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You have already used the Free Trial.")),
        );
        return;
      }
    }

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
      sessionUrl = await StripeApi.createSubscriptionSession(priceId!);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (sessionUrl != null && sessionUrl.isNotEmpty) {
      final uri = Uri.parse(sessionUrl);
      try {
        await TokenStorage.savePendingCheckout(true);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
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

  Future<void> _handleBottomActionTap(Map<String, dynamic> plan) async {
    final planId = plan["id"].toString();
    final isTopup = planId.startsWith("credit_");

    if (isTopup) {
      await _handlePayment(plan);
      return;
    }

    if (_subscriptionStatus >= 1) {
      await _openManagePortal();
      return;
    }

    await _handlePayment(plan);
  }

  Future<void> _openManagePortal() async {
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

    if (_usedPromoCodes.contains(code.toUpperCase())) {
      setState(() {
        _promoError = "Promo Code Already Used";
      });
      _clearErrorAfterDelay();
      return;
    }

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
        _promoSuccessMessage = promoType == "1 Year Free Access"
            ? "1 Year Free Access Activated"
            : (promoType == "Unlimited Free Access" ? "Unlimited Free Access Activated" : "1 Month Free Access Activated");
        _promoError = null;
        _promoInput = "";
        _promoController.clear();
      });
    } else {
      setState(() {
        _promoError = "Invalid Promo Code";
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
      return Container(
        height: AppSize.h(44),
        decoration: BoxDecoration(
          color: const Color(0xFFD1D9E0),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.symmetric(horizontal: AppSize.w(14)),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _promoSuccessMessage ?? "1 Month Free Access Activated",
                  style: TextStyle(
                    color: const Color(0xFF5A6C7D),
                    fontSize: AppSize.sp(14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Agar error hai toh controller me error text daal do taaki box ke andar dikhe
    if (_promoError != null && _promoController.text != _promoError) {
      _promoController.text = _promoError!;
      _promoController.selection = TextSelection.fromPosition(
        TextPosition(offset: _promoController.text.length),
      );
    }

    bool hasText = _promoInput.isNotEmpty && _promoError == null;

    return Container(
      height: AppSize.h(44),
      decoration: BoxDecoration(
        color: const Color(0xFFD1D9E0),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.symmetric(horizontal: AppSize.w(14)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promoController,
              // Agar error hai toh text red color me dikhega
              style: TextStyle(
                color: _promoError != null ? const Color(0xFFEE6A59) : const Color(0xFF5A6C7D),
                fontSize: AppSize.sp(14),
                fontWeight: _promoError != null ? FontWeight.w600 : FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: "Promo Code",
                hintStyle: TextStyle(
                  color: const Color(0xFF8A99A6),
                  fontSize: AppSize.sp(14),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) {
                if (_promoError != null) {
                  setState(() {
                    _promoError = null;
                    _promoController.clear();
                    _promoInput = "";
                  });
                } else {
                  setState(() {
                    _promoInput = val.trim();
                  });
                }
              },
            ),
          ),
          GestureDetector(
            onTap: hasText ? _applyPromoCode : null,
            child: Text(
              "Apply",
              style: TextStyle(
                color: hasText ? const Color(0xFF5A6C7D) : const Color(0xFF8A99A6),
                fontSize: AppSize.sp(14),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }  @override
  void dispose() {
    _pageController.dispose();
    _promoController.dispose();
    super.dispose();
  }

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
    final bool isTrial = (id == "trial");
    final bool isYearly = (id == "yearly");
    final bool isCredit = id.startsWith("credit_");

    return Transform.scale(
      scale: scale,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: AppSize.h(235),
          margin: EdgeInsets.symmetric(horizontal: AppSize.w(2)),
          padding: EdgeInsets.fromLTRB(AppSize.w(10), isMonthly ? AppSize.h(14) : AppSize.h(12), AppSize.w(10), AppSize.h(12)),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF001D2B),
                offset: Offset(6, 6),
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
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        bigNumber,
                        style: TextStyle(
                          fontSize: AppSize.sp(60),
                          height: 0.9,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    SizedBox(height: AppSize.h(2)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: isCredit ? AppSize.sp(20.0) : AppSize.sp(24.0),
                          height: 1.1,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    SizedBox(height: AppSize.h(2)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        price,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: isTrial ? AppSize.sp(15.0) : AppSize.sp(18.0),
                          fontWeight: isTrial ? FontWeight.w400 : FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (saveText != null) ...[
                      SizedBox(height: AppSize.h(1)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          saveText,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: AppSize.sp(11),
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: isMonthly ? AppSize.h(22) : (isYearly || isCredit ? AppSize.h(8) : (isTrial ? AppSize.h(6) : AppSize.h(16)))),
              Row(
                children: [
                  Text(
                    "Benefits",
                    style: TextStyle(
                      fontSize: AppSize.sp(13),
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: AppSize.w(8)),
                  Expanded(
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSize.h(6)),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: benefits
                      .map((benefit) => Padding(
                    padding: EdgeInsets.only(bottom: AppSize.h(2)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "• ",
                          style: TextStyle(fontSize: AppSize.sp(10), color: Colors.black87),
                        ),
                        SizedBox(width: AppSize.w(2)),
                        Expanded(
                          child: Text(
                            benefit,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppSize.sp(10),
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

    final activePlanIndex = (_currentPage.round() % _plans.length);
    final activePlan = _plans[activePlanIndex];
    final String activePlanId = activePlan["id"].toString();
    final bool isTopupFocused = activePlanId.startsWith("credit_");

    const String dynamicHeadingTitle = "Your credits at a glance";
    const String displayHeaderTitle = "Available\nCredits";
    const String displaySubtitle = "This Month";

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

    final String mainDisplayValue = "$_credits";

    final double dynamicFontSize = mainDisplayValue.length <= 1
        ? 128
        : mainDisplayValue.length == 2
        ? 70.0
        : 50.0;

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
                        padding: EdgeInsets.symmetric(horizontal: AppSize.w(18)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Padding(
                                padding: EdgeInsets.symmetric(horizontal: AppSize.w(4)),
                                child: const Icon(Icons.arrow_back, color: Color(0xFFA8B6C2)),
                              ),
                              padding: EdgeInsets.zero,
                              alignment: Alignment.centerLeft,
                            ),
                            SizedBox(height: AppSize.h(4)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: AppSize.w(4)),
                              child: Text(
                                "Keep Your\nCheck-ins\nActive",
                                style: TextStyle(
                                  color: const Color(0xFF78BCC4),
                                  fontSize: AppSize.sp(36),
                                  height: 1.1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(height: AppSize.h(10)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: AppSize.w(4)),
                              child: Text(
                                "Subscribe so I can look out for you every day",
                                style: TextStyle(
                                  color: const Color(0xFFD1D9E0),
                                  fontSize: AppSize.sp(16),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            SizedBox(height: AppSize.h(14)),
                            Center(
                              child: SizedBox(
                                width: AppSize.w(84),
                                height: AppSize.h(7),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (int i = 0; i < _plans.length; i++)
                                      Container(
                                        margin: EdgeInsets.symmetric(horizontal: AppSize.w(3)),
                                        width: 6,
                                        height: 6,
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
                            SizedBox(height: AppSize.h(14)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: AppSize.w(4)),
                              child: const Divider(color: Colors.white24),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: AppSize.h(4), horizontal: AppSize.w(4)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Plans",
                                    style: TextStyle(
                                      color: !isTopupFocused ? Colors.white : Colors.white54,
                                      fontSize: AppSize.sp(16),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    "Add Credits",
                                    style: TextStyle(
                                      color: isTopupFocused ? Colors.white : Colors.white54,
                                      fontSize: AppSize.sp(16),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: AppSize.w(4)),
                              child: const Divider(color: Colors.white24),
                            ),
                            SizedBox(height: AppSize.h(14)),
                            SizedBox(
                              height: AppSize.h(232),
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
                                      onTap: () {
                                        _pageController.animateToPage(
                                          index,
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: AppSize.h(14)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: AppSize.w(4)),
                              child: _buildPromoCodeField(),
                            ),
                            if (!_hideDisclaimer) ...[
                              SizedBox(height: AppSize.h(12)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: AppSize.w(4)),
                                child: Text(
                                  "Start your 7‑day free trial. Auto‑renews after trial until cancelled. Cancel anytime in your App Store settings.",
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: AppSize.sp(10),
                                  ),
                                ),
                              ),
                            ],
                            SizedBox(height: AppSize.h(14)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: AppSize.w(4)),
                              child: const Divider(color: Colors.white24),
                            ),
                            SizedBox(height: AppSize.h(10)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: AppSize.w(4)),
                              child: Text(
                                dynamicHeadingTitle,
                                style: TextStyle(
                                  color: const Color(0xFF78BCC4),
                                  fontSize: AppSize.sp(22),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(height: AppSize.h(10)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: AppSize.w(4)),
                              child: Center(
                                child: Container(
                                  width: AppSize.w(342),
                                  height: AppSize.h(155),
                                  padding: EdgeInsets.fromLTRB(AppSize.w(16), AppSize.h(14), AppSize.w(16), AppSize.h(12)),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF114B5F),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      if (_activePromoPlan != null)
                                        Positioned(
                                          top: -12,
                                          left: 0,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: AppSize.w(8), vertical: AppSize.h(2)),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: const Color(0xFFEE6A59)),
                                              borderRadius: BorderRadius.circular(4),
                                              color: const Color(0xFF114B5F),
                                            ),
                                            child: Text(
                                              _activePromoPlan!,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: AppSize.sp(11),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            flex: 5,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (_activePromoPlan != null) SizedBox(height: AppSize.h(4)),
                                                Text(
                                                  displayHeaderTitle,
                                                  style: TextStyle(
                                                    color: const Color(0xFFA8B6C2),
                                                    fontSize: AppSize.sp(32),
                                                    fontWeight: FontWeight.w700,
                                                    height: 1.05,
                                                  ),
                                                ),
                                                SizedBox(height: AppSize.h(4)),
                                                Text(
                                                  displaySubtitle,
                                                  style: TextStyle(
                                                    color: const Color(0xff89BCC8),
                                                    fontSize: AppSize.sp(16),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                SizedBox(height: AppSize.h(8)),
                                                Text(
                                                  planLabel,
                                                  style: TextStyle(
                                                    color: const Color(0xFFA8B6C2),
                                                    fontSize: AppSize.sp(11.5),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if (renewalText != null) ...[
                                                  SizedBox(height: AppSize.h(2)),
                                                  Text(
                                                    renewalText,
                                                    style: TextStyle(
                                                      color: const Color(0xff89BCC8),
                                                      fontSize: AppSize.sp(11),
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: 1,
                                            height: AppSize.h(115),
                                            color: const Color(0xff8A99A6),
                                            margin: EdgeInsets.symmetric(horizontal: AppSize.w(12)),
                                          ),
                                          Expanded(
                                            flex: 4,
                                            child: Center(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  mainDisplayValue,
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
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: AppSize.h(24)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Builder(
                  builder: (context) {
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
                      padding: EdgeInsets.symmetric(horizontal: AppSize.w(22), vertical: AppSize.h(12)),
                      color: const Color(0xFF002C3E),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: shouldDisableClick ? null : () => _handleBottomActionTap(activePlan),
                        child: Row(
                          children: [
                            const Spacer(),
                            Text(
                              buttonText,
                              style: TextStyle(
                                color: shouldDisableClick ? const Color(0xFF8A99A6) : Colors.white,
                                fontSize: AppSize.sp(15),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: AppSize.w(14)),
                            shouldDisableClick
                                ? Container(
                              width: 54,
                              height: 54,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4A5A6A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Color(0xFF8A99A6),
                                size: 28,
                              ),
                            )
                                : SvgPicture.asset(
                              "assets/svg/nextbutton.svg",
                              width: 54,
                              height: 54,
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