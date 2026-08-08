import 'package:flutter/material.dart';
import 'package:solo_app/core/widgets/solo_logo.dart';
import '../core/utils/app_size.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSize.w(20), vertical: AppSize.h(10)),
              child: const SoloLogo(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: AppSize.w(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppSize.h(20)),
                    Text(
                      "About Us",
                      style: TextStyle(
                        fontSize: AppSize.sp(20),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF002C3E),
                      ),
                    ),
                    SizedBox(height: AppSize.h(10)),
                    Text(
                      "Let’s get\nto know SOLO",
                      style: TextStyle(
                        fontSize: AppSize.sp(44),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF002C3E),
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: AppSize.h(24)),
                    Text(
                      "SOLO was designed with a simple, caring intention: to ensure that people who live or travel alone are never truly alone.\n\nIn today’s world, many of us spend time alone — sometimes by choice, sometimes by circumstance — and can feel isolated. Yet a quiet worry remains: “If something happened, how long would it take for anyone to know?”\n\nSOLO is for those who live alone, travel solo, work remotely, or simply want the reassurance that someone is looking out for them. It’s not just an app — it’s your daily check-in buddy. Built with a minimalist, user-focused design free of ads and distractions, SOLO is here to give you and your loved ones the quiet assurance of knowing all is okay.",
                      style: TextStyle(
                        fontSize: AppSize.sp(12),
                        color: const Color(0xFF002C3E),
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: AppSize.h(34)),
                    Text(
                      "Loving SOLO?",
                      style: TextStyle(
                        fontSize: AppSize.sp(16),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF002C3E),
                      ),
                    ),
                    Text(
                      "Share the feeling. Rate us on the app stores",
                      style: TextStyle(
                        fontSize: AppSize.sp(12),
                        color: const Color(0xFF5A6C7D),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: AppSize.h(12)),
                    Row(
                      children: [
                        rateButton("Rate on", "App Store", const Color(0xFF26415E)),
                        SizedBox(width: AppSize.w(12)),
                        rateButton("Rate on", "Google Play", const Color(0xFF14B8A6)),
                      ],
                    ),
                    SizedBox(height: AppSize.h(30)),
                    versionInfo(),
                    SizedBox(height: AppSize.h(40)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.only(bottom: 30),
                        child: Icon(Icons.arrow_back, color: Color(0xFF8A99A6), size: 28),
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

  Widget rateButton(String sub, String main, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppSize.h(8)),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              sub,
              style: const TextStyle(color: Color(0xFFF5F5F5), fontSize: 12, fontWeight: FontWeight.w400), 
            ),
            Text(
              main,
              style: const TextStyle(color: Color(0xFFF5F5F5), fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget versionInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Version 1.0.0",
          style: TextStyle(color: Color(0xFF8A99A6), fontSize: 12,fontWeight: FontWeight.w400),
        ),
        const Text(
          "SOLO © 2026 Social Rebels™ Design. All rights reserved.",
          style: TextStyle(color: Color(0xFF8A99A6), fontSize: 12,fontWeight: FontWeight.w400),
        ),
        Row(
          children: [
            Text(
              "Privacy Policy",
              style: TextStyle(
                color: const Color(0xFF8A99A6),
                fontSize: 10,
                fontWeight: FontWeight.w400,
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFF8A99A6).withOpacity(0.5),
              ),
            ),
            const Text(" | ", style: TextStyle(color: Color(0xFF8A99A6), fontSize: 12)),
            Text(
              "Terms of Use",
              style: TextStyle(
                color: const Color(0xFF8A99A6),
                fontWeight: FontWeight.w400,
                fontSize: 10,
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFF8A99A6).withOpacity(0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
