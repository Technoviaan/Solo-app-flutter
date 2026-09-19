import 'package:flutter/material.dart';
import 'package:solo_app/core/widgets/solo_logo.dart';
import '../core/utils/app_size.dart';

class CommonQuestionsPage extends StatelessWidget {
  const CommonQuestionsPage({super.key});

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
                      "Common Questions",
                      style: TextStyle(
                        fontSize: AppSize.sp(20),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF002C3E),
                      ),
                    ),
                    SizedBox(height: AppSize.h(20)),

                    questionItem(
                      "1. Is SOLO available worldwide?",
                      "SOLO is available in most countries, but not all. Some countries are excluded due to local regulations or app store policies. If your country is not supported, the Apple App Store or Google Play Store will automatically show a notice that the app is not available in your region.",
                    ),
                    questionItem(
                      "2. How does SOLO help me?",
                      "SOLO is your friendly daily check-in companion, like a friend looking out for you. At your preferred times, a big friendly turquoise SOLO button appears on your screen. Just tap it to check in.\n\nIf you miss a check-in, SOLO will send you reminders every 30 minutes. If you still haven't checked in within 2 hours, your trusted contacts will be alerted via SMS with your location.\n\nThis gives both you and your loved ones peace of mind knowing you're okay each day, especially helpful if you're staying or travelling on your own.",
                    ),
                    questionItem(
                      "3. How do check-ins work?",
                      "You can set up to 2 check-in times per day. At each scheduled time, a big friendly turquoise SOLO button appears on your screen for 20 seconds, then dismisses itself if not tapped. Just tap it to check in.",
                    ),
                    questionItem(
                      "4. Can I use SOLO offline?",
                      "No, SOLO requires an active internet connection (Wi-Fi or mobile data) to send check-ins, reminders, alerts, and for OTP verification during sign-in or account updates.",
                    ),
                    questionItem(
                      "5. Will SOLO drain my phone battery?",
                      "SOLO is designed to be lightweight and runs only when needed, at scheduled check-in times, during the 2-hour window, and when you open the app. It does not run constantly in the background and has minimal impact on your battery.",
                    ),
                    questionItem(
                      "6. What is the voice feature?",
                      "You can customise your app by selecting a voice (male or female). This voice will be used during check-in screen takeover reminders only. This feature is optional.",
                    ),
                    questionItem(
                      "7. Can I change my check-in times?",
                      "Yes, you can update your check-in times whenever you want. On the home screen, tap Schedule. Your changes take effect immediately for your next scheduled reminders.",
                    ),
                    questionItem(
                      "8. Can I pause or turn off my check-ins?",
                      "Yes, you can pause or turn off your check-ins anytime. On the home screen, tap Schedule. Use the toggle to turn reminders ON or OFF. If turned OFF, SOLO will not check in with you until you turn it back ON.",
                    ),
                    questionItem(
                      "9. What happens if I miss a check-in?",
                      "If you miss your scheduled check-in, the big friendly button screen stays for 2 minutes then dismisses. SOLO will immediately send you a push notification — just tap it to return and check in.\n\nIf you still don't check in, the screen pops up again every 30 minutes as a reminder. Your contacts will only be alerted if you haven't checked in within the 2-hour check-in window.\n\nOnce an alert is sent, a push notification will be sent to you to inform you that your contacts have been alerted. Your check-in schedule will be paused. Tap the notification to return to SOLO and resume your next scheduled check-in, or edit your settings before resuming.",
                    ),
                    questionItem(
                      "10. How does SOS work?",
                      "SOLO includes an enhanced emergency SOS button at the bottom-right of the check-in screen during screen take-over.\n\nIf you need urgent help, tap SOS, confirm your choice, and SOLO will send an SMS alert to your contacts right away — no need to wait for the next check-in reminder pop up which happens every 30 minutes within the 2-hour window.",
                    ),
                    questionItem(
                      "11. How do I add or remove a contact?",
                      "On the home screen, tap Contacts. Tap + to add a trusted contact from your phone. Once added, the + changes to -. Tap - to remove the contact.\n\nFree trial users can add up to 1 contact during the trial period. Monthly and yearly subscribers can add up to 2 contacts.",
                    ),
                    questionItem(
                      "12. Do my contacts need to agree to alerts?",
                      "SOLO will always send an SMS asking them to reply YES or NO to receive alerts. Until they reply YES, no alerts are sent. If they reply NO, they won't receive alerts, and you can then remove them and add another contact.",
                    ),
                    questionItem(
                      "13. How do I check a contact's consent?",
                      "After adding a contact, you can see their status in the Contacts screen: Pending (waiting for a reply), Opted In (replied YES, alerts will be sent), or Opted Out (replied NO, no alerts). You will also receive a push notification when they reply. You can remove an Opted Out contact and add another one.",
                    ),
                    questionItem(
                      "14. How are my contacts alerted?",
                      "Once you've added your trusted contacts, SOLO attempts to send them an SMS alert with a map link showing your last known location, if 2 hours pass without a scheduled check-in, or if you trigger the SOS button.\n\nSMS works using a cellular signal; it does not require Wi-Fi or mobile data. However, delivery depends on network conditions, the recipient's carrier, and local country regulations.\n\nIn some countries, automated SMS alerts from apps may be blocked, which can prevent alerts from being delivered. This is independent of the SOLO app. If unsure whether SMS alerts will work in your country, check with your local mobile provider.",
                    ),
                    questionItem(
                      "15. What if an SMS alert fails?",
                      "SOLO will automatically retry sending the alert up to 5 times to your added contacts. If all attempts are unsuccessful, you will receive a push notification to let you know. The alert credit used will be returned to your account.",
                    ),
                    questionItem(
                      "16. What are alert credits?",
                      "Alert credits are used when SOLO sends an alert to your trusted contacts, either because you missed a check-in or triggered the SOS button.\n\nEach alert uses 1 alert credit, regardless of how many contacts you have added. For example, whether you have 1 or 2 contacts, a single alert will still use only 1 alert credit.\n\nYour alert credits refresh monthly based on your active plan. Unused alert credits do not roll over to the next month.",
                    ),
                    questionItem(
                      "17. What if I need more alert credits?",
                      "No worries — you can easily top up more credits. On the home screen, tap Subscription. Scroll through the carousel to find the top-up options and proceed to purchase. Payment is processed through Stripe. Additional alert credits will be added immediately. Your daily check-ins keep going as normal.",
                    ),
                    questionItem(
                      "18. Do my unused alert credits roll over?",
                      "No, your unused alert credits will not roll over. They refresh monthly based on your active plan.",
                    ),
                    questionItem(
                      "19. How do I upgrade my plan?",
                      "On the home screen, tap Subscription. Choose the plan you want to upgrade to (e.g., from monthly to yearly) and confirm. Stripe handles the prorated charge automatically. Any remaining value from your current plan will be credited toward your upgrade. Your old alert credits will not carry over. The unused value is applied to your new plan.",
                    ),
                    questionItem(
                      "20. Can I downgrade my yearly plan?",
                      "You can only switch from a yearly plan to a monthly plan after your current plan expires. If you wish to change earlier, you can cancel your yearly plan (which stops future renewal). Your yearly access will continue until the year ends. Then resubscribe to a monthly plan separately thereafter. You will not receive a refund for any unused months.",
                    ),
                    questionItem(
                      "21. How do I cancel my subscription?",
                      "On the home screen, tap Subscription, then tap Cancel Subscription. Deleting the app does not cancel your subscription. You can still continue to use the app until your current subscription expires. Your check-ins will keep working normally during this time.",
                    ),
                    questionItem(
                      "22. What is SOLO's refund policy?",
                      "Refunds are considered on a case-by-case basis for valid reasons, at SOLO's discretion. For an accidental purchase, you may request a refund within 30 minutes, provided you have not used any subscription alert credits.\n\nOther valid reasons include technical failure on SOLO's side, persistent SMS delivery failure due to confirmed issues on our end, or your country blocking automated SMS alerts, which makes the service unusable. To request a refund, submit a support ticket through the app for approval.",
                    ),
                    questionItem(
                      "23. What happens if I delete the app?",
                      "Deleting the app does not cancel your subscription. Your check-ins will stop until you reinstall and sign back in. Your emergency contacts and settings are saved on SOLO's cloud servers, so you can download the app again and pick up where you left off.",
                    ),
                    questionItem(
                      "24. How do I sign back in to SOLO?",
                      "If you've signed out, you can sign back in using your registered phone number or email address. SOLO will send a one-time passcode (OTP) to verify your credentials. Enter the code to access your account.",
                    ),
                    questionItem(
                      "25. What if I change phone number or SIM?",
                      "Your emergency contacts and alerts are not affected because their numbers are stored securely on SOLO's cloud servers, not on your phone or SIM card. With an active internet connection (Wi-Fi or mobile data), your check-in reminders, push notifications, and SMS alerts to your trusted contacts will still work normally.\n\nHowever, you may not receive one-time passcodes (OTP) to verify your identity or update account settings. To keep full access, update your phone number in the app. On the home screen, tap More, then Account Settings, and select Profile. Tap the pencil icon next to your phone number, make your changes, and tap Save.",
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

  Widget questionItem(String question, String answer) {
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
              color: const Color(0xFF5A6C7D),
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}