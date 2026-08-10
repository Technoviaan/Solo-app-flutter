import 'package:flutter/material.dart';
import '../core/storage/token_storage.dart';
import 'subscription_page.dart';

class PlanDetailsPage extends StatelessWidget {
  const PlanDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("My Plan")),

      body: FutureBuilder(
        future: Future.wait([
          TokenStorage.getSubscriptionStatus(),
          TokenStorage.getCredits(),
          TokenStorage.getMaxContacts(),
          TokenStorage.getMaxCheckins(),
        ]),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final status = snapshot.data![0] as int;
          final credits = snapshot.data![1] as int;
          final contacts = snapshot.data![2] as int;
          final checkins = snapshot.data![3] as int;

          String planName = "";
          if (status == 1) planName = "Free Trial";
          if (status == 2) planName = "Monthly";
          if (status == 3) planName = "Yearly";

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  "Plan: $planName",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text("Credits: $credits"),
                Text("Max Contacts: $contacts"),
                Text("Max Check-ins: $checkins"),

                const SizedBox(height: 30),

                /// TOP-UP (ONLY monthly/yearly)
                if (status == 2 || status == 3)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SubscriptionPage(),
                        ),
                      );
                    },
                    child: const Text("Buy Top-up Credits"),
                  ),

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionPage(),
                      ),
                    );
                  },
                  child: const Text("Upgrade Plan"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}