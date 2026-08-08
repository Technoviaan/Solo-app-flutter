import 'package:flutter/material.dart';
import 'subscription_page.dart';

class NoCreditsPage extends StatelessWidget {
  const NoCreditsPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF002C3E),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const Icon(
                Icons.warning,
                color: Colors.red,
                size: 60,
              ),

              const SizedBox(height: 20),

              const Text(
                "No Credits Available",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "You need credits to trigger alerts.\nPlease purchase a plan.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () {

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionPage(),
                    ),
                  );
                },
                child: const Text("Get Credits"),
              )
            ],
          ),
        ),
      ),
    );
  }
}