# Email Page Integration Guide

This document provides the full setup and flow for the **Email Page**, which appears immediately after the **"How SOLO works"** onboarding screen in the SOLO project.

## 1. User Flow Overview

1.  **Onboarding End**: The user finishes the "How SOLO works" step in `NameOnboardingPage` or `SoloOnboardingPage`.
2.  **Navigation**: Clicking the "Next" (arrow) button on the last onboarding page triggers:
    ```dart
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const EmailPage()),
    );
    ```
3.  **Email Page**: The user enters their email and agrees to the Privacy Policy.
4.  **API Call**: The app calls `UserApi.saveEmail(email)` to persist the email on the server.
5.  **Success Action**: 
    - Saves `email_completed = true` in local storage.
    - Checks `subscription_status`.
6.  **Next Screen**:
    - If `subscription_status == 0` (Free User) → Navigates to `SubscriptionPage`.
    - If `subscription_status != 0` (Subscribed) → Navigates to `HomePage`.

---

## 2. Page Code: `lib/loginWithNumber/email_page.dart`

This page handles email input, validation, and terms acceptance.

```dart
import 'package:flutter/material.dart';
import 'package:solo_app/core/storage/token_storage.dart';
import 'package:solo_app/home/home_page.dart';
import 'package:solo_app/loginWithNumber/user_email_api.dart';
import 'package:solo_app/subscription/subscription_page.dart';
import '../core/utils/app_size.dart';
import '../widgets/solo_mascot.dart';

class EmailPage extends StatefulWidget {
  const EmailPage({super.key});

  @override
  State<EmailPage> createState() => _EmailPageState();
}

class _EmailPageState extends State<EmailPage> {
  final TextEditingController emailController = TextEditingController();
  String error = "";
  bool loading = false;
  bool agree = false;

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    return emailRegex.hasMatch(email);
  }

  void submitEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      setState(() => error = "Email required");
      return;
    }

    if (!isValidEmail(email)) {
      setState(() => error = "Invalid email");
      return;
    }

    if (!agree) {
      setState(() => error = "Please accept terms");
      return;
    }

    setState(() {
      loading = true;
      error = "";
    });

    final res = await UserApi.saveEmail(email);

    setState(() => loading = false);

    if (res["status"] == 1) {
      await TokenStorage.saveEmailCompleted(true);
      
      final subscriptionStatus = await TokenStorage.getSubscriptionStatus();

      if (subscriptionStatus == 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } else if (res["status"] == 2) {
      setState(() => error = "Email already exists");
    } else {
      setState(() => error = "Something went wrong");
    }
  }

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSize.w(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSize.h(40)),
                  Text(
                    "Let’s keep\nyou connected\nand cared for",
                    style: TextStyle(
                      fontSize: AppSize.sp(30),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF083B44),
                    ),
                  ),
                  SizedBox(height: AppSize.h(30)),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12)],
                    ),
                    child: TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: "Email",
                        prefixIcon: Icon(Icons.email),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSize.h(20)),
                  Row(
                    children: [
                      Checkbox(
                        value: agree,
                        onChanged: (v) => setState(() => agree = v!),
                      ),
                      const Expanded(child: Text("I agree to Privacy Policy & Terms")),
                    ],
                  ),
                  if (error.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: AppSize.h(8)),
                      child: Text(error, style: const TextStyle(color: Colors.red)),
                    ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: loading ? null : submitEmail,
                      child: Container(
                        width: AppSize.w(50),
                        height: AppSize.w(50),
                        decoration: const BoxDecoration(
                          color: Color(0xFFB7D43A),
                          shape: BoxShape.circle,
                        ),
                        child: loading
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.arrow_forward),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSize.h(20)),
                ],
              ),
            ),
            if (!keyboardOpen)
              Positioned(
                left: -AppSize.w(50),
                bottom: AppSize.h(60),
                child: const IgnorePointer(child: SoloMascot()),
              ),
          ],
        ),
      ),
    );
  }
}
```

---

## 3. API Setup: `lib/loginWithNumber/user_email_api.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/api_config.dart';
import '../core/storage/token_storage.dart';

class UserApi {
  static Future<Map<String, dynamic>> saveEmail(String email) async {
    final token = await TokenStorage.getToken();

    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/user/email"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode({"email": email}),
    );

    return jsonDecode(res.body);
  }
}
```

---

## 4. Required Dependencies & Utilities

### Storage: `TokenStorage`
Used to manage auth tokens and onboarding status.
- **Path**: `lib/core/storage/token_storage.dart`
- **Dependency**: `flutter_secure_storage`

### Sizing Utility: `AppSize`
Handles responsive sizing based on screen dimensions.
- **Path**: `lib/core/utils/app_size.dart`

### Widget: `SoloMascot`
The animated eye mascot appearing in the background.
- **Path**: `lib/widgets/solo_mascot.dart`
- **Requires**: Assets `eye_center.png`, `eye_right.png`, `eye_left.png`.

---

## 5. Summary of Flow After Email Page
Once the email is submitted, the app transitions based on the user's subscription:
1. **Free User**: Sent to `SubscriptionPage` to choose a plan.
2. **Paid User**: Sent directly to `HomePage`.
