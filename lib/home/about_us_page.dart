import 'package:flutter/material.dart';
import 'package:solo_app/core/widgets/solo_logo.dart';
import 'package:solo_app/home/privacy_policy_page.dart';
import 'package:solo_app/home/terms_of_use_page.dart';
import '../core/utils/app_size.dart';
// TODO: Apne project ke actual path ke hisaab se pages import kar lena
// import 'privacy_policy_page.dart';
// import 'terms_of_use_page.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F3),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: SoloLogo(),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "About Us",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF002C3E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Let’s get\nto know SOLO",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF002C3E),
                        height: 1.15,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "SOLO was designed with a simple, caring intention: to ensure that people who live or travel alone are never truly alone.\n\nIn today’s world, many of us spend time alone — sometimes by choice, sometimes by circumstance — and can feel isolated. Yet a quiet worry remains: “If something happened, how long would it take for anyone to know?”\n\nSOLO is for those who live alone, travel solo, work remotely, or simply want the reassurance that someone is looking out for them. It’s not just an app — it’s your daily check-in buddy. Built with a minimalist, user-focused design free of ads and distractions, SOLO is here to give you and your loved ones the quiet assurance of knowing all is okay.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF002C3E),
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      "Loving SOLO?",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF002C3E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Share the feeling. Rate us on the app stores",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5A6C7D),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: rateButton(
                            "Rate on",
                            "App Store",
                            const Color(0xFF26415E),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: rateButton(
                            "Rate on",
                            "Google Play",
                            const Color(0xFF14B8A6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    versionInfo(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Color(0xFF8A99A6), size: 26),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget rateButton(String sub, String main, Color color) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            sub,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w400,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            main,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget versionInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Version 1.0.0",
          style: TextStyle(
            color: Color(0xFF8A99A6),
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "SOLO © 2026 Social Rebels™ Design. All rights reserved.",
          style: TextStyle(
            color: Color(0xFF8A99A6),
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()));
              },
              child: Text(
                "Privacy Policy",
                style: TextStyle(
                  color: const Color(0xFF8A99A6),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFF8A99A6).withValues(alpha: 0.5),
                ),
              ),
            ),
            const Text(" | ", style: TextStyle(color: Color(0xFF8A99A6), fontSize: 11)),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfUsePage()));
              },
              child: Text(
                "Terms of Use",
                style: TextStyle(
                  color: const Color(0xFF8A99A6),
                  fontWeight: FontWeight.w400,
                  fontSize: 11,
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFF8A99A6).withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}