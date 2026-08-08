import 'package:flutter/material.dart';
import 'package:solo_app/core/widgets/solo_logo.dart';
import '../core/utils/app_size.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

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
              padding: EdgeInsets.symmetric(horizontal: AppSize.w(24), vertical: AppSize.h(10)),
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
                      "Terms of Use",
                      style: TextStyle(
                        fontSize: AppSize.sp(20),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF002C3E),
                      ),
                    ),
                    SizedBox(height: AppSize.h(20)),
                    
                    termItem(
                      "1. How does SOLO help me as a check‑in buddy?",
                      "SOLO is your friendly daily check‑in companion — like a friend looking out for you. It checks in on you at your preferred scheduled times.\n\nIf you miss the 2‑hour check‑in period, SOLO alerts your trusted contacts with your location, with reminders every 30 minutes in between.\n\nThis gives both you and your loved ones peace of mind knowing you’re okay each day — especially helpful if you’re staying or travelling on your own.",
                    ),
                    termItem(
                      "2. How do check‑ins work?",
                      "You can choose up to 2 check‑in times daily. At each scheduled time, the big friendly turquoise SOLO button will pop up on your screen — just tap it to check in.",
                    ),
                    termItem(
                      "3. What happens if I miss my scheduled check‑in?",
                      "If you miss the check‑in, the big friendly button screen stays for 2 minutes then dismisses. SOLO will immediately send you a gentle push notification — just tap it to return and check in.\n\nThe check‑in screen also pops up again every 30 minutes as a reminder. An alert to your contacts is only sent if you haven’t checked in within 2 hours of the scheduled time.",
                    ),
                    termItem(
                      "4. How does SOS work?",
                      "SOLO includes an enhanced emergency SOS button at the bottom‑right of the check‑in screen during screen take‑over. If you need urgent help, tap SOS, confirm your choice, and SOLO will send an SMS alert to your contacts right away — no need to wait for the 2‑hour check‑in window.",
                    ),
                    termItem(
                      "5. How do I add or remove a contact?",
                      "Go to Contacts on the home screen. Tap + to add a trusted contact. Tap the pencil icon to edit or remove.\n\nUse the toggle to turn alerts ON or OFF for each contact. You can add up to 2 contacts.",
                    ),
                    termItem(
                      "6. How are my contacts alerted?",
                      "Once you’ve added up to 2 trusted contacts, SOLO sends them an SMS alert along with a map link showing your last known location if you miss tapping the check‑in button after 2 hours, or if you trigger the SOS button.\n\nSMS works even without Wi‑Fi or mobile data, so alerts are delivered directly to their phones.",
                    ),
                    termItem(
                      "7. Can I change my check‑in times?",
                      "Yes — you can update your check‑in times whenever you want in the Schedule section of the app. Your changes take effect immediately for your next scheduled reminders.",
                    ),
                    termItem(
                      "8. What if I need more alert credits?",
                      "No worries — you can easily top up more credits in the Subscription section. Your daily check‑ins keep going as normal.",
                    ),
                    termItem(
                      "9. How do I cancel my subscription?",
                      "To cancel or change your plan, please visit your device’s app store settings. Your check‑ins will continue until your current subscription expires.",
                    ),
                    
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

  Widget termItem(String question, String answer) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.h(32)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: AppSize.sp(16),
              fontWeight: FontWeight.w500,
              color: const Color(0xFF002C3E),
              height: 1.3,
            ),
          ),
          SizedBox(height: AppSize.h(16)),
          Text(
            answer,
            style: TextStyle(
              fontSize: AppSize.sp(12),
              color: const Color(0xFF8A99A6),
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
