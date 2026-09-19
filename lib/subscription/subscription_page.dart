import 'dart:async'; // Required for Timer
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/storage/token_storage.dart';
import '../core/utils/app_size.dart';
import '../home/checkin/local_storage.dart';
import '../home/home_page.dart';
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
      "svgAsset": "assets/svg/mothly.svg",
      "priceId": "price_1TZ8zgH682jITs1wzNptVVi0",
    },
    {
      "id": "trial",
      "svgAsset": "assets/svg/free_trial.svg",
      "priceId": "price_1TZ8zgH682jITs1wzNptVVi0",
    },
    {
      "id": "yearly",
      "svgAsset": "assets/svg/year.svg",
      "priceId": "price_1TZ97RH682jITs1w0gc0XrBX",
    },
    {
      "id": "credit_3",
      "svgAsset": "assets/svg/3_alert.svg",
      "priceId": "price_1TZ993H682jITs1wc1kGxKlC",
    },
    {
      "id": "credit_5",
      "svgAsset": "assets/svg/5_alert.svg",
      "priceId": "price_1TZ9AaH682jITs1wrJafUO7C",
    },
  ];

  String? _activePromoPlan;
  DateTime? _promoActivationTime;
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
    final activationTimeStr =
    await LocalStorage.getString("promo_activation_time");
    final usedCodes = await LocalStorage.getStringList("used_promo_codes");

    final status = await TokenStorage.getSubscriptionStatus();
    final creditsVal = await TokenStorage.getCredits();

    setState(() {
      _activePromoPlan = activePlan;
      if (activationTimeStr != null) {
        _promoActivationTime = DateTime.parse(activationTimeStr);
      }
      _usedPromoCodes = usedCodes;
      _subscriptionStatus = status;
      _credits = creditsVal > 0 ? creditsVal : 1;

      if (activePlan != null) {
        _promoSuccess = true;
        _promoSuccessMessage = activePlan;
      }
    });

    try {
      final data = await SubscriptionApi.getSubscriptionStatus();
      if (data != null && mounted) {
        final freshStatus = await TokenStorage.getSubscriptionStatus();
        final freshCredits = await TokenStorage.getCredits();
        setState(() {
          _subscriptionStatus = freshStatus;
          _credits = freshCredits > 0 ? freshCredits : 1;
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
      if (_subscriptionStatus != 2 && _subscriptionStatus != 3 && _subscriptionStatus != 4) {
        showSubscriptionRequiredDialog(context);
        return;
      }
    }

    if (planId == "trial") {
      if (_subscriptionStatus >= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("You have already used the Free Trial.")),
        );
        return;
      }
    }

    if ((planId == "monthly" && _subscriptionStatus == 2) ||
        (planId == "yearly" && _subscriptionStatus == 3)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "You are already on the ${planId == 'monthly' ? 'Monthly' : 'Yearly'} plan.")),
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
      if (_subscriptionStatus != 2 && _subscriptionStatus != 3 && _subscriptionStatus != 4) {
        showSubscriptionRequiredDialog(context);
        return;
      }
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

  void _handleBackNavigation() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
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
      await LocalStorage.saveString(
          "promo_activation_time", now.toIso8601String());
      await LocalStorage.saveStringList("used_promo_codes", _usedPromoCodes);
      await LocalStorage.saveBool("hide_disclaimer", true);

      await SubscriptionApi.getSubscriptionStatus();
      await _loadPromoState();

      setState(() {
        _activePromoPlan = promoType;
        _promoActivationTime = now;
        _promoSuccess = true;
        _promoSuccessMessage = promoType == "1 Year Free Access"
            ? "1 Year Free Access Activated"
            : (promoType == "Unlimited Free Access"
            ? "Unlimited Free Access Activated"
            : "1 Month Free Access Activated");
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
              style: TextStyle(
                color: _promoError != null
                    ? const Color(0xFFEE6A59)
                    : const Color(0xFF5A6C7D),
                fontSize: AppSize.sp(14),
                fontWeight:
                _promoError != null ? FontWeight.w600 : FontWeight.w500,
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
                color:
                hasText ? const Color(0xFF5A6C7D) : const Color(0xFF8A99A6),
                fontSize: AppSize.sp(14),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  Widget _buildSvgCard({
    required String svgAsset,
    required double width,
    required double height,
    required VoidCallback onTap,
  }) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: AppSize.w(width),
          height: AppSize.h(height),
          child: SvgPicture.asset(
            svgAsset,
            width: AppSize.w(width),
            height: AppSize.h(height),
            fit: BoxFit.fill,
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

    const String dynamicHeadingTitle = "Your Credits At A Glance";
    const String displayHeaderTitle = "Available\nCredits";
    const String displaySubtitle = "This Month";

    String badgeLabel = "Trial Plan";
    if (activePlanId == "monthly") {
      badgeLabel = "Monthly Plan";
    } else if (activePlanId == "yearly") {
      badgeLabel = "Yearly Plan";
    } else if (isTopupFocused) {
      badgeLabel = "Top-Up Credits";
    }

    String planLabel = "1 free credit to start";
    String? renewalText;

    if (_activePromoPlan != null) {
      badgeLabel = _activePromoPlan!;
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
      badgeLabel = "Trial Plan";
      planLabel = "Free Trial Plan";
    } else if (_subscriptionStatus == 2) {
      badgeLabel = "Monthly Plan";
      planLabel = "Monthly Subscription";
    } else if (_subscriptionStatus == 3) {
      badgeLabel = "Yearly Plan";
      planLabel = "Yearly Subscription";
    }

    final String mainDisplayValue = "$_credits";

    final double dynamicFontSize = mainDisplayValue.length <= 1
        ? 128
        : mainDisplayValue.length == 2
        ? 70.0
        : 50.0;

    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
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
                          padding:
                          EdgeInsets.symmetric(horizontal: AppSize.w(18)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IconButton(
                                onPressed: _handleBackNavigation,
                                icon: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: AppSize.w(4)),
                                  child: const Icon(Icons.arrow_back,
                                      color: Color(0xFFA8B6C2)),
                                ),
                                padding: EdgeInsets.zero,
                                alignment: Alignment.centerLeft,
                              ),
                              SizedBox(height: AppSize.h(4)),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: AppSize.w(4)),
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
                                padding: EdgeInsets.symmetric(
                                    horizontal: AppSize.w(4)),
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
                                          margin: EdgeInsets.symmetric(
                                              horizontal: AppSize.w(3)),
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: (i ==
                                                (_currentPage.round() %
                                                    _plans.length))
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
                                padding: EdgeInsets.symmetric(
                                    horizontal: AppSize.w(4)),
                                child: const Divider(color: Colors.white24),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: AppSize.h(4),
                                    horizontal: AppSize.w(4)),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        int currentBase =
                                            (_currentPage / _plans.length).floor() *
                                                _plans.length;
                                        _pageController.animateToPage(
                                          currentBase + 1,
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                      child: Text(
                                        "Plans",
                                        style: TextStyle(
                                          color: !isTopupFocused
                                              ? Colors.white
                                              : Colors.white54,
                                          fontSize: AppSize.sp(16),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        int currentBase =
                                            (_currentPage / _plans.length).floor() *
                                                _plans.length;
                                        _pageController.animateToPage(
                                          currentBase + 3,
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                      child: Text(
                                        "Add Credits",
                                        style: TextStyle(
                                          color: isTopupFocused
                                              ? Colors.white
                                              : Colors.white54,
                                          fontSize: AppSize.sp(16),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: AppSize.w(4)),
                                child: const Divider(color: Colors.white24),
                              ),
                              SizedBox(height: AppSize.h(14)),
                              SizedBox(
                                height: AppSize.h(268),
                                child: PageView.builder(
                                  controller: _pageController,
                                  itemCount: 10000,
                                  clipBehavior: Clip.none,
                                  physics: const BouncingScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final plan = _plans[index % _plans.length];

                                    double diff = (index - _currentPage)
                                        .abs()
                                        .clamp(0.0, 1.0);
                                    double cardWidth =
                                        181.0 - (diff * (181.0 - 150.0));
                                    double cardHeight =
                                        260.0 - (diff * (260.0 - 217.0));
                                    double opacity = 1.0 - (diff * 0.4);

                                    return Opacity(
                                      opacity: opacity,
                                      child: _buildSvgCard(
                                        svgAsset: plan["svgAsset"],
                                        width: cardWidth,
                                        height: cardHeight,
                                        onTap: () {
                                          final activeIdx =
                                              _currentPage.round() % _plans.length;
                                          final tappedIdx = index % _plans.length;
                                          if (activeIdx != tappedIdx) {
                                            _pageController.animateToPage(
                                              index,
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              curve: Curves.easeInOut,
                                            );
                                          } else {
                                            final planId =
                                                plan["id"].toString();
                                            if (planId.startsWith("credit_")) {
                                              if (_subscriptionStatus != 2 &&
                                                  _subscriptionStatus != 3 &&
                                                  _subscriptionStatus != 4) {
                                                showSubscriptionRequiredDialog(
                                                    context);
                                              }
                                            }
                                          }
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: AppSize.h(24)),
                              Builder(
                                builder: (context) {
                                  String disclaimerText;
                                  if (activePlanId == "trial") {
                                    disclaimerText =
                                        "Start your 7-day free trial. Auto-renews after trial until cancelled. Cancel anytime in your App Store settings.";
                                  } else if (activePlanId == "monthly" ||
                                      activePlanId == "yearly") {
                                    disclaimerText =
                                        "Purchase confirms auto-renewal and agreement to Terms. Cancel anytime in your App Store settings.";
                                  } else {
                                    disclaimerText =
                                        "One-time purchase of alert credits. No auto-renewal. By purchasing, you agree to our Terms.";
                                  }

                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: AppSize.w(4)),
                                    child: Text(
                                      disclaimerText,
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: AppSize.sp(10),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: AppSize.h(12)),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: AppSize.w(4)),
                                child: _buildPromoCodeField(),
                              ),
                              SizedBox(height: AppSize.h(14)),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: AppSize.w(4)),
                                child: const Divider(color: Colors.white24),
                              ),
                              SizedBox(height: AppSize.h(14)),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: AppSize.w(4)),
                                child: Text(
                                  dynamicHeadingTitle,
                                  style: TextStyle(
                                    color: const Color(0xFF78BCC4),
                                    fontSize: AppSize.sp(22),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(height: AppSize.h(8)),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: AppSize.w(4)),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    badgeLabel,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: AppSize.sp(11),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: AppSize.h(10)),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: AppSize.w(4)),
                                child: Center(
                                  child: Container(
                                    width: AppSize.w(342),
                                    constraints: BoxConstraints(
                                        minHeight: AppSize.h(155)),
                                    padding: EdgeInsets.fromLTRB(
                                        AppSize.w(18),
                                        AppSize.h(14),
                                        AppSize.w(18),
                                        AppSize.h(12)),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF114B5F),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            flex: 6,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    displayHeaderTitle,
                                                    style: TextStyle(
                                                      color: const Color(
                                                          0xFFA8B6C2),
                                                      fontSize: AppSize.sp(32),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      height: 1.05,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: AppSize.h(4)),
                                                FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    displaySubtitle,
                                                    style: TextStyle(
                                                      color: const Color(
                                                          0xFFA8B6C2),
                                                      fontSize: AppSize.sp(16),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: AppSize.h(8)),
                                                FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    planLabel,
                                                    style: TextStyle(
                                                      color: const Color(
                                                          0xFFA8B6C2),
                                                      fontSize:
                                                          AppSize.sp(11.5),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                if (renewalText != null) ...[
                                                  SizedBox(
                                                      height: AppSize.h(2)),
                                                  FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      renewalText,
                                                      style: TextStyle(
                                                        color: const Color(
                                                            0xff89BCC8),
                                                        fontSize:
                                                            AppSize.sp(11),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: 1,
                                            color: const Color(0xff8A99A6),
                                            margin: EdgeInsets.symmetric(
                                                horizontal: AppSize.w(18)),
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
                                                    color:
                                                        const Color(0xFFA8B6C2),
                                                    fontSize: dynamicFontSize,
                                                    fontWeight: FontWeight.w600,
                                                    height: 1.0,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
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
                      final isCtaDisabled =
                          (_activePromoPlan != null) && !isTopup;

                      String buttonText = "Start 7-Day Free Trial";

                      // 1. If user HAS an active subscription
                      if (_subscriptionStatus >= 1) {
                        if (isTopup) {
                          if (planId == "credit_3") {
                            buttonText = "Top-Up 3 Alert Credits";
                          } else if (planId == "credit_5") {
                            buttonText = "Top-Up 5 Alert Credits";
                          }
                        } else if (_subscriptionStatus == 1) {
                          if (planId == "trial") {
                            buttonText = "Free Trial (Current)";
                          } else {
                            buttonText = "Upgrade plan";
                          }
                        } else if (_subscriptionStatus == 2 ||
                            _subscriptionStatus == 3) {
                          if (planId == "trial") {
                            buttonText = "Free Trial (Used)";
                          } else {
                            buttonText = "Upgrade your plan";
                          }
                        }
                      }
                      // 2. If user has NO subscription (_subscriptionStatus == 0)
                      else {
                        if (planId == "trial") {
                          buttonText = "Start 7-Day Free Trial";
                        } else if (planId == "monthly") {
                          buttonText = "Subscribe Monthly Plan";
                        } else if (planId == "yearly") {
                          buttonText = "Subscribe Yearly Plan";
                        } else if (planId == "credit_3") {
                          buttonText = "Top-Up 3 Alert Credits";
                        } else if (planId == "credit_5") {
                          buttonText = "Top-Up 5 Alert Credits";
                        }
                      }

                      if (_activePromoPlan != null && !isTopup) {
                        buttonText = _activePromoPlan!;
                      }

                      bool isTrialDisabled =
                          (planId == "trial") && (_subscriptionStatus >= 1);
                      bool isUpgradeText =
                      buttonText.toLowerCase().contains("upgrade");
                      bool shouldDisableClick =
                          (isCtaDisabled || isTrialDisabled) && !isUpgradeText;

                      return Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppSize.w(22), vertical: AppSize.h(12)),
                        color: const Color(0xFF002C3E),
                        child: Row(
                          children: [
                            const Spacer(),
                            Text(
                              buttonText,
                              style: TextStyle(
                                color: shouldDisableClick
                                    ? const Color(0xFF8A99A6)
                                    : Colors.white,
                                fontSize: AppSize.sp(15),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: AppSize.w(14)),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: shouldDisableClick
                                  ? null
                                  : () => _handleBottomActionTap(activePlan),
                              child: shouldDisableClick
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
                            ),
                          ],
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
      ),
    );
  }

  void showSubscriptionRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: EdgeInsets.zero,
          child: SizedBox(
            width: AppSize.w(342),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSize.w(24),
                vertical: AppSize.h(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEE6A59),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.lock,
                            color: Color(0xFF002C3E),
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Subscription\nRequired",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF002C3E),
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSize.h(20)),
                  const Text(
                    "To top up alert credits,\nplease subscribe to a\nMonthly or Yearly plan.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF002C3E),
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: AppSize.h(24)),
                  SizedBox(
                    width: AppSize.w(120),
                    height: AppSize.h(44),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF002C3E),
                        foregroundColor: const Color(0xFFF5F5F5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        int currentBase =
                            (_currentPage / _plans.length).floor() *
                                _plans.length;
                        _pageController.animateToPage(
                          currentBase,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text(
                        "Get It",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF5F5F5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showTopupRestrictedDialog(BuildContext context) {
    showSubscriptionRequiredDialog(context);
  }
}